-- Demonstrating SQL Plan Directives
-- Setup
-- display child cursors of specific SQL ID
col IS_REOPTIMIZABLE format a16
SELECT SQL_ID, CHILD_NUMBER, PLAN_HASH_VALUE, IS_REOPTIMIZABLE
FROM V$SQL
WHERE SQL_ID='&v_sql_id' ORDER BY CHILD_NUMBER;
--
--display SQL Plan Directives
EXEC DBMS_SPD.FLUSH_SQL_PLAN_DIRECTIVE;
--
SELECT 
	'DIR_ID: ' || TO_CHAR(d.DIRECTIVE_ID) ||chr(10) ||
	'Type: ' || d.TYPE||chr(10) ||
	'State: ' || d.STATE || chr(10) ||
	'Object Name: '|| o.OBJECT_NAME ||chr(10) ||
	'Object Type: ' || o.OBJECT_TYPE||chr(10) ||
	'Column: ' || o.SUBOBJECT_NAME ||chr(10) ||
	'Reason: ' || d.REASON ||chr(10) ||
	'Last Used: ' || d.LAST_USED ||chr(10) ||
	'Num Rows: ' || o.NUM_ROWS ||chr(10) ||
	'Notes: ' || d.Notes ||chr(10) DIRECTIVE
FROM 
	DBA_SQL_PLAN_DIRECTIVES d, 
	DBA_SQL_PLAN_DIR_OBJECTS o
WHERE 
	d.DIRECTIVE_ID=o.DIRECTIVE_ID AND o.OWNER ='SOE' and o.OBJECT_NAME = 'CUSTOMERS2'
ORDER BY d.DIRECTIVE_ID,d.TYPE;
--
-- Setting OPTIMIZER_ADAPTIVE_STATISTICS parameter
--
-- OPTIMIZER_ADAPTIVE_STATISTICS does not control Dynamic Statistics feature. It controls the following features:
-- SQL Plan Directives, Statistics feedback for joins and Adaptive dynamic sampling for parallel execution
-- OPTIMIZER_ADAPTIVE_STATISTICS enable the use of SQL Plan Directives but it does not control their creation.
-- Even if OPTIMIZER_ADAPTIVE_STATISTICS is FALSE, SQL Plan Directives are created by the Optimizer.
--
show parameter OPTIMIZER_ADAPTIVE_STATISTICS
--
NAME                                 TYPE        VALUE
------------------------------------ ----------- ------------------------------
optimizer_adaptive_statistics        boolean     FALSE
--
ALTER SESSION SET OPTIMIZER_ADAPTIVE_STATISTICS=TRUE;
--
-- Drop Table if it exists.
DROP TABLE SOE.CUSTOMERS2 PURGE;
-- Create table using CTAS so that Statistics are automatically gathered.
CREATE TABLE SOE.CUSTOMERS2 AS SELECT * FROM SOE.CUSTOMERS;
--
-- Flush Shared Pool: This will flush the queries in Shared Pool
ALTER SYSTEM FLUSH SHARED_POOL;
--
-- Demonstrating How the Optimizer Uses SQL Plan Directives
--
SET LINESIZE 180
-- Run the following Query
SELECT /*+ GATHER_PLAN_STATISTICS */ * FROM SOE.CUSTOMERS2 WHERE NLS_LANGUAGE = 'us' AND NLS_TERRITORY='AMERICA';
--
--And check its exeution plan
SELECT * FROM table (DBMS_XPLAN.DISPLAY_CURSOR(null,null,'ALLSTATS LAST'));
--
-- We can see the huge cardinality mismatch - 1 vs 3256.
SQL_ID  dvzpsg6f05g16, child number 0
-------------------------------------
SELECT /*+ GATHER_PLAN_STATISTICS */ * FROM SOE.CUSTOMERS2 WHERE NLS_LANGUAGE = 'us' AND NLS_TERRITORY='AMERICA'

Plan hash value: 1141662121

