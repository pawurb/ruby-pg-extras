/* List all the indexes with their corresponding tables and columns. */

SELECT
  n.nspname AS schemaname,
  i.relname AS indexname,
  t.relname AS tablename,
  string_agg(key_column.display_column, ', ' ORDER BY key_column.position) AS columns,
  json_agg(key_column.display_column ORDER BY key_column.position)::text AS columns_json,
  COALESCE(
    string_agg(key_column.attname, ', ' ORDER BY key_column.position) FILTER (WHERE key_column.attname IS NOT NULL),
    ''
  ) AS key_columns,
  json_agg(key_column.attname ORDER BY key_column.position)::text AS key_column_names,
  COALESCE(included_columns.columns, '') AS included_columns,
  COALESCE(included_columns.columns_json, '[]') AS included_columns_json,
  am.amname AS index_method,
  ix.indisunique AS is_unique,
  ix.indisprimary AS is_primary,
  (ix.indpred IS NOT NULL) AS is_partial,
  pg_get_expr(ix.indpred, ix.indrelid) AS predicate
FROM pg_index ix
JOIN pg_class i ON i.oid = ix.indexrelid
JOIN pg_class t ON t.oid = ix.indrelid
JOIN pg_namespace n ON n.oid = t.relnamespace
JOIN pg_am am ON am.oid = i.relam
-- Expand each index into one row per key position so column/opclass/collation/options stay aligned.
CROSS JOIN LATERAL (
  SELECT
    key_position.position,
    a.attname,
    concat_ws(
      ' ',
      pg_get_indexdef(i.oid, key_position.position, true),
      CASE
        WHEN c.oid IS NOT NULL AND c.collname <> 'default' AND (a.attcollation IS NULL OR c.oid <> a.attcollation)
          THEN 'COLLATE ' || quote_ident(c.collname)
      END,
      CASE
        WHEN oc.oid IS NOT NULL AND oc.opcdefault = false THEN oc.opcname
      END,
      CASE
        WHEN (index_option.option_value & 1) = 1 THEN 'DESC'
      END,
      CASE
        WHEN (index_option.option_value & 2) = 2 THEN 'NULLS FIRST'
        WHEN (index_option.option_value & 1) = 1 THEN 'NULLS LAST'
      END
    ) AS display_column
  FROM generate_series(1, ix.indnkeyatts) AS key_position(position)
  LEFT JOIN pg_attribute a
    ON a.attrelid = t.oid
    AND a.attnum = (string_to_array(ix.indkey::text, ' '))[key_position.position]::int
  LEFT JOIN pg_opclass oc
    ON oc.oid = (string_to_array(ix.indclass::text, ' '))[key_position.position]::oid
  LEFT JOIN pg_collation c
    ON c.oid = (string_to_array(ix.indcollation::text, ' '))[key_position.position]::oid
  CROSS JOIN LATERAL (
    SELECT COALESCE((string_to_array(ix.indoption::text, ' '))[key_position.position]::int, 0) AS option_value
  ) index_option
) key_column
-- INCLUDE columns are stored after key columns in pg_index and must be reported separately.
LEFT JOIN LATERAL (
  SELECT
    string_agg(pg_get_indexdef(i.oid, included_position.position, true), ', ' ORDER BY included_position.position) AS columns,
    json_agg(pg_get_indexdef(i.oid, included_position.position, true) ORDER BY included_position.position)::text AS columns_json
  FROM generate_series(ix.indnkeyatts + 1, ix.indnatts) AS included_position(position)
) included_columns ON true
WHERE t.oid IN (SELECT relid FROM pg_statio_user_tables)
GROUP BY
  n.nspname,
  i.relname,
  t.relname,
  included_columns.columns,
  included_columns.columns_json,
  am.amname,
  ix.indisunique,
  ix.indisprimary,
  ix.indpred,
  ix.indrelid;
