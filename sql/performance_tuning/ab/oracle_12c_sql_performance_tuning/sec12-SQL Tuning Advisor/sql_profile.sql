--
-- Run the following query to retrieve the SQL Tuning Advisor parameters that affect creating SQL Profiles.
--
SELECT PARAMETER_NAME, PARAMETER_VALUE AS "VALUE"
FROM DBA_ADVISOR_PARAMETERS
WHERE (TASK_NAME = 'SYS_AUTO_SQL_TUNING_TASK')
AND (PARAMETER_NAME LIKE '%PROFILE%');
--
PARAMETER_NAME
----------------------------------------
VALUE
-----------------------------------------
ACCEPT_SQL_PROFILES
FALSE

MAX_SQL_PROFILES_PER_EXEC
20

MAX_AUTO_SQL_PROFILES
10000
--
-- Setup data (soe window)
--
DROP TABLE SOE.ORDERS2 PURGE;
CREATE TABLE ORDERS2 (ORDER_ID CONSTRAINT ORDERS2_PK PRIMARY KEY, NOTES)
AS SELECT ORDER_ID, LPAD ('*',4000,'*') FROM ORDERS WHERE ROWNUM<=10000;
--
ALTER SYSTEM FLUSH SHARED_POOL;
--
-- Run the following script and compare the number of rows retrived vs optimizer cardinality estimate
--
@run_query2.sql
--
  COUNT(*)
----------
         1
--
-- COUNT is 1 but cardinality estimated by optimizer is 100.
--
Execution Plan
----------------------------------------------------------
Plan hash value: 1441466254

------------------------------------------------------------------------------------
| Id  | Operation             | Name       | Rows  | Bytes | Cost (%CPU)| Time     |
------------------------------------------------------------------------------------
|   0 | SELECT STATEMENT      |            |     1 |     6 |     8   (0)| 00:00:01 |
|   1 |  SORT AGGREGATE       |            |     1 |     6 |            |          |
|*  2 |   INDEX FAST FULL SCAN| ORDERS2_PK |   100 |   600 |     8   (0)| 00:00:01 |
------------------------------------------------------------------------------------
--
-- Create a SQL Tuning Advisor Task to tune the query the executed query
--
SET AUTOT OFF
DECLARE
V_TASK_NAME VARCHAR2(30);
V_SQLTEXT CLOB;
BEGIN
	V_SQLTEXT := ' SELECT COUNT(*) FROM ORDERS2 WHERE ORDER_ID+32 = 862464';
	V_TASK_NAME := DBMS_SQLTUNE.CREATE_TUNING_TASK (SQL_TEXT => V_SQLTEXT, BIND_LIST => null, USER_NAME => 'SOE', 
	SCOPE => 'COMPREHENSIVE',
	TIME_LIMIT => NULL,
	TASK_NAME => 'TASK1');
END;
/
--
-- Execute the Task
--
exec DBMS_SQLTUNE.EXECUTE_TUNING_TASK(TASK_NAME=>'TASK1');
--
-- Get the SQL Tuning Advisor Report
--
set long 5000
set longchunksize 1000
set linesize 100
SELECT DBMS_SQLTUNE.REPORT_TUNING_TASK( 'TASK1' ) FROM DUAL;
--
-- The SQL Tuning Advisor has three recommendations: 1. Accept SQL Profile 2. Create an index and 3. reqwrite the SQL 
--
-------------------------------------------------------------------------------
Schema Name   : SOE
Container Name: DB19C01
SQL ID        : 5rxrdnz8a90pv
SQL Text      :  SELECT COUNT(*) FROM ORDERS2 WHERE ORDER_ID+32 = 862464

-------------------------------------------------------------------------------
FINDINGS SECTION (3 findings)
-------------------------------------------------------------------------------