---------------------------------------------------------------------------------------------------
| Id  | Operation         | Name       | Starts | E-Rows | A-Rows |   A-Time   | Buffers | Reads  |
---------------------------------------------------------------------------------------------------
|   0 | SELECT STATEMENT  |            |      1 |        |   3256 |00:00:00.02 |     954 |    733 |
|*  1 |  TABLE ACCESS FULL| CUSTOMERS2 |      1 |      1 |   3256 |00:00:00.02 |     954 |    733 |
---------------------------------------------------------------------------------------------------

Predicate Information (identified by operation id):
---------------------------------------------------

   1 - filter(("NLS_LANGUAGE"='us' AND "NLS_TERRITORY"='AMERICA'))
--
define v_sql_id = 'dvzpsg6f05g16'
--
--Display Child cursor of the SQL ID.
col IS_REOPTIMIZABLE format a16
SELECT SQL_ID, CHILD_NUMBER, PLAN_HASH_VALUE, IS_REOPTIMIZABLE
FROM V$SQL
WHERE SQL_ID='&v_sql_id' ORDER BY CHILD_NUMBER;
--
-- The plan is still optimized so Optimizer marked IS_REOPTIMIZABLE to Y.
SQL_ID        CHILD_NUMBER PLAN_HASH_VALUE IS_REOPTIMIZABLE
------------- ------------ --------------- ----------------
dvzpsg6f05g16            0      1141662121 Y
--
EXEC DBMS_SPD.FLUSH_SQL_PLAN_DIRECTIVE;
--
SELECT 
	'DIR_ID: ' || TO_CHAR(d.DIRECTIVE_ID) ||chr(10) ||
	'Type: ' || d.TYPE||chr(10) ||
	'State: ' || d.STATE || chr(10) ||
	'Object Name: '|| o.OBJECT_NAME ||chr(10) ||
	'Object Type: ' || o.OBJECT_TYPE||chr(10) ||
	'Column: ' || o.SUBOBJECT_NAME ||chr(10) ||
	'Reason: ' || d.REASON ||chr(10) ||
	'Last Used: ' || d.LAST_USED ||chr(10) ||
	'Num Rows: ' || o.NUM_ROWS ||chr(10) ||
	'Notes: ' || d.Notes ||chr(10) DIRECTIVE
FROM 
	DBA_SQL_PLAN_DIRECTIVES d, 
	DBA_SQL_PLAN_DIR_OBJECTS o
WHERE 
	d.DIRECTIVE_ID=o.DIRECTIVE_ID AND o.OWNER ='SOE' and o.OBJECT_NAME = 'CUSTOMERS2'
ORDER BY d.DIRECTIVE_ID,d.TYPE;
--
-- The following output shows three rows of the directive ID 16146197347752157163. One row is for the table (CUSTOMERS2)
-- (Object Type = TABLE) and the remaining two rows for the columns NLS_LANGUAGE and NLS_TERRITORY (Object Type = COLUMN)
-- LAST_USED is NULL because the directive has not yet been used.
--
DIRECTIVE
------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
DIR_ID: 16146197347752157163
Type: DYNAMIC_SAMPLING
State: USABLE
Object Name: CUSTOMERS2
Object Type: COLUMN
Column: NLS_LANGUAGE
Reason: SINGLE TABLE CARDINALITY MISESTIMATE
Last Used:
Num Rows:
Notes: <spd_note><internal_state>NEW</internal_state><redundant>NO</redundant><spd_text>{EC(SOE.CUSTOMERS2)[NLS_LANGUAGE, NLS_TERRITORY]}</spd_text></spd_note>

DIR_ID: 16146197347752157163
Type: DYNAMIC_SAMPLING
State: USABLE
Object Name: CUSTOMERS2
Object Type: TABLE
Column:
Reason: SINGLE TABLE CARDINALITY MISESTIMATE
Last Used:
Num Rows:
Notes: <spd_note><internal_state>NEW</internal_state><redundant>NO</redundant><spd_text>{EC(SOE.CUSTOMERS2)[NLS_LANGUAGE, NLS_TERRITORY]}</spd_text></spd_note>

