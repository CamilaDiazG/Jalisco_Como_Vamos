-- Run once in Supabase SQL Editor before deploying delete-account.
begin;

-- Payment records stay for accounting, without a link to the deleted person.
alter table public.donation_intents alter column user_id drop not null;
alter table public.donation_intents drop constraint if exists donation_intents_user_id_fkey;
alter table public.donation_intents add constraint donation_intents_user_id_fkey
  foreign key (user_id) references auth.users(id) on delete set null;

-- Called ONLY by delete-account with the authenticated user's id.
create or replace function public.jcv_delete_account_data(p_user_id uuid)
returns void language plpgsql security definer set search_path = '' as $$
begin
  delete from jcv_private.tec_submissions where user_id = p_user_id;
  delete from jcv_private.lectores where usuario_id = p_user_id;
end;
$$;
revoke all on function public.jcv_delete_account_data(uuid) from public, anon, authenticated;
grant execute on function public.jcv_delete_account_data(uuid) to service_role;

commit;
