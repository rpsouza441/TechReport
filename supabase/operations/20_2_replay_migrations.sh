#!/usr/bin/env bash
set -euo pipefail

if [ "$#" -ne 10 ]; then
  echo "usage: $0 <stage-directory> <manifest-sha256> <container-env:supabase-storage:SERVICE_KEY> <api-base-url> <expected-db-container-id> <expected-system-id> <backup-file> <expected-backup-bytes> <expected-backup-sha256> <expected-pg-restore-toc-entries>" >&2
  exit 64
fi

stage_dir=$1
expected_manifest_sha256=$2
credential_source=$3
api_base=${4%/}
expected_container_id=$5
expected_system_id=$6
backup_file=$7
expected_backup_bytes=$8
expected_backup_sha256=$9
expected_toc_entries=${10}

db_container=supabase-db
credential_container=supabase-storage
expected_api_base=http://127.0.0.1:18000
backup_root=/srv/DATA/supabase/backups/techreport-reset

expected_files=(
  0001_company_auth_base.sql
  0002_company_rats_base.sql
  0003_rat_completo_fields.sql
  0004_optimize_rls_auth_uid.sql
  0005_fix_function_search_path.sql
  0006_admin_roles_base.sql
  0007_optimize_admin_rls_auth_uid.sql
  0008_responsavel_documento.sql
  0009_tecnico_convites_equipe.sql
  0010_fix_tecnico_convites_digest.sql
  0011_finalize_sprint_8_5_convites.sql
  0012_fix_invite_acceptance_password.sql
  0013_gerente_convites_tecnicos.sql
  0014_gerente_gerencia_tecnicos.sql
  0015_rat_signature_attachments.sql
  0016_update_own_display_name.sql
  0018_add_rat_audit_fields.sql
  0019_create_rat_audit_log.sql
  0020_add_admin_empresa_to_rats_select_policy.sql
  0021_fix_tecnicos_update_with_check_self_update.sql
  0022_update_own_display_name_rpc.sql
  0023_update_display_name_all_profiles.sql
  0024_add_admin_empresa_update_empresas_policy.sql
  0025_guard_app_admin_company_identity.sql
  0026_rats_permissions_and_guard.sql
  0027_rat_audit_server_trigger.sql
)
expected_versions=(
  0001 0002 0003 0004 0005 0006 0007 0008 0009 0010 0011 0012 0013
  0014 0015 0016 0018 0019 0020 0021 0022 0023 0024 0025 0026 0027
)

command -v curl >/dev/null
command -v jq >/dev/null
command -v sha256sum >/dev/null
command -v stat >/dev/null
command -v cmp >/dev/null
command -v sed >/dev/null
command -v find >/dev/null
command -v grep >/dev/null
command -v awk >/dev/null
command -v sort >/dev/null
command -v wc >/dev/null
command -v readlink >/dev/null
command -v docker >/dev/null

[[ "$expected_manifest_sha256" =~ ^[0-9a-f]{64}$ ]] || {
  echo 'BLOCK: invalid expected manifest SHA-256' >&2
  exit 64
}
[[ "$expected_container_id" =~ ^[0-9a-f]{64}$ ]] || {
  echo 'BLOCK: invalid expected database container identity' >&2
  exit 64
}
[[ "$expected_system_id" =~ ^[0-9]+$ ]] || {
  echo 'BLOCK: invalid expected PostgreSQL system identifier' >&2
  exit 64
}
[[ "$expected_backup_bytes" =~ ^[1-9][0-9]*$ ]] || {
  echo 'BLOCK: invalid expected backup byte count' >&2
  exit 64
}
[[ "$expected_backup_sha256" =~ ^[0-9a-f]{64}$ ]] || {
  echo 'BLOCK: invalid expected backup SHA-256' >&2
  exit 64
}
[[ "$expected_toc_entries" =~ ^[1-9][0-9]*$ ]] || {
  echo 'BLOCK: invalid expected pg_restore catalog count' >&2
  exit 64
}
[ "$credential_source" = 'container-env:supabase-storage:SERVICE_KEY' ] || {
  echo 'BLOCK: unsupported credential source' >&2
  exit 65
}
[ "$api_base" = "$expected_api_base" ] || {
  echo 'BLOCK: unexpected Storage API base URL' >&2
  exit 65
}

