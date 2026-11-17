-- Run once in Supabase SQL Editor after the existing JCV migrations.
begin;

create table if not exists public.donation_intents (
  attempt_id uuid primary key,
  user_id uuid not null references auth.users(id),
  amount_mxn integer not null check (amount_mxn between 20 and 10000),
  currency text not null default 'mxn' check (currency = 'mxn'),
  stripe_payment_intent_id text unique,
  status text not null default 'pending'
    check (status in ('pending', 'succeeded', 'failed', 'refunded')),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index if not exists donation_intents_user_created_idx
  on public.donation_intents(user_id, created_at desc);

alter table public.donation_intents enable row level security;
revoke all on public.donation_intents from public, anon, authenticated;
grant select on public.donation_intents to authenticated;
drop policy if exists donation_intents_owner_select on public.donation_intents;
create policy donation_intents_owner_select on public.donation_intents
  for select to authenticated using (user_id = (select auth.uid()));

create table if not exists public.donation_payment_events (
  stripe_event_id text primary key,
  stripe_payment_intent_id text not null,
  event_type text not null,
  processed_at timestamptz not null default now()
);
alter table public.donation_payment_events enable row level security;
revoke all on public.donation_payment_events from public, anon, authenticated;

-- Called ONLY by the server with a secret key, after Stripe signature verification.
create or replace function public.apply_donation_payment_event(
  p_event_id text, p_payment_intent_id text, p_amount_cents integer,
  p_currency text, p_status text, p_event_type text
) returns boolean language plpgsql security definer set search_path = '' as $$
declare changed integer;
begin
  if p_status not in ('pending', 'succeeded', 'failed', 'refunded')
     or p_currency <> 'mxn' or p_amount_cents < 2000 then
    raise exception 'invalid payment event';
  end if;
  if exists (select 1 from public.donation_payment_events where stripe_event_id = p_event_id) then
    return false;
  end if;
  update public.donation_intents
     set status = case
       when status = 'refunded' then status
       when status = 'succeeded' and p_status in ('failed', 'pending') then status
       else p_status end,
       updated_at = now()
   where stripe_payment_intent_id = p_payment_intent_id
     and amount_mxn * 100 = p_amount_cents
     and currency = p_currency;
  get diagnostics changed = row_count;
  if changed <> 1 then
    raise exception 'payment intent not registered or amount mismatch';
  end if;
  insert into public.donation_payment_events(stripe_event_id, stripe_payment_intent_id, event_type)
  values(p_event_id, p_payment_intent_id, p_event_type);
  return true;
end;
$$;
revoke all on function public.apply_donation_payment_event(text,text,integer,text,text,text)
  from public, anon, authenticated;
grant execute on function public.apply_donation_payment_event(text,text,integer,text,text,text)
  to service_role;

commit;