1- SQL Profile Finding (see explain plans section below)
--------------------------------------------------------
  A potentially better execution plan was found for this statement.

  Recommendation (estimated benefit: 14.81%)
  ------------------------------------------
  - Consider accepting the recommended SQL profile.
    execute dbms_sqltune.accept_sql_profile(task_name => 'TASK1', task_owner
            => 'SOE', replace => TRUE);

  Validation results
  ------------------
  The SQL profile was tested by executing both its plan and the original plan
  and measuring their respective execution statistics. A plan may have been
  only partially executed if the other could be run to completion in less time.

                           Original Plan  With SQL Profile  % Improved
                           -------------  ----------------  ----------
  Completion Status:            COMPLETE          COMPLETE
  Elapsed Time (s):             .000559            .00049      12.34 %
  CPU Time (s):                       0                 0
  User I/O Time (s):                  0                 0
  Buffer Gets:                       27                23      14.81 %
  Physical Read Requests:             0                 0
  Physical Write Requests:            0                 0
  Physical Read Bytes:                0                 0
  Physical Write Bytes:               0                 0
  Rows Processed:                     1                 1
  Fetches:                            1                 1
  Executions:                         1                 1

  Notes
  -----
  1. Statistics for the original plan were averaged over 10 executions.
  2. Statistics for the SQL profile plan were averaged over 10 executions.

2- Index Finding (see explain plans section below)
--------------------------------------------------
  The execution plan of this statement can be improved by creating one or more
  indices.

  Recommendation (estimated benefit: 95.65%)
  ------------------------------------------
  - Consider running the Access Advisor to improve the physical schema design
    or creating the recommended index.
    create index SOE.IDX$$_00690001 on SOE.ORDERS2("ORDER_ID"+32);

  Rationale
  ---------
    Creating the recommended indices significantly improves the execution plan
    of this statement. However, it might be preferable to run "Access Advisor"
    using a representative SQL workload as opposed to a single statement. This
    will allow to get comprehensive index recommendations which takes into
    account index maintenance overhead and additional space consumption.

3- Restructure SQL finding (see plan 1 in explain plans section)
----------------------------------------------------------------
  The predicate "ORDERS2"."ORDER_ID"+32=862464 used at line ID 2 of the
  execution plan contains an expression on indexed column "ORDER_ID". This
  expression prevents the optimizer from selecting indices on table
  "SOE"."ORDERS2".

  Recommendation
  --------------
  - Rewrite the predicate into an equivalent form to take advantage of
    indices. Alternatively, create a function-based index on the expression.

-------------------------------------------------------------------------------
EXPLAIN PLANS SECTION
-------------------------------------------------------------------------------

1- Original With Adjusted Cost
------------------------------
Plan hash value: 1441466254

------------------------------------------------------------------------------------
| Id  | Operation             | Name       | Rows  | Bytes | Cost (%CPU)| Time     |
------------------------------------------------------------------------------------
|   0 | SELECT STATEMENT      |            |     1 |     6 |     8   (0)| 00:00:01 |
|   1 |  SORT AGGREGATE       |            |     1 |     6 |            |          |
|*  2 |   INDEX FAST FULL SCAN| ORDERS2_PK |     2 |    12 |     8   (0)| 00:00:01 |
------------------------------------------------------------------------------------

Predicate Information (identified by operation id):
---------------------------------------------------

   2 - filter("ORDER_ID"+32=862464)
--
-- In soe window run the following script to display the created SQL profile
-- Observe that no SQL profile has been created by the Optimizer. The Optimizer did not accept the profile 
-- as ACCEPT_SQL_PROFILES parameter is FALSE
--
@display_profiles.sql
no rows selected   
--
-- In soe window accept the SQL Profile
--
exec DBMS_SQLTUNE.ACCEPT_SQL_PROFILE(TASK_NAME => 'TASK1', TASK_OWNER => 'SOE', REPLACE => TRUE);
--
@display_profiles.sql
--
NAME                         CATEGORY   SQL_TEXT                                 TYPE    STATUS
---------------------------- ---------- ---------------------------------------- ------- ----------
FOR
---
SYS_SQLPROF_0182e52147540000 DEFAULT     SELECT COUNT(*) FROM ORDERS2 WHERE ORDE MANUAL  ENABLED
                                        R_ID+32 = 862464
