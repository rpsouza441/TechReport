#!/usr/bin/env bash
set -euo pipefail

if [ "$#" -ne 9 ]; then
  echo "usage: $0 <container-env:supabase-storage:SERVICE_KEY> <api-base-url> <expected-db-container-id> <expected-system-id> <expected-user-count> <backup-file> <expected-backup-bytes> <expected-backup-sha256> <expected-pg-restore-toc-entries>" >&2
  exit 64
fi

credential_source=$1
api_base=${2%/}
expected_container_id=$3
expected_system_id=$4
expected_user_count=$5
backup_file=$6
expected_backup_bytes=$7
expected_backup_sha256=$8
expected_toc_entries=$9

db_container=supabase-db
auth_container=supabase-auth
credential_container=supabase-storage
expected_api_base=http://127.0.0.1:18000
backup_root=/srv/DATA/supabase/backups/techreport-reset

command -v curl >/dev/null
command -v jq >/dev/null
command -v sha256sum >/dev/null
command -v stat >/dev/null
command -v cmp >/dev/null
command -v sed >/dev/null
command -v sort >/dev/null

[[ "$expected_container_id" =~ ^[0-9a-f]{64}$ ]] || {
  echo 'BLOCK: invalid expected database container identity' >&2
  exit 64
}
[[ "$expected_system_id" =~ ^[0-9]+$ ]] || {
  echo 'BLOCK: invalid expected PostgreSQL system identifier' >&2
  exit 64
}
[[ "$expected_user_count" =~ ^[1-9][0-9]*$ ]] || {
  echo 'BLOCK: invalid expected Auth user count' >&2
  exit 64
}
[ "$expected_user_count" = '14' ] || {
  echo 'BLOCK: this operation is pinned to the 14-user definitive inventory' >&2
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
  echo 'BLOCK: unexpected GoTrue API base URL' >&2
  exit 65
}

actual_container_id=$(docker inspect --format '{{.Id}}' "$db_container")
[ "$actual_container_id" = "$expected_container_id" ] || {
  echo 'BLOCK: database container identity mismatch' >&2
  exit 65
}
db_running=$(docker inspect --format '{{.State.Running}}' "$db_container")
[ "$db_running" = 'true' ] || {
  echo 'BLOCK: database container is not running' >&2
  exit 65
}
db_image=$(docker inspect --format '{{.Config.Image}}' "$db_container")
case "$db_image" in
  *supabase/postgres*) ;;
  *) echo "BLOCK: unexpected database image: $db_image" >&2; exit 65 ;;
esac

docker inspect "$auth_container" >/dev/null
auth_running=$(docker inspect --format '{{.State.Running}}' "$auth_container")
[ "$auth_running" = 'true' ] || {
  echo 'BLOCK: supabase-auth container is not running' >&2
  exit 65
}
auth_image=$(docker inspect --format '{{.Config.Image}}' "$auth_container")
case "$auth_image" in
  *supabase/gotrue*|*gotrue*) ;;
  *) echo "BLOCK: unexpected GoTrue image: $auth_image" >&2; exit 65 ;;
esac

docker inspect "$credential_container" >/dev/null
credential_running=$(docker inspect --format '{{.State.Running}}' "$credential_container")
[ "$credential_running" = 'true' ] || {
  echo 'BLOCK: supabase-storage credential container is not running' >&2
  exit 65
}
credential_image=$(docker inspect --format '{{.Config.Image}}' "$credential_container")
case "$credential_image" in
  *supabase/storage-api*) ;;
  *) echo "BLOCK: unexpected credential container image: $credential_image" >&2; exit 65 ;;
esac

psql_query_as() {
  local role=$1
  local sql=$2
  docker exec "$db_container" \
    psql -U "$role" -d postgres -X -v ON_ERROR_STOP=1 -Atqc "$sql"
}

postgres_query() {
  psql_query_as postgres "$1"
}

admin_query() {
  psql_query_as supabase_admin "$1"
}

actual_system_id=$(postgres_query 'select system_identifier from pg_control_system()')
[ "$actual_system_id" = "$expected_system_id" ] || {
  echo 'BLOCK: PostgreSQL system identifier mismatch' >&2
  exit 65
}

