-- Run read-only in the project's SQL Editor BEFORE applying migration 013.
-- Returns schema and function definitions, never reader identities or microdata.
select column_name, data_type, is_nullable
from information_schema.columns
where table_schema = 'jcv_private' and table_name = 'lectores'
order by ordinal_position;

select p.oid::regprocedure as signature, p.prosecdef as security_definer,
       p.proconfig as configuration, pg_get_functiondef(p.oid) as definition
from pg_proc p join pg_namespace n on n.oid = p.pronamespace
where n.nspname in ('public', 'jcv_private')
  and (p.proname in ('jcv_catalogos', 'jcv_resumen_bienestar', 'jcv_dimension')
       or p.prosrc ilike '%lectores%');

select schemaname, tablename, policyname, roles, cmd, qual
from pg_policies where schemaname = 'jcv_private' and tablename = 'lectores';
