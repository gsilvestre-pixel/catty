-- =====================================================================
--  Diagnóstico — por qué no se puede editar
--
--  Pegar TODO en el SQL Editor de Supabase y pulsar Run. No modifica
--  nada: solo consulta. Devuelve una fila por cosa revisada, con el
--  resultado en la columna «estado».
-- =====================================================================

select 'columna visitas.tipo'   as revisa,
       coalesce((select 'existe' from information_schema.columns
                 where table_schema='public' and table_name='visitas' and column_name='tipo'),
                'FALTA — ejecutar migracion-02') as estado
union all
select 'columna visitas.codigo',
       coalesce((select 'existe' from information_schema.columns
                 where table_schema='public' and table_name='visitas' and column_name='codigo'),
                'FALTA — ejecutar migracion-06')
union all
select 'columna visitas.estado',
       coalesce((select 'existe' from information_schema.columns
                 where table_schema='public' and table_name='visitas' and column_name='estado'),
                'FALTA — ejecutar migracion-01')
union all
select 'tabla entidades (padrón)',
       coalesce((select 'existe' from information_schema.tables
                 where table_schema='public' and table_name='entidades'),
                'FALTA — ejecutar migracion-05')
union all
select 'función es_editor()',
       coalesce((select 'existe' from pg_proc p join pg_namespace n on n.oid=p.pronamespace
                 where n.nspname='public' and p.proname='es_editor' limit 1),
                'FALTA — volver a ejecutar schema.sql')
union all
select 'función es_inspector()',
       coalesce((select 'existe' from pg_proc p join pg_namespace n on n.oid=p.pronamespace
                 where n.nspname='public' and p.proname='es_inspector' limit 1),
                'FALTA — ejecutar migracion-01')
union all
select 'tabla inspectores',
       coalesce((select 'existe' from information_schema.tables
                 where table_schema='public' and table_name='inspectores'),
                'no existe (normal si no se ejecutó la migracion-01)')
union all
select 'candado del inspector (trigger)',
       coalesce((select 'activo' from pg_trigger
                 where tgname='visitas_limita_inspector' and not tgisinternal limit 1),
                'no está')
union all
select 'permisos de escritura (políticas)',
       (select count(*)::text || ' de 3 (insertar, actualizar, borrar)'
        from pg_policies where schemaname='public' and tablename='visitas'
          and policyname in ('visitas_insertar','visitas_actualizar','visitas_borrar'))
union all
select 'correos con permiso de editar',
       coalesce((select string_agg(email, ', ') from public.editores), 'NINGUNO — nadie puede editar')
union all
select 'visitas guardadas',
       (select count(*)::text from public.visitas);
