#!/usr/bin/env bash
set -euo pipefail

if [ "$#" -ne 6 ]; then
  echo "usage: $0 <reset-sql> <backup-dump> <backup-sha256> <db-container-id> <system-id> <reset-sql-sha256>" >&2
  exit 64
fi

reset_sql=$1
backup_dump=$2
expected_backup_sha=$3
expected_container_id=$4
expected_system_id=$5
expected_sql_sha=$6
db_container='supabase-db'

case "$expected_backup_sha" in
  *[!0-9a-fA-F]*|'') echo 'BLOCK: invalid backup SHA-256' >&2; exit 64 ;;
esac
case "$expected_sql_sha" in
  *[!0-9a-fA-F]*|'') echo 'BLOCK: invalid reset SQL SHA-256' >&2; exit 64 ;;
esac
[ "${#expected_backup_sha}" -eq 64 ]
[ "${#expected_sql_sha}" -eq 64 ]
case "$expected_container_id" in
  *[!0-9a-fA-F]*|'') echo 'BLOCK: invalid container ID' >&2; exit 64 ;;
esac
[ "${#expected_container_id}" -eq 64 ]
case "$expected_system_id" in
  *[!0-9]*|'') echo 'BLOCK: invalid PostgreSQL system identifier' >&2; exit 64 ;;
esac

[ -f "$reset_sql" ] && [ ! -L "$reset_sql" ] && [ -s "$reset_sql" ]
[ -f "$backup_dump" ] && [ ! -L "$backup_dump" ] && [ -s "$backup_dump" ]

reset_sql=$(readlink -f "$reset_sql")
backup_dump=$(readlink -f "$backup_dump")

[ "$(basename "$reset_sql")" = '20_2_reset_allowlist.sql' ] || {
  echo 'BLOCK: unexpected reset SQL basename' >&2
  exit 65
}