DIR_ID: 16146197347752157163
Type: DYNAMIC_SAMPLING
State: USABLE
Object Name: CUSTOMERS2
Object Type: COLUMN
Column: NLS_TERRITORY
Reason: SINGLE TABLE CARDINALITY MISESTIMATE
Last Used:
Num Rows:
Notes: <spd_note><internal_state>NEW</internal_state><redundant>NO</redundant><spd_text>{EC(SOE.CUSTOMERS2)[NLS_LANGUAGE, NLS_TERRITORY]}</spd_text></spd_note>
--
--
-- Run the following Query again
SELECT /*+ GATHER_PLAN_STATISTICS */ * FROM SOE.CUSTOMERS2 WHERE NLS_LANGUAGE = 'us' AND NLS_TERRITORY='AMERICA';
--
SELECT * FROM table (DBMS_XPLAN.DISPLAY_CURSOR(null,null,'ALLSTATS LAST'));
--
-- The cardinality mismatch is completely resolved now but using Statistics Feedback not SQL Plan Directive.
-- The Directive is not used because the SQL has not been recompiled (hard parsed). Also note that Child cursor 1 is used.
--
PLAN_TABLE_OUTPUT
------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
SQL_ID  dvzpsg6f05g16, child number 1
-------------------------------------
SELECT /*+ GATHER_PLAN_STATISTICS */ * FROM SOE.CUSTOMERS2 WHERE
NLS_LANGUAGE = 'us' AND NLS_TERRITORY='AMERICA'

Plan hash value: 1141662121

------------------------------------------------------------------------------------------
| Id  | Operation         | Name       | Starts | E-Rows | A-Rows |   A-Time   | Buffers |
------------------------------------------------------------------------------------------
|   0 | SELECT STATEMENT  |            |      1 |        |   3256 |00:00:00.01 |     954 |
|*  1 |  TABLE ACCESS FULL| CUSTOMERS2 |      1 |   3256 |   3256 |00:00:00.01 |     954 |
------------------------------------------------------------------------------------------

Predicate Information (identified by operation id):
---------------------------------------------------

   1 - filter(("NLS_LANGUAGE"='us' AND "NLS_TERRITORY"='AMERICA'))

Note
-----
   - statistics feedback used for this statement
--
define v_sql_id = 'dvzpsg6f05g16'
--
col IS_REOPTIMIZABLE format a16
SELECT SQL_ID, CHILD_NUMBER, PLAN_HASH_VALUE, IS_REOPTIMIZABLE
FROM V$SQL
WHERE SQL_ID='&v_sql_id' ORDER BY CHILD_NUMBER;
--
--The output shows child cursor 1 is used and it is now optimized.
--
SQL_ID        CHILD_NUMBER PLAN_HASH_VALUE IS_REOPTIMIZABLE
------------- ------------ --------------- ----------------
dvzpsg6f05g16            0      1141662121 Y
dvzpsg6f05g16            1      1141662121 N
--
--Let's run the same query with a slight difference
--
SELECT /*+ GATHER_PLAN_STATISTICS */ * FROM SOE.CUSTOMERS2 WHERE NLS_LANGUAGE = 'hi' AND NLS_TERRITORY='INDIA';
--
SELECT * FROM table (DBMS_XPLAN.DISPLAY_CURSOR(null,null,'ALLSTATS LAST'));
--
-- Query Plan shows that SQL Plan Directive has been used and cardinality perfectly matched. 
-- This is because the Directive was already created. 
--
PLAN_TABLE_OUTPUT
------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
SQL_ID  aqhjc3t4gwyt8, child number 0
-------------------------------------
SELECT /*+ GATHER_PLAN_STATISTICS */ * FROM SOE.CUSTOMERS2 WHERE
NLS_LANGUAGE = 'hi' AND NLS_TERRITORY='INDIA'

Plan hash value: 1141662121

