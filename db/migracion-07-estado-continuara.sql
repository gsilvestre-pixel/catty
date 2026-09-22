-- =====================================================================
--  Migración 07 — estado «continuará»
--
--  Ejecutar UNA VEZ en el SQL Editor. Es idempotente.
--
--  Agrega un cuarto estado para la inspección que se empezó y sigue otro
--  día. La base valida los estados permitidos, así que sin esta migración
--  la agenda no puede guardarlo: lo rechaza con un error de validación.
--
--  Se puede ejecutar por sí sola; solo necesita la tabla `visitas`.
-- =====================================================================

alter table public.visitas drop constraint if exists visitas_estado_check;
alter table public.visitas
  add constraint visitas_estado_check
  check (estado in ('exitosa', 'negada', 'reprogramado', 'continuara'));
