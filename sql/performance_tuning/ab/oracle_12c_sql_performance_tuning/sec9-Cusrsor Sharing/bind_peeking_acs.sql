-- Demostrationg Bind variable
-- Preparation and Setup
-- V$SQLAREA:: Holds the information of SQL Parent Cursors.
-- V$SQL:: Holds the information of Child cursors.
-- V$SQL_PLAN:: Holds the information of SQL Plans.
--
COL BIND_AWARE FORMAT a10
COL SQL_TEXT FORMAT a22
COL CHILD# FORMAT 99999
COL EXEC FORMAT 9999
COL BUFF_GETS FORMAT 999999999
COL BIND_SENS FORMAT a9
COL SHARABLE FORMAT a9
SELECT 
	CHILD_NUMBER AS CHILD#, 
	EXECUTIONS AS EXEC, 
	BUFFER_GETS AS BUFF_GETS,
	IS_BIND_SENSITIVE AS BIND_SENS,
	IS_BIND_AWARE AS BIND_AWARE, 
	IS_SHAREABLE AS SHARABLE
FROM 
	V$SQL
WHERE SQL_ID='&v_sql_id'
ORDER BY CHILD_NUMBER;
--
--Executing the same SQL query with same literal 
SELECT /* my query */ TO_CHAR(SUM(ORDER_TOTAL),'999,999,999') TOTAL FROM
SOE.ORDERS WHERE TO_CHAR(ORDER_DATE,'MM-RRRR') ='01-2010';
SELECT /* my query */ TO_CHAR(SUM(ORDER_TOTAL),'999,999,999') TOTAL FROM
SOE.ORDERS WHERE TO_CHAR(ORDER_DATE,'MM-RRRR') ='02-2010';
SELECT /* my query */ TO_CHAR(SUM(ORDER_TOTAL),'999,999,999') TOTAL FROM
SOE.ORDERS WHERE TO_CHAR(ORDER_DATE,'MM-RRRR') ='03-2010';
--
--Retrieve the parent cursor of the SQL from SQLAREA
--
COL SQL_TEXT FORMAT a30
SELECT 
	SQL_TEXT, 
	SQL_ID, 
	VERSION_COUNT, 
	HASH_VALUE
FROM 
	V$SQLAREA
WHERE SQL_TEXT LIKE '%my query%' AND SQL_TEXT NOT LIKE '%SQL_TEXT%';
--
-- Three SQL statements have created three separate SQL IDs and HASH Value. 
-- This is because literals instead of bind variables have been used.
--
SQL_TEXT                       SQL_ID        VERSION_COUNT HASH_VALUE
------------------------------ ------------- ------------- ----------
SELECT /* my query */ TO_CHAR( 2pw9k1mdrjujd             1 3682134573
SUM(ORDER_TOTAL),'999,999,999'
) TOTAL FROM SOE.ORDERS WHERE
TO_CHAR(ORDER_DATE,'MM-RRRR')
=:month_year

SELECT /* my query */ TO_CHAR( ga4a19st1yp20             1  840913984
SUM(ORDER_TOTAL),'999,999,999'
) TOTAL FROM SOE.ORDERS WHERE
TO_CHAR(ORDER_DATE,'MM-RRRR')
='03-2010'

SELECT /* my query */ TO_CHAR( 0v50cj9m5uw8v             1 1717399835
SUM(ORDER_TOTAL),'999,999,999'
) TOTAL FROM SOE.ORDERS WHERE
TO_CHAR(ORDER_DATE,'MM-RRRR')
='02-2010'

SELECT /* my query */ TO_CHAR( 24yhkypdqvfsd             1 1533917965
SUM(ORDER_TOTAL),'999,999,999'
) TOTAL FROM SOE.ORDERS WHERE
TO_CHAR(ORDER_DATE,'MM-RRRR')
='01-2010'
--
--Retrieve SQL Plan for the SQL Statements
--
col PRNT_STMT_HASH_VALUE format 99999999999
col OPERATION format a20
SELECT
	HASH_VALUE AS PRNT_STMT_HASH_VALUE,
	SQL_ID,
	PLAN_HASH_VALUE,
	CHILD_NUMBER,
	OPERATION