requested_stage_dir=$stage_dir
[ -d "$requested_stage_dir" ] && [ ! -L "$requested_stage_dir" ] || {
  echo 'BLOCK: stage directory is absent, not a directory, or a symlink' >&2
  exit 66
}
stage_dir=$(readlink -f -- "$stage_dir")
case "$stage_dir" in
  /tmp/techreport-replay-*) ;;
  *) echo 'BLOCK: stage directory is outside the unique approved /tmp prefix' >&2; exit 66 ;;
esac
[ "$(stat -c '%U' -- "$stage_dir")" = 'codexanalysis' ] || {
  echo 'BLOCK: stage directory owner is not codexanalysis' >&2
  exit 66
}
[ -z "$(find "$stage_dir" -mindepth 1 -maxdepth 1 -perm /022 -print -quit)" ] || {
  echo 'BLOCK: staged artifact is group/world writable' >&2
  exit 66
}
[ -z "$(find "$stage_dir" -mindepth 1 -maxdepth 1 -type l -print -quit)" ] || {
  echo 'BLOCK: symlink found in stage directory' >&2
  exit 66
}
[ "$(find "$stage_dir" -mindepth 1 -maxdepth 1 -printf '.' | wc -c)" = '27' ] || {
  echo 'BLOCK: stage directory must contain exactly 26 SQL files plus one manifest' >&2
  exit 66
}

manifest_path=$stage_dir/replay-manifest.json
[ -f "$manifest_path" ] && [ ! -L "$manifest_path" ] && [ -s "$manifest_path" ] || {
  echo 'BLOCK: replay manifest is missing or unsafe' >&2
  exit 66
}
actual_manifest_sha256=$(sha256sum -- "$manifest_path" | awk '{print $1}')
[ "$actual_manifest_sha256" = "$expected_manifest_sha256" ] || {
  echo 'BLOCK: replay manifest SHA-256 mismatch' >&2
  exit 66
}
jq -e '
  .schema_version == 1
  and .migration_count == 26
  and .historical_absent == "0017"
  and (.approved_sequence | type == "array" and length == 26 and (index("0017") | not))
  and (.migrations | type == "array" and length == 26)
  and all(.migrations[];
    (.version | type == "string" and test("^[0-9]{4}$"))
    and (.source | type == "string" and test("^[0-9]{4}_[A-Za-z0-9_]+\\.sql$"))
    and (.source_sha256 | type == "string" and test("^[0-9a-f]{64}$"))
    and (.staged_sha256 | type == "string" and test("^[0-9a-f]{64}$"))
    and (.staged_bytes | type == "number" and . > 0 and floor == .)
  )
' "$manifest_path" >/dev/null

mapfile -t manifest_versions < <(jq -r '.approved_sequence[]' "$manifest_path")
[ "${manifest_versions[*]}" = "${expected_versions[*]}" ] || {
  echo 'BLOCK: manifest approved sequence mismatch' >&2
  exit 66
}
mapfile -t manifest_sources < <(jq -r '.migrations[].source' "$manifest_path")
[ "${manifest_sources[*]}" = "${expected_files[*]}" ] || {
  echo 'BLOCK: manifest source order mismatch' >&2
  exit 66
}
mapfile -t manifest_entry_versions < <(jq -r '.migrations[].version' "$manifest_path")
[ "${manifest_entry_versions[*]}" = "${expected_versions[*]}" ] || {
  echo 'BLOCK: manifest migration-entry version order mismatch' >&2
  exit 66
}
[ "$(printf '%s\n' "${manifest_versions[@]}" | sort -u | wc -l)" = '26' ] || {
  echo 'BLOCK: duplicate migration version in manifest' >&2
  exit 66
}