--
-- In soe window 
--
define v_profile_name='SYS_SQLPROF_0182e52147540000'
@display_profile_hints.sql
--
--- PROFILE HINTS from TASK1 (1) statement 5rxrdnz8a90pv:
/*+
OPT_ESTIMATE(@"SEL$1", TABLE, "ORDERS2"@"SEL$1", SCALE_ROWS=0.02001381215)
*/
--
-- Another Easy way to get the hints
--
SELECT COMP_DATA
FROM DBA_SQL_PROFILES prof,
DBMSHSXP_SQL_PROFILE_ATTR attr
WHERE prof.NAME=attr.PROFILE_NAME
AND NAME = '&v_profile_name'
ORDER BY prof.name;
--
COMP_DATA
----------------------------------------------------------------------------------------------------
<outline_data><hint><![CDATA[OPT_ESTIMATE(@"SEL$1", TABLE, "ORDERS2"@"SEL$1", SCALE_ROWS=0.020013812
15)]]></hint><hint><![CDATA[IGNORE_OPTIM_EMBEDDED_HINTS]]></hint><hint><![CDATA[OPTIMIZER_FEATURES_E
NABLE('8.0.0')]]></hint></outline_data>
--
-- run the previous SQL statements again
--
ALTER SYSTEM FLUSH SHARED_POOL;
@run_query2.sql
--
  COUNT(*)
----------
         1
--
-- You can see that the SQL has used the SQL profile SYS_SQLPROF_0182e52147540000
--
Execution Plan
----------------------------------------------------------
Plan hash value: 3173423194

---------------------------------------------------------------
| Id  | Operation        | Name       | Rows  | Bytes | Cost  |
---------------------------------------------------------------
|   0 | SELECT STATEMENT |            |     1 |    13 |    23 |
|   1 |  SORT AGGREGATE  |            |     1 |    13 |       |
|*  2 |   INDEX FULL SCAN| ORDERS2_PK |     2 |    26 |    23 |
---------------------------------------------------------------

Predicate Information (identified by operation id):
---------------------------------------------------

   2 - filter("ORDER_ID"+32=862464)

Note
-----
   - cpu costing is off (consider enabling it)
   - SQL profile "SYS_SQLPROF_0182e52147540000" used for this statement
--
-- Disable the SQL Profile
--
define v_profile_name='SYS_SQLPROF_0182e52147540000'
exec DBMS_SQLTUNE.ALTER_SQL_PROFILE('&v_profile_name','STATUS','DISABLED');
--
-- run the script again and check the execution plan. SQL Profile is no longer used and 
-- optimizer cardinality estimate is back to the old execution plan (without SQL profile)
--
------------------------------------------------------------------------------------
| Id  | Operation             | Name       | Rows  | Bytes | Cost (%CPU)| Time     |
------------------------------------------------------------------------------------
|   0 | SELECT STATEMENT      |            |     1 |     6 |     8   (0)| 00:00:01 |
|   1 |  SORT AGGREGATE       |            |     1 |     6 |            |          |
|*  2 |   INDEX FAST FULL SCAN| ORDERS2_PK |   100 |   600 |     8   (0)| 00:00:01 |
------------------------------------------------------------------------------------

Predicate Information (identified by operation id):
---------------------------------------------------

   2 - filter("ORDER_ID"+32=862464)


Statistics
----------------------------------------------------------
        120  recursive calls
          0  db block gets
        297  consistent gets
          3  physical reads
          0  redo size
        359  bytes sent via SQL*Net to client
        377  bytes received via SQL*Net from client
          2  SQL*Net roundtrips to/from client
         39  sorts (memory)
          0  sorts (disk)
          1  rows processed