FROM 
	V$SQL_PLAN
WHERE SQL_ID IN ('ga4a19st1yp20', '2pw9k1mdrjujd', '0v50cj9m5uw8v', '24yhkypdqvfsd')
ORDER BY HASH_VALUE;
--
-- Though the SQL ID is different, Optimizer is using the same Plan (same Plan Hash Value) - which could lead to 
-- sub-optimal performance. The Parent cursor value is different.
--
PRNT_STMT_HASH_VALUE SQL_ID        PLAN_HASH_VALUE CHILD_NUMBER OPERATION
-------------------- ------------- --------------- ------------ --------------------
           840913984 ga4a19st1yp20       630573765            0 TABLE ACCESS
           840913984 ga4a19st1yp20       630573765            0 SORT
           840913984 ga4a19st1yp20       630573765            0 SELECT STATEMENT
          1533917965 24yhkypdqvfsd       630573765            0 SELECT STATEMENT
          1533917965 24yhkypdqvfsd       630573765            0 SORT
          1533917965 24yhkypdqvfsd       630573765            0 TABLE ACCESS
          1717399835 0v50cj9m5uw8v       630573765            0 SELECT STATEMENT
          1717399835 0v50cj9m5uw8v       630573765            0 SORT
          1717399835 0v50cj9m5uw8v       630573765            0 TABLE ACCESS
          3682134573 2pw9k1mdrjujd       630573765            0 TABLE ACCESS
          3682134573 2pw9k1mdrjujd       630573765            0 SORT
          3682134573 2pw9k1mdrjujd       630573765            0 SELECT STATEMENT
--
ALTER SYSTEM FLUSH SHARED_POOL;
--
--Run the same SQL with Bind Variables
--
VARIABLE month_year VARCHAR2(7)
EXEC :month_year := '01-2010';
SELECT /* my query */ TO_CHAR(SUM(ORDER_TOTAL),'999,999,999') TOTAL FROM
SOE.ORDERS WHERE TO_CHAR(ORDER_DATE,'MM-RRRR') =:month_year;
EXEC :month_year := '02-2010';
SELECT /* my query */ TO_CHAR(SUM(ORDER_TOTAL),'999,999,999') TOTAL FROM
SOE.ORDERS WHERE TO_CHAR(ORDER_DATE,'MM-RRRR') =:month_year;
EXEC :month_year := '03-2010';
SELECT /* my query */ TO_CHAR(SUM(ORDER_TOTAL),'999,999,999') TOTAL FROM
SOE.ORDERS WHERE TO_CHAR(ORDER_DATE,'MM-RRRR') =:month_year;
--
--Retrieve the parent cursor of the SQL from V$SQLAREA.
--Version Count is 1 means only one Child Cursor has been reused.
--
COL SQL_TEXT FORMAT a30
SELECT 
	SQL_TEXT, 
	SQL_ID, 
	VERSION_COUNT, 
	HASH_VALUE
FROM 
	V$SQLAREA
WHERE SQL_TEXT LIKE '%my query%' AND SQL_TEXT NOT LIKE '%SQL_TEXT%';
--
SQL_TEXT                       SQL_ID        VERSION_COUNT HASH_VALUE
------------------------------ ------------- ------------- ----------
SELECT /* my query */ TO_CHAR( 2pw9k1mdrjujd             1 3682134573
SUM(ORDER_TOTAL),'999,999,999'
) TOTAL FROM SOE.ORDERS WHERE
TO_CHAR(ORDER_DATE,'MM-RRRR')
=:month_year
---
--Child cursor - same as parent cursor.
SELECT SQL_ID, CHILD_NUMBER, PLAN_HASH_VALUE
FROM V$SQL
WHERE SQL_ID='2pw9k1mdrjujd' ORDER BY CHILD_NUMBER;
--
SQL_ID        CHILD_NUMBER PLAN_HASH_VALUE
------------- ------------ ---------------
2pw9k1mdrjujd            0       630573765
--
--Retrieve the SQL Plan. There is only Parent Cursor for all the SQL Statements.
--
col PRNT_STMT_HASH_VALUE format 99999999999
col OPERATION format a20
SELECT
	HASH_VALUE AS PRNT_STMT_HASH_VALUE,
	SQL_ID,
	PLAN_HASH_VALUE,
	CHILD_NUMBER,
	OPERATION
