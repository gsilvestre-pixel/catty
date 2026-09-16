-- =====================================================================
--  Migración 04 — la agenda deja de ser pública: se ve con la clave del
--  equipo
--
--  Reemplaza a la migración 03 (no hace falta ejecutar aquella).
--
--  Cómo queda:
--    * Sin sesión, la agenda no devuelve nada: ni desde la página ni
--      desde fuera de ella.
--    * Con la clave del equipo se ve todo, en modo consulta.
--    * Los editores y los inspectores siguen entrando con su correo y
--      su código, y conservan sus permisos de escritura.
--
--  ANTES de ejecutar esto hay que crear la cuenta compartida:
--    Supabase → Authentication → Users → Add user → Create new user
--      Email: equipo@jmasociados.pe      (o el que prefiera)
--      Password: la clave que repartirá al equipo
--      Auto Confirm User: activado
--  Ese correo no necesita existir como buzón: nunca recibe nada.
--
--  Y después, en config.js del repositorio:
--    window.CONFIG_EQUIPO = { correo: "equipo@jmasociados.pe" };
-- =====================================================================

-- ------------------------------------------------------------------
-- 1. Quiénes solo consultan (aquí entra la cuenta compartida)
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

-- ⬇⬇ CAMBIAR por el correo de la cuenta compartida que acaba de crear ⬇⬇
insert into public.lectores (email, nombre)
values ('equipo@jmasociados.pe', 'Cuenta compartida del equipo')
on conflict (email) do nothing;

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

-- Los nombres del personal tampoco se publican sin sesión.
revoke select on public.inspectores_publicos from anon;

-- =====================================================================
--  PARA VOLVER A LA LECTURA ABIERTA:
--
--    drop policy if exists visitas_lectura on public.visitas;
--    create policy visitas_lectura on public.visitas for select using (true);
--    grant select on public.inspectores_publicos to anon;
--
--  PARA CAMBIAR LA CLAVE: Supabase → Authentication → Users → la cuenta
--  compartida → Reset password. No hay que tocar la aplicación.
-- =====================================================================