------------------------------------------------------------------------------------------
| Id  | Operation         | Name       | Starts | E-Rows | A-Rows |   A-Time   | Buffers |
------------------------------------------------------------------------------------------
|   0 | SELECT STATEMENT  |            |      1 |        |   3139 |00:00:00.01 |     945 |
|*  1 |  TABLE ACCESS FULL| CUSTOMERS2 |      1 |   3139 |   3139 |00:00:00.01 |     945 |
------------------------------------------------------------------------------------------

Predicate Information (identified by operation id):
---------------------------------------------------

   1 - filter(("NLS_LANGUAGE"='hi' AND "NLS_TERRITORY"='INDIA'))

Note
-----
   - dynamic statistics used: dynamic sampling (level=2)
   - 1 Sql Plan Directive used for this statement
--
EXEC DBMS_SPD.FLUSH_SQL_PLAN_DIRECTIVE;
--
SELECT 
	'DIR_ID: ' || TO_CHAR(d.DIRECTIVE_ID) ||chr(10) ||
	'Type: ' || d.TYPE||chr(10) ||
	'State: ' || d.STATE || chr(10) ||
	'Object Name: '|| o.OBJECT_NAME ||chr(10) ||
	'Object Type: ' || o.OBJECT_TYPE||chr(10) ||
	'Column: ' || o.SUBOBJECT_NAME ||chr(10) ||
	'Reason: ' || d.REASON ||chr(10) ||
	'Last Used: ' || d.LAST_USED ||chr(10) ||
	'Num Rows: ' || o.NUM_ROWS ||chr(10) ||
	'Notes: ' || d.Notes ||chr(10) DIRECTIVE
FROM 
	DBA_SQL_PLAN_DIRECTIVES d, 
	DBA_SQL_PLAN_DIR_OBJECTS o
WHERE 
	d.DIRECTIVE_ID=o.DIRECTIVE_ID AND o.OWNER ='SOE' and o.OBJECT_NAME = 'CUSTOMERS2'
ORDER BY d.DIRECTIVE_ID,d.TYPE;
--
-- Last Used column has been updated now since the directive was used. 
-- Also a new type of Directive called DYNAMIC_SAMPLING_RESULT has been added.
--
DIRECTIVE
------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
DIR_ID: 4112472790421109895
Type: DYNAMIC_SAMPLING_RESULT
State: USABLE
Object Name: CUSTOMERS2
Object Type: TABLE
Column:
Reason: VERIFY CARDINALITY ESTIMATE
Last Used: 15-JUL-22 02.29.36.000000000 AM
Num Rows: 45703
Notes: <spd_note><internal_state>NEW</internal_state><redundant>NO</redundant><spd_text>{(SOE.CUSTOMERS2, num_rows=45703) - (SQL_ID:7j3b6bym14fk4, T.CARD=3139[-2 -2])}</spd_text></
spd_note>

DIR_ID: 16146197347752157163
Type: DYNAMIC_SAMPLING
State: USABLE
Object Name: CUSTOMERS2
Object Type: TABLE
Column:
Reason: SINGLE TABLE CARDINALITY MISESTIMATE
Last Used: 15-JUL-22 02.24.19.000000000 AM
Num Rows:
Notes: <spd_note><internal_state>MISSING_STATS</internal_state><redundant>NO</redundant><spd_text>{EC(SOE.CUSTOMERS2)[NLS_LANGUAGE, NLS_TERRITORY]}</spd_text></spd_note>

DIR_ID: 16146197347752157163
Type: DYNAMIC_SAMPLING
State: USABLE
Object Name: CUSTOMERS2
Object Type: COLUMN
Column: NLS_LANGUAGE
Reason: SINGLE TABLE CARDINALITY MISESTIMATE
Last Used: 15-JUL-22 02.24.19.000000000 AM
Num Rows:
Notes: <spd_note><internal_state>MISSING_STATS</internal_state><redundant>NO</redundant><spd_text>{EC(SOE.CUSTOMERS2)[NLS_LANGUAGE, NLS_TERRITORY]}</spd_text></spd_note>

