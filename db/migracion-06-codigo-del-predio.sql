-- =====================================================================
--  Migración 06 — código del predio en cada visita
--
--  Ejecutar UNA VEZ en el SQL Editor. Es idempotente.
--
--  Guarda junto a la visita el código de la infraestructura que se va a
--  inspeccionar. Se toma del padrón al elegir la entidad, pero queda
--  escrito en la visita: si mañana el padrón cambia o la entidad se
--  renombra, lo inspeccionado ese día sigue siendo lo que fue.
--
--  Mientras esta migración no se aplique, la agenda igual muestra el
--  código deduciéndolo del padrón por el nombre de la entidad; lo que
--  falta es dejarlo escrito.
--
--  Se puede ejecutar por sí sola. Solo necesita la tabla `visitas` y la
--  función `es_editor()`, que vienen en db/schema.sql.
-- =====================================================================

alter table public.visitas add column if not exists codigo text not null default '';

create index if not exists visitas_codigo_idx on public.visitas (codigo) where codigo <> '';

-- El código identifica el predio, igual que la entidad: lo define quien
-- programa, no quien va a inspeccionar.
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
