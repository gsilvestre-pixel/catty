-- =====================================================================
--  Migración 05 — padrón de entidades y rol de administrador
--
--  Ejecutar UNA VEZ en el SQL Editor. Es idempotente.
--
--  Agrega:
--    1. Un administrador —por encima del editor— que es quien puede
--       mantener el padrón desde la propia agenda.
--    2. La tabla `entidades`: el padrón que alimenta las sugerencias al
--       escribir el nombre de una entidad.
-- =====================================================================

-- ------------------------------------------------------------------
-- 1. Administrador
-- ------------------------------------------------------------------
alter table public.editores add column if not exists admin boolean not null default false;

-- ⬇⬇ CAMBIAR por el correo de quien administra ⬇⬇
insert into public.editores (email, nombre, admin)
values ('gsilvestre@jmasociados.pe', 'Administrador', true)
on conflict (email) do update set admin = true;

create or replace function public.es_admin() returns boolean
  language sql stable security definer set search_path = public as $$
  select exists (
    select 1 from public.editores e
    where lower(e.email) = lower(coalesce(auth.jwt() ->> 'email', ''))
      and e.admin
  );
$$;

-- ------------------------------------------------------------------
-- 2. Padrón de entidades
--    El código es la llave: es lo que enlaza con la carpeta de fotos.
-- ------------------------------------------------------------------
create table if not exists public.entidades (
  codigo         text primary key,
  nombre         text not null,
  ubicacion      text not null default '',
  actualizado_en timestamptz not null default now()
);

create index if not exists entidades_nombre_idx on public.entidades (nombre);

drop trigger if exists entidades_actualizado on public.entidades;
create trigger entidades_actualizado before update on public.entidades
  for each row execute function public.tocar_actualizado();

alter table public.entidades enable row level security;

-- Lectura abierta, igual que la agenda. Si más adelante se ejecuta la
-- migración 04 y la agenda pasa a ser privada, cambiar esta política por:
--   for select to authenticated using (public.es_del_equipo())
drop policy if exists entidades_lectura on public.entidades;
create policy entidades_lectura on public.entidades for select using (true);

-- El padrón lo mantiene únicamente el administrador.
drop policy if exists entidades_escritura on public.entidades;
create policy entidades_escritura on public.entidades
  for all to authenticated using (public.es_admin()) with check (public.es_admin());