DIR_ID: 16146197347752157163
Type: DYNAMIC_SAMPLING
State: USABLE
Object Name: CUSTOMERS2
Object Type: COLUMN
Column: NLS_TERRITORY
Reason: SINGLE TABLE CARDINALITY MISESTIMATE
Last Used: 15-JUL-22 02.24.19.000000000 AM
Num Rows:
Notes: <spd_note><internal_state>MISSING_STATS</internal_state><redundant>NO</redundant><spd_text>{EC(SOE.CUSTOMERS2)[NLS_LANGUAGE, NLS_TERRITORY]}</spd_text></spd_note>
--
define v_sql_id = 'aqhjc3t4gwyt8'
--
col IS_REOPTIMIZABLE format a16
SELECT SQL_ID, CHILD_NUMBER, PLAN_HASH_VALUE, IS_REOPTIMIZABLE
FROM V$SQL
WHERE SQL_ID='&v_sql_id' ORDER BY CHILD_NUMBER;
--
SQL_ID        CHILD_NUMBER PLAN_HASH_VALUE IS_REOPTIMIZABLE
------------- ------------ --------------- ----------------
aqhjc3t4gwyt8            0      1141662121 N
--
-- Using the Directives in Gathering Table Statistics
-- We will see how SQL Plan Directives helps create Column group or Extended Statistics.
-- DBMS_STAT does not automatically gather extension statistics unless AUTO_STAT_EXTENSIONS is ON. 
-- By default AUTO_STAT_EXTENSIONS is OFF.
--
col AUTO_STAT_EXT format a13
SELECT DBMS_STATS.GET_PREFS(OWNNAME =>'SOE', PNAME=>'AUTO_STAT_EXTENSIONS') AUTO_STAT_EXT FROM DUAL;
--
AUTO_STAT_EXT
-------------
OFF
--
-- Enable AUTO_STAT_EXTENSIONS.
exec DBMS_STATS.SET_SCHEMA_PREFS (OWNNAME =>'SOE', PNAME=>'AUTO_STAT_EXTENSIONS', PVALUE =>'ON');
--
-- Gather table stat
EXEC DBMS_STATS.GATHER_TABLE_STATS('SOE','CUSTOMERS2');
--
-- And check if an column group has been created on NLS_LANGUAGE and NLS_TERRITORY
col TABLE_NAME format a12
col EXTENSION_NAME format a35
col EXTENSION format a40
SELECT 
	TABLE_NAME, 
	EXTENSION_NAME, 
	EXTENSION
FROM 
	DBA_STAT_EXTENSIONS
WHERE OWNER='SOE' AND TABLE_NAME='CUSTOMERS2';
--
TABLE_NAME   EXTENSION_NAME                      EXTENSION
------------ ----------------------------------- ----------------------------------------
CUSTOMERS2   SYS_STSYW6#GFCPQMT660UM0#5W#IN      ("NLS_LANGUAGE","NLS_TERRITORY")
--
ALTER SYSTEM FLUSH SHARED_POOL;
--
SELECT /*+ GATHER_PLAN_STATISTICS */ * FROM SOE.CUSTOMERS2 WHERE NLS_LANGUAGE = 'us' AND NLS_TERRITORY='AMERICA';
--
SELECT * FROM table (DBMS_XPLAN.DISPLAY_CURSOR(null,null,'ALLSTATS LAST'));
--
-- The Optimizer is still using the SQL Plan directive not extended stat because the SQL is not recompiled.
-- 
SELECT /*+ GATHER_PLAN_STATISTICS */ * FROM SOE.CUSTOMERS2 WHERE
NLS_LANGUAGE = 'us' AND NLS_TERRITORY='AMERICA'

Plan hash value: 1141662121

