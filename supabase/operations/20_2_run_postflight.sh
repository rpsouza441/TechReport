#!/usr/bin/env bash
set -euo pipefail

if [ "$#" -ne 14 ]; then
  echo "usage: $0 <manifest> <manifest-sha256> <postflight-sql> <postflight-sha256> <pgtap-sql> <pgtap-sha256> <container-env:supabase-storage:SERVICE_KEY> <api-base-url> <expected-db-container-id> <expected-system-id> <backup-file> <expected-backup-bytes> <expected-backup-sha256> <expected-pg-restore-toc-entries>" >&2
  exit 64
fi

manifest_path=$1
expected_manifest_sha256=$2
postflight_sql=$3
expected_postflight_sha256=$4
pgtap_sql=$5
expected_pgtap_sha256=$6
credential_source=$7
api_base=${8%/}
expected_container_id=$9
expected_system_id=${10}
backup_file=${11}
expected_backup_bytes=${12}
expected_backup_sha256=${13}
expected_toc_entries=${14}

db_container=supabase-db
credential_container=supabase-storage
expected_api_base=http://127.0.0.1:18000
backup_root=/srv/DATA/supabase/backups/techreport-reset

command -v curl >/dev/null
command -v jq >/dev/null
command -v sha256sum >/dev/null
command -v stat >/dev/null
command -v cmp >/dev/null
command -v grep >/dev/null
command -v awk >/dev/null
command -v sed >/dev/null
command -v tee >/dev/null
command -v docker >/dev/null
command -v readlink >/dev/null
command -v install >/dev/null

for expected_hash in "$expected_manifest_sha256" "$expected_postflight_sha256" "$expected_pgtap_sha256" "$expected_backup_sha256"; do
  [[ "$expected_hash" =~ ^[0-9a-f]{64}$ ]] || {
    echo 'BLOCK: invalid expected SHA-256 argument' >&2
    exit 64
  }
done
[[ "$expected_container_id" =~ ^[0-9a-f]{64}$ ]] || { echo 'BLOCK: invalid database container identity' >&2; exit 64; }
[[ "$expected_system_id" =~ ^[0-9]+$ ]] || { echo 'BLOCK: invalid PostgreSQL system identifier' >&2; exit 64; }
[[ "$expected_backup_bytes" =~ ^[1-9][0-9]*$ ]] || { echo 'BLOCK: invalid backup byte count' >&2; exit 64; }
[[ "$expected_toc_entries" =~ ^[1-9][0-9]*$ ]] || { echo 'BLOCK: invalid TOC count' >&2; exit 64; }
[ "$credential_source" = 'container-env:supabase-storage:SERVICE_KEY' ] || { echo 'BLOCK: unsupported credential source' >&2; exit 65; }
[ "$api_base" = "$expected_api_base" ] || { echo 'BLOCK: unexpected API base URL' >&2; exit 65; }

requested_manifest_path=$manifest_path
requested_postflight_sql=$postflight_sql
requested_pgtap_sql=$pgtap_sql
for requested_artifact in "$requested_manifest_path" "$requested_postflight_sql" "$requested_pgtap_sql"; do
  [ -f "$requested_artifact" ] && [ ! -L "$requested_artifact" ] || {
    echo "BLOCK: requested verification artifact is missing or a symlink: $requested_artifact" >&2
    exit 66
  }
done

manifest_path=$(readlink -f -- "$manifest_path")
case "$manifest_path" in
  /tmp/techreport-replay-*/replay-manifest.json) ;;
  *) echo 'BLOCK: manifest path is outside an approved replay stage' >&2; exit 66 ;;
esac
postflight_sql=$(readlink -f -- "$postflight_sql")
pgtap_sql=$(readlink -f -- "$pgtap_sql")
[ "$postflight_sql" = '/tmp/20_2_live_postflight.sql' ] || { echo 'BLOCK: unexpected postflight SQL path' >&2; exit 66; }
[ "$pgtap_sql" = '/tmp/20_2_permissions_audit_trash.test.sql' ] || { echo 'BLOCK: unexpected pgTAP SQL path' >&2; exit 66; }

