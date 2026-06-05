-- 15: rat_signature_attachments
-- Sincronização remota de assinaturas de RAT via Supabase Storage privado.
-- RLS: admins_empresa, gerentes e técnicos da empresa podem ler;
-- admins_empresa e gerentes podem modificar.
-- Schema: tecnicos.papel em ('admin_empresa', 'gerente', 'tecnico')

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

-- 3) Policies RLS para leitura na tabela
alter table public.rat_signature_attachments enable row level security;

-- Idempotencia: remover policies da tabela antes de recriar
-- (nomes legados de policies por papel + nomes consolidados)
drop policy if exists "leitura rat_signature_attachments para admins da empresa" on public.rat_signature_attachments;
drop policy if exists "leitura rat_signature_attachments para gerentes da empresa" on public.rat_signature_attachments;
drop policy if exists "leitura rat_signature_attachments para tecnicos da empresa" on public.rat_signature_attachments;
drop policy if exists "admins_empresa podem upsert rat_signature_attachments" on public.rat_signature_attachments;
drop policy if exists "admins_empresa podem atualizar rat_signature_attachments" on public.rat_signature_attachments;
drop policy if exists "gerentes podem upsert rat_signature_attachments" on public.rat_signature_attachments;
drop policy if exists "gerentes podem atualizar rat_signature_attachments" on public.rat_signature_attachments;
drop policy if exists "tecnicos podem upsert rat_signature_attachments" on public.rat_signature_attachments;
drop policy if exists "tecnicos podem atualizar rat_signature_attachments" on public.rat_signature_attachments;
drop policy if exists "rat_signature_attachments_select_membros" on public.rat_signature_attachments;
drop policy if exists "rat_signature_attachments_insert_membros" on public.rat_signature_attachments;
drop policy if exists "rat_signature_attachments_update_membros" on public.rat_signature_attachments;

-- Leitura: membros ativos da empresa (admin_empresa, gerente, tecnico)
-- Policy unica por acao evita multiplas permissive policies (perf).
create policy "rat_signature_attachments_select_membros"
  on public.rat_signature_attachments
  for select
  using (
    exists (
      select 1 from public.tecnicos t
      where t.empresa_id = rat_signature_attachments.empresa_id
        and t.user_id = (select auth.uid())
        and t.papel in ('admin_empresa', 'gerente', 'tecnico')
        and t.ativo = true
    )
  );

-- 4) Policies RLS para escrita (upsert / update deleted_at)
-- Insert: membros ativos da empresa
create policy "rat_signature_attachments_insert_membros"
  on public.rat_signature_attachments
  for insert
  with check (
    exists (
      select 1 from public.tecnicos t
      where t.empresa_id = rat_signature_attachments.empresa_id
        and t.user_id = (select auth.uid())
        and t.papel in ('admin_empresa', 'gerente', 'tecnico')
        and t.ativo = true
    )
  );

-- Update: membros ativos da empresa (upsert on_conflict -> update, deleted_at)
create policy "rat_signature_attachments_update_membros"
  on public.rat_signature_attachments
  for update
  using (
    exists (
      select 1 from public.tecnicos t
      where t.empresa_id = rat_signature_attachments.empresa_id
        and t.user_id = (select auth.uid())
        and t.papel in ('admin_empresa', 'gerente', 'tecnico')
        and t.ativo = true
    )
  );

-- 5) Policies RLS para Storage bucket
-- O bucket é privado; políticas de storage determinam acesso ao arquivo.
-- Storage path: {empresa_id}/{rat_id}/{assinatura_id}/v{version}.png
-- storage.foldername(name) retorna array com primeiro segmento = empresa_id

-- Idempotencia: remover policies de storage antes de recriar
-- (nomes legados por papel + nomes consolidados)
drop policy if exists "admins_empresa acessam storage rat-signatures" on storage.objects;
drop policy if exists "gerentes acessam storage rat-signatures" on storage.objects;
drop policy if exists "tecnicos acessam storage rat-signatures" on storage.objects;
drop policy if exists "admins_empresa fazem upload em rat-signatures" on storage.objects;
drop policy if exists "gerentes fazem upload em rat-signatures" on storage.objects;
drop policy if exists "tecnicos fazem upload em rat-signatures" on storage.objects;
drop policy if exists "membros atualizam objeto em rat-signatures" on storage.objects;
drop policy if exists "rat_signatures_select_membros" on storage.objects;
drop policy if exists "rat_signatures_insert_membros" on storage.objects;
drop policy if exists "rat_signatures_update_membros" on storage.objects;

-- Leitura: membros ativos da empresa acessam storage rat-signatures
create policy "rat_signatures_select_membros"
  on storage.objects
  for select
  using (
    bucket_id = 'rat-signatures'
    and
    exists (
      select 1 from public.tecnicos t
      where t.empresa_id = (storage.foldername(name))[1]::uuid
        and t.user_id = (select auth.uid())
        and t.papel in ('admin_empresa', 'gerente', 'tecnico')
        and t.ativo = true
    )
  );

-- Upload: membros ativos da empresa fazem upload em rat-signatures
create policy "rat_signatures_insert_membros"
  on storage.objects
  for insert
  with check (
    bucket_id = 'rat-signatures'
    and
    exists (
      select 1 from public.tecnicos t
      where t.empresa_id = (storage.foldername(name))[1]::uuid
        and t.user_id = (select auth.uid())
        and t.papel in ('admin_empresa', 'gerente', 'tecnico')
        and t.ativo = true
    )
  );

-- Update: membros ativos da empresa atualizam objeto (retry/re-upload)
create policy "rat_signatures_update_membros"
  on storage.objects
  for update
  using (
    bucket_id = 'rat-signatures'
    and
    exists (
      select 1 from public.tecnicos t
      where t.empresa_id = (storage.foldername(name))[1]::uuid
        and t.user_id = (select auth.uid())
        and t.papel in ('admin_empresa', 'gerente', 'tecnico')
        and t.ativo = true
    )
  );
