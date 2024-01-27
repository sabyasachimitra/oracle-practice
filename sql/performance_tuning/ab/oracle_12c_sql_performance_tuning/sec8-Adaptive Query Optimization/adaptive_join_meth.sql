--setup
DROP TABLE tab2 PURGE;
DROP SEQUENCE tab2_seq;
DROP TABLE tab1 PURGE;
DROP SEQUENCE tab1_seq;
--
CREATE TABLE tab1 (
  id    NUMBER,
  code  VARCHAR2(5),
  data  NUMBER(5),
  CONSTRAINT tab1_pk PRIMARY KEY (id)
);
--
CREATE INDEX tab1_code ON tab1(code);

CREATE SEQUENCE tab1_seq;

INSERT INTO tab1 VALUES (tab1_seq.nextval, 'ONE', 1);
INSERT INTO tab1 VALUES (tab1_seq.nextval, 'TWO', 2);
INSERT INTO tab1 VALUES (tab1_seq.nextval, 'THREE', 3);
INSERT INTO tab1 VALUES (tab1_seq.nextval, 'FOUR', 4);
INSERT INTO tab1 VALUES (tab1_seq.nextval, 'FIVE', 5);
COMMIT;
--
CREATE TABLE tab2 (
  id       NUMBER,
  tab1_id  NUMBER,
  data     NUMBER(5),
  CONSTRAINT tab2_pk PRIMARY KEY (id),
  CONSTRAINT tab2_tab1_fk FOREIGN KEY (tab1_id) REFERENCES tab1(id)
);

CREATE SEQUENCE tab2_seq;

CREATE INDEX tab2_tab1_fki ON tab2(tab1_id);
--
INSERT /*+ APPEND */ INTO tab2
SELECT tab2_seq.nextval,
       TRUNC(DBMS_RANDOM.value(1,5)),
       level
FROM   dual
CONNECT BY level <= 100;
COMMIT;
--
EXEC DBMS_STATS.gather_table_stats(USER, 'TAB1');
EXEC DBMS_STATS.gather_table_stats(USER, 'TAB2');
--
--Query-1:: Showing Plain Execution Plan.
--
SELECT a.data AS tab1_data,
       b.data AS tab2_data
FROM   tab1 a
       JOIN tab2 b ON b.tab1_id = a.id
WHERE  a.code = 'ONE';
--
SET LINESIZE 200 PAGESIZE 100
SELECT * FROM TABLE(DBMS_XPLAN.display_cursor);
--
--
--Note section shows it's an adaptive plan
--
SQL_ID  4r3harjun4dvz, child number 0
-------------------------------------
SELECT a.data AS tab1_data,        b.data AS tab2_data FROM   tab1 a
    JOIN tab2 b ON b.tab1_id = a.id WHERE  a.code = 'ONE'

Plan hash value: 2996652912

----------------------------------------------------------------------------------------------
| Id  | Operation                    | Name          | Rows  | Bytes | Cost (%CPU)| Time     |
----------------------------------------------------------------------------------------------
|   0 | SELECT STATEMENT             |               |       |       |     4 (100)|          |
|   1 |  NESTED LOOPS                |               |    25 |   425 |     4   (0)| 00:00:01 |
|   2 |   NESTED LOOPS               |               |    25 |   425 |     4   (0)| 00:00:01 |
|*  3 |    TABLE ACCESS FULL         | TAB1          |     1 |    11 |     3   (0)| 00:00:01 |
|*  4 |    INDEX RANGE SCAN          | TAB2_TAB1_FKI |    25 |       |     0   (0)|          |
|   5 |   TABLE ACCESS BY INDEX ROWID| TAB2          |    25 |   150 |     1   (0)| 00:00:01 |
----------------------------------------------------------------------------------------------

Predicate Information (identified by operation id):
---------------------------------------------------

   3 - filter("A"."CODE"='ONE')
   4 - access("B"."TAB1_ID"="A"."ID")

Note
-----
   - this is an adaptive plan
--
--Query-2:: Showing Adaptive Execution Plan.
--
SELECT a.data AS tab1_data,
       b.data AS tab2_data
FROM   tab1 a
       JOIN tab2 b ON b.tab1_id = a.id