--
-- Enable the SQL profile
--          
exec DBMS_SQLTUNE.ALTER_SQL_PROFILE('&v_profile_name','STATUS','ENABLED');
--
-- Testing SQL Profile impact for specific sessions ::
-- By default, SQL profiles are enabled in every session when they're enabled, including production system.
-- Using the following method you can test a SQL profile for a specific session before enabling them database wide
--
-- In Tykte window change the SQL profile settings.
--
define v_profile_name='SYS_SQLPROF_0182e52147540000'
BEGIN
	DBMS_SQLTUNE.ALTER_SQL_PROFILE(NAME => '&v_profile_name', ATTRIBUTE_NAME => 'CATEGORY',VALUE => 'TESTING');
END;
/
-- 
-- After changing the category the SQL profile is no longer used in another client (soe) session.
--
ALTER SYSTEM FLUSH SHARED_POOL;
@run_query2.sql
--
Execution Plan
----------------------------------------------------------
Plan hash value: 1441466254

------------------------------------------------------------------------------------
| Id  | Operation             | Name       | Rows  | Bytes | Cost (%CPU)| Time     |
------------------------------------------------------------------------------------
|   0 | SELECT STATEMENT      |            |     1 |     6 |     8   (0)| 00:00:01 |
|   1 |  SORT AGGREGATE       |            |     1 |     6 |            |          |
|*  2 |   INDEX FAST FULL SCAN| ORDERS2_PK |   100 |   600 |     8   (0)| 00:00:01 |
------------------------------------------------------------------------------------
--
-- Change the SQLTUNE_CATEGORY to TESTING in soe session and run the SQL again.
-- This time you can observe that the SQL profile is used and optimizer cardinality estimate has improved.
--
ALTER SESSION SET SQLTUNE_CATEGORY=TESTING;
@run_query2.sql
--
Execution Plan
----------------------------------------------------------
Plan hash value: 3173423194

---------------------------------------------------------------
| Id  | Operation        | Name       | Rows  | Bytes | Cost  |
---------------------------------------------------------------
|   0 | SELECT STATEMENT |            |     1 |    13 |    23 |
|   1 |  SORT AGGREGATE  |            |     1 |    13 |       |
|*  2 |   INDEX FULL SCAN| ORDERS2_PK |     2 |    26 |    23 |
---------------------------------------------------------------

Predicate Information (identified by operation id):
---------------------------------------------------

   2 - filter("ORDER_ID"+32=862464)

Note
-----
   - cpu costing is off (consider enabling it)
   - SQL profile "SYS_SQLPROF_0182e52147540000" used for this statement
--
-- Change the SQLTUNE_CATEGORY to default (since testing is successful and it can be used database wide)
--
ALTER SESSION SET SQLTUNE_CATEGORY=DEFAULT;
--
-- and set the profile CATEGORY attribute to DEFAULT
--
define v_profile_name='SYS_SQLPROF_0182e52147540000'
BEGIN
	DBMS_SQLTUNE.ALTER_SQL_PROFILE(NAME => '&v_profile_name', ATTRIBUTE_NAME => 'CATEGORY',VALUE => 'DEFAULT');
END;
/
-- When you open a new session and run run_query2.sql, it will use the SQL profile.
--
-- Transporting a SQL Profile to a Different Database
--
-- Craete the stage table for storing the profile
--
BEGIN
  DBMS_SQLTUNE.CREATE_STGTAB_SQLPROF(TABLE_NAME => 'PROF_STAGE', SCHEMA_NAME => 'SOE' );
END;
/
--
-- Populate the staging table.
-- Note: SQL profiles cannot be populated if they are disabled or they are of a non-DEFAULT category.
--
define v_profile_name='SYS_SQLPROF_0182e52147540000'
BEGIN
  DBMS_SQLTUNE.PACK_STGTAB_SQLPROF(PROFILE_NAME => '&v_profile_name', STAGING_TABLE_NAME => 'PROF_STAGE', STAGING_SCHEMA_OWNER => 'SOE' );
