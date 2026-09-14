-- =====================================================================
--  Control de cartas e inspecciones a entidades
--  Esquema PostgreSQL (probado sobre Supabase)
--
--  Modelo de acceso:
--    * Cualquier visitante (incluso sin sesión) puede LEER.
--    * Solo los correos registrados en public.editores pueden ESCRIBIR.
--  El control se aplica con RLS dentro de la base de datos, de modo que
--  la clave pública (anon key) del navegador no habilita escritura.
-- =====================================================================

create extension if not exists "pgcrypto";

-- ------------------------------------------------------------------
-- 1. Editores autorizados
-- ------------------------------------------------------------------
create table if not exists public.editores (
  email      text primary key,
  nombre     text,
  creado_en  timestamptz not null default now()
);

-- Reemplazar por los tres correos autorizados:
-- insert into public.editores (email, nombre) values
--   ('persona1@dominio.pe', 'Nombre 1'),
--   ('persona2@dominio.pe', 'Nombre 2'),
--   ('persona3@dominio.pe', 'Nombre 3')
-- on conflict (email) do nothing;

create or replace function public.es_editor() returns boolean
  language sql stable security definer set search_path = public as $$
  select exists (
    select 1 from public.editores e
    where lower(e.email) = lower(coalesce(auth.jwt() ->> 'email', ''))
  );
$$;

-- ------------------------------------------------------------------
-- 2. Padrón de entidades
-- ------------------------------------------------------------------
create table if not exists public.entidades (
  id             uuid primary key default gen_random_uuid(),
  nombre         text not null,
  ubicacion      text not null default '',
  responsable    text not null default '',
  carta_estado   text not null default 'pendiente'
                 check (carta_estado in ('pendiente', 'cursada')),
  carta_fecha    date,
  carta_numero   text not null default '',
  nota           text not null default '',
  creado_en      timestamptz not null default now(),
  actualizado_en timestamptz not null default now()
);

-- ------------------------------------------------------------------
-- 3. Visitas (programadas y realizadas)
-- ------------------------------------------------------------------
create table if not exists public.visitas (
  id             uuid primary key default gen_random_uuid(),
  entidad_id     uuid not null references public.entidades(id) on delete cascade,
  fecha          date not null,
  hora           time,
  estado         text not null default 'programada'
                 check (estado in ('programada', 'realizada', 'no_realizada')),
  resultado      text check (resultado in ('positivo', 'negativo')),
  responsable    text not null default '',
  nota           text not null default '',
  creado_en      timestamptz not null default now(),
  actualizado_en timestamptz not null default now(),
  -- el resultado solo tiene sentido en una visita realizada
  constraint resultado_coherente check (resultado is null or estado = 'realizada')
);

create index if not exists visitas_fecha_idx    on public.visitas (fecha);
create index if not exists visitas_entidad_idx  on public.visitas (entidad_id);

-- ------------------------------------------------------------------
-- 4. Marca de tiempo de actualización
-- ------------------------------------------------------------------
create or replace function public.tocar_actualizado() returns trigger
  language plpgsql as $$
begin
  new.actualizado_en = now();
  return new;
end;
$$;

drop trigger if exists entidades_actualizado on public.entidades;
create trigger entidades_actualizado before update on public.entidades
  for each row execute function public.tocar_actualizado();

drop trigger if exists visitas_actualizado on public.visitas;
create trigger visitas_actualizado before update on public.visitas
  for each row execute function public.tocar_actualizado();

-- ------------------------------------------------------------------
-- 5. Seguridad a nivel de fila (RLS)
-- ------------------------------------------------------------------
alter table public.editores  enable row level security;
alter table public.entidades enable row level security;
alter table public.visitas   enable row level security;

-- Lectura abierta: el enlace es público.
drop policy if exists editores_lectura on public.editores;
create policy editores_lectura on public.editores for select using (true);

drop policy if exists entidades_lectura on public.entidades;
create policy entidades_lectura on public.entidades for select using (true);

drop policy if exists visitas_lectura on public.visitas;
create policy visitas_lectura on public.visitas for select using (true);

-- Escritura reservada a los editores autorizados.
drop policy if exists entidades_escritura on public.entidades;
create policy entidades_escritura on public.entidades
  for all to authenticated using (public.es_editor()) with check (public.es_editor());

drop policy if exists visitas_escritura on public.visitas;
create policy visitas_escritura on public.visitas
  for all to authenticated using (public.es_editor()) with check (public.es_editor());

-- La tabla de editores no se modifica desde la aplicación: se administra
-- desde el panel de Supabase (sin política de escritura, RLS la bloquea).

-- ------------------------------------------------------------------
-- 6. Actualizaciones en vivo para los demás navegadores abiertos
-- ------------------------------------------------------------------
alter publication supabase_realtime add table public.entidades;
alter publication supabase_realtime add table public.visitas;