WHERE  a.code = 'ONE';

SET LINESIZE 200 PAGESIZE 100
--
--note the adaptive option in format. 
SELECT * FROM TABLE(DBMS_XPLAN.display_cursor(format => 'adaptive'));
--
SQL_ID  4r3harjun4dvz, child number 0
-------------------------------------
SELECT a.data AS tab1_data,        b.data AS tab2_data FROM   tab1 a
    JOIN tab2 b ON b.tab1_id = a.id WHERE  a.code = 'ONE'

Plan hash value: 2996652912
--
--The adaptive plan has two subplans - one with HASH JOIN and the other with NESTED LOOP.
--HASH JOIN method is marked inactive. NESTED LOOP is marked active.
-------------------------------------------------------------------------------------------------
|   Id  | Operation                     | Name          | Rows  | Bytes | Cost (%CPU)| Time     |
-------------------------------------------------------------------------------------------------
|     0 | SELECT STATEMENT              |               |       |       |     4 (100)|          |
|- *  1 |  HASH JOIN                    |               |    25 |   425 |     4   (0)| 00:00:01 |
|     2 |   NESTED LOOPS                |               |    25 |   425 |     4   (0)| 00:00:01 |
|     3 |    NESTED LOOPS               |               |    25 |   425 |     4   (0)| 00:00:01 |
|-    4 |     STATISTICS COLLECTOR      |               |       |       |            |          |
|  *  5 |      TABLE ACCESS FULL        | TAB1          |     1 |    11 |     3   (0)| 00:00:01 |
|  *  6 |     INDEX RANGE SCAN          | TAB2_TAB1_FKI |    25 |       |     0   (0)|          |
|     7 |    TABLE ACCESS BY INDEX ROWID| TAB2          |    25 |   150 |     1   (0)| 00:00:01 |
|-    8 |   TABLE ACCESS FULL           | TAB2          |    25 |   150 |     1   (0)| 00:00:01 |
-------------------------------------------------------------------------------------------------

Predicate Information (identified by operation id):
---------------------------------------------------

   1 - access("B"."TAB1_ID"="A"."ID")
   5 - filter("A"."CODE"='ONE')
   6 - access("B"."TAB1_ID"="A"."ID")

Note
-----
   - this is an adaptive plan (rows marked '-' are inactive)
--
--Query-3:: Adaptive Execution Plan with Statistics (E-Rows and A-Rows).
--
SELECT /*+ GATHER_PLAN_STATISTICS */
       a.data AS tab1_data,
       b.data AS tab2_data
FROM   tab1 a
       JOIN tab2 b ON b.tab1_id = a.id
WHERE  a.code = 'ONE';

SET LINESIZE 200 PAGESIZE 100
SELECT * FROM TABLE(DBMS_XPLAN.display_cursor(format => 'adaptive allstats last'));
--
SQL_ID  1km5kczcgr0fr, child number 0
-------------------------------------
SELECT /*+ GATHER_PLAN_STATISTICS */        a.data AS tab1_data,
b.data AS tab2_data FROM   tab1 a        JOIN tab2 b ON b.tab1_id =
a.id WHERE  a.code = 'ONE'

Plan hash value: 2996652912

-----------------------------------------------------------------------------------------------------------
|   Id  | Operation                     | Name          | Starts | E-Rows | A-Rows |   A-Time   | Buffers |
-----------------------------------------------------------------------------------------------------------
|     0 | SELECT STATEMENT              |               |      1 |        |     25 |00:00:00.01 |      12 |
|- *  1 |  HASH JOIN                    |               |      1 |     25 |     25 |00:00:00.01 |      12 |
|     2 |   NESTED LOOPS                |               |      1 |     25 |     25 |00:00:00.01 |      12 |
|     3 |    NESTED LOOPS               |               |      1 |     25 |     25 |00:00:00.01 |       9 |
|-    4 |     STATISTICS COLLECTOR      |               |      1 |        |      1 |00:00:00.01 |       6 |
|  *  5 |      TABLE ACCESS FULL        | TAB1          |      1 |      1 |      1 |00:00:00.01 |       6 |
|  *  6 |     INDEX RANGE SCAN          | TAB2_TAB1_FKI |      1 |     25 |     25 |00:00:00.01 |       3 |
|     7 |    TABLE ACCESS BY INDEX ROWID| TAB2          |     25 |     25 |     25 |00:00:00.01 |       3 |
|-    8 |   TABLE ACCESS FULL           | TAB2          |      0 |     25 |      0 |00:00:00.01 |       0 |
-----------------------------------------------------------------------------------------------------------