------------------------------------------------------------------------------------------
| Id  | Operation         | Name       | Starts | E-Rows | A-Rows |   A-Time   | Buffers |
------------------------------------------------------------------------------------------
|   0 | SELECT STATEMENT  |            |      1 |        |   3256 |00:00:00.01 |     954 |
|*  1 |  TABLE ACCESS FULL| CUSTOMERS2 |      1 |   3256 |   3256 |00:00:00.01 |     954 |
------------------------------------------------------------------------------------------

Predicate Information (identified by operation id):
---------------------------------------------------

   1 - filter(("NLS_TERRITORY"='AMERICA' AND "NLS_LANGUAGE"='us'))

Note
-----
   - dynamic statistics used: dynamic sampling (level=2)
   - 1 Sql Plan Directive used for this statement
--
EXEC DBMS_SPD.FLUSH_SQL_PLAN_DIRECTIVE;
--
SELECT 
	'DIR_ID: ' || TO_CHAR(d.DIRECTIVE_ID) ||chr(10) ||
	'Type: ' || d.TYPE||chr(10) ||
	'State: ' || d.STATE || chr(10) ||
	'Object Name: '|| o.OBJECT_NAME ||chr(10) ||
	'Object Type: ' || o.OBJECT_TYPE||chr(10) ||
	'Column: ' || o.SUBOBJECT_NAME ||chr(10) ||
	'Reason: ' || d.REASON ||chr(10) ||
	'Last Used: ' || d.LAST_USED ||chr(10) ||
	'Num Rows: ' || o.NUM_ROWS ||chr(10) ||
	'Notes: ' || d.Notes ||chr(10) DIRECTIVE
FROM 
	DBA_SQL_PLAN_DIRECTIVES d, 
	DBA_SQL_PLAN_DIR_OBJECTS o
WHERE 
	d.DIRECTIVE_ID=o.DIRECTIVE_ID AND o.OWNER ='SOE' and o.OBJECT_NAME = 'CUSTOMERS2'
ORDER BY d.DIRECTIVE_ID,d.TYPE;
--
-- Note:: that all Column type directives has been SUPERSEDED which means the SQL compilation will NOT use these directives
--
DIRECTIVE
------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
DIR_ID: 4094368677557740560
Type: DYNAMIC_SAMPLING_RESULT
State: USABLE
Object Name: CUSTOMERS2
Object Type: TABLE
Column:
Reason: VERIFY CARDINALITY ESTIMATE
Last Used: 15-JUL-22 02.55.46.000000000 AM
Num Rows: 45703
Notes: <spd_note><internal_state>NEW</internal_state><redundant>NO</redundant><spd_text>{(SOE.CUSTOMERS2, num_rows=45703) - (SQL_ID:27bkasnzgafv0, T.CARD=3256[-2 -2])}</spd_text></
spd_note>

DIR_ID: 4112472790421109895
Type: DYNAMIC_SAMPLING_RESULT
State: USABLE
Object Name: CUSTOMERS2
Object Type: TABLE
Column:
Reason: VERIFY CARDINALITY ESTIMATE
Last Used: 15-JUL-22 02.29.36.000000000 AM
Num Rows: 45703
Notes: <spd_note><internal_state>NEW</internal_state><redundant>NO</redundant><spd_text>{(SOE.CUSTOMERS2, num_rows=45703) - (SQL_ID:7j3b6bym14fk4, T.CARD=3139[-2 -2])}</spd_text></
spd_note>

DIR_ID: 16146197347752157163
Type: DYNAMIC_SAMPLING
State: SUPERSEDED
Object Name: CUSTOMERS2
Object Type: COLUMN
Column: NLS_TERRITORY
Reason: SINGLE TABLE CARDINALITY MISESTIMATE
Last Used: 15-JUL-22 02.58.53.000000000 AM
Num Rows:
Notes: <spd_note><internal_state>HAS_STATS</internal_state><redundant>NO</redundant><spd_text>{EC(SOE.CUSTOMERS2)[NLS_LANGUAGE, NLS_TERRITORY]}</spd_text></spd_note>

