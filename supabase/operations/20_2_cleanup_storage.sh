#!/usr/bin/env bash
set -euo pipefail

if [ "$#" -ne 5 ]; then
  echo "usage: $0 <env-file> <api-base-url> <expected-db-container-id> <expected-system-id> <expected-object-count>" >&2
  exit 64
fi

env_file=$1
api_base=${2%/}
expected_container_id=$3
expected_system_id=$4
expected_object_count=$5
db_container=supabase-db
bucket=rat-signatures

command -v curl >/dev/null
[ -r "$env_file" ]

actual_container_id=$(docker inspect --format '{{.Id}}' "$db_container")
[ "$actual_container_id" = "$expected_container_id" ] || {
  echo 'BLOCK: database container identity mismatch' >&2
  exit 65
}

actual_system_id=$(docker exec "$db_container" psql -U postgres -d postgres -X -Atqc \
  "select system_identifier from pg_control_system()")
[ "$actual_system_id" = "$expected_system_id" ] || {
  echo 'BLOCK: PostgreSQL system identifier mismatch' >&2
  exit 65
}

actual_object_count=$(docker exec "$db_container" psql -U postgres -d postgres -X -Atqc \
  "select count(*) from storage.objects where bucket_id = 'rat-signatures'")
[ "$actual_object_count" = "$expected_object_count" ] || {
  echo "BLOCK: expected $expected_object_count Storage objects, found $actual_object_count" >&2
  exit 66
}

set -a
# shellcheck disable=SC1090
. "$env_file"
set +a
service_key=${SERVICE_ROLE_KEY:-${SUPABASE_SERVICE_ROLE_KEY:-}}
[ -n "$service_key" ] || {
  echo 'BLOCK: service-role key variable not found in env file' >&2
  exit 67
}

curl_config=$(mktemp)
trap 'rm -f "$curl_config"' EXIT
chmod 600 "$curl_config"
{
  printf 'silent\nshow-error\nfail-with-body\n'
  printf 'header = "apikey: %s"\n' "$service_key"
  printf 'header = "Authorization: Bearer %s"\n' "$service_key"
  printf 'header = "Content-Type: application/json"\n'
} >"$curl_config"
unset service_key SERVICE_ROLE_KEY SUPABASE_SERVICE_ROLE_KEY

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
  exit 68
}

echo "TECHREPORT_STORAGE_API_CLEANUP=PASS objects_removed=$actual_object_count bucket=$bucket"
