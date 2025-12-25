-- Create table for client registrations
create extension if not exists pgcrypto;

create table if not exists public.client_registrations (
  id uuid primary key default gen_random_uuid(),
  created_at timestamptz not null default now(),
  status text not null default 'new',

  interest_type text not null,
  business_opportunities text[] not null default '{}',
  wealth_solutions text[] not null default '{}',

  first_name text not null,
  last_name text not null,
  phone text not null,
  email text not null,
  profession text,

  preferred_days text[] not null default '{}',
  preferred_time text not null,
  referred_by text not null
);

-- Optional: helpful index for admin searches
create index if not exists client_registrations_created_at_idx
  on public.client_registrations (created_at desc);