admin_identity=$(admin_query "select concat_ws('|',
  current_database(), current_user, session_user,
  (select rolsuper::int from pg_roles where rolname=current_user),
  (select system_identifier::text from pg_control_system())
)")
expected_admin_identity="postgres|supabase_admin|supabase_admin|1|$expected_system_id"
[ "$admin_identity" = "$expected_admin_identity" ] || {
  echo "BLOCK: direct database verification principal mismatch: $admin_identity" >&2
  exit 65
}

# Re-prove the exact recoverability artifact before any GoTrue mutation.
requested_backup_file=$backup_file
[ -f "$requested_backup_file" ] && [ ! -L "$requested_backup_file" ] || {
  echo 'BLOCK: backup file is missing, non-regular, or a symlink' >&2
  exit 66
}
backup_file=$(readlink -f -- "$backup_file")
case "$backup_file" in
  "$backup_root"/*.dump) ;;
  *) echo 'BLOCK: backup file is outside the approved reset backup directory' >&2; exit 66 ;;
esac

actual_backup_bytes=$(stat -c '%s' -- "$backup_file")
[ "$actual_backup_bytes" = "$expected_backup_bytes" ] || {
  echo 'BLOCK: backup byte count mismatch' >&2
  exit 66
}
actual_backup_sha256=$(sha256sum -- "$backup_file" | awk '{print $1}')
[ "$actual_backup_sha256" = "$expected_backup_sha256" ] || {
  echo 'BLOCK: backup SHA-256 mismatch' >&2
  exit 66
}
actual_toc_entries=$(
  docker exec -i "$db_container" pg_restore --list <"$backup_file" |
    awk '!/^;/ && NF { count++ } END { print count + 0 }'
)
[ "$actual_toc_entries" = "$expected_toc_entries" ] || {
  echo 'BLOCK: pg_restore catalog entry count mismatch' >&2
  exit 66
}

# Exact Task 3 post-state. The schema-history shape is part of the reset
# contract, while Auth still contains the 14 users awaiting supported cleanup.
reset_poststate=$(admin_query "select concat_ws('|',
  (select count(*) from pg_class c join pg_namespace n on n.oid=c.relnamespace where n.nspname='public' and c.relkind in ('r','p','v','m','S','f')),
  (select count(*) from pg_proc p join pg_namespace n on n.oid=p.pronamespace where n.nspname='public'),
  (select count(*) from pg_policies where schemaname='public'),
  (select count(*) from pg_policies where schemaname='storage' and tablename='objects' and (policyname ilike '%rat_signature%' or policyname ilike '%rat-signature%' or coalesce(qual,'') ilike '%public.tecnicos%' or coalesce(with_check,'') ilike '%public.tecnicos%')),
  (select count(*) from auth.users),
  (select count(*) from storage.buckets),
  (select count(*) from storage.objects),
  (to_regclass('supabase_migrations.schema_migrations') is not null)::int,
  (select count(*) from supabase_migrations.schema_migrations),
  (select string_agg(column_name || ':' || udt_name, ',' order by ordinal_position) from information_schema.columns where table_schema='supabase_migrations' and table_name='schema_migrations'),
  (select pg_get_userbyid(c.relowner)::text from pg_class c where c.oid='supabase_migrations.schema_migrations'::regclass),
  (current_user='supabase_admin' and session_user='supabase_admin' and (select rolsuper from pg_roles where rolname=current_user))::int
)")
expected_reset_poststate='0|0|0|0|14|0|0|1|0|version:text,statements:_text,name:text|supabase_admin|1'
[ "$reset_poststate" = "$expected_reset_poststate" ] || {
  echo "BLOCK: Task 3 post-state drift: $reset_poststate" >&2
  exit 67
}

platform_schemas_before=$(admin_query "select string_agg(nspname,',' order by nspname) from pg_namespace where nspname !~ '^pg_' and nspname not in ('information_schema','public','supabase_migrations')")
extensions_before=$(admin_query "select string_agg(e.extname || ':' || n.nspname,',' order by e.extname) from pg_extension e join pg_namespace n on n.oid=e.extnamespace")

set +x
mapfile -t service_key_values < <(
  docker inspect --format '{{json .Config.Env}}' "$credential_container" |
    jq -r '.[] | select(startswith("SERVICE_KEY=")) | sub("^SERVICE_KEY="; "")'
)
[ "${#service_key_values[@]}" -eq 1 ] || {
  echo 'BLOCK: expected exactly one SERVICE_KEY in supabase-storage environment' >&2
  exit 68
}
service_key=${service_key_values[0]}
unset service_key_values
[ -n "$service_key" ] || {
  echo 'BLOCK: SERVICE_KEY in supabase-storage environment is empty' >&2
  exit 68
}

curl_config=$(mktemp)
users_before=$(mktemp)
users_after=$(mktemp)
api_ids_before=$(mktemp)
db_ids_before=$(mktemp)
auth_platform_before=$(mktemp)
auth_platform_after=$(mktemp)
trap 'unset service_key SERVICE_KEY SERVICE_ROLE_KEY SUPABASE_SERVICE_ROLE_KEY 2>/dev/null || true; rm -f "$curl_config" "$users_before" "$users_after" "$api_ids_before" "$db_ids_before" "$auth_platform_before" "$auth_platform_after"' EXIT
chmod 600 "$curl_config" "$users_before" "$users_after" "$api_ids_before" \
  "$db_ids_before" "$auth_platform_before" "$auth_platform_after"
{
  printf 'silent\nshow-error\nfail-with-body\n'
  printf 'header = "apikey: %s"\n' "$service_key"
  printf 'header = "Authorization: Bearer %s"\n' "$service_key"
  printf 'header = "Content-Type: application/json"\n'
} >"$curl_config"
unset service_key SERVICE_KEY SERVICE_ROLE_KEY SUPABASE_SERVICE_ROLE_KEY

echo 'CREDENTIAL_SOURCE=PASS mode=container-env container=supabase-storage variable=SERVICE_KEY'
echo "BACKUP_RECHECK=PASS bytes=$actual_backup_bytes sha256=$actual_backup_sha256 toc_entries=$actual_toc_entries"
echo 'AUTH_RESET_POSTSTATE=PASS public_relations=0 public_functions=0 public_policies=0 storage_policies=0 auth_users=14 storage_buckets=0 storage_objects=0 history_rows=0 history_owner=supabase_admin'

curl --config "$curl_config" \
  --url "$api_base/auth/v1/admin/users?page=1&per_page=1000" \
  --output "$users_before"
jq -e '.users | type == "array"' "$users_before" >/dev/null
api_count=$(jq '.users | length' "$users_before")
[ "$api_count" = "$expected_user_count" ] || {
  echo "BLOCK: GoTrue API returned $api_count users, expected $expected_user_count" >&2
  exit 69
}
jq -e '
  [.users[].id] as $ids
  | ($ids | length) == ($ids | unique | length)
    and all($ids[]; type == "string" and test("^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[1-5][0-9a-fA-F]{3}-[89aAbB][0-9a-fA-F]{3}-[0-9a-fA-F]{12}$"))
' "$users_before" >/dev/null
jq -r '.users[].id | ascii_downcase' "$users_before" | sort >"$api_ids_before"
admin_query 'select lower(id::text) from auth.users order by id' >"$db_ids_before"
cmp -s "$api_ids_before" "$db_ids_before" || {
  echo 'BLOCK: GoTrue API and auth.users UUID inventories differ' >&2
  exit 69
}

auth_counts_before=$(admin_query "select concat_ws('|',
  (select count(*) from auth.users),
  (select count(*) from auth.identities),
  (select count(*) from auth.sessions),
  (select count(*) from auth.refresh_tokens)
)")

# Capture the complete Auth schema plus all non-user table data. Only data from
# the explicit user/session/ephemeral allowlist is excluded from comparison.
dump_auth_platform() {
  docker exec "$db_container" pg_dump -U supabase_admin -d postgres \
    --schema=auth \
    --exclude-table-data=auth.audit_log_entries \
    --exclude-table-data=auth.flow_state \
    --exclude-table-data=auth.identities \
    --exclude-table-data=auth.mfa_amr_claims \
    --exclude-table-data=auth.mfa_challenges \
    --exclude-table-data=auth.mfa_factors \
    --exclude-table-data=auth.oauth_authorizations \
    --exclude-table-data=auth.oauth_consents \
    --exclude-table-data=auth.one_time_tokens \
    --exclude-table-data=auth.refresh_tokens \
    --exclude-table-data=auth.saml_relay_states \
    --exclude-table-data=auth.sessions \
    --exclude-table-data=auth.users |
    sed '/^\\restrict /d; /^\\unrestrict /d; /^SELECT pg_catalog\.setval/d'
}

dump_auth_platform >"$auth_platform_before"
[ -s "$auth_platform_before" ] || {
  echo 'BLOCK: Auth platform preservation snapshot is empty' >&2
  exit 70
}

echo "GOTRUE_PRECHECK=PASS api_users=$api_count db_core_counts=$auth_counts_before uuid_inventory=exact"

# Supported GoTrue Admin API sequence. Only the 14 UUIDs captured above are
# targeted; new/concurrent users are never swept into this operation.
deleted_count=0
while IFS= read -r user_id; do
  curl --config "$curl_config" --request DELETE \
    --url "$api_base/auth/v1/admin/users/$user_id" \
    --output /dev/null
  deleted_count=$((deleted_count + 1))
done <"$api_ids_before"
[ "$deleted_count" = "$expected_user_count" ] || {
  echo 'BLOCK: deletion loop did not process the exact approved UUID count' >&2
  exit 71
}

curl --config "$curl_config" \
  --url "$api_base/auth/v1/admin/users?page=1&per_page=1000" \
  --output "$users_after"
jq -e '.users | type == "array"' "$users_after" >/dev/null
remaining_api=$(jq '.users | length' "$users_after")
auth_counts_after=$(admin_query "select concat_ws('|',
  (select count(*) from auth.users),
  (select count(*) from auth.identities),
  (select count(*) from auth.sessions),
  (select count(*) from auth.refresh_tokens)
)")
[ "$remaining_api" = '0' ] && [ "$auth_counts_after" = '0|0|0|0' ] || {
  echo "BLOCK: GoTrue cleanup incomplete (api_users=$remaining_api db_core_counts=$auth_counts_after)" >&2
  exit 72
}

dump_auth_platform >"$auth_platform_after"
cmp -s "$auth_platform_before" "$auth_platform_after" || {
  echo 'BLOCK: Auth schema or non-user platform data changed' >&2
  exit 73
}

platform_schemas_after=$(admin_query "select string_agg(nspname,',' order by nspname) from pg_namespace where nspname !~ '^pg_' and nspname not in ('information_schema','public','supabase_migrations')")
extensions_after=$(admin_query "select string_agg(e.extname || ':' || n.nspname,',' order by e.extname) from pg_extension e join pg_namespace n on n.oid=e.extnamespace")
[ "$platform_schemas_after" = "$platform_schemas_before" ] || {
  echo 'BLOCK: internal Supabase schema inventory changed' >&2
  exit 73
}
[ "$extensions_after" = "$extensions_before" ] || {
  echo 'BLOCK: extension inventory changed' >&2
  exit 73
}

cleanup_poststate=$(admin_query "select concat_ws('|',
  (select count(*) from pg_class c join pg_namespace n on n.oid=c.relnamespace where n.nspname='public' and c.relkind in ('r','p','v','m','S','f')),
  (select count(*) from pg_proc p join pg_namespace n on n.oid=p.pronamespace where n.nspname='public'),
  (select count(*) from pg_policies where schemaname='public'),
  (select count(*) from pg_policies where schemaname='storage' and tablename='objects' and (policyname ilike '%rat_signature%' or policyname ilike '%rat-signature%' or coalesce(qual,'') ilike '%public.tecnicos%' or coalesce(with_check,'') ilike '%public.tecnicos%')),
  (select count(*) from auth.users),
  (select count(*) from storage.buckets),
  (select count(*) from storage.objects),
  (to_regclass('supabase_migrations.schema_migrations') is not null)::int,
  (select count(*) from supabase_migrations.schema_migrations),
  (select pg_get_userbyid(c.relowner)::text from pg_class c where c.oid='supabase_migrations.schema_migrations'::regclass)
)")
[ "$cleanup_poststate" = '0|0|0|0|0|0|0|1|0|supabase_admin' ] || {
  echo "BLOCK: platform post-state changed during Auth cleanup: $cleanup_poststate" >&2
  exit 74
}

echo 'AUTH_CORE_CLEANUP=PASS users=0 identities=0 sessions=0 refresh_tokens=0'
echo 'AUTH_PLATFORM_PRESERVATION=PASS schema=unchanged non_user_data=unchanged internal_schemas=unchanged extensions=unchanged'
echo "TECHREPORT_GOTRUE_ADMIN_CLEANUP=PASS users_removed=$deleted_count"