for index in "${!expected_files[@]}"; do
  file_name=${expected_files[$index]}
  expected_version=${expected_versions[$index]}
  staged_path=$stage_dir/$file_name
  [ -f "$staged_path" ] && [ ! -L "$staged_path" ] && [ -s "$staged_path" ] || {
    echo "BLOCK: staged migration is missing or unsafe: $file_name" >&2
    exit 66
  }
  [ "${file_name:0:4}" = "$expected_version" ] || {
    echo "BLOCK: filename/version mismatch: $file_name" >&2
    exit 66
  }
  if LC_ALL=C grep -q $'\r' "$staged_path"; then
    echo "BLOCK: CR byte found in staged migration: $file_name" >&2
    exit 66
  fi
  manifest_hash=$(jq -r --arg source "$file_name" '.migrations[] | select(.source == $source) | .staged_sha256' "$manifest_path")
  manifest_bytes=$(jq -r --arg source "$file_name" '.migrations[] | select(.source == $source) | .staged_bytes' "$manifest_path")
  [ "$(sha256sum -- "$staged_path" | awk '{print $1}')" = "$manifest_hash" ] || {
    echo "BLOCK: staged SHA-256 mismatch: $file_name" >&2
    exit 66
  }
  [ "$(stat -c '%s' -- "$staged_path")" = "$manifest_bytes" ] || {
    echo "BLOCK: staged byte count mismatch: $file_name" >&2
    exit 66
  }
done

actual_container_id=$(docker inspect --format '{{.Id}}' "$db_container")
[ "$actual_container_id" = "$expected_container_id" ] || {
  echo 'BLOCK: database container identity mismatch' >&2
  exit 67
}
[ "$(docker inspect --format '{{.State.Running}}' "$db_container")" = 'true' ] || {
  echo 'BLOCK: database container is not running' >&2
  exit 67
}
case "$(docker inspect --format '{{.Config.Image}}' "$db_container")" in
  *supabase/postgres*) ;;
  *) echo 'BLOCK: unexpected database image' >&2; exit 67 ;;
esac

psql_query_as() {
  local role=$1
  local sql=$2
  docker exec "$db_container" \
    psql -U "$role" -d postgres -X -v ON_ERROR_STOP=1 -Atqc "$sql"
}
postgres_query() { psql_query_as postgres "$1"; }
admin_query() { psql_query_as supabase_admin "$1"; }

actual_system_id=$(postgres_query 'select system_identifier from pg_control_system()')
[ "$actual_system_id" = "$expected_system_id" ] || {
  echo 'BLOCK: PostgreSQL system identifier mismatch' >&2
  exit 67
}
admin_identity=$(admin_query "select concat_ws('|', current_database(), current_user, session_user, (select rolsuper::int from pg_roles where rolname=current_user), (select system_identifier::text from pg_control_system()))")
[ "$admin_identity" = "postgres|supabase_admin|supabase_admin|1|$expected_system_id" ] || {
  echo "BLOCK: direct replay principal mismatch: $admin_identity" >&2
  exit 67
}