Predicate Information (identified by operation id):
---------------------------------------------------

   1 - access("B"."TAB1_ID"="A"."ID")
   5 - filter("A"."CODE"='ONE')
   6 - access("B"."TAB1_ID"="A"."ID")

Note
-----
   - this is an adaptive plan (rows marked '-' are inactive)
--
--Insert new data and DON'T update the statistics
--
INSERT /*+ APPEND */ INTO tab1
SELECT tab1_seq.nextval,
       'ONE',
       level
FROM   dual
CONNECT BY level <= 10000;
COMMIT;
--
INSERT /*+ APPEND */ INTO tab2
SELECT tab2_seq.nextval,
       TRUNC(DBMS_RANDOM.value(11,10005)),
       level
FROM   dual
CONNECT BY level <= 10000;
COMMIT;
--
--Query-4:: 
--
SELECT /*+ GATHER_PLAN_STATISTICS */
       a.data AS tab1_data,
       b.data AS tab2_data
FROM   tab1 a
       JOIN tab2 b ON b.tab1_id = a.id
WHERE  a.code = 'ONE';
--
SET LINESIZE 200 PAGESIZE 100
SELECT * FROM TABLE(DBMS_XPLAN.display_cursor(format => 'allstats last adaptive'));
--
--------------------------------------------------------------------------------------------------------------------------------------
|   Id  | Operation                     | Name          | Starts | E-Rows | A-Rows |   A-Time   | Buffers |  OMem |  1Mem | Used-Mem |
--------------------------------------------------------------------------------------------------------------------------------------
|     0 | SELECT STATEMENT              |               |      1 |        |  10025 |00:00:00.02 |     728 |       |       |          |
|  *  1 |  HASH JOIN                    |               |      1 |     25 |  10025 |00:00:00.02 |     728 |  2011K|  2011K| 2169K (0)|
|-    2 |   NESTED LOOPS                |               |      1 |     25 |  10001 |00:00:00.01 |      31 |       |       |          |
|-    3 |    NESTED LOOPS               |               |      1 |     25 |  10001 |00:00:00.01 |      31 |       |       |          |
|-    4 |     STATISTICS COLLECTOR      |               |      1 |        |  10001 |00:00:00.01 |      31 |       |       |          |
|  *  5 |      TABLE ACCESS FULL        | TAB1          |      1 |      1 |  10001 |00:00:00.01 |      31 |       |       |          |
|- *  6 |     INDEX RANGE SCAN          | TAB2_TAB1_FKI |      0 |     25 |      0 |00:00:00.01 |       0 |       |       |          |
|-    7 |    TABLE ACCESS BY INDEX ROWID| TAB2          |      0 |     25 |      0 |00:00:00.01 |       0 |       |       |          |
|     8 |   TABLE ACCESS FULL           | TAB2          |      1 |     25 |  10100 |00:00:00.01 |     697 |       |       |          |
--------------------------------------------------------------------------------------------------------------------------------------
--
col IS_RESOLVED_ADAPTIVE_PLAN format a25
col IS_REOPTIMIZABLE format a16
SELECT 
	SQL_ID, 
	CHILD_NUMBER, 
	PLAN_HASH_VALUE, 
	IS_RESOLVED_ADAPTIVE_PLAN IS_RESOLVED_ADAPTIVE_PLAN,
	IS_REOPTIMIZABLE IS_REOPTIMIZABLE
FROM 
	V$SQL 
WHERE SQL_ID='1km5kczcgr0fr' ORDER BY SQL_ID, CHILD_NUMBER;
--
SQL_ID        CHILD_NUMBER PLAN_HASH_VALUE IS_RESOLVED_ADAPTIVE_PLAN IS_REOPTIMIZABLE
------------- ------------ --------------- ------------------------- ----------------
1km5kczcgr0fr            0        65130617 Y                         N
--



