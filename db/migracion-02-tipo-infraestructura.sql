-- =====================================================================
--  Migración 02 — tipo de infraestructura
--
--  Ejecutar UNA VEZ en el SQL Editor, después de la migración 01.
--  Es idempotente: repetirla no rompe nada.
--
--  Agrega a cada visita la clase de obra inspeccionada:
--    'edificaciones' (se muestra en morado) o
--    'superficies'   (se muestra en verde).
--  Queda nula mientras no se especifique.
-- =====================================================================

alter table public.visitas add column if not exists tipo text;

alter table public.visitas drop constraint if exists visitas_tipo_check;
alter table public.visitas
  add constraint visitas_tipo_check check (tipo in ('edificaciones', 'superficies'));

create index if not exists visitas_tipo_idx on public.visitas (tipo);

-- El tipo lo define quien programa, igual que la fecha o la entidad: se suma
-- a las columnas que un inspector no puede modificar.
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
