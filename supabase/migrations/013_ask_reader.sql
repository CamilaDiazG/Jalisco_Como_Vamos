-- Additive: does not change lectores, existing RPCs, or dashboard permissions.
begin;
-- Fail closed instead of guessing the identity column of the private table.
do $$
begin
  if not exists (
    select 1 from information_schema.columns
    where table_schema = 'jcv_private' and table_name = 'lectores'
      and column_name = 'usuario_id' and udt_name = 'uuid'
  ) then
    raise exception 'Review jcv_private.lectores: ask requires usuario_id uuid; see ASK.md';
  end if;
end $$;

create or replace function public.jcv_ask_authorized()
returns boolean
language sql stable security definer
set search_path = ''
as $$
  select auth.uid() is not null and exists (
    select 1 from jcv_private.lectores where usuario_id = auth.uid()
  );
$$;
revoke all on function public.jcv_ask_authorized() from public, anon;
grant execute on function public.jcv_ask_authorized() to authenticated;
commit;