for artifact in "$manifest_path" "$postflight_sql" "$pgtap_sql"; do
  [ -f "$artifact" ] && [ ! -L "$artifact" ] && [ -s "$artifact" ] || {
    echo "BLOCK: verification artifact is missing or unsafe: $artifact" >&2
    exit 66
  }
  [ -z "$(find "$artifact" -perm /022 -print -quit)" ] || {
    echo "BLOCK: verification artifact is group/world writable: $artifact" >&2
    exit 66
  }
done
[ "$(sha256sum -- "$manifest_path" | awk '{print $1}')" = "$expected_manifest_sha256" ] || { echo 'BLOCK: manifest hash mismatch' >&2; exit 66; }
[ "$(sha256sum -- "$postflight_sql" | awk '{print $1}')" = "$expected_postflight_sha256" ] || { echo 'BLOCK: postflight SQL hash mismatch' >&2; exit 66; }
[ "$(sha256sum -- "$pgtap_sql" | awk '{print $1}')" = "$expected_pgtap_sha256" ] || { echo 'BLOCK: pgTAP SQL hash mismatch' >&2; exit 66; }

# Freeze the verified inputs in a root-private directory before any SQL is run.
# This closes the check/use window on the unprivileged SCP upload paths.
verified_artifact_dir=$(mktemp -d)
chmod 700 "$verified_artifact_dir"
trap 'rm -f -- "$verified_artifact_dir/replay-manifest.json" "$verified_artifact_dir/live-postflight.sql" "$verified_artifact_dir/pgtap.test.sql" 2>/dev/null || true; rmdir -- "$verified_artifact_dir" 2>/dev/null || true' EXIT
install -m 0600 -- "$manifest_path" "$verified_artifact_dir/replay-manifest.json"
install -m 0600 -- "$postflight_sql" "$verified_artifact_dir/live-postflight.sql"
install -m 0600 -- "$pgtap_sql" "$verified_artifact_dir/pgtap.test.sql"
manifest_path=$verified_artifact_dir/replay-manifest.json
postflight_sql=$verified_artifact_dir/live-postflight.sql
pgtap_sql=$verified_artifact_dir/pgtap.test.sql
[ "$(sha256sum -- "$manifest_path" | awk '{print $1}')" = "$expected_manifest_sha256" ] || { echo 'BLOCK: private manifest copy hash mismatch' >&2; exit 66; }
[ "$(sha256sum -- "$postflight_sql" | awk '{print $1}')" = "$expected_postflight_sha256" ] || { echo 'BLOCK: private postflight copy hash mismatch' >&2; exit 66; }
[ "$(sha256sum -- "$pgtap_sql" | awk '{print $1}')" = "$expected_pgtap_sha256" ] || { echo 'BLOCK: private pgTAP copy hash mismatch' >&2; exit 66; }

jq -e '.schema_version == 1 and .migration_count == 26 and .historical_absent == "0017" and (.migrations | length == 26)' "$manifest_path" >/dev/null

actual_container_id=$(docker inspect --format '{{.Id}}' "$db_container")
[ "$actual_container_id" = "$expected_container_id" ] || { echo 'BLOCK: database container identity mismatch' >&2; exit 67; }

validate_service_container() {
  local container=$1
  local image_pattern=$2
  docker inspect "$container" >/dev/null
  [ "$(docker inspect --format '{{.State.Running}}' "$container")" = 'true' ] || {
    echo "BLOCK: service container is not running: $container" >&2
    exit 67
  }
  local image
  image=$(docker inspect --format '{{.Config.Image}}' "$container")
  case "$image" in
    $image_pattern) ;;
    *) echo "BLOCK: unexpected image for $container: $image" >&2; exit 67 ;;
  esac
  local health
  health=$(docker inspect --format '{{if .State.Health}}{{.State.Health.Status}}{{else}}none{{end}}' "$container")
  case "$health" in
    healthy|none) ;;
    *) echo "BLOCK: unhealthy service container $container: $health" >&2; exit 67 ;;
  esac
}

validate_service_container supabase-db '*supabase/postgres*'
validate_service_container supabase-auth '*gotrue*'
validate_service_container supabase-storage '*supabase/storage-api*'
validate_service_container supabase-rest '*postgrest*'
validate_service_container supabase-studio '*supabase/studio*'

service_ids_before=$(for container in supabase-db supabase-auth supabase-storage supabase-rest supabase-studio; do docker inspect --format '{{.Name}}={{.Id}}' "$container"; done)