END;
/
-- After that, you can export the table, import it into the testing database, 
-- then unpack the table contents using the procedure DBMS_SQLTUNE.UNPACK_STGTAB_SQLPROF.
--
-- Drop the SQL Tuning Task, Profile and test tables.
--
exec DBMS_SQLTUNE.DROP_TUNING_TASK(TASK_NAME => 'TASK1');
DROP TABLE SOE.ORDERS2;
DROP TABLE SOE.PROF_STAGE;
exec DBMS_SQLTUNE.DROP_SQL_PROFILE('&v_profile_name');
--
--
-- Manually Creating a SQL Profile (non-standard)
--
-- In the following steps we will create a manual profile tied to a specific SQL statement. 
-- The SQL Profile will add the FULL hint to a statement.
-- Manual SQL Profiles are useful when you want to force a hint on a statement that 
-- is submitted by an out-of-the-box application.
--
-- Login as soe user and create the test data
--
DROP TABLE SOE.CUSTOMERS2;
CREATE TABLE SOE.CUSTOMERS2 NOLOGGING AS SELECT * FROM CUSTOMERS WHERE
CUSTOMER_ID<=20000;
CREATE UNIQUE INDEX CUST_ID_IX ON CUSTOMERS2(CUSTOMER_ID);
exec DBMS_STATS.GATHER_INDEX_STATS('SOE','CUST_ID_IX');
--
-- Run the query. The optimizer will use the index for retrieving the data
--
@run_query.sql
--
SQL_ID  dbpn5qt49z7nd, child number 0
-------------------------------------
SELECT CUST_FIRST_NAME, CUST_LAST_NAME FROM CUSTOMERS2 C WHERE
CUSTOMER_ID=100

Plan hash value: 518886608

------------------------------------------------------------------------------------------
| Id  | Operation                   | Name       | Rows  | Bytes | Cost (%CPU)| Time     |
------------------------------------------------------------------------------------------
|   0 | SELECT STATEMENT            |            |       |       |     2 (100)|          |
|   1 |  TABLE ACCESS BY INDEX ROWID| CUSTOMERS2 |     1 |    20 |     2   (0)| 00:00:01 |
|*  2 |   INDEX UNIQUE SCAN         | CUST_ID_IX |     1 |       |     1   (0)| 00:00:01 |
------------------------------------------------------------------------------------------
--
-- In soe and Tkyte window save the SQL ID
--
DEFINE V_SQL_ID='dbpn5qt49z7nd'
--
-- In soe window run the following and display execution plan
--
SELECT /*+ FULL(C) */
CUST_FIRST_NAME, CUST_LAST_NAME
FROM CUSTOMERS2 C
WHERE CUSTOMER_ID=100;
--
SELECT * FROM TABLE(DBMS_XPLAN.DISPLAY_CURSOR);
--
SQL_ID  1m1rbkcb9mj05, child number 0
-------------------------------------
SELECT /*+ FULL(C) */ CUST_FIRST_NAME, CUST_LAST_NAME FROM CUSTOMERS2 C
WHERE CUSTOMER_ID=100

Plan hash value: 1141662121

