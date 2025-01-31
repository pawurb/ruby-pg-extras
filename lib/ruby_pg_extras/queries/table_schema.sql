/* Table column names and types */

SELECT column_name, data_type, is_nullable, column_default 
  FROM information_schema.columns 
  WHERE table_name = '%{table_name}';