FROM 
	V$SQL_PLAN
WHERE SQL_ID='2pw9k1mdrjujd' ORDER BY CHILD_NUMBER;
--
PRNT_STMT_HASH_VALUE SQL_ID        PLAN_HASH_VALUE CHILD_NUMBER OPERATION
-------------------- ------------- --------------- ------------ --------------------
          3682134573 2pw9k1mdrjujd       630573765            0 SELECT STATEMENT
          3682134573 2pw9k1mdrjujd       630573765            0 TABLE ACCESS
          3682134573 2pw9k1mdrjujd       630573765            0 SORT
--
-- Demonstrating the Impact of setting CURSOR_SHARING to FORCE
-- 
ALTER SYSTEM FLUSH SHARED_POOL;
--
-- set CURSOR_SHARING parameter to FORCE
ALTER SESSION SET CURSOR_SHARING=FORCE;
--
-- Run the following queries (without bind variables)
--
SELECT /* my query */ TO_CHAR(SUM(ORDER_TOTAL),'999,999,999') TOTAL FROM
SOE.ORDERS WHERE TO_CHAR(ORDER_DATE,'MM-RRRR') ='01-2010';
SELECT /* my query */ TO_CHAR(SUM(ORDER_TOTAL),'999,999,999') TOTAL FROM
SOE.ORDERS WHERE TO_CHAR(ORDER_DATE,'MM-RRRR') ='02-2010';
SELECT /* my query */ TO_CHAR(SUM(ORDER_TOTAL),'999,999,999') TOTAL FROM
SOE.ORDERS WHERE TO_CHAR(ORDER_DATE,'MM-RRRR') ='03-2010';
--
--Retrieve the parent cursor of the SQL from V$SQLAREA.
--
COL SQL_TEXT FORMAT a30
SELECT 
	SQL_TEXT, 
	SQL_ID, 
	VERSION_COUNT, 
	HASH_VALUE
FROM 
	V$SQLAREA
WHERE SQL_TEXT LIKE '%my query%' AND SQL_TEXT NOT LIKE '%SQL_TEXT%';
--
--Only one SQL ID has been created and Optimizer has replaced the literals with a system generated Bind Variable.
--
SQL_TEXT                       SQL_ID        VERSION_COUNT HASH_VALUE
------------------------------ ------------- ------------- ----------
SELECT /* my query */ TO_CHAR( g547kssxraxn0             1  997553792
SUM(ORDER_TOTAL),:"SYS_B_0") T
OTAL FROM SOE.ORDERS WHERE TO_
CHAR(ORDER_DATE,:"SYS_B_1") =:
"SYS_B_2"
--
-- Demonstrating Adaptive Cursor Sharing Lifecycle
-- Adaptive Cursor Sharing or ACS is a mechanism that makes Optimizer  
-- create different execution plans for the bind variable-based queries 
-- depending on the bind variable value. 
--
-- Setup
DROP TABLE SOE.CUSTOMERS2;
--
-- the value 'd' is of high cardinality (returns high number of rows) while rest of the values are of low cardinality. 
CREATE TABLE SOE.CUSTOMERS2 AS SELECT * FROM SOE.CUSTOMERS WHERE NLS_LANGUAGE IN ('d','XD','PH','LY','SQ');
--
ALTER TABLE SOE.CUSTOMERS2 ADD PRIMARY KEY (CUSTOMER_ID);
--
CREATE INDEX SOE.CUSTOMERS2_NLSL_IX ON SOE.CUSTOMERS2(NLS_LANGUAGE) NOLOGGING;
--
EXEC DBMS_STATS.GATHER_INDEX_STATS('SOE','CUSTOMERS2_NLSL_IX');
--
-- Create Histogram on NLS_LANGUAGE
--
exec DBMS_STATS.GATHER_TABLE_STATS ( OWNNAME => 'SOE', TABNAME => 'CUSTOMERS2', METHOD_OPT => 'FOR COLUMNS NLS_LANGUAGE');
--
ALTER SYSTEM FLUSH SHARED_POOL;
--
-- Execute the following query with a low cardinality NLS_LANGUAGE value (SQ).
--
VARIABLE V_LANG VARCHAR2(4)
exec :V_LANG := 'SQ';
SELECT COUNT(*) FROM SOE.CUSTOMERS2 WHERE NLS_LANGUAGE = :V_LANG;
--
  COUNT(*)
