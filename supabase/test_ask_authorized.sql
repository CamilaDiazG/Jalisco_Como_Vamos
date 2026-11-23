-- Ejecutar en SQL Editor como administrador DESPUÉS de aplicar 013.
-- No inserta lectores ni expone sus UUID. Todos los cambios de sesión se revierten.
begin;
select
  to_regprocedure('public.jcv_ask_authorized()')::text as firma,
  has_function_privilege('anon', 'public.jcv_ask_authorized()', 'EXECUTE') as anon_debe_ser_false,
  has_function_privilege('authenticated', 'public.jcv_ask_authorized()', 'EXECUTE') as authenticated_debe_ser_true;

-- Simular claims de un lector existente sin mostrar su identidad.
do $$
declare lector uuid;
begin
  select usuario_id into lector from jcv_private.lectores limit 1;
  if lector is null then raise exception 'Se necesita un lector existente para esta prueba'; end if;
  perform set_config('request.jwt.claim.sub', lector::text, true);
  perform set_config('request.jwt.claims', jsonb_build_object('sub', lector, 'role', 'authenticated')::text, true);
end $$;
set local role authenticated;
select public.jcv_ask_authorized() as lector_debe_ser_true;
reset role;

-- UUID aleatorio que se comprueba que no pertenece a lectores.
do $$
declare ajeno uuid;
begin
  loop
    ajeno := gen_random_uuid();
    exit when not exists (select 1 from jcv_private.lectores where usuario_id = ajeno);
  end loop;
  perform set_config('request.jwt.claim.sub', ajeno::text, true);
  perform set_config('request.jwt.claims', jsonb_build_object('sub', ajeno, 'role', 'authenticated')::text, true);
end $$;
set local role authenticated;
select public.jcv_ask_authorized() as no_lector_debe_ser_false;
reset role;

do $$
begin
  perform set_config('request.jwt.claim.sub', '', true);
  perform set_config('request.jwt.claims', '{}', true);
end $$;
set local role authenticated;
select public.jcv_ask_authorized() as sin_identidad_debe_ser_false;
reset role;
rollback;
