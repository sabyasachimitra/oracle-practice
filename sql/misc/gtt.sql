/* Oracle DB: 19.3 */
/* creating GTT */
CREATE GLOBAL TEMPORARY TABLE my_gtt_table (
  id           NUMBER,
  description  VARCHAR2(20)
)
ON COMMIT DELETE ROWS;
--
INSERT INTO my_gtt_table VALUES (1, 'ONE');
--
SELECT * FROM my_gtt_table;
--
COMMIT;
--
SELECT * FROM my_gtt_table;
--
DROP TABLE my_gtt_table;
--
CREATE GLOBAL TEMPORARY TABLE my_gtt_table (
  id           NUMBER,
  description  VARCHAR2(20)
)
ON COMMIT PRESERVE ROWS;
--
INSERT INTO my_gtt_table VALUES (2, 'TWO');
COMMIT;
--
SELECT * FROM my_gtt_table;
/* reconnect and check the contents again */
SELECT * FROM my_gtt_table; /* rows are deleted */
--
select * from dba_objects where object_name = 'MY_GTT_TABLE';
--
