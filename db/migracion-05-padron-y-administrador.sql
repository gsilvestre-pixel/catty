-- =====================================================================
--  Migración 05 — padrón de entidades y rol de administrador
--
--  Ejecutar UNA VEZ en el SQL Editor. Es idempotente.
--
--  Agrega:
--    1. Un administrador —por encima del editor— que es quien puede
--       mantener el padrón desde la propia agenda.
--    2. La tabla `entidades`: el padrón que alimenta las sugerencias al
--       escribir el nombre de una entidad y propone su clase de obra.
--
--  Se puede ejecutar por sí sola, sin la 01. Solo necesita la tabla
--  `editores` y la función `tocar_actualizado()`, que vienen en
--  db/schema.sql.
-- =====================================================================

-- ------------------------------------------------------------------
-- 1. Administrador
-- ------------------------------------------------------------------
alter table public.editores add column if not exists admin boolean not null default false;

-- ⬇⬇ CAMBIAR por el correo de quien administra, antes de ejecutar ⬇⬇
-- (este archivo es público: no conviene dejar aquí correos reales)
insert into public.editores (email, nombre, admin)
values ('CORREO-DEL-ADMINISTRADOR@dominio.pe', 'Administrador', true)
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
--    La llave es el NOMBRE, no el código: en el padrón de trabajo hay
--    entidades sin código (empresas de servicios, entidades del Estado,
--    titulares recién agregados). El código, cuando existe, es lo que
--    enlaza con la carpeta de fotos, y ahí sí no puede repetirse.
-- ------------------------------------------------------------------
create table if not exists public.entidades (
  id             bigint generated always as identity primary key,
  nombre         text not null,
  codigo         text not null default '',
  -- clase de obra del titular, para proponerla al programar la visita
  tipo           text not null default '',
  ubicacion      text not null default '',
  actualizado_en timestamptz not null default now()
);

-- Si la tabla ya existía de una ejecución anterior, se le agrega la columna.
alter table public.entidades add column if not exists tipo text not null default '';

alter table public.entidades drop constraint if exists entidades_tipo_check;
alter table public.entidades
  add constraint entidades_tipo_check check (tipo in ('', 'edificaciones', 'superficies', 'ambas'));

-- Una entidad, una fila. El índice tiene que ser sobre la columna tal cual:
-- uno sobre lower(nombre) sería más estricto, pero PostgreSQL no lo acepta
-- como destino de un "upsert por nombre", que es como carga el padrón.
drop index if exists public.entidades_nombre_uniq;
create unique index if not exists entidades_nombre_uniq on public.entidades (nombre);

-- El código se repite lo menos posible, pero no se declara único: 33 de las
-- 173 entidades no tienen, y renombrar una obligaría a borrarla antes.
drop index if exists public.entidades_codigo_uniq;
create index if not exists entidades_codigo_idx on public.entidades (codigo) where codigo <> '';

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
