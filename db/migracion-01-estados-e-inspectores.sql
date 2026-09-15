-- =====================================================================
--  Migración 01 — estados de inspección e inspectores por correo
--
--  Ejecutar UNA VEZ en el SQL Editor de un proyecto que ya tenga
--  db/schema.sql aplicado. Es idempotente: repetirla no rompe nada.
--
--  Qué cambia:
--   1. La columna `resultado` pasa a llamarse `estado` y admite
--      'exitosa', 'negada' y 'reprogramado'.
--   2. Nueva tabla `inspectores` (nombre + correo) y vista pública que
--      expone solo los nombres, nunca los correos.
--   3. Cada inspector, identificado con su correo, puede cambiar el
--      estado y las observaciones ÚNICAMENTE de las visitas donde
--      figura asignado. Programar, editar y borrar sigue siendo de los
--      editores.
-- =====================================================================

-- ------------------------------------------------------------------
-- 1. resultado -> estado
-- ------------------------------------------------------------------
do $$
begin
  if exists (select 1 from information_schema.columns
             where table_schema = 'public' and table_name = 'visitas' and column_name = 'resultado')
     and not exists (select 1 from information_schema.columns
             where table_schema = 'public' and table_name = 'visitas' and column_name = 'estado') then
    alter table public.visitas rename column resultado to estado;
  end if;
  if not exists (select 1 from information_schema.columns
             where table_schema = 'public' and table_name = 'visitas' and column_name = 'estado') then
    alter table public.visitas add column estado text;
  end if;
end $$;

alter table public.visitas drop constraint if exists resultado_coherente;
alter table public.visitas drop constraint if exists visitas_resultado_check;
alter table public.visitas drop constraint if exists visitas_estado_check;
alter table public.visitas
  add constraint visitas_estado_check check (estado in ('exitosa', 'negada', 'reprogramado'));

drop index if exists visitas_resultado_idx;
create index if not exists visitas_estado_idx on public.visitas (estado);

-- ------------------------------------------------------------------
-- 2. Inspectores
--    `nombre` debe escribirse EXACTAMENTE como aparece en las visitas.
-- ------------------------------------------------------------------
create table if not exists public.inspectores (
  nombre    text primary key,
  email     text not null unique,
  creado_en timestamptz not null default now()
);

alter table public.inspectores enable row level security;

-- Cada persona autenticada solo ve su propia fila: los correos del
-- equipo no quedan expuestos en un sitio público.
drop policy if exists inspectores_propia on public.inspectores;
create policy inspectores_propia on public.inspectores
  for select to authenticated
  using (lower(email) = lower(coalesce(auth.jwt() ->> 'email', '')));

-- La agenda necesita los nombres para mostrarlos y filtrarlos; esta
-- vista los publica sin los correos.
create or replace view public.inspectores_publicos as
  select nombre from public.inspectores;
grant select on public.inspectores_publicos to anon, authenticated;

-- Registrar aquí al equipo (el nombre, tal cual se escribe en la agenda):
-- insert into public.inspectores (nombre, email) values
--   ('J. Quispe',  'jquispe@jmasociados.pe'),
--   ('R. Vargas',  'rvargas@jmasociados.pe'),
--   ('M. Flores',  'mflores@jmasociados.pe')
-- on conflict (nombre) do update set email = excluded.email;

-- ------------------------------------------------------------------
-- 3. Permisos: editores administran todo; inspectores solo lo suyo
-- ------------------------------------------------------------------
create or replace function public.es_inspector(personas text[]) returns boolean
  language sql stable security definer set search_path = public as $$
  select exists (
    select 1 from public.inspectores i
    where lower(i.email) = lower(coalesce(auth.jwt() ->> 'email', ''))
      and i.nombre = any(personas)
  );
$$;

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
  or new.personas is distinct from old.personas then
    raise exception 'Solo puedes cambiar el estado y las observaciones de tus visitas';
  end if;
  return new;
end $$;

drop trigger if exists visitas_limita_inspector on public.visitas;
create trigger visitas_limita_inspector before update on public.visitas
  for each row execute function public.visitas_guardia();