DIR_ID: 16146197347752157163
Type: DYNAMIC_SAMPLING
State: SUPERSEDED
Object Name: CUSTOMERS2
Object Type: COLUMN
Column: NLS_LANGUAGE
Reason: SINGLE TABLE CARDINALITY MISESTIMATE
Last Used: 15-JUL-22 02.58.53.000000000 AM
Num Rows:
Notes: <spd_note><internal_state>HAS_STATS</internal_state><redundant>NO</redundant><spd_text>{EC(SOE.CUSTOMERS2)[NLS_LANGUAGE, NLS_TERRITORY]}</spd_text></spd_note>

DIR_ID: 16146197347752157163
Type: DYNAMIC_SAMPLING
State: SUPERSEDED
Object Name: CUSTOMERS2
Object Type: TABLE
Column:
Reason: SINGLE TABLE CARDINALITY MISESTIMATE
Last Used: 15-JUL-22 02.58.53.000000000 AM
Num Rows:
Notes: <spd_note><internal_state>HAS_STATS</internal_state><redundant>NO</redundant><spd_text>{EC(SOE.CUSTOMERS2)[NLS_LANGUAGE, NLS_TERRITORY]}</spd_text></spd_note>
--
-- Run the same query with slight modification
SELECT /*+ GATHER_PLAN_STATISTICS */ /* a comment to reparse */ * FROM SOE.CUSTOMERS2 
WHERE NLS_LANGUAGE = 'us' AND NLS_TERRITORY='AMERICA';
--
SELECT * FROM table (DBMS_XPLAN.DISPLAY_CURSOR(null,null,'ALLSTATS LAST'));
--
--As we can see below, SQL Plan directive is no longer used and cardinality is quite correct.
--
SQL_ID  2qvcwjwcau9d1, child number 0
Plan hash value: 1141662121

------------------------------------------------------------------------------------------
| Id  | Operation         | Name       | Starts | E-Rows | A-Rows |   A-Time   | Buffers |
------------------------------------------------------------------------------------------
|   0 | SELECT STATEMENT  |            |      1 |        |   3256 |00:00:00.01 |     954 |
|*  1 |  TABLE ACCESS FULL| CUSTOMERS2 |      1 |   3279 |   3256 |00:00:00.01 |     954 |
------------------------------------------------------------------------------------------

Predicate Information (identified by operation id):
---------------------------------------------------

   1 - filter(("NLS_TERRITORY"='AMERICA' AND "NLS_LANGUAGE"='us'))
--
define v_sql_id = '2qvcwjwcau9d1'
--
col IS_REOPTIMIZABLE format a16
SELECT SQL_ID, CHILD_NUMBER, PLAN_HASH_VALUE, IS_REOPTIMIZABLE
FROM V$SQL
WHERE SQL_ID='&v_sql_id' ORDER BY CHILD_NUMBER;
--
--Cursor is now fully Optimized
--
SQL_ID        CHILD_NUMBER PLAN_HASH_VALUE IS_REOPTIMIZABLE
------------- ------------ --------------- ----------------
2qvcwjwcau9d1            0      1141662121 N
--
-- Wrap Up
-- Delete the directives
-- if you receive the error “ORA-13158”, just run the block again
BEGIN
	FOR R IN ( SELECT D.DIRECTIVE_ID FROM DBA_SQL_PLAN_DIRECTIVES D, DBA_SQL_PLAN_DIR_OBJECTS O
				WHERE D.DIRECTIVE_ID=O.DIRECTIVE_ID AND O.OWNER = 'SOE' AND O.OBJECT_NAME='CUSTOMERS2' ) 
	LOOP
			DBMS_SPD.DROP_SQL_PLAN_DIRECTIVE(R.DIRECTIVE_ID);
	END LOOP;
END;
/
exec DBMS_STATS.SET_SCHEMA_PREFS ( OWNNAME =>'SOE', PNAME =>'AUTO_STAT_EXTENSIONS', PVALUE =>'OFF');
--
DROP TABLE SOE.CUSTOMERS2;
--



