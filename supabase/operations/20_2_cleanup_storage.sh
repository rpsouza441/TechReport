#!/usr/bin/env bash
set -euo pipefail

if [ "$#" -ne 9 ]; then
  echo "usage: $0 <env-file|auto> <api-base-url> <expected-db-container-id> <expected-system-id> <expected-object-count> <backup-file> <expected-backup-bytes> <expected-backup-sha256> <expected-pg-restore-toc-entries>" >&2
  exit 64
fi

env_file=$1
api_base=${2%/}
expected_container_id=$3
expected_system_id=$4
expected_object_count=$5
backup_file=$6
expected_backup_bytes=$7
expected_backup_sha256=$8
expected_toc_entries=$9
db_container=supabase-db
bucket=rat-signatures
expected_api_base=http://127.0.0.1:18000
backup_root=/srv/DATA/supabase/backups/techreport-reset

command -v curl >/dev/null
command -v jq >/dev/null
command -v sha256sum >/dev/null
command -v stat >/dev/null

[[ "$expected_container_id" =~ ^[0-9a-f]{64}$ ]] || {
  echo 'BLOCK: invalid expected database container identity' >&2
  exit 64
}
[[ "$expected_system_id" =~ ^[0-9]+$ ]] || {
  echo 'BLOCK: invalid expected PostgreSQL system identifier' >&2
  exit 64
}
[[ "$expected_object_count" =~ ^[0-9]+$ ]] || {
  echo 'BLOCK: invalid expected Storage object count' >&2
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
[ "$api_base" = "$expected_api_base" ] || {
  echo 'BLOCK: unexpected Storage API base URL' >&2
  exit 65
}

actual_container_id=$(docker inspect --format '{{.Id}}' "$db_container")
[ "$actual_container_id" = "$expected_container_id" ] || {
  echo 'BLOCK: database container identity mismatch' >&2
  exit 65
}

actual_image=$(docker inspect --format '{{.Config.Image}}' "$db_container")
case "$actual_image" in
  *supabase/postgres*) ;;
  *)
    echo 'BLOCK: database container is not a Supabase Postgres image' >&2
    exit 65
    ;;
esac

actual_system_id=$(docker exec "$db_container" psql -U postgres -d postgres -X -Atqc \
  "select system_identifier from pg_control_system()")
[ "$actual_system_id" = "$expected_system_id" ] || {
  echo 'BLOCK: PostgreSQL system identifier mismatch' >&2
  exit 65
}