psql_query_as() {
  local role=$1
  local sql=$2
  docker exec "$db_container" psql -U "$role" -d postgres -X -v ON_ERROR_STOP=1 -Atqc "$sql"
}
postgres_query() { psql_query_as postgres "$1"; }
admin_query() { psql_query_as supabase_admin "$1"; }

actual_system_id=$(postgres_query 'select system_identifier from pg_control_system()')
[ "$actual_system_id" = "$expected_system_id" ] || { echo 'BLOCK: PostgreSQL system identifier mismatch' >&2; exit 67; }
admin_identity=$(admin_query "select concat_ws('|', current_database(), current_user, session_user, (select rolsuper::int from pg_roles where rolname=current_user), (select system_identifier::text from pg_control_system()))")
[ "$admin_identity" = "postgres|supabase_admin|supabase_admin|1|$expected_system_id" ] || { echo 'BLOCK: postflight principal mismatch' >&2; exit 67; }

requested_backup_file=$backup_file
[ -f "$requested_backup_file" ] && [ ! -L "$requested_backup_file" ] || { echo 'BLOCK: backup file is missing or unsafe' >&2; exit 68; }
backup_file=$(readlink -f -- "$backup_file")
case "$backup_file" in "$backup_root"/*.dump) ;; *) echo 'BLOCK: backup is outside approved root' >&2; exit 68 ;; esac
[ "$(stat -c '%s' -- "$backup_file")" = "$expected_backup_bytes" ] || { echo 'BLOCK: backup byte count mismatch' >&2; exit 68; }
[ "$(sha256sum -- "$backup_file" | awk '{print $1}')" = "$expected_backup_sha256" ] || { echo 'BLOCK: backup hash mismatch' >&2; exit 68; }
actual_toc_entries=$(docker exec -i "$db_container" pg_restore --list <"$backup_file" | awk '!/^;/ && NF { count++ } END { print count + 0 }')
[ "$actual_toc_entries" = "$expected_toc_entries" ] || { echo 'BLOCK: backup TOC mismatch' >&2; exit 68; }

history_expected=$(mktemp)
history_actual=$(mktemp)
tap_output=$(mktemp)
curl_config=$(mktemp)
auth_api_output=$(mktemp)
storage_api_output=$(mktemp)
rest_api_output=$(mktemp)
trap 'unset service_key SERVICE_KEY SERVICE_ROLE_KEY SUPABASE_SERVICE_ROLE_KEY 2>/dev/null || true; rm -f -- "$history_expected" "$history_actual" "$tap_output" "$curl_config" "$auth_api_output" "$storage_api_output" "$rest_api_output" "$verified_artifact_dir/replay-manifest.json" "$verified_artifact_dir/live-postflight.sql" "$verified_artifact_dir/pgtap.test.sql" 2>/dev/null || true; rmdir -- "$verified_artifact_dir" 2>/dev/null || true' EXIT
chmod 600 "$history_expected" "$history_actual" "$tap_output" "$curl_config" "$auth_api_output" "$storage_api_output" "$rest_api_output"

jq -r '.migrations[] | [.version, ("sha256:" + .source_sha256), (.source | sub("^[0-9]{4}_"; "") | sub("\\.sql$"; ""))] | @tsv' "$manifest_path" >"$history_expected"
admin_query "select version || E'\\t' || statements[1] || E'\\t' || name from supabase_migrations.schema_migrations order by version" >"$history_actual"
cmp -s "$history_expected" "$history_actual" || { echo 'BLOCK: live history differs from local signed manifest' >&2; exit 69; }

platform_schemas_before=$(admin_query "select string_agg(nspname,',' order by nspname) from pg_namespace where nspname !~ '^pg_' and nspname not in ('information_schema','public','supabase_migrations')")
extensions_before=$(admin_query "select string_agg(e.extname || ':' || n.nspname,',' order by e.extname) from pg_extension e join pg_namespace n on n.oid=e.extnamespace")
residue_before=$(admin_query "select concat_ws('|',
  (select count(*) from public.empresas), (select count(*) from public.tecnicos),
  (select count(*) from public.app_admins), (select count(*) from public.tecnico_convites),
  (select count(*) from public.rats), (select count(*) from public.rat_audit_log),
  (select count(*) from public.rat_signature_attachments), (select count(*) from auth.users),
  (select count(*) from auth.identities), (select count(*) from auth.sessions),
  (select count(*) from auth.refresh_tokens), (select count(*) from storage.objects),
  (select count(*) from supabase_migrations.schema_migrations)
)")
[ "$residue_before" = '0|0|0|0|0|0|0|0|0|0|0|0|26' ] || { echo "BLOCK: final preflight data is not clean: $residue_before" >&2; exit 69; }

set +x
mapfile -t service_key_values < <(
  docker inspect --format '{{json .Config.Env}}' "$credential_container" |
    jq -r '.[] | select(startswith("SERVICE_KEY=")) | sub("^SERVICE_KEY="; "")'
)
[ "${#service_key_values[@]}" -eq 1 ] || { echo 'BLOCK: expected exactly one Storage SERVICE_KEY' >&2; exit 70; }
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

curl --config "$curl_config" --url "$api_base/auth/v1/admin/users?page=1&per_page=1000" --output "$auth_api_output"
jq -e '(.users | type == "array" and length == 0)' "$auth_api_output" >/dev/null
curl --config "$curl_config" --url "$api_base/storage/v1/bucket" --output "$storage_api_output"
jq -e 'type == "array" and length == 1 and .[0].id == "rat-signatures" and .[0].public == false' "$storage_api_output" >/dev/null
curl --config "$curl_config" --url "$api_base/rest/v1/" --output "$rest_api_output"
jq -e 'type == "object" and ((.swagger == "2.0") or (.openapi | type == "string"))' "$rest_api_output" >/dev/null

echo 'FINAL_HISTORY_MANIFEST=PASS rows=26 hashes=local_manifest names=local_manifest historical_0017=absent'
echo "FINAL_BACKUP_RECHECK=PASS bytes=$expected_backup_bytes sha256=$expected_backup_sha256 toc_entries=$actual_toc_entries"
echo 'FINAL_SERVICE_PREFLIGHT=PASS auth_api=healthy storage_api=healthy postgrest=healthy studio_container=running'

docker exec -i "$db_container" \
  psql -U supabase_admin -d postgres -X -v ON_ERROR_STOP=1 \
  -v expected_system_identifier="$expected_system_id" <"$postflight_sql"

pgtap_available=$(admin_query "select count(*) from pg_available_extensions where name='pgtap'")
if [ "$pgtap_available" != '1' ]; then
  echo 'PGTAP_PREFLIGHT=BLOCK available=false action=operator_must_add_pgtap_to_supabase_postgres_image_then_rerun' >&2
  exit 75
fi
pgtap_installed_before=$(admin_query "select count(*) from pg_extension where extname='pgtap'")
pgtap_schema_before=$(admin_query "select coalesce((select n.nspname from pg_extension e join pg_namespace n on n.oid=e.extnamespace where e.extname='pgtap'),'absent')")
case "$pgtap_schema_before" in
  absent|extensions) ;;
  *) echo "PGTAP_PREFLIGHT=BLOCK installed_schema=$pgtap_schema_before expected=extensions" >&2; exit 75 ;;
esac
echo "PGTAP_PREFLIGHT=PASS available=true installed_before=$pgtap_installed_before schema_before=$pgtap_schema_before transaction_scoped_setup=true"

set +e
docker exec -i "$db_container" \
  psql -U supabase_admin -d postgres -X -qAt -v ON_ERROR_STOP=1 \
  -v expected_system_identifier="$expected_system_id" \
  <"$pgtap_sql" 2>&1 | tee "$tap_output"
tap_psql_exit=${PIPESTATUS[0]}
set -e
[ "$tap_psql_exit" = '0' ] || { echo "BLOCK: pgTAP psql exit=$tap_psql_exit" >&2; exit 76; }

tap_not_ok=$(grep -Ec '^not ok [0-9]+' "$tap_output" || true)
tap_ok=$(grep -Ec '^ok [0-9]+' "$tap_output" || true)
tap_plan=$(grep -Ec '^1\.\.67$' "$tap_output" || true)
tap_rollback=$(grep -Ec '^TECHREPORT_PGTAP_ROLLBACK=PASS tests=67$' "$tap_output" || true)
[ "$tap_not_ok" = '0' ] && [ "$tap_ok" = '67' ] && [ "$tap_plan" = '1' ] && [ "$tap_rollback" = '1' ] || {
  echo "BLOCK: pgTAP TAP contract mismatch ok=$tap_ok not_ok=$tap_not_ok plan=$tap_plan rollback=$tap_rollback" >&2
  exit 76
}
echo 'PGTAP_SUITE=PASS tests=67 failed=0'

pgtap_installed_after=$(admin_query "select count(*) from pg_extension where extname='pgtap'")
[ "$pgtap_installed_after" = "$pgtap_installed_before" ] || { echo 'BLOCK: pgTAP installation state changed despite rollback' >&2; exit 77; }
residue_after=$(admin_query "select concat_ws('|',
  (select count(*) from public.empresas), (select count(*) from public.tecnicos),
  (select count(*) from public.app_admins), (select count(*) from public.tecnico_convites),
  (select count(*) from public.rats), (select count(*) from public.rat_audit_log),
  (select count(*) from public.rat_signature_attachments), (select count(*) from auth.users),
  (select count(*) from auth.identities), (select count(*) from auth.sessions),
  (select count(*) from auth.refresh_tokens), (select count(*) from storage.objects),
  (select count(*) from supabase_migrations.schema_migrations)
)")
[ "$residue_after" = "$residue_before" ] || { echo "BLOCK: pgTAP fixtures left residue: $residue_after" >&2; exit 77; }

# Re-run the complete read-only postflight after the pgTAP rollback.
docker exec -i "$db_container" \
  psql -U supabase_admin -d postgres -X -v ON_ERROR_STOP=1 \
  -v expected_system_identifier="$expected_system_id" <"$postflight_sql"

platform_schemas_after=$(admin_query "select string_agg(nspname,',' order by nspname) from pg_namespace where nspname !~ '^pg_' and nspname not in ('information_schema','public','supabase_migrations')")
extensions_after=$(admin_query "select string_agg(e.extname || ':' || n.nspname,',' order by e.extname) from pg_extension e join pg_namespace n on n.oid=e.extnamespace")
[ "$platform_schemas_after" = "$platform_schemas_before" ] || { echo 'BLOCK: platform schema inventory changed' >&2; exit 77; }
[ "$extensions_after" = "$extensions_before" ] || { echo 'BLOCK: extension inventory changed' >&2; exit 77; }
admin_query "select version || E'\\t' || statements[1] || E'\\t' || name from supabase_migrations.schema_migrations order by version" >"$history_actual"
cmp -s "$history_expected" "$history_actual" || { echo 'BLOCK: migration history changed during pgTAP validation' >&2; exit 77; }

curl --config "$curl_config" --url "$api_base/auth/v1/admin/users?page=1&per_page=1000" --output "$auth_api_output"
jq -e '(.users | type == "array" and length == 0)' "$auth_api_output" >/dev/null
curl --config "$curl_config" --url "$api_base/storage/v1/bucket" --output "$storage_api_output"
jq -e 'type == "array" and length == 1 and .[0].id == "rat-signatures" and .[0].public == false' "$storage_api_output" >/dev/null
curl --config "$curl_config" --url "$api_base/rest/v1/" --output "$rest_api_output"
jq -e 'type == "object" and ((.swagger == "2.0") or (.openapi | type == "string"))' "$rest_api_output" >/dev/null

service_ids_after=$(for container in supabase-db supabase-auth supabase-storage supabase-rest supabase-studio; do docker inspect --format '{{.Name}}={{.Id}}' "$container"; done)
[ "$service_ids_after" = "$service_ids_before" ] || { echo 'BLOCK: required service container identity changed' >&2; exit 77; }

echo "PGTAP_RESIDUE=PASS app_auth_rows=0 history_rows=26 installed_state_unchanged=$pgtap_installed_after"
echo 'FINAL_SERVICE_POSTCHECK=PASS auth_api=healthy storage_api=healthy postgrest=healthy studio_container=running container_ids=unchanged platform_schemas=unchanged extensions=unchanged'
echo 'TECHREPORT_PHASE_20_2_RESET_REPLAY_VALIDATION=PASS fresh_company_ready=true'
