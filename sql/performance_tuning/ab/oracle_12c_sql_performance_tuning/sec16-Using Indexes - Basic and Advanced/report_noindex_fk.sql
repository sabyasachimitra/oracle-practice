/* Query to report non-indexed foreign key. It doesn't catch all cases */
-- 
SET LINESIZE 180
col CONS_NAME format a20
col TABLE_NAME format a15
col CONS_COLUMN format a15
col IND_COLUMN format a15
--
SELECT DISTINCT
    a.constraint_name              cons_name,
    a.table_name,
    b.column_name                  cons_column,
    nvl(c.column_name, 'NO INDEX') ind_column
FROM
    user_constraints  a,
    user_cons_columns b,
    user_ind_columns  c
WHERE
        constraint_type = 'R'
    AND a.constraint_name = b.constraint_name
    AND b.column_name = c.column_name (+)
    AND b.table_name = c.table_name (+)
    AND b.position = c.column_position (+)
    AND c.column_name IS NULL
ORDER BY
    table_name,
    ind_column;
--    