-- 15: rat_signature_attachments
-- Sincronização remota de assinaturas de RAT via Supabase Storage privado.
-- RLS: admins, gerentes e técnicos da empresa podem ler; admins e gerentes podem modificar.

-- 1) Bucket privado para assinaturas
insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values (
  'rat-signatures',
  'rat-signatures',
  false,
  10485760, -- 10 MB
  array ['image/png', 'image/jpeg']
)
on conflict (id) do update
  set public = false,
      file_size_limit = 10485760,
      allowed_mime_types = array ['image/png', 'image/jpeg'];

-- 2) Tabela de metadados
create table if not exists public.rat_signature_attachments (
  id uuid primary key default gen_random_uuid(),
  empresa_id uuid not null references public.empresas(id),
  rat_id uuid not null references public.rats(id),
  assinatura_id text not null,
  storage_bucket text not null default 'rat-signatures',
  storage_path text not null,
  sha256 text not null,
  size_bytes integer not null,
  mime_type text not null default 'image/png',
  version integer not null default 1,
  deleted_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (empresa_id, rat_id, assinatura_id, version)
);

-- 3) Policies RLS para leitura
alter table public.rat_signature_attachments enable row level security;

-- Leitura: admins e gerentes da empresa + técnicos que pertencem à empresa
create policy "leitura rat_signature_attachments para admins da empresa"
  on public.rat_signature_attachments
  for select
  using (
    exists (
      select 1 from public.admin_empresas ae
      where ae.empresa_id = rat_signature_attachments.empresa_id
        and ae.user_id = auth.uid()
    )
  );

create policy "leitura rat_signature_attachments para gerentes da empresa"
  on public.rat_signature_attachments
  for select
  using (
    exists (
      select 1 from public.gerente_empresas ge
      where ge.empresa_id = rat_signature_attachments.empresa_id
        and ge.user_id = auth.uid()
    )
  );

create policy "leitura rat_signature_attachments para tecnicos da empresa"
  on public.rat_signature_attachments
  for select
  using (
    exists (
      select 1 from public.equipe_membros em
      join public.equipes e on e.id = em.equipe_id
      where e.empresa_id = rat_signature_attachments.empresa_id
        and em.user_id = auth.uid()
    )
  );

-- 4) Policies RLS para escrita (upsert / update deleted_at)
create policy "admins podem upsert rat_signature_attachments"
  on public.rat_signature_attachments
  for insert with check (
    exists (
      select 1 from public.admin_empresas ae
      where ae.empresa_id = rat_signature_attachments.empresa_id
        and ae.user_id = auth.uid()
    )
  );

create policy "admins podem atualizar rat_signature_attachments"
  on public.rat_signature_attachments
  for update
  using (
    exists (
      select 1 from public.admin_empresas ae
      where ae.empresa_id = rat_signature_attachments.empresa_id
        and ae.user_id = auth.uid()
    )
  );

create policy "gerentes podem upsert rat_signature_attachments"
  on public.rat_signature_attachments
  for insert with check (
    exists (
      select 1 from public.gerente_empresas ge
      where ge.empresa_id = rat_signature_attachments.empresa_id
        and ge.user_id = auth.uid()
    )
  );

create policy "gerentes podem atualizar rat_signature_attachments"
  on public.rat_signature_attachments
  for update
  using (
    exists (
      select 1 from public.gerente_empresas ge
      where ge.empresa_id = rat_signature_attachments.empresa_id
        and ge.user_id = auth.uid()
    )
  );

-- 5) Policies RLS para Storage bucket
-- O bucket é privado; políticas de storage determinam acesso ao arquivo.
-- Usuários com policy de leitura na tabela podem acessar o arquivo via signed URL.

create policy "admins acessam storage rat-signatures"
  on storage.objects
  for select
  using (
    bucket_id = 'rat-signatures'
    and
    exists (
      select 1 from public.admin_empresas ae
      where ae.empresa_id = (storage.foldername(name))[1]::uuid
        and ae.user_id = auth.uid()
    )
  );

create policy "gerentes acessam storage rat-signatures"
  on storage.objects
  for select
  using (
    bucket_id = 'rat-signatures'
    and
    exists (
      select 1 from public.gerente_empresas ge
      where ge.empresa_id = (storage.foldername(name))[1]::uuid
        and ge.user_id = auth.uid()
    )
  );

create policy "tecnicos acessam storage rat-signatures"
  on storage.objects
  for select
  using (
    bucket_id = 'rat-signatures'
    and
    exists (
      select 1 from public.equipe_membros em
      join public.equipes e on e.id = em.equipe_id
      where e.empresa_id = (storage.foldername(name))[1]::uuid
        and em.user_id = auth.uid()
    )
  );

create policy "admins fazem upload em rat-signatures"
  on storage.objects
  for insert
  with check (
    bucket_id = 'rat-signatures'
    and
    exists (
      select 1 from public.admin_empresas ae
      where ae.empresa_id = (storage.foldername(name))[1]::uuid
        and ae.user_id = auth.uid()
    )
  );

create policy "gerentes fazem upload em rat-signatures"
  on storage.objects
  for insert
  with check (
    bucket_id = 'rat-signatures'
    and
    exists (
      select 1 from public.gerente_empresas ge
      where ge.empresa_id = (storage.foldername(name))[1]::uuid
        and ge.user_id = auth.uid()
    )
  );