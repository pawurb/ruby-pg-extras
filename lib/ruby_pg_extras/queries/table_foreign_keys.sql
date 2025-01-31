/* Foreign keys info for a specific table  */

SELECT 
    conrelid::regclass AS table_name,
    conname AS constraint_name,
    a.attname AS column_name,
    confrelid::regclass AS foreign_table_name,
    af.attname AS foreign_column_name
FROM 
    pg_constraint AS c
JOIN 
    pg_attribute AS a ON a.attnum = ANY(c.conkey) AND a.attrelid = c.conrelid
JOIN 
    pg_attribute AS af ON af.attnum = ANY(c.confkey) AND af.attrelid = c.confrelid
WHERE 
    c.contype = 'f'
    AND c.conrelid = '%{table_name}'::regclass;
