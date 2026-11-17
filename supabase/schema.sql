-- DVASLLC Owner Command Center schema
-- Run in Supabase SQL Editor. Then create the owner account in Supabase Auth.
create extension if not exists pgcrypto;

create table if not exists public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  display_name text not null default 'DVASLLC Owner',
  is_owner boolean not null default false,
  created_at timestamptz not null default now()
);

create table if not exists public.customers (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  email text not null,
  phone text,
  notes text,
  created_at timestamptz not null default now()
);
create table if not exists public.events (
  id uuid primary key default gen_random_uuid(),
  customer_id uuid not null references public.customers(id) on delete restrict,
  title text not null,
  event_type text,
  event_date date,
  guest_count integer check (guest_count is null or guest_count >= 0),
  budget numeric(12,2) not null default 0 check (budget >= 0),
  status text not null default 'inquiry' check (status in ('inquiry','planning','confirmed','completed','cancelled')),
  notes text,
  created_at timestamptz not null default now()
);
create table if not exists public.quotes (
  id uuid primary key default gen_random_uuid(),
  quote_number text not null default ('DV-' || upper(substr(replace(gen_random_uuid()::text,'-',''),1,8))),
  customer_id uuid not null references public.customers(id) on delete restrict,
  event_id uuid references public.events(id) on delete set null,
  event_type text,
  amount numeric(12,2) not null default 0 check (amount >= 0),
  status text not null default 'draft' check (status in ('draft','pending','sent','approved','rejected','expired')),
  reviewed_at timestamptz,
  notes text,
  created_at timestamptz not null default now()
);
create table if not exists public.communications (
  id uuid primary key default gen_random_uuid(),
  customer_id uuid not null references public.customers(id) on delete cascade,
  channel text not null,
  direction text not null check (direction in ('inbound','outbound','internal')),
  summary text not null,
  status text not null default 'logged',
  created_at timestamptz not null default now()
);
create table if not exists public.payments (
  id uuid primary key default gen_random_uuid(),
  customer_id uuid not null references public.customers(id) on delete restrict,
  event_id uuid references public.events(id) on delete set null,
  quote_id uuid references public.quotes(id) on delete set null,
  amount numeric(12,2) not null check (amount > 0),
  method text,
  reference text,
  paid_at date not null default current_date,
  created_at timestamptz not null default now()
);

alter table public.profiles enable row level security;
alter table public.customers enable row level security;
alter table public.events enable row level security;
alter table public.quotes enable row level security;
alter table public.communications enable row level security;
alter table public.payments enable row level security;

create or replace function public.is_dvas_owner()
returns boolean language sql stable security definer set search_path = public
as $$ select exists (select 1 from public.profiles p where p.id = auth.uid() and p.is_owner = true); $$;
revoke all on function public.is_dvas_owner() from public;
grant execute on function public.is_dvas_owner() to authenticated;

create policy "owner reads own profile" on public.profiles for select to authenticated using (id = auth.uid() and is_owner = true);

do $$ declare t text; begin
  foreach t in array array['customers','events','quotes','communications','payments'] loop
    execute format('create policy "owner manages %s" on public.%I for all to authenticated using (public.is_dvas_owner()) with check (public.is_dvas_owner())', t, t);
  end loop;
end $$;

grant select on public.profiles to authenticated;
grant select, insert, update, delete on public.customers, public.events, public.quotes, public.communications, public.payments to authenticated;

-- After creating the owner's account in Authentication > Users, replace the UUID below
-- with that user's Auth UID and run this insert in SQL Editor.
-- insert into public.profiles (id, display_name, is_owner)
-- values ('YOUR-AUTH-USER-UUID', 'DiverseVisualArtsStudioLLC Owner', true)
-- on conflict (id) do update set display_name=excluded.display_name, is_owner=true;