# Re-prove the exact recoverability artifact before any Storage mutation.
requested_backup_file=$backup_file
[ -f "$requested_backup_file" ] && [ ! -L "$requested_backup_file" ] || {
  echo 'BLOCK: backup file is missing, non-regular, or a symlink' >&2
  exit 66
}
backup_file=$(readlink -f -- "$backup_file")
case "$backup_file" in
  "$backup_root"/*.dump) ;;
  *)
    echo 'BLOCK: backup file is outside the approved reset backup directory' >&2
    exit 66
    ;;
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
echo "BACKUP_RECHECK=PASS bytes=$actual_backup_bytes sha256=$actual_backup_sha256 toc_entries=$actual_toc_entries"

actual_object_count=$(docker exec "$db_container" psql -U postgres -d postgres -X -Atqc \
  "select count(*) from storage.objects where bucket_id = 'rat-signatures'")
[ "$actual_object_count" = "$expected_object_count" ] || {
  echo "BLOCK: expected $expected_object_count Storage objects, found $actual_object_count" >&2
  exit 67
}
target_bucket_count=$(docker exec "$db_container" psql -U postgres -d postgres -X -Atqc \
  "select count(*) from storage.buckets where id = 'rat-signatures'")
[ "$target_bucket_count" = '1' ] || {
  echo "BLOCK: expected exactly one $bucket bucket, found $target_bucket_count" >&2
  exit 67
}

if [ "$env_file" = 'auto' ]; then
  mapfile -d '' env_candidates < <(
    find /srv/DATA/supabase -maxdepth 3 -type f -name .env -print0
  )
  [ "${#env_candidates[@]}" -eq 1 ] || {
    echo 'BLOCK: expected exactly one self-hosted Supabase .env file' >&2
    exit 68
  }
  env_file=${env_candidates[0]}
fi
requested_env_file=$env_file
[ -f "$requested_env_file" ] && [ ! -L "$requested_env_file" ] || {
  echo 'BLOCK: self-hosted Supabase env file is missing, non-regular, or a symlink' >&2
  exit 68
}
env_file=$(readlink -f -- "$env_file")
case "$env_file" in
  /srv/DATA/supabase/*) ;;
  *)
    echo 'BLOCK: env file is outside the self-hosted Supabase directory' >&2
    exit 68
    ;;
esac
[ -r "$env_file" ] || {
  echo 'BLOCK: self-hosted Supabase env file is not readable' >&2
  exit 68
}

set +x
# shellcheck disable=SC1090
. "$env_file"
service_key=${SERVICE_ROLE_KEY:-${SUPABASE_SERVICE_ROLE_KEY:-}}
[ -n "$service_key" ] || {
  echo 'BLOCK: service-role key variable not found in env file' >&2
  exit 69
}

curl_config=$(mktemp)
api_buckets_before=$(mktemp)
api_buckets_after=$(mktemp)
other_storage_before=$(mktemp)
other_storage_after=$(mktemp)
trap 'rm -f "$curl_config" "$api_buckets_before" "$api_buckets_after" "$other_storage_before" "$other_storage_after"' EXIT
chmod 600 "$curl_config" "$api_buckets_before" "$api_buckets_after" \
  "$other_storage_before" "$other_storage_after"
{
  printf 'silent\nshow-error\nfail-with-body\n'
  printf 'header = "apikey: %s"\n' "$service_key"
  printf 'header = "Authorization: Bearer %s"\n' "$service_key"
  printf 'header = "Content-Type: application/json"\n'
} >"$curl_config"
unset service_key SERVICE_ROLE_KEY SUPABASE_SERVICE_ROLE_KEY

inventory_sql="select jsonb_build_object(
  'buckets', coalesce((select jsonb_agg(to_jsonb(b) order by b.id) from storage.buckets b where b.id <> 'rat-signatures'), '[]'::jsonb),
  'objects', coalesce((select jsonb_agg(to_jsonb(o) order by o.bucket_id, o.name, o.id) from storage.objects o where o.bucket_id <> 'rat-signatures'), '[]'::jsonb)
)::text"
docker exec "$db_container" psql -U postgres -d postgres -X -Atqc "$inventory_sql" \
  >"$other_storage_before"

curl --config "$curl_config" --url "$api_base/storage/v1/bucket" |
  jq --arg bucket "$bucket" -S -c \
    'if type != "array" then error("Storage bucket inventory is not an array") else map(select(.id != $bucket)) | sort_by(.id) end' \
    >"$api_buckets_before"
api_target_bucket_count=$(
  curl --config "$curl_config" --url "$api_base/storage/v1/bucket" |
    jq --arg bucket "$bucket" '[.[] | select(.id == $bucket)] | length'
)
[ "$api_target_bucket_count" = '1' ] || {
  echo "BLOCK: Storage API did not inventory exactly one $bucket bucket" >&2
  exit 70
}

other_bucket_count=$(docker exec "$db_container" psql -U postgres -d postgres -X -Atqc \
  "select count(*) from storage.buckets where id <> 'rat-signatures'")
other_object_count=$(docker exec "$db_container" psql -U postgres -d postgres -X -Atqc \
  "select count(*) from storage.objects where bucket_id <> 'rat-signatures'")
echo "STORAGE_PRECHECK=PASS objects=$actual_object_count bucket=$bucket other_buckets=$other_bucket_count other_objects=$other_object_count"

# Supported Storage API sequence. Never delete storage.objects directly.
curl --config "$curl_config" --request POST \
  --url "$api_base/storage/v1/bucket/$bucket/empty" \
  --data '{}'
curl --config "$curl_config" --request DELETE \
  --url "$api_base/storage/v1/bucket/$bucket"

remaining_objects=$(docker exec "$db_container" psql -U postgres -d postgres -X -Atqc \
  "select count(*) from storage.objects where bucket_id = 'rat-signatures'")
bucket_exists=$(docker exec "$db_container" psql -U postgres -d postgres -X -Atqc \
  "select exists(select 1 from storage.buckets where id = 'rat-signatures')")

[ "$remaining_objects" = '0' ] && [ "$bucket_exists" = 'f' ] || {
  echo "BLOCK: Storage API cleanup incomplete (objects=$remaining_objects bucket_exists=$bucket_exists)" >&2
  exit 71
}

docker exec "$db_container" psql -U postgres -d postgres -X -Atqc "$inventory_sql" \
  >"$other_storage_after"
cmp -s "$other_storage_before" "$other_storage_after" || {
  echo 'BLOCK: non-target Storage database inventory changed' >&2
  exit 72
}
curl --config "$curl_config" --url "$api_base/storage/v1/bucket" |
  jq --arg bucket "$bucket" -S -c \
    'if type != "array" then error("Storage bucket inventory is not an array") else map(select(.id != $bucket)) | sort_by(.id) end' \
    >"$api_buckets_after"
cmp -s "$api_buckets_before" "$api_buckets_after" || {
  echo 'BLOCK: non-target Storage API bucket inventory changed' >&2
  exit 72
}
api_target_bucket_count=$(
  curl --config "$curl_config" --url "$api_base/storage/v1/bucket" |
    jq --arg bucket "$bucket" '[.[] | select(.id == $bucket)] | length'
)
[ "$api_target_bucket_count" = '0' ] || {
  echo "BLOCK: Storage API still reports $bucket" >&2
  exit 72
}

echo "STORAGE_PRESERVATION=PASS other_buckets=$other_bucket_count other_objects=$other_object_count"
echo "TECHREPORT_STORAGE_API_CLEANUP=PASS objects_removed=$actual_object_count bucket=$bucket"
