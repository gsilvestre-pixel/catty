-- =====================================================================
--  Agenda de inspecciones — esquema PostgreSQL (probado sobre Supabase)
--
--  Modelo de acceso:
--    * Cualquier visitante, incluso sin sesión, puede LEER la agenda.
--    * Los correos de `editores` administran todo: programar, editar,
--      reasignar y borrar.
--    * Los correos de `inspectores` solo pueden cambiar el ESTADO y las
--      OBSERVACIONES de las visitas donde figuran asignados.
--  Todo se aplica con RLS dentro de la base: la clave pública que viaja
--  en el navegador no habilita ninguna escritura por sí sola.
--
--  Si el proyecto ya tenía una versión anterior de este archivo, no lo
--  vuelvas a ejecutar: usa db/migracion-01-estados-e-inspectores.sql.
-- =====================================================================

create extension if not exists "pgcrypto";

-- ------------------------------------------------------------------
-- 1. Quién administra la agenda
-- ------------------------------------------------------------------
create table if not exists public.editores (
  email     text primary key,
  nombre    text,
  creado_en timestamptz not null default now()
);

-- insert into public.editores (email, nombre) values
--   ('persona1@dominio.pe', 'Nombre 1'),
--   ('persona2@dominio.pe', 'Nombre 2')
-- on conflict (email) do nothing;

create or replace function public.es_editor() returns boolean
  language sql stable security definer set search_path = public as $$
  select exists (
    select 1 from public.editores e
    where lower(e.email) = lower(coalesce(auth.jwt() ->> 'email', ''))
  );
$$;

-- ------------------------------------------------------------------
-- 2. Quién hace las inspecciones
--    `nombre` debe escribirse EXACTAMENTE como aparece en las visitas.
-- ------------------------------------------------------------------
create table if not exists public.inspectores (
  nombre    text primary key,
  email     text not null unique,
  creado_en timestamptz not null default now()
);

-- insert into public.inspectores (nombre, email) values
--   ('J. Quispe', 'jquispe@dominio.pe'),
--   ('R. Vargas', 'rvargas@dominio.pe')
-- on conflict (nombre) do update set email = excluded.email;

create or replace function public.es_inspector(personas text[]) returns boolean
  language sql stable security definer set search_path = public as $$
  select exists (
    select 1 from public.inspectores i
    where lower(i.email) = lower(coalesce(auth.jwt() ->> 'email', ''))
      and i.nombre = any(personas)
  );
$$;

-- ------------------------------------------------------------------
-- 3. Visitas programadas
-- ------------------------------------------------------------------
create table if not exists public.visitas (
  id             uuid primary key default gen_random_uuid(),
  entidad        text not null,
  fecha          date not null,
  hora           time not null,
  -- clase de obra: 'edificaciones' (morado) o 'superficies' (verde)
  tipo           text check (tipo in ('edificaciones', 'superficies')),
  -- una o más personas por visita
  personas       text[] not null default '{}',
  -- nulo mientras la visita solo está programada
  estado         text check (estado in ('exitosa', 'negada', 'reprogramado')),
  observaciones  text not null default '',
  creado_en      timestamptz not null default now(),
  actualizado_en timestamptz not null default now()
);

create index if not exists visitas_fecha_idx    on public.visitas (fecha);
create index if not exists visitas_estado_idx   on public.visitas (estado);
create index if not exists visitas_tipo_idx     on public.visitas (tipo);
create index if not exists visitas_personas_idx on public.visitas using gin (personas);

create or replace function public.tocar_actualizado() returns trigger
  language plpgsql as $$
begin
  new.actualizado_en = now();
  return new;
end;
$$;

drop trigger if exists visitas_actualizado on public.visitas;
create trigger visitas_actualizado before update on public.visitas
  for each row execute function public.tocar_actualizado();

-- Un inspector puede tocar su visita, pero solo el estado y las
-- observaciones: la fecha, la hora, la entidad y a quién se asigna las
-- decide quien programa.
create or replace function public.visitas_guardia() returns trigger
  language plpgsql security definer set search_path = public as $$
begin
  if public.es_editor() then
    return new;
  end if;
  if new.entidad  is distinct from old.entidad
  or new.fecha    is distinct from old.fecha
  or new.hora     is distinct from old.hora
  or new.tipo     is distinct from old.tipo
  or new.personas is distinct from old.personas then
    raise exception 'Solo puedes cambiar el estado y las observaciones de tus visitas';
  end if;
  return new;
end $$;

drop trigger if exists visitas_limita_inspector on public.visitas;
create trigger visitas_limita_inspector before update on public.visitas
  for each row execute function public.visitas_guardia();

-- ------------------------------------------------------------------
-- 4. Seguridad a nivel de fila (RLS)
-- ------------------------------------------------------------------
alter table public.editores    enable row level security;
alter table public.inspectores enable row level security;
alter table public.visitas     enable row level security;

-- Cada persona autenticada solo ve su propia fila: los correos del
-- equipo no quedan expuestos en un sitio público.
drop policy if exists editores_lectura on public.editores;
create policy editores_lectura on public.editores
  for select to authenticated
  using (lower(email) = lower(coalesce(auth.jwt() ->> 'email', '')));

drop policy if exists inspectores_propia on public.inspectores;
create policy inspectores_propia on public.inspectores
  for select to authenticated
  using (lower(email) = lower(coalesce(auth.jwt() ->> 'email', '')));

-- La agenda muestra y filtra por nombre; esta vista los publica sin
-- los correos.
create or replace view public.inspectores_publicos as
  select nombre from public.inspectores;
grant select on public.inspectores_publicos to anon, authenticated;

-- La agenda es de lectura abierta.
drop policy if exists visitas_lectura on public.visitas;
create policy visitas_lectura on public.visitas for select using (true);

drop policy if exists visitas_escritura on public.visitas;

drop policy if exists visitas_insertar on public.visitas;
create policy visitas_insertar on public.visitas
  for insert to authenticated with check (public.es_editor());

drop policy if exists visitas_borrar on public.visitas;
create policy visitas_borrar on public.visitas
  for delete to authenticated using (public.es_editor());

drop policy if exists visitas_actualizar on public.visitas;
create policy visitas_actualizar on public.visitas
  for update to authenticated
  using (public.es_editor() or public.es_inspector(personas))
  with check (public.es_editor() or public.es_inspector(personas));

-- ------------------------------------------------------------------
-- 5. Actualizaciones en vivo para los navegadores abiertos
-- ------------------------------------------------------------------
alter publication supabase_realtime add table public.visitas;