requested_backup_file=$backup_file
[ -f "$requested_backup_file" ] && [ ! -L "$requested_backup_file" ] || {
  echo 'BLOCK: backup file is missing, non-regular, or a symlink' >&2
  exit 68
}
backup_file=$(readlink -f -- "$backup_file")
case "$backup_file" in
  "$backup_root"/*.dump) ;;
  *) echo 'BLOCK: backup file is outside the approved reset backup directory' >&2; exit 68 ;;
esac
[ "$(stat -c '%s' -- "$backup_file")" = "$expected_backup_bytes" ] || {
  echo 'BLOCK: backup byte count mismatch' >&2
  exit 68
}
[ "$(sha256sum -- "$backup_file" | awk '{print $1}')" = "$expected_backup_sha256" ] || {
  echo 'BLOCK: backup SHA-256 mismatch' >&2
  exit 68
}
actual_toc_entries=$(docker exec -i "$db_container" pg_restore --list <"$backup_file" | awk '!/^;/ && NF { count++ } END { print count + 0 }')
[ "$actual_toc_entries" = "$expected_toc_entries" ] || {
  echo 'BLOCK: pg_restore catalog entry count mismatch' >&2
  exit 68
}

prestate=$(admin_query "select concat_ws('|',
  (select count(*) from pg_class c join pg_namespace n on n.oid=c.relnamespace where n.nspname='public' and c.relkind in ('r','p','v','m','S','f')),
  (select count(*) from pg_proc p join pg_namespace n on n.oid=p.pronamespace where n.nspname='public'),
  (select count(*) from pg_policies where schemaname='public'),
  (select count(*) from pg_policies where schemaname='storage' and tablename='objects' and policyname like 'rat_signatures_%'),
  (select count(*) from auth.users),
  (select count(*) from auth.identities),
  (select count(*) from auth.sessions),
  (select count(*) from auth.refresh_tokens),
  (select count(*) from storage.buckets),
  (select count(*) from storage.objects),
  (to_regclass('supabase_migrations.schema_migrations') is not null)::int,
  (select count(*) from supabase_migrations.schema_migrations),
  (select string_agg(column_name || ':' || udt_name, ',' order by ordinal_position) from information_schema.columns where table_schema='supabase_migrations' and table_name='schema_migrations'),
  (select pg_get_userbyid(c.relowner)::text from pg_class c where c.oid='supabase_migrations.schema_migrations'::regclass)
)")
expected_prestate='0|0|0|0|0|0|0|0|0|0|1|0|version:text,statements:_text,name:text|supabase_admin'
[ "$prestate" = "$expected_prestate" ] || {
  echo "BLOCK: replay pre-state drift: $prestate" >&2
  exit 69
}

platform_schemas_before=$(admin_query "select string_agg(nspname,',' order by nspname) from pg_namespace where nspname !~ '^pg_' and nspname not in ('information_schema','public','supabase_migrations')")
extensions_before=$(admin_query "select string_agg(e.extname || ':' || n.nspname,',' order by e.extname) from pg_extension e join pg_namespace n on n.oid=e.extnamespace")
storage_other_sql="select jsonb_build_object(
  'buckets', coalesce((select jsonb_agg(to_jsonb(b) order by b.id) from storage.buckets b where b.id <> 'rat-signatures'), '[]'::jsonb),
  'objects', coalesce((select jsonb_agg(to_jsonb(o) order by o.bucket_id, o.name, o.id) from storage.objects o where o.bucket_id <> 'rat-signatures'), '[]'::jsonb)
)::text"

auth_before=$(mktemp)
auth_after=$(mktemp)
storage_other_before=$(mktemp)
storage_other_after=$(mktemp)
api_other_before=$(mktemp)
api_other_after=$(mktemp)
curl_config=$(mktemp)
history_expected=$(mktemp)
history_actual=$(mktemp)
trap 'unset service_key SERVICE_KEY SERVICE_ROLE_KEY SUPABASE_SERVICE_ROLE_KEY 2>/dev/null || true; rm -f "$auth_before" "$auth_after" "$storage_other_before" "$storage_other_after" "$api_other_before" "$api_other_after" "$curl_config" "$history_expected" "$history_actual"' EXIT
chmod 600 "$auth_before" "$auth_after" "$storage_other_before" "$storage_other_after" \
  "$api_other_before" "$api_other_after" "$curl_config" "$history_expected" "$history_actual"

dump_auth() {
  docker exec "$db_container" pg_dump -U supabase_admin -d postgres --schema=auth |
    sed '/^\\restrict /d; /^\\unrestrict /d; /^SELECT pg_catalog\.setval/d'
}
dump_auth >"$auth_before"
[ -s "$auth_before" ] || { echo 'BLOCK: Auth preservation snapshot is empty' >&2; exit 69; }
admin_query "$storage_other_sql" >"$storage_other_before"

docker inspect "$credential_container" >/dev/null
[ "$(docker inspect --format '{{.State.Running}}' "$credential_container")" = 'true' ] || {
  echo 'BLOCK: supabase-storage container is not running' >&2
  exit 70
}
case "$(docker inspect --format '{{.Config.Image}}' "$credential_container")" in
  *supabase/storage-api*) ;;
  *) echo 'BLOCK: unexpected Storage API image' >&2; exit 70 ;;
esac
set +x
mapfile -t service_key_values < <(
  docker inspect --format '{{json .Config.Env}}' "$credential_container" |
    jq -r '.[] | select(startswith("SERVICE_KEY=")) | sub("^SERVICE_KEY="; "")'
)
[ "${#service_key_values[@]}" -eq 1 ] || {
  echo 'BLOCK: expected exactly one SERVICE_KEY in supabase-storage environment' >&2
  exit 70
}
service_key=${service_key_values[0]}
unset service_key_values
[ -n "$service_key" ] || { echo 'BLOCK: Storage SERVICE_KEY is empty' >&2; exit 70; }
{
  printf 'silent\nshow-error\nfail-with-body\n'
  printf 'header = "apikey: %s"\n' "$service_key"
  printf 'header = "Authorization: Bearer %s"\n' "$service_key"
  printf 'header = "Content-Type: application/json"\n'
} >"$curl_config"
unset service_key SERVICE_KEY SERVICE_ROLE_KEY SUPABASE_SERVICE_ROLE_KEY

curl --config "$curl_config" --url "$api_base/storage/v1/bucket" |
  jq -S -c 'if type != "array" then error("Storage bucket inventory is not an array") else map(select(.id != "rat-signatures")) | sort_by(.id) end' >"$api_other_before"
api_target_before=$(curl --config "$curl_config" --url "$api_base/storage/v1/bucket" | jq '[.[] | select(.id == "rat-signatures")] | length')
[ "$api_target_before" = '0' ] || { echo 'BLOCK: Storage API reports target bucket before replay' >&2; exit 70; }

echo "REPLAY_PACKAGE_PRECHECK=PASS migrations=26 manifest_sha256=$actual_manifest_sha256 historical_0017=absent lf_only=true"
echo "BACKUP_RECHECK=PASS bytes=$expected_backup_bytes sha256=$expected_backup_sha256 toc_entries=$actual_toc_entries"
echo 'REPLAY_DATABASE_PRESTATE=PASS public_relations=0 public_functions=0 auth_core=0 storage_buckets=0 storage_objects=0 history_rows=0 principal=supabase_admin'
echo 'REPLAY_STORAGE_API_PRESTATE=PASS target_bucket=absent'

history_prefix=''
for index in "${!expected_files[@]}"; do
  file_name=${expected_files[$index]}
  version=${expected_versions[$index]}
  staged_path=$stage_dir/$file_name

  docker exec -i "$db_container" \
    psql -U supabase_admin -d postgres -X -v ON_ERROR_STOP=1 \
    -v expected_system_identifier="$expected_system_id" <"$staged_path"

  if [ -z "$history_prefix" ]; then
    history_prefix=$version
  else
    history_prefix=$history_prefix,$version
  fi
  actual_prefix=$(admin_query "select string_agg(version,',' order by version) from supabase_migrations.schema_migrations")
  [ "$actual_prefix" = "$history_prefix" ] || {
    echo "BLOCK: migration history prefix mismatch after $version: $actual_prefix" >&2
    exit 71
  }
done

jq -r '.migrations[] | [.version, ("sha256:" + .source_sha256), (.source | sub("^[0-9]{4}_"; "") | sub("\\.sql$"; ""))] | @tsv' "$manifest_path" >"$history_expected"
admin_query "select version || E'\\t' || statements[1] || E'\\t' || name from supabase_migrations.schema_migrations order by version" >"$history_actual"
cmp -s "$history_expected" "$history_actual" || {
  echo 'BLOCK: final migration history differs from signed manifest' >&2
  exit 72
}

final_state=$(admin_query "select concat_ws('|',
  (select count(*) from pg_class c join pg_namespace n on n.oid=c.relnamespace where n.nspname='public' and c.relkind in ('r','p','v','m','S','f')),
  (select count(*) from pg_proc p join pg_namespace n on n.oid=p.pronamespace where n.nspname='public'),
  (select count(*) from pg_policies where schemaname='public'),
  (select count(*) from pg_policies where schemaname='storage' and tablename='objects' and policyname like 'rat_signatures_%'),
  (select count(*) from pg_trigger t join pg_class c on c.oid=t.tgrelid join pg_namespace n on n.oid=c.relnamespace where not t.tgisinternal and n.nspname='public'),
  (select count(*) from public.empresas),
  (select count(*) from public.tecnicos),
  (select count(*) from public.app_admins),
  (select count(*) from public.tecnico_convites),
  (select count(*) from public.rats),
  (select count(*) from public.rat_audit_log),
  (select count(*) from public.rat_signature_attachments),
  (select count(*) from auth.users),
  (select count(*) from auth.identities),
  (select count(*) from auth.sessions),
  (select count(*) from auth.refresh_tokens),
  (select count(*) from storage.buckets),
  (select count(*) from storage.objects),
  (select count(*) from supabase_migrations.schema_migrations),
  (select string_agg(distinct pg_get_userbyid(c.relowner)::text,',' order by pg_get_userbyid(c.relowner)::text) from pg_class c join pg_namespace n on n.oid=c.relnamespace where n.nspname='public' and c.relkind in ('r','p','v','m','S','f')),
  (select string_agg(distinct pg_get_userbyid(p.proowner)::text,',' order by pg_get_userbyid(p.proowner)::text) from pg_proc p join pg_namespace n on n.oid=p.pronamespace where n.nspname='public'),
  (select string_agg(distinct pg_get_userbyid(c.relowner)::text,',' order by pg_get_userbyid(c.relowner)::text) from pg_class c join pg_namespace n on n.oid=c.relnamespace where n.nspname='storage' and c.relname in ('buckets','objects')),
  (select pg_get_userbyid(c.relowner)::text from pg_class c where c.oid='supabase_migrations.schema_migrations'::regclass)
)")
expected_final_state='7|17|17|4|5|0|0|0|0|0|0|0|0|0|0|0|1|0|26|supabase_admin|supabase_admin|supabase_storage_admin|supabase_admin'
[ "$final_state" = "$expected_final_state" ] || {
  echo "BLOCK: final replay state mismatch: $final_state" >&2
  exit 73
}

bucket_state=$(admin_query "select concat_ws('|', id, name, public::int, file_size_limit, array_to_string(allowed_mime_types,',')) from storage.buckets where id='rat-signatures'")
[ "$bucket_state" = 'rat-signatures|rat-signatures|0|10485760|image/png,image/jpeg' ] || {
  echo "BLOCK: rat-signatures bucket metadata mismatch: $bucket_state" >&2
  exit 73
}
storage_policy_names=$(admin_query "select string_agg(policyname,',' order by policyname) from pg_policies where schemaname='storage' and tablename='objects' and policyname like 'rat_signatures_%'")
[ "$storage_policy_names" = 'rat_signatures_delete_membros,rat_signatures_insert_membros,rat_signatures_select_membros,rat_signatures_update_membros' ] || {
  echo "BLOCK: Storage policy inventory mismatch: $storage_policy_names" >&2
  exit 73
}

admin_query "$storage_other_sql" >"$storage_other_after"
cmp -s "$storage_other_before" "$storage_other_after" || {
  echo 'BLOCK: non-target Storage database inventory changed' >&2
  exit 74
}
curl --config "$curl_config" --url "$api_base/storage/v1/bucket" |
  jq -S -c 'if type != "array" then error("Storage bucket inventory is not an array") else map(select(.id != "rat-signatures")) | sort_by(.id) end' >"$api_other_after"
cmp -s "$api_other_before" "$api_other_after" || {
  echo 'BLOCK: non-target Storage API inventory changed' >&2
  exit 74
}
curl --config "$curl_config" --url "$api_base/storage/v1/bucket" |
  jq -e '[.[] | select(.id == "rat-signatures")] | length == 1 and .[0].public == false' >/dev/null

dump_auth >"$auth_after"
cmp -s "$auth_before" "$auth_after" || {
  echo 'BLOCK: Auth schema or data changed during migration replay' >&2
  exit 74
}
platform_schemas_after=$(admin_query "select string_agg(nspname,',' order by nspname) from pg_namespace where nspname !~ '^pg_' and nspname not in ('information_schema','public','supabase_migrations')")
extensions_after=$(admin_query "select string_agg(e.extname || ':' || n.nspname,',' order by e.extname) from pg_extension e join pg_namespace n on n.oid=e.extnamespace")
[ "$platform_schemas_after" = "$platform_schemas_before" ] || { echo 'BLOCK: platform schema inventory changed' >&2; exit 74; }
[ "$extensions_after" = "$extensions_before" ] || { echo 'BLOCK: extension inventory changed' >&2; exit 74; }

echo 'MIGRATION_HISTORY_VALIDATION=PASS rows=26 versions=0001-0016,0018-0027 hashes=manifest names=manifest historical_0017=absent'
echo 'REPLAY_STORAGE_VALIDATION=PASS bucket=rat-signatures private=true objects=0 policies=4 api_visible=true non_target=unchanged'
echo 'REPLAY_PLATFORM_PRESERVATION=PASS auth=unchanged internal_schemas=unchanged extensions=unchanged storage_non_target=unchanged'
echo 'TECHREPORT_MIGRATION_REPLAY=PASS migrations=26'