----------
        16
--
--Display the execution plan
--
SET LINESIZE 180
SELECT * FROM TABLE(DBMS_XPLAN.DISPLAY_CURSOR);
--
SQL_ID  4fdczvbsxbawj, child number 0
-------------------------------------
SELECT COUNT(*) FROM SOE.CUSTOMERS2 WHERE NLS_LANGUAGE = :V_LANG

Plan hash value: 1786546252

----------------------------------------------------------------------------------------
| Id  | Operation         | Name               | Rows  | Bytes | Cost (%CPU)| Time     |
----------------------------------------------------------------------------------------
|   0 | SELECT STATEMENT  |                    |       |       |     1 (100)|          |
|   1 |  SORT AGGREGATE   |                    |     1 |     3 |            |          |
|*  2 |   INDEX RANGE SCAN| CUSTOMERS2_NLSL_IX |    16 |    48 |     1   (0)| 00:00:01 |
----------------------------------------------------------------------------------------
--
define v_sql_id = '4fdczvbsxbawj'
--
COL BIND_AWARE FORMAT a10
COL SQL_TEXT FORMAT a22
COL CHILD# FORMAT 99999
COL EXEC FORMAT 9999
COL BUFF_GETS FORMAT 999999999
COL BIND_SENS FORMAT a9
COL SHARABLE FORMAT a9
SELECT 
	CHILD_NUMBER AS CHILD#, 
	EXECUTIONS AS EXEC, 
	BUFFER_GETS AS BUFF_GETS,
	IS_BIND_SENSITIVE AS BIND_SENS,
	IS_BIND_AWARE AS BIND_AWARE, 
	IS_SHAREABLE AS SHARABLE
FROM 
	V$SQL
WHERE SQL_ID='&v_sql_id'
ORDER BY CHILD_NUMBER;
--
-- The BIND_SENSITIVE indicator is turned on which means Optimizer identifies that the SQL has used a bind variable.
-- Optimizer has derived and saved the cardinality of the value 'SQ'.
--
CHILD#  EXEC  BUFF_GETS BIND_SENS BIND_AWARE SHARABLE
------ ----- ---------- --------- ---------- ---------
     0     1        583 Y         N          Y
--
-- Execute the same query with different bind variable value - d
--
exec :V_LANG := 'd';
SELECT COUNT(*) FROM SOE.CUSTOMERS2 WHERE NLS_LANGUAGE = :V_LANG;
--
 COUNT(*)
----------
      6461
--
SELECT * FROM TABLE(DBMS_XPLAN.DISPLAY_CURSOR);
--
-- Note that the Optimizer is still using INDEX RANGE SCAN, even though cardinality is quite high, instead of TABLE FULL ACCESS.
-- Optimizer has derived and saved the cardinality of the value 'd'.
--
SQL_ID  4fdczvbsxbawj, child number 0
-------------------------------------
SELECT COUNT(*) FROM SOE.CUSTOMERS2 WHERE NLS_LANGUAGE = :V_LANG