case "$reset_sql" in
  /tmp/*|/srv/DATA/supabase/operations/*) ;;
  *) echo "BLOCK: reset SQL path outside approved roots: $reset_sql" >&2; exit 65 ;;
esac
case "$backup_dump" in
  /srv/DATA/supabase/backups/techreport-reset/*.dump) ;;
  *) echo "BLOCK: backup path outside approved root: $backup_dump" >&2; exit 65 ;;
esac

actual_backup_sha=$(sha256sum "$backup_dump" | awk '{print $1}')
actual_sql_sha=$(sha256sum "$reset_sql" | awk '{print $1}')
[ "$actual_backup_sha" = "${expected_backup_sha,,}" ] || {
  echo 'BLOCK: backup SHA-256 mismatch' >&2
  exit 66
}
[ "$actual_sql_sha" = "${expected_sql_sha,,}" ] || {
  echo 'BLOCK: reset SQL SHA-256 mismatch' >&2
  exit 66
}

actual_container_id=$(docker inspect --format '{{.Id}}' "$db_container")
container_running=$(docker inspect --format '{{.State.Running}}' "$db_container")
container_image=$(docker inspect --format '{{.Config.Image}}' "$db_container")
[ "$actual_container_id" = "${expected_container_id,,}" ] || {
  echo 'BLOCK: database container identity mismatch' >&2
  exit 67
}
[ "$container_running" = 'true' ]
case "$container_image" in
  *supabase/postgres*) ;;
  *) echo "BLOCK: unexpected database image: $container_image" >&2; exit 67 ;;
esac

psql_query_as() {
  local role=$1
  local sql=$2
  docker exec "$db_container" \
    psql -U "$role" -d postgres -X -v ON_ERROR_STOP=1 -Atqc "$sql"
}

psql_query() {
  psql_query_as postgres "$1"
}

reset_psql_query() {
  psql_query_as supabase_admin "$1"
}

actual_database=$(psql_query 'select current_database()')
actual_role=$(psql_query 'select current_user')
actual_system_id=$(psql_query 'select system_identifier from pg_control_system()')
[ "$actual_database" = 'postgres' ]
[ "$actual_role" = 'postgres' ]
[ "$actual_system_id" = "$expected_system_id" ] || {
  echo 'BLOCK: PostgreSQL system identifier mismatch' >&2
  exit 67
}

# The reset transaction connects directly as the exact owner/superuser. Prove
# that this local container connection resolves to the expected principal and
# database instance before any mutation is possible.
reset_identity=$(reset_psql_query "select concat_ws('|',
  current_database(),
  current_user,
  session_user,
  (select rolsuper::int from pg_roles where rolname=current_user),
  (select system_identifier::text from pg_control_system())
)")
expected_reset_identity="postgres|supabase_admin|supabase_admin|1|$expected_system_id"
[ "$reset_identity" = "$expected_reset_identity" ] || {
  echo "BLOCK: direct reset principal mismatch: $reset_identity" >&2
  exit 67
}

# Re-prove archive readability with the exact running PostgreSQL toolchain.
toc_entries=$(
  docker exec -i "$db_container" pg_restore --list <"$backup_dump" |
    awk 'BEGIN { count=0 } $0 !~ /^;/ && NF { count++ } END { print count }'
)
[ "$toc_entries" -gt 0 ] || {
  echo 'BLOCK: backup archive has no pg_restore TOC entries' >&2
  exit 68
}

# Exact definitive inventory after the supported Storage API cleanup and before
# any SQL mutation. Field order is documented in the PASS marker below.
prestate=$(reset_psql_query "select concat_ws('|',
  (select count(*) from public.empresas),
  (select count(*) from public.tecnicos),
  (select count(*) from public.app_admins),
  (select count(*) from public.tecnico_convites),
  (select count(*) from public.rats),
  (select count(*) from public.rat_audit_log),
  (select count(*) from public.rat_signature_attachments),
  (select count(*) from auth.users),
  (select count(*) from public.tecnicos t join public.app_admins a on a.user_id=t.user_id where t.ativo and a.ativo),
  (select count(*) from storage.buckets),
  (select count(*) from storage.objects),
  (select count(*) from pg_extension e join pg_namespace n on n.oid=e.extnamespace where n.nspname='public'),
  (select count(*) from pg_publication_tables where schemaname in ('public','storage')),
  (select count(*) from pg_class c join pg_namespace n on n.oid=c.relnamespace where n.nspname='public' and c.relkind in ('r','p','v','m','S','f')),
  (select count(*) from pg_proc p join pg_namespace n on n.oid=p.pronamespace where n.nspname='public'),
  (select count(*) from pg_policies where schemaname='public'),
  (select count(*) from pg_policies where schemaname='storage' and tablename='objects' and policyname like 'rat_signatures_%'),
  (select count(*) from pg_trigger t join pg_class c on c.oid=t.tgrelid join pg_namespace n on n.oid=c.relnamespace where not t.tgisinternal and n.nspname='public'),
  (to_regclass('supabase_migrations.schema_migrations') is null)::int,
  (select string_agg(distinct pg_get_userbyid(c.relowner)::text,',' order by pg_get_userbyid(c.relowner)::text) from pg_class c join pg_namespace n on n.oid=c.relnamespace where n.nspname='public' and c.relkind in ('r','p','v','m','S','f')),
  (select string_agg(distinct pg_get_userbyid(p.proowner)::text,',' order by pg_get_userbyid(p.proowner)::text) from pg_proc p join pg_namespace n on n.oid=p.pronamespace where n.nspname='public'),
  (select string_agg(distinct pg_get_userbyid(c.relowner)::text,',' order by pg_get_userbyid(c.relowner)::text) from pg_class c join pg_namespace n on n.oid=c.relnamespace where n.nspname='storage' and c.relname in ('buckets','objects')),
  (current_user='supabase_admin' and session_user='supabase_admin' and
    (select rolsuper from pg_roles where rolname=current_user))::int
)")
expected_prestate='8|13|1|15|70|0|42|14|1|0|0|0|0|7|13|19|4|1|1|supabase_admin|supabase_admin|supabase_storage_admin|1'
[ "$prestate" = "$expected_prestate" ] || {
  echo "BLOCK: live pre-state drift: $prestate" >&2
  exit 69
}

platform_schemas_before=$(reset_psql_query "select string_agg(nspname,',' order by nspname) from pg_namespace where nspname !~ '^pg_' and nspname not in ('information_schema','public','supabase_migrations')")
extensions_before=$(reset_psql_query "select string_agg(e.extname || ':' || n.nspname,',' order by e.extname) from pg_extension e join pg_namespace n on n.oid=e.extnamespace")

echo "TECHREPORT_RESET_HOST_PRECHECK=PASS backup_sha256=$actual_backup_sha sql_sha256=$actual_sql_sha toc_entries=$toc_entries"
echo "TECHREPORT_RESET_DIRECT_PRINCIPAL=PASS database=postgres current_user=supabase_admin session_user=supabase_admin rolsuper=true system_identifier=$expected_system_id"
echo 'TECHREPORT_RESET_LIVE_PRESTATE=PASS empresas=8 tecnicos=13 app_admins=1 convites=15 rats=70 audit=0 signature_metadata=42 auth_users=14 dual_identity=1 storage_buckets=0 storage_objects=0 public_relations=7 public_functions=13 public_policies=19 storage_policies=4 public_triggers=1 history_absent=1 relation_owner=supabase_admin function_owner=supabase_admin storage_relation_owner=supabase_storage_admin direct_principal=PASS'

docker exec -i "$db_container" \
  psql -U supabase_admin -d postgres -X -v ON_ERROR_STOP=1 \
  -v expected_system_identifier="$expected_system_id" <"$reset_sql"

poststate=$(reset_psql_query "select concat_ws('|',
  (select count(*) from pg_class c join pg_namespace n on n.oid=c.relnamespace where n.nspname='public' and c.relkind in ('r','p','v','m','S','f')),
  (select count(*) from pg_proc p join pg_namespace n on n.oid=p.pronamespace where n.nspname='public'),
  (select count(*) from auth.users),
  (select count(*) from storage.buckets),
  (select count(*) from storage.objects),
  (select count(*) from pg_policies where schemaname='storage' and tablename='objects' and policyname like 'rat_signatures_%'),
  (to_regclass('supabase_migrations.schema_migrations') is not null)::int,
  (select count(*) from supabase_migrations.schema_migrations)
)")
[ "$poststate" = '0|0|14|0|0|0|1|0' ] || {
  echo "BLOCK: unexpected post-reset state: $poststate" >&2
  exit 70
}

platform_schemas_after=$(reset_psql_query "select string_agg(nspname,',' order by nspname) from pg_namespace where nspname !~ '^pg_' and nspname not in ('information_schema','public','supabase_migrations')")
extensions_after=$(reset_psql_query "select string_agg(e.extname || ':' || n.nspname,',' order by e.extname) from pg_extension e join pg_namespace n on n.oid=e.extnamespace")
[ "$platform_schemas_after" = "$platform_schemas_before" ] || {
  echo 'BLOCK: internal Supabase schema inventory changed' >&2
  exit 71
}
[ "$extensions_after" = "$extensions_before" ] || {
  echo 'BLOCK: extension inventory changed' >&2
  exit 71
}

echo 'TECHREPORT_RESET_PRESERVATION=PASS auth_users=14 storage_buckets=0 storage_objects=0 internal_schemas=unchanged extensions=unchanged'
echo 'TECHREPORT_RESET_TASK3=PASS'
