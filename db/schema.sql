-- =====================================================================
--  Agenda de inspecciones — esquema PostgreSQL (probado sobre Supabase)
--
--  Modelo de acceso:
--    * Cualquier visitante (incluso sin sesión) puede LEER la agenda.
--    * Solo los correos registrados en public.editores pueden ESCRIBIR.
--  El control se aplica con RLS dentro de la base de datos, así que la
--  clave pública (anon key) del navegador no habilita escritura.
-- =====================================================================

create extension if not exists "pgcrypto";

-- ------------------------------------------------------------------
-- 1. Editores autorizados
-- ------------------------------------------------------------------
create table if not exists public.editores (
  email     text primary key,
  nombre    text,
  creado_en timestamptz not null default now()
);

-- Reemplazar por los correos autorizados:
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
-- 2. Visitas programadas
-- ------------------------------------------------------------------
create table if not exists public.visitas (
  id             uuid primary key default gen_random_uuid(),
  entidad        text not null,
  fecha          date not null,
  hora           time not null,
  -- una o más personas por visita
  personas       text[] not null default '{}',
  observaciones  text not null default '',
  creado_en      timestamptz not null default now(),
  actualizado_en timestamptz not null default now()
);

create index if not exists visitas_fecha_idx    on public.visitas (fecha);
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

-- ------------------------------------------------------------------
-- 3. Seguridad a nivel de fila (RLS)
-- ------------------------------------------------------------------
alter table public.editores enable row level security;
alter table public.visitas  enable row level security;

drop policy if exists editores_lectura on public.editores;
create policy editores_lectura on public.editores for select using (true);

drop policy if exists visitas_lectura on public.visitas;
create policy visitas_lectura on public.visitas for select using (true);

drop policy if exists visitas_escritura on public.visitas;
create policy visitas_escritura on public.visitas
  for all to authenticated using (public.es_editor()) with check (public.es_editor());

-- La tabla de editores se administra desde el panel de Supabase: sin
-- política de escritura, el RLS la bloquea desde la aplicación.

-- ------------------------------------------------------------------
-- 4. Actualizaciones en vivo para los navegadores abiertos
-- ------------------------------------------------------------------
alter publication supabase_realtime add table public.visitas;
