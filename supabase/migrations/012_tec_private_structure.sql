-- Estructura únicamente: no crea ni aprueba un cuestionario o consentimiento.
begin;
create schema if not exists jcv_private;

create table if not exists jcv_private.tec_instruments (
  instrument_id text not null,
  version text not null,
  status text not null default 'draft' check (status in ('draft', 'approved', 'retired')),
  introduction text,
  eligibility jsonb,
  questionnaire jsonb,
  consent_version text,
  consent_text text,
  privacy_notice text,
  approved_at timestamptz,
  approved_by text,
  primary key (instrument_id, version),
  check (status <> 'approved' or (
    nullif(introduction, '') is not null and eligibility is not null and
    questionnaire is not null and jsonb_typeof(questionnaire) = 'array' and
    jsonb_array_length(questionnaire) > 0 and nullif(consent_version, '') is not null and
    nullif(consent_text, '') is not null and nullif(privacy_notice, '') is not null and
    approved_at is not null and nullif(approved_by, '') is not null
  ))
);

create table if not exists jcv_private.tec_submissions (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id),
  request_id uuid not null,
  instrument_id text not null,
  instrument_version text not null,
  consent_version text not null,
  consent_accepted_at timestamptz not null,
  received_at timestamptz not null default now(),
  answers jsonb not null check (jsonb_typeof(answers) = 'object'),
  foreign key (instrument_id, instrument_version)
    references jcv_private.tec_instruments(instrument_id, version),
  unique (user_id, request_id)
);

alter table jcv_private.tec_instruments enable row level security;
alter table jcv_private.tec_submissions enable row level security;
revoke all on jcv_private.tec_instruments, jcv_private.tec_submissions from public, anon, authenticated;
-- Sin políticas ni RPC de escritura: no aceptar respuestas hasta aprobar y
-- validar el instrumento en servidor. Las RPC AMG/TEC actuales no se modifican.
commit;
