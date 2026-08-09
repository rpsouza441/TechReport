[CmdletBinding()]
param(
  [Parameter(Mandatory = $true)]
  [string]$OutputDirectory,

  [string]$MigrationDirectory
)

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

if ([string]::IsNullOrWhiteSpace($MigrationDirectory)) {
  $MigrationDirectory = Join-Path $PSScriptRoot '..\migrations'
}

$manifest = @(
  '0001_company_auth_base.sql',
  '0002_company_rats_base.sql',
  '0003_rat_completo_fields.sql',
  '0004_optimize_rls_auth_uid.sql',
  '0005_fix_function_search_path.sql',
  '0006_admin_roles_base.sql',
  '0007_optimize_admin_rls_auth_uid.sql',
  '0008_responsavel_documento.sql',
  '0009_tecnico_convites_equipe.sql',
  '0010_fix_tecnico_convites_digest.sql',
  '0011_finalize_sprint_8_5_convites.sql',
  '0012_fix_invite_acceptance_password.sql',
  '0013_gerente_convites_tecnicos.sql',
  '0014_gerente_gerencia_tecnicos.sql',
  '0015_rat_signature_attachments.sql',
  '0016_update_own_display_name.sql',
  '0018_add_rat_audit_fields.sql',
  '0019_create_rat_audit_log.sql',
  '0020_add_admin_empresa_to_rats_select_policy.sql',
  '0021_fix_tecnicos_update_with_check_self_update.sql',
  '0022_update_own_display_name_rpc.sql',
  '0023_update_display_name_all_profiles.sql',
  '0024_add_admin_empresa_update_empresas_policy.sql',
  '0025_guard_app_admin_company_identity.sql',
  '0026_rats_permissions_and_guard.sql',
  '0027_rat_audit_server_trigger.sql'
)

$migrationRoot = [IO.Path]::GetFullPath($MigrationDirectory)
$outputRoot = [IO.Path]::GetFullPath($OutputDirectory)

if (-not (Test-Path -LiteralPath $migrationRoot -PathType Container)) {
  throw "Migration directory not found: $migrationRoot"
}

if ($outputRoot -eq $migrationRoot -or $outputRoot.StartsWith($migrationRoot + [IO.Path]::DirectorySeparatorChar)) {
  throw 'OutputDirectory must not be the authoritative migration directory.'
}

$actual = @(
  Get-ChildItem -LiteralPath $migrationRoot -File -Filter '*.sql' |
    Sort-Object Name |
    ForEach-Object Name
)

$unexpected = @($actual | Where-Object { $_ -notin $manifest })
$missing = @($manifest | Where-Object { $_ -notin $actual })

if ($unexpected.Count -gt 0 -or $missing.Count -gt 0) {
  throw "Migration manifest mismatch. Missing=[$($missing -join ', ')] Unexpected=[$($unexpected -join ', ')]"
}

if ($actual -match '^0017_') {
  throw 'Historical migration 0017 must remain absent; replay cannot guess or synthesize it.'
}

if (Test-Path -LiteralPath $outputRoot) {
  $existing = @(Get-ChildItem -Force -LiteralPath $outputRoot)
  if ($existing.Count -gt 0) {
    throw "OutputDirectory must be empty: $outputRoot"
  }
} else {
  New-Item -ItemType Directory -Path $outputRoot | Out-Null
}

$utf8NoBom = [Text.UTF8Encoding]::new($false)
$stagedManifest = [Collections.Generic.List[object]]::new()

foreach ($fileName in $manifest) {
  $sourcePath = Join-Path $migrationRoot $fileName
  $sourceHash = (Get-FileHash -Algorithm SHA256 -LiteralPath $sourcePath).Hash.ToLowerInvariant()
  $raw = [IO.File]::ReadAllText($sourcePath, [Text.Encoding]::UTF8)
  $lines = [Collections.Generic.List[string]]::new()
  foreach ($line in ($raw -split "`r?`n", 0, 'RegexMatch')) {
    $lines.Add($line)
  }

  $firstSql = -1
  for ($i = 0; $i -lt $lines.Count; $i++) {
    $trimmed = $lines[$i].Trim()
    if ($trimmed -ne '' -and -not $trimmed.StartsWith('--')) {
      $firstSql = $i
      break
    }
  }

  if ($firstSql -ge 0 -and $lines[$firstSql].Trim() -match '^(?i:begin(?:\s+transaction)?);$') {
    $lines.RemoveAt($firstSql)
  }

  $lastSql = -1
  for ($i = $lines.Count - 1; $i -ge 0; $i--) {
    if ($lines[$i].Trim() -ne '') {
      $lastSql = $i
      break
    }
  }

  if ($lastSql -ge 0 -and $lines[$lastSql].Trim() -match '^(?i:commit);$') {
    $lines.RemoveAt($lastSql)
  }

  $remainingTransactionControl = @(
    $lines | Where-Object { $_ -match '^\s*(?i:begin(?:\s+transaction)?|commit|rollback)\s*;\s*$' }
  )
  if ($remainingTransactionControl.Count -gt 0) {
    throw "Nested transaction control remains in $fileName; refusing to stage."
  }

  $version = $fileName.Substring(0, 4)
  $name = [IO.Path]::GetFileNameWithoutExtension($fileName).Substring(5)
  $body = $lines -join "`n"
  $escapedName = $name.Replace("'", "''")
  $payload = @"
\set ON_ERROR_STOP on
\pset pager off
begin;
set local lock_timeout = '5s';
set local statement_timeout = '120s';

-- Authoritative source: $fileName
-- Source SHA-256: $sourceHash
$body

insert into supabase_migrations.schema_migrations(version, statements, name)
values (
  '$version',
  array['sha256:$sourceHash']::text[],
  '$escapedName'
);

commit;
\echo 'MIGRATION_REPLAYED=$version'
"@

  $stagedPath = Join-Path $outputRoot $fileName
  [IO.File]::WriteAllText($stagedPath, $payload, $utf8NoBom)
  $stagedHash = (Get-FileHash -Algorithm SHA256 -LiteralPath $stagedPath).Hash.ToLowerInvariant()

  $stagedManifest.Add([pscustomobject]@{
    version = $version
    source = $fileName
    source_sha256 = $sourceHash
    staged_sha256 = $stagedHash
  })
}

$manifestPath = Join-Path $outputRoot 'replay-manifest.json'
$manifestJson = $stagedManifest | ConvertTo-Json -Depth 4
[IO.File]::WriteAllText($manifestPath, $manifestJson + "`n", $utf8NoBom)

Write-Output "STAGED_MIGRATIONS=$($manifest.Count)"
Write-Output 'APPROVED_SEQUENCE=0001-0016,0018-0027'
Write-Output 'HISTORICAL_0017=ABSENT'
Write-Output "MANIFEST=$manifestPath"
