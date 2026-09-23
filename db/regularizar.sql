-- =====================================================================
--  Regularizar la base — aplica de una vez lo que falte de las
--  migraciones 02, 06 y 07.
--
--  Pegar TODO en el SQL Editor de Supabase y pulsar Run.
--  Es idempotente: lo que ya exista no se toca, y repetirlo no rompe
--  nada. No borra ni modifica ninguna visita.
--
--  Al final muestra el estado de cada cosa, para confirmar que quedó.
-- =====================================================================

-- 1. Clase de obra de cada visita (migración 02)
alter table public.visitas add column if not exists tipo text;
create index if not exists visitas_tipo_idx on public.visitas (tipo);

alter table public.visitas drop constraint if exists visitas_tipo_check;
alter table public.visitas
  add constraint visitas_tipo_check
  check (tipo in ('edificaciones', 'superficies', 'ambas'));

-- 2. Código del predio (migración 06)
alter table public.visitas add column if not exists codigo text not null default '';
create index if not exists visitas_codigo_idx on public.visitas (codigo) where codigo <> '';

-- 3. Estados admitidos, incluido «continuará» (migraciones 01 y 07)
alter table public.visitas drop constraint if exists visitas_estado_check;
alter table public.visitas
  add constraint visitas_estado_check
  check (estado in ('exitosa', 'negada', 'reprogramado', 'continuara'));

-- 4. Lo que un inspector NO puede cambiar de sus visitas: solo le quedan
--    el estado y las observaciones.
create or replace function public.visitas_guardia() returns trigger
  language plpgsql security definer set search_path = public as $$
begin
  if public.es_editor() then
    return new;
  end if;
  if new.entidad  is distinct from old.entidad
  or new.codigo   is distinct from old.codigo
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
-- Confirmación
-- ------------------------------------------------------------------
select 'columna visitas.tipo' as revisa,
       coalesce((select 'listo' from information_schema.columns
                 where table_schema='public' and table_name='visitas' and column_name='tipo'), 'FALTA') as estado
union all
select 'columna visitas.codigo',
       coalesce((select 'listo' from information_schema.columns
                 where table_schema='public' and table_name='visitas' and column_name='codigo'), 'FALTA')
union all
select 'estado «continuará» admitido',
       coalesce((select 'listo' from pg_constraint
                 where conname='visitas_estado_check'
                   and pg_get_constraintdef(oid) like '%continuara%'), 'FALTA')
union all
select 'tipo «ambas» admitido',
       coalesce((select 'listo' from pg_constraint
                 where conname='visitas_tipo_check'
                   and pg_get_constraintdef(oid) like '%ambas%'), 'FALTA')
union all
select 'tabla entidades (padrón)',
       coalesce((select 'listo' from information_schema.tables
                 where table_schema='public' and table_name='entidades'), 'FALTA — ejecutar migracion-05')
union all
select 'visitas guardadas', (select count(*)::text from public.visitas);