Plan hash value: 1786546252
----------------------------------------------------------------------------------------
| Id  | Operation         | Name               | Rows  | Bytes | Cost (%CPU)| Time     |
----------------------------------------------------------------------------------------
|   0 | SELECT STATEMENT  |                    |       |       |     1 (100)|          |
|   1 |  SORT AGGREGATE   |                    |     1 |     3 |            |          |
|*  2 |   INDEX RANGE SCAN| CUSTOMERS2_NLSL_IX |    16 |    48 |     1   (0)| 00:00:01 |
----------------------------------------------------------------------------------------
--
define v_sql_id = '4fdczvbsxbawj'
--
COL BIND_AWARE FORMAT a10
COL SQL_TEXT FORMAT a22
COL CHILD# FORMAT 99999
COL EXEC FORMAT 9999
COL BUFF_GETS FORMAT 999999999
COL BIND_SENS FORMAT a9
COL SHARABLE FORMAT a9
SELECT 
	CHILD_NUMBER AS CHILD#, 
	EXECUTIONS AS EXEC, 
	BUFFER_GETS AS BUFF_GETS,
	IS_BIND_SENSITIVE AS BIND_SENS,
	IS_BIND_AWARE AS BIND_AWARE, 
	IS_SHAREABLE AS SHARABLE
FROM 
	V$SQL
WHERE SQL_ID='&v_sql_id'
ORDER BY CHILD_NUMBER;
--
-- Observe the EXEC = 2. It means the Child cursor is executed two times. The same plan has been used. 
-- Also note that BUFFER_GETS is 596, which quite high. BIND_AWARE indicator is still unchanged.
-- Optimizer has soft parsed the statement and saves the execution statistics such as cardinality estimate.
--
CHILD#  EXEC  BUFF_GETS BIND_SENS BIND_AWARE SHARABLE
------ ----- ---------- --------- ---------- ---------
     0     2        596 Y         N          Y
--
-- Execute the same query with same value - NLS_LANGUAGE = 'd'
--
SELECT COUNT(*) FROM SOE.CUSTOMERS2 WHERE NLS_LANGUAGE = :V_LANG;
--
SELECT * FROM TABLE(DBMS_XPLAN.DISPLAY_CURSOR);
--
-- Notice that that PLAN_HASH_VALUE has changed. A new plan has been generated because Optimizer has created a new plan 
-- with access path INDEX FAST FULL SCAN which has lower cost than the previsou one.
--
SQL_ID  4fdczvbsxbawj, child number 1
-------------------------------------
SELECT COUNT(*) FROM SOE.CUSTOMERS2 WHERE NLS_LANGUAGE = :V_LANG

Plan hash value: 486287562

--------------------------------------------------------------------------------------------
| Id  | Operation             | Name               | Rows  | Bytes | Cost (%CPU)| Time     |
--------------------------------------------------------------------------------------------
|   0 | SELECT STATEMENT      |                    |       |       |     5 (100)|          |
|   1 |  SORT AGGREGATE       |                    |     1 |     3 |            |          |
|*  2 |   INDEX FAST FULL SCAN| CUSTOMERS2_NLSL_IX |  6461 | 19383 |     5   (0)| 00:00:01 |
--------------------------------------------------------------------------------------------
--
define v_sql_id = '4fdczvbsxbawj'
--
COL BIND_AWARE FORMAT a10
COL SQL_TEXT FORMAT a22
COL CHILD# FORMAT 99999
COL EXEC FORMAT 9999
COL BUFF_GETS FORMAT 999999999
COL BIND_SENS FORMAT a9
COL SHARABLE FORMAT a9
SELECT 
	CHILD_NUMBER AS CHILD#, 
	EXECUTIONS AS EXEC, 
	BUFFER_GETS AS BUFF_GETS,
	IS_BIND_SENSITIVE AS BIND_SENS,
	IS_BIND_AWARE AS BIND_AWARE, 
	IS_SHAREABLE AS SHARABLE
FROM 
	V$SQL
