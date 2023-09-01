/* Find indexes with a high ratio of NULL values */

SELECT
    c.oid,
    c.relname AS index,
    pg_size_pretty(pg_relation_size(c.oid)) AS index_size,
    i.indisunique AS unique,
    a.attname AS indexed_column,
    s.tablename AS table,
    CASE s.null_frac
        WHEN 0 THEN ''
        ELSE to_char(s.null_frac * 100, '999.00%%')
    END AS null_frac,
    pg_size_pretty((pg_relation_size(c.oid) * s.null_frac)::bigint) AS expected_saving,
    n.nspname as schema
FROM
    pg_class c
    JOIN pg_index i ON i.indexrelid = c.oid
    JOIN pg_attribute a ON a.attrelid = c.oid
    JOIN pg_class c_table ON c_table.oid = i.indrelid
    JOIN pg_indexes ixs ON c.relname = ixs.indexname
    LEFT JOIN pg_namespace n ON (n.oid = c.relnamespace)
    LEFT JOIN pg_stats s ON s.tablename = c_table.relname AND a.attname = s.attname
WHERE
    -- Primary key cannot be partial
    NOT i.indisprimary
    -- Exclude already partial indexes
    AND i.indpred IS NULL
    -- Exclude composite indexes
    AND array_length(i.indkey, 1) = 1
    -- Exclude indexes without null_frac ratio
    AND coalesce(s.null_frac, 0) != 0
    -- Larger than threshold
    AND pg_relation_size(c.oid) > %{min_relation_size_mb} * 1024 ^ 2
ORDER BY
  pg_relation_size(c.oid) * s.null_frac DESC;