--------------------------------------------------------------------------------
| Id  | Operation         | Name       | Rows  | Bytes | Cost (%CPU)| Time     |
--------------------------------------------------------------------------------
|   0 | SELECT STATEMENT  |            |       |       |    92 (100)|          |
|*  1 |  TABLE ACCESS FULL| CUSTOMERS2 |     1 |    20 |    92   (0)| 00:00:01 |
--------------------------------------------------------------------------------
--
-- Display the execution plan with OUTLINE option
--
SELECT * FROM TABLE(DBMS_XPLAN.DISPLAY_CURSOR('1m1rbkcb9mj05',0,'OUTLINE'));
--
-- Note the FULL hint used: FULL(@"SEL$1" "C"@"SEL$1")
Outline Data
-------------

  /*+
      BEGIN_OUTLINE_DATA
      IGNORE_OPTIM_EMBEDDED_HINTS
      OPTIMIZER_FEATURES_ENABLE('19.1.0')
      DB_VERSION('19.1.0')
      ALL_ROWS
      OUTLINE_LEAF(@"SEL$1")
      FULL(@"SEL$1" "C"@"SEL$1")
      END_OUTLINE_DATA
  */
--
-- In the Tkyte window run the following to create the SQL Profile using IMPORT_SQL_PROFILE
-- In PROFILE parameter pass SQLPROF_ATTR with FULL(@"SEL$1" "C"@"SEL$1") parameter (obtained in prev. step)
--
DECLARE
V_SQL_TEXT CLOB;
BEGIN
  SELECT SQL_FULLTEXT INTO V_SQL_TEXT FROM V$SQLAREA WHERE SQL_ID = '&V_SQL_ID';
  DBMS_SQLTUNE.IMPORT_SQL_PROFILE(SQL_TEXT => V_SQL_TEXT, PROFILE=> SQLPROF_ATTR('FULL(@"SEL$1" "C"@"SEL$1")'),
  NAME=>'PROFILE_&V_SQL_ID', FORCE_MATCH=>TRUE);
END;
/
--
@display_profiles.sql
--
-- Profile has been created
--
NAME                         CATEGORY   SQL_TEXT                                 TYPE    STATUS     FOR
---------------------------- ---------- ---------------------------------------- ------- ---------- ---
PROFILE_dbpn5qt49z7nd        DEFAULT    SELECT                                   MANUAL  ENABLED    YES
                                        CUST_FIRST_NAME, CUST_LAST_NAME
                                        FROM CUSTOMERS2 C
                                        WHERE CUSTOMER_ID=100
--
DEFINE v_profile_name='PROFILE_dbpn5qt49z7nd'         
--
SELECT 
  COMP_DATA
FROM 
  DBA_SQL_PROFILES prof,
  DBMSHSXP_SQL_PROFILE_ATTR attr
WHERE 
  prof.NAME=attr.PROFILE_NAME AND NAME LIKE 'PROFILE%'
ORDER BY prof.name;                               
--
COMP_DATA
--------------------------------------------------------------------------------
<outline_data><hint><![CDATA[FULL(@"SEL$1" "C"@"SEL$1")]]></hint></outline_data>
--
-- In soe window run the following SQL again 
-- 
@run_query.sql
--
-- Observe that even without FULL hint, the Optimizer has used FULL hint. 
-- It also indicated that the SQL profie has been used
--
CUST_FIRST_NAME                          CUST_LAST_NAME
---------------------------------------- ----------------------------------------
kareem                                   heinrichs

PLAN_TABLE_OUTPUT
------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
SQL_ID  dbpn5qt49z7nd, child number 0
-------------------------------------
SELECT CUST_FIRST_NAME, CUST_LAST_NAME FROM CUSTOMERS2 C WHERE
CUSTOMER_ID=100

Plan hash value: 1141662121

--------------------------------------------------------------------------------
| Id  | Operation         | Name       | Rows  | Bytes | Cost (%CPU)| Time     |
--------------------------------------------------------------------------------
|   0 | SELECT STATEMENT  |            |       |       |    92 (100)|          |
|*  1 |  TABLE ACCESS FULL| CUSTOMERS2 |     1 |    20 |    92   (0)| 00:00:01 |
--------------------------------------------------------------------------------

Predicate Information (identified by operation id):
---------------------------------------------------

   1 - filter("CUSTOMER_ID"=100)

Note
-----
   - SQL profile PROFILE_dbpn5qt49z7nd used for this statement