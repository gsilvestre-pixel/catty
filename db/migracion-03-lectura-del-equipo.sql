-- =====================================================================
--  Migración 03 (OPCIONAL) — limitar la lectura al equipo
--
--  Estado actual: la agenda es de lectura abierta; cualquiera con el
--  enlace la ve. Ejecutar este archivo cambia eso: solo los correos
--  autorizados pueden leerla, y el resto encuentra una pantalla de
--  acceso. Al final está la instrucción para volver atrás.
--
--  Quedan autorizados: los editores, los inspectores y, además,
--  quienes se registren en la tabla `lectores` (personal que solo
--  consulta).
-- =====================================================================

-- ------------------------------------------------------------------
-- 1. Personal que solo consulta
-- ------------------------------------------------------------------
create table if not exists public.lectores (
  email     text primary key,
  nombre    text,
  creado_en timestamptz not null default now()
);

alter table public.lectores enable row level security;

drop policy if exists lectores_propia on public.lectores;
create policy lectores_propia on public.lectores
  for select to authenticated
  using (lower(email) = lower(coalesce(auth.jwt() ->> 'email', '')));

-- Registrar aquí a quienes solo miran la agenda:
-- insert into public.lectores (email, nombre) values
--   ('persona@jmasociados.pe', 'Nombre')
-- on conflict (email) do nothing;

-- ------------------------------------------------------------------
-- 2. Quién pertenece al equipo
-- ------------------------------------------------------------------
create or replace function public.es_del_equipo() returns boolean
  language sql stable security definer set search_path = public as $$
  select
    public.es_editor()
    or exists (select 1 from public.inspectores i
               where lower(i.email) = lower(coalesce(auth.jwt() ->> 'email', '')))
    or exists (select 1 from public.lectores l
               where lower(l.email) = lower(coalesce(auth.jwt() ->> 'email', '')));
$$;

-- ------------------------------------------------------------------
-- 3. La lectura deja de ser abierta
-- ------------------------------------------------------------------
drop policy if exists visitas_lectura on public.visitas;
create policy visitas_lectura on public.visitas
  for select to authenticated using (public.es_del_equipo());

-- Los nombres del equipo dejan de publicarse sin sesión.
revoke select on public.inspectores_publicos from anon;

-- =====================================================================
--  PARA VOLVER A LA LECTURA ABIERTA, ejecutar esto:
--
--    drop policy if exists visitas_lectura on public.visitas;
--    create policy visitas_lectura on public.visitas for select using (true);
--    grant select on public.inspectores_publicos to anon;
-- =====================================================================
