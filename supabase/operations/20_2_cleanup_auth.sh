#!/usr/bin/env bash
set -euo pipefail

if [ "$#" -ne 5 ]; then
  echo "usage: $0 <env-file> <api-base-url> <expected-db-container-id> <expected-system-id> <expected-user-count>" >&2
  exit 64
fi

env_file=$1
api_base=${2%/}
expected_container_id=$3
expected_system_id=$4
expected_user_count=$5
db_container=supabase-db

command -v curl >/dev/null
command -v jq >/dev/null
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

actual_db_count=$(docker exec "$db_container" psql -U postgres -d postgres -X -Atqc \
  'select count(*) from auth.users')
[ "$actual_db_count" = "$expected_user_count" ] || {
  echo "BLOCK: expected $expected_user_count Auth users, found $actual_db_count" >&2
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
users_json=$(mktemp)
trap 'rm -f "$curl_config" "$users_json"' EXIT
chmod 600 "$curl_config" "$users_json"
{
  printf 'silent\nshow-error\nfail-with-body\n'
  printf 'header = "apikey: %s"\n' "$service_key"
  printf 'header = "Authorization: Bearer %s"\n' "$service_key"
  printf 'header = "Content-Type: application/json"\n'
} >"$curl_config"
unset service_key SERVICE_ROLE_KEY SUPABASE_SERVICE_ROLE_KEY

curl --config "$curl_config" \
  --url "$api_base/auth/v1/admin/users?page=1&per_page=1000" \
  --output "$users_json"

api_count=$(jq '.users | length' "$users_json")
[ "$api_count" = "$expected_user_count" ] || {
  echo "BLOCK: GoTrue API returned $api_count users, expected $expected_user_count" >&2
  exit 68
}

# Supported GoTrue Admin API sequence. Never delete auth schema rows directly.
while IFS= read -r user_id; do
  curl --config "$curl_config" --request DELETE \
    --url "$api_base/auth/v1/admin/users/$user_id" \
    --output /dev/null
done < <(jq -r '.users[].id' "$users_json")

curl --config "$curl_config" \
  --url "$api_base/auth/v1/admin/users?page=1&per_page=1000" \
  --output "$users_json"
remaining_api=$(jq '.users | length' "$users_json")
remaining_db=$(docker exec "$db_container" psql -U postgres -d postgres -X -Atqc \
  'select count(*) from auth.users')

[ "$remaining_api" = '0' ] && [ "$remaining_db" = '0' ] || {
  echo "BLOCK: GoTrue cleanup incomplete (api=$remaining_api db=$remaining_db)" >&2
  exit 69
}

echo "TECHREPORT_GOTRUE_ADMIN_CLEANUP=PASS users_removed=$api_count"