WHERE SQL_ID='&v_sql_id'
ORDER BY CHILD_NUMBER;
--
-- A new child cursor has been created (CHILD_NUMBER 1) and its BIND_AWARE indicator is set to Y which means 
-- Optimizer has hard parsed the statement following the cardinality mismatch and created a new plan.
-- The fisrt cursor has now been marked as non-Sharable and not Bind Aware which means it will not be used for this value.
-- Note that the BUFFER_GETS has also reduced to a great extent.
--
CHILD#  EXEC  BUFF_GETS BIND_SENS BIND_AWARE SHARABLE
------ ----- ---------- --------- ---------- ---------
     0     2        596 Y         N          N
     1     1         21 Y         Y          Y
--
-- Execute the same query with a low cardinality value - 'PH'
--
exec :V_LANG := 'PH';
SELECT COUNT(*) FROM SOE.CUSTOMERS2 WHERE NLS_LANGUAGE = :V_LANG;
SELECT * FROM TABLE(DBMS_XPLAN.DISPLAY_CURSOR);
--
-- Note that the Optimizer has created a new Child (Child# 2) with a new plan.
-- 
SQL_ID  4fdczvbsxbawj, child number 2
-------------------------------------
SELECT COUNT(*) FROM SOE.CUSTOMERS2 WHERE NLS_LANGUAGE = :V_LANG

Plan hash value: 1786546252

----------------------------------------------------------------------------------------
| Id  | Operation         | Name               | Rows  | Bytes | Cost (%CPU)| Time     |
----------------------------------------------------------------------------------------
|   0 | SELECT STATEMENT  |                    |       |       |     1 (100)|          |
|   1 |  SORT AGGREGATE   |                    |     1 |     3 |            |          |
|*  2 |   INDEX RANGE SCAN| CUSTOMERS2_NLSL_IX |    45 |   135 |     1   (0)| 00:00:01 |
----------------------------------------------------------------------------------------
--
define v_sql_id = '4fdczvbsxbawj'
--
COL BIND_AWARE FORMAT a10
COL SQL_TEXT FORMAT a22
COL CHILD# FORMAT 99999
COL EXEC FORMAT 9999
COL BUFF_GETS FORMAT 999999999
COL BIND_SENS FORMAT a9
COL SHARABLE FORMAT a9
SELECT 
	CHILD_NUMBER AS CHILD#, 
	EXECUTIONS AS EXEC, 
	BUFFER_GETS AS BUFF_GETS,
	IS_BIND_SENSITIVE AS BIND_SENS,
	IS_BIND_AWARE AS BIND_AWARE, 
	IS_SHAREABLE AS SHARABLE
FROM 
	V$SQL
WHERE SQL_ID='&v_sql_id'
ORDER BY CHILD_NUMBER;
--
-- We now have three child cursors of which two are SHARABLE and BIND_AWARE. All are BIND_SENSITIVE. 
-- The new Child#2 is created for a low cardinality value 'PH', just as 'SQ'. 
--
CHILD#  EXEC  BUFF_GETS BIND_SENS BIND_AWARE SHARABLE
------ ----- ---------- --------- ---------- ---------
     0     2        596 Y         N          N
     1     2         39 Y         Y          Y
     2     1         51 Y         Y          Y
--
exec :V_LANG := 'LY';
SELECT COUNT(*) FROM SOE.CUSTOMERS2 WHERE NLS_LANGUAGE = :V_LANG;
--
  COUNT(*)
----------
        44
--        
SELECT * FROM TABLE(DBMS_XPLAN.DISPLAY_CURSOR);
--
SQL_ID  4fdczvbsxbawj, child number 2
-------------------------------------
SELECT COUNT(*) FROM SOE.CUSTOMERS2 WHERE NLS_LANGUAGE = :V_LANG

Plan hash value: 1786546252

----------------------------------------------------------------------------------------
| Id  | Operation         | Name               | Rows  | Bytes | Cost (%CPU)| Time     |
----------------------------------------------------------------------------------------
|   0 | SELECT STATEMENT  |                    |       |       |     1 (100)|          |
|   1 |  SORT AGGREGATE   |                    |     1 |     3 |            |          |
|*  2 |   INDEX RANGE SCAN| CUSTOMERS2_NLSL_IX |    45 |   135 |     1   (0)| 00:00:01 |
----------------------------------------------------------------------------------------
--
define v_sql_id = '4fdczvbsxbawj'
--
COL BIND_AWARE FORMAT a10
COL SQL_TEXT FORMAT a22
COL CHILD# FORMAT 99999
COL EXEC FORMAT 9999
COL BUFF_GETS FORMAT 999999999
COL BIND_SENS FORMAT a9
COL SHARABLE FORMAT a9
SELECT 
	CHILD_NUMBER AS CHILD#, 
	EXECUTIONS AS EXEC, 
	BUFFER_GETS AS BUFF_GETS,
	IS_BIND_SENSITIVE AS BIND_SENS,
	IS_BIND_AWARE AS BIND_AWARE, 
	IS_SHAREABLE AS SHARABLE
FROM 
	V$SQL
WHERE SQL_ID='&v_sql_id'
ORDER BY CHILD_NUMBER;
--
-- This time no new Child cursor is created as the Optimizer reuse the Child# 2 cursor.
-- 
CHILD#  EXEC  BUFF_GETS BIND_SENS BIND_AWARE SHARABLE
------ ----- ---------- --------- ---------- ---------
     0     2        596 Y         N          N
     1     2         39 Y         Y          Y
     2     2         53 Y         Y          Y
--
-- Now execute the first query again (NLS_LANGUAGE = 'SQ')
-- 
VARIABLE V_LANG VARCHAR2(4)
exec :V_LANG := 'SQ';
SELECT COUNT(*) FROM SOE.CUSTOMERS2 WHERE NLS_LANGUAGE = :V_LANG;
--
SELECT * FROM TABLE(DBMS_XPLAN.DISPLAY_CURSOR);
--
SQL_ID  4fdczvbsxbawj, child number 3
-------------------------------------
SELECT COUNT(*) FROM SOE.CUSTOMERS2 WHERE NLS_LANGUAGE = :V_LANG

Plan hash value: 1786546252

----------------------------------------------------------------------------------------
| Id  | Operation         | Name               | Rows  | Bytes | Cost (%CPU)| Time     |
----------------------------------------------------------------------------------------
|   0 | SELECT STATEMENT  |                    |       |       |     1 (100)|          |
|   1 |  SORT AGGREGATE   |                    |     1 |     3 |            |          |
|*  2 |   INDEX RANGE SCAN| CUSTOMERS2_NLSL_IX |    16 |    48 |     1   (0)| 00:00:01 |
----------------------------------------------------------------------------------------
--
define v_sql_id = '4fdczvbsxbawj'
--
COL BIND_AWARE FORMAT a10
COL SQL_TEXT FORMAT a22
COL CHILD# FORMAT 99999
COL EXEC FORMAT 9999
COL BUFF_GETS FORMAT 999999999
COL BIND_SENS FORMAT a9
COL SHARABLE FORMAT a9
SELECT 
	CHILD_NUMBER AS CHILD#, 
	EXECUTIONS AS EXEC, 
	BUFFER_GETS AS BUFF_GETS,
	IS_BIND_SENSITIVE AS BIND_SENS,
	IS_BIND_AWARE AS BIND_AWARE, 
	IS_SHAREABLE AS SHARABLE
FROM 
	V$SQL
WHERE SQL_ID='&v_sql_id'
ORDER BY CHILD_NUMBER;
--
-- Observe that CHILD#0 and CHILD#2 are now marked Non-Sharable (so they will not be used to execute the SQL any more) and 
-- a new CHILD#3 has been created with INDEX RANG SCAN access methid.
-- 
CHILD#  EXEC  BUFF_GETS BIND_SENS BIND_AWARE SHARABLE
------ ----- ---------- --------- ---------- ---------
     0     2        596 Y         N          N
     1     2         39 Y         Y          Y
     2     2         53 Y         Y          N
     3     1          2 Y         Y          Y
--
