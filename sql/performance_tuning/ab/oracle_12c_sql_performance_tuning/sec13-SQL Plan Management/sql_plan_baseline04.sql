--
-- Managing the SPM Evolve Advisor Task
--
-- Configuring SPM Evolve Advisor
--
-- SPM Evolve Advisor task and Automatic SQL Tuning Advisor is controlled by one Client - SQL Tuning Advisor.
--
-- check the if SQL Tuning Advisor is enabled
--
SELECT STATUS FROM DBA_AUTOTASK_CLIENT WHERE CLIENT_NAME = 'sql tuning advisor';
--
STATUS
--------
ENABLED
--
-- Display SPM Evolve Advisor Task parameters
--
col PARAMETER_NAME format a25
col VALUE format a42
SELECT PARAMETER_NAME, PARAMETER_VALUE AS "VALUE"
FROM DBA_ADVISOR_PARAMETERS
WHERE TASK_NAME = 'SYS_AUTO_SPM_EVOLVE_TASK' AND PARAMETER_VALUE<>'UNUSED';
--
PARAMETER_NAME            VALUE
------------------------- ------------------------------------------
ALTERNATE_PLAN_LIMIT      UNLIMITED
ALTERNATE_PLAN_SOURCE     AUTO
ALTERNATE_PLAN_BASELINE   AUTO
ACCEPT_PLANS              TRUE
DAYS_TO_EXPIRE            UNLIMITED
JOURNALING                INFORMATION
MODE                      COMPREHENSIVE
TARGET_OBJECTS            1
TIME_LIMIT                3600
DEFAULT_EXECUTION_TYPE    SPM EVOLVE
EXECUTION_DAYS_TO_EXPIRE  30
--
-- Example of modifying SPM Evolve Advisor Task Parameters.
--
-- configure SYS_AUTO_SPM_EVOLVE_TASK to time out after 30 minutes per a single execution.
--
exec DBMS_SPM.SET_EVOLVE_TASK_PARAMETER(TASK_NAME => 'SYS_AUTO_SPM_EVOLVE_TASK', PARAMETER => 'TIME_LIMIT', VALUE => '1800');
--
--
-- Manually Evolve SQL Plans into Baselines :: We will load specific plan from cursor cache into a 
-- plan baseline and create an Evolve task on the created plan
--
-- Manually evolve SQL plans into baselines using DBMS_SPM.EVOLVE_SQL_PLAN_BASELINE
--
-- As SYS
ALTER SYSTEM FLUSH SHARED_POOL;
ALTER SYSTEM FLUSH BUFFER_CACHE;
--
-- enable automatic SQL plan capture
--
ALTER SYSTEM SET OPTIMIZER_CAPTURE_SQL_PLAN_BASELINES=true;
--
-- in SOE window run the SQL
--
SELECT * FROM INVENTORIES2 WHERE WAREHOUSE_ID=999;
--
-- load the plan from the cursor cache into the SPM. New baseline will be created.
--
set serveroutput on
DECLARE
   v_sql_id VARCHAR2(50);
   v_plan_cnt NUMBER;
BEGIN
   SELECT SQL_ID INTO v_sql_id FROM V$SQL WHERE SQL_TEXT='SELECT * FROM INVENTORIES2 WHERE WAREHOUSE_ID=999';
   v_plan_cnt := DBMS_SPM.LOAD_PLANS_FROM_CURSOR_CACHE( SQL_ID => v_sql_id );
   DBMS_OUTPUT.PUT_LINE('Number of Loaded Plans: ' || v_plan_cnt );
END;
/
--
Number of Loaded Plans: 1
--
-- verify if baseline is created
--
@display_soe_baselines.sql
--
SQL_HANDLE           SQL_TEXT                                           ENA ACC FIX  COST DISK_READS BUFFER_GETS    FETCHES ELAPSED_TIME ORIGIN
-------------------- -------------------------------------------------- --- --- --- ----- ---------- ----------- ---------- ------------ -----------------------------
SQL_2ed32f72ca911bc7 SELECT * FROM INVENTORIES2 WHERE WAREHOUSE_ID=999  YES YES NO     42        347        2839          2        ##### MANUAL-LOAD-FROM-CURSOR-CACHE
--
-- in soe window
--
CREATE INDEX INV2_WAREH_IX ON INVENTORIES2(WAREHOUSE_ID) COMPUTE STATISTICS;
--
-- In SYS window
--
ALTER SYSTEM FLUSH SHARED_POOL;
--
-- In SOE window run the SQL. It's still using FULL TABLE ACCESS
--
SET AUTOT ON
SELECT * FROM INVENTORIES2 WHERE WAREHOUSE_ID=999;
SET AUTOT OFF
-- 
-- observe that the SQL is still using SQL_PLAN_2xntgfb5926y7071e6496 plan in the base plan.
--
Execution Plan
----------------------------------------------------------
Plan hash value: 999836115

----------------------------------------------------------------------------------
| Id  | Operation         | Name         | Rows  | Bytes | Cost (%CPU)| Time     |
----------------------------------------------------------------------------------
|   0 | SELECT STATEMENT  |              |     5 |    65 |    42   (0)| 00:00:01 |
|*  1 |  TABLE ACCESS FULL| INVENTORIES2 |     5 |    65 |    42   (0)| 00:00:01 |
----------------------------------------------------------------------------------
Predicate Information (identified by operation id):
---------------------------------------------------

   1 - filter("WAREHOUSE_ID"=999)

Note
-----
   - SQL plan baseline "SQL_PLAN_2xntgfb5926y7071e6496" used for this statement
--
-- display baseline and oberve that an additional plan has been added (ORIGIN: Auto Capture) with ACCEPTED flag as NO.
--
@display_soe_baselines.sql
-- 
-- we can observe that second SQL Plan in the baseline has not been accepted yet. 
--
SQL_HANDLE           SQL_TEXT                                           PLAN_NAME                      ENA ACC FIX  COST ELAPSED_TIME ORIGIN
-------------------- -------------------------------------------------- ------------------------------ --- --- --- ----- ------------ --------------------
SQL_115024ccba5e158c DELETE FROM PLAN_TABLE WHERE STATEMENT_ID=:1       SQL_PLAN_12n14tkx5w5cc52d2775d YES YES NO      2            0 AUTO-CAPTURE
SQL_1b81ebf40756e565 SELECT PT.VALUE FROM SYS.V_$SESSTAT PT WHERE PT.SI SQL_PLAN_1r0gbyh3pdtb52e8a86b7 YES YES NO      1            0 AUTO-CAPTURE
                     D=:1 AND PT.STATISTIC# IN (9,159,163,172,313,1879,
                     1880,1881,1889,1890) ORDER BY PT.STATISTIC#

SQL_294c437e331fa51f SELECT PLAN_TABLE_OUTPUT FROM TABLE(DBMS_XPLAN.DIS SQL_PLAN_2km23gstjz98zdf463620 YES YES NO     29            0 AUTO-CAPTURE
                     PLAY('PLAN_TABLE', :1))

SQL_2ed32f72ca911bc7 SELECT * FROM INVENTORIES2 WHERE WAREHOUSE_ID=999  SQL_PLAN_2xntgfb5926y7071e6496 YES YES NO     42        ##### MANUAL-LOAD-FROM-CUR
                                                                                                                                      SOR-CACHE

SQL_2ed32f72ca911bc7 SELECT * FROM INVENTORIES2 WHERE WAREHOUSE_ID=999  SQL_PLAN_2xntgfb5926y7e4aeac26 YES NO  NO      2            0 AUTO-CAPTURE
--
-- evolve the unaccepted plan using the SQL handle obtained from the above output.
--
set serveroutput on
set long 10000
DECLARE
   R CLOB;
BEGIN
   R:= DBMS_SPM.EVOLVE_SQL_PLAN_BASELINE(SQL_HANDLE=>'&Enter_SQL_HANDLE');
   DBMS_OUTPUT.PUT_LINE(R);
END;
/
--
-- output
-- it tells that the Test plan (whose SQL handle has been passed) is 46.67860 times better 
-- than that of the baseline plan hence automatically accepted. The plan would have been accepted
-- anyway by Automatic SQL Tuning Advisor task which triggers SPM Evolve task. But we're doing it manually.
--
GENERAL INFORMATION SECTION
---------------------------------------------------------------------------------------------

 Task Information:

---------------------------------------------
 Task Name            : TASK_115
 Task Owner           : SYS
 Execution Name       : EXEC_622
 Execution Type
: SPM EVOLVE
 Scope                : COMPREHENSIVE
 Status               : COMPLETED
 Started              : 09/24/2022 15:19:08
 Finished             : 09/24/2022
15:19:09
 Last Updated         : 09/24/2022 15:19:09
 Global Time Limit    : 2147483646
 Per-Plan Time Limit  : UNUSED
 Number of Errors     : 0

---------------------------------------------------------------------------------------------

SUMMARY
SECTION
---------------------------------------------------------------------------------------------
  Number of plans processed  : 1
  Number of findings         : 2
  Number of recommendations
: 1
  Number of errors           : 0
---------------------------------------------------------------------------------------------

DETAILS
SECTION
---------------------------------------------------------------------------------------------
 Object ID          : 2
 Test Plan Name
: SQL_PLAN_2xntgfb5926y7e4aeac26
 Base Plan Name     : SQL_PLAN_2xntgfb5926y7071e6496
 SQL Handle         : SQL_2ed32f72ca911bc7

 Parsing Schema     : SOE
 Test Plan Creator  : SOE
 SQL Text           : SELECT * FROM
INVENTORIES2 WHERE WAREHOUSE_ID=999

Execution Statistics:
-----------------------------
                    Base Plan                     Test Plan

----------------------------  ----------------------------
 Elapsed Time (s):  .00004                        .000001
 CPU Time (s):      .000036                       0

 Buffer Gets:       14                            0
 Optimizer Cost:    42                            2
 Disk Reads:        0
0
 Direct Writes:     0                             0
 Rows Processed:    0                             0

Executions:        10                            10


FINDINGS
SECTION
---------------------------------------------------------------------------------------------

Findings (2):
-----------------------------
 1. The plan was verified in 0.13200 seconds. It
passed the benefit criterion
    because its verified performance was 46.67860 times better than that of the
    baseline plan.
 2.
The plan was automatically accepted.

Recommendation:
-----------------------------
 Consider accepting the plan.



EXPLAIN PLANS SECTION
---------------------------------------------------------------------------------------------

Baseline Plan
-----------------------------
 Plan Id          : 130
 Plan
Hash Value  : 119432342

-----------------------------------------------------------------------------
| Id  | Operation           | Name         | Rows | Bytes | Cost | Time
|
-----------------------------------------------------------------------------
|   0 | SELECT STATEMENT    |              |    5 |    65 |   42 | 00:00:01 |
| * 1 |   TABLE ACCESS FULL | INVENTORIES2
|    5 |    65 |   42 | 00:00:01 |
-----------------------------------------------------------------------------

Predicate Information (identified by operation
id):
------------------------------------------
* 1 - filter("WAREHOUSE_ID"=999)


Test Plan
-----------------------------
 Plan Id          : 131
 Plan Hash Value  : 3836652582


------------------------------------------------------------------------------------------------
| Id  | Operation                             | Name          | Rows | Bytes | Cost | Time
|
------------------------------------------------------------------------------------------------
|   0 | SELECT STATEMENT                      |               |    5 |    65 |    2 | 00:00:01 |
|
1 |   TABLE ACCESS BY INDEX ROWID BATCHED | INVENTORIES2  |    5 |    65 |    2 | 00:00:01 |
| * 2 |    INDEX RANGE SCAN                   | INV2_WAREH_IX |    5 |       |    1 | 00:00:01
|
------------------------------------------------------------------------------------------------

Predicate Information (identified by operation id):
------------------------------------------
* 2 -
access("WAREHOUSE_ID"=999)

---------------------------------------------------------------------------------------------
--
-- verify the baseline if the plan has been accepted.
--
@display_soe_baselines.sql
--
-- observe that the plan is now accepted in the baseline.
--
SQL_HANDLE           SQL_TEXT                                           PLAN_NAME                      ENA ACC FIX  COST ELAPSED_TIME ORIGIN
-------------------- -------------------------------------------------- ------------------------------ --- --- --- ----- ------------ --------------------
SQL_115024ccba5e158c DELETE FROM PLAN_TABLE WHERE STATEMENT_ID=:1       SQL_PLAN_12n14tkx5w5cc52d2775d YES YES NO      2            0 AUTO-CAPTURE
SQL_1b81ebf40756e565 SELECT PT.VALUE FROM SYS.V_$SESSTAT PT WHERE PT.SI SQL_PLAN_1r0gbyh3pdtb52e8a86b7 YES YES NO      1            0 AUTO-CAPTURE
                     D=:1 AND PT.STATISTIC# IN (9,159,163,172,313,1879,
                     1880,1881,1889,1890) ORDER BY PT.STATISTIC#

SQL_294c437e331fa51f SELECT PLAN_TABLE_OUTPUT FROM TABLE(DBMS_XPLAN.DIS SQL_PLAN_2km23gstjz98zdf463620 YES YES NO     29            0 AUTO-CAPTURE
                     PLAY('PLAN_TABLE', :1))

SQL_2ed32f72ca911bc7 SELECT * FROM INVENTORIES2 WHERE WAREHOUSE_ID=999  SQL_PLAN_2xntgfb5926y7071e6496 YES YES NO     42        ##### MANUAL-LOAD-FROM-CUR
                                                                                                                                      SOR-CACHE

SQL_2ed32f72ca911bc7 SELECT * FROM INVENTORIES2 WHERE WAREHOUSE_ID=999  SQL_PLAN_2xntgfb5926y7e4aeac26 YES YES NO      2            0 AUTO-CAPTURE
--
--
SET AUTOT ON
SELECT * FROM INVENTORIES2 WHERE WAREHOUSE_ID=999;
SET AUTOT OFF
--
-- observe that the query is now using the Index by using  SQL_PLAN_2xntgfb5926y7e4aeac26 
-- instead of SQL_PLAN_2xntgfb5926y7071e6496
--
Execution Plan
----------------------------------------------------------
Plan hash value: 2186172278

-----------------------------------------------------------------------------------------------------
| Id  | Operation                           | Name          | Rows  | Bytes | Cost (%CPU)| Time     |
-----------------------------------------------------------------------------------------------------
|   0 | SELECT STATEMENT                    |               |     5 |    65 |     2   (0)| 00:00:01 |
|   1 |  TABLE ACCESS BY INDEX ROWID BATCHED| INVENTORIES2  |     5 |    65 |     2   (0)| 00:00:01 |
|*  2 |   INDEX RANGE SCAN                  | INV2_WAREH_IX |     5 |       |     1   (0)| 00:00:01 |
-----------------------------------------------------------------------------------------------------

Predicate Information (identified by operation id):
---------------------------------------------------

   2 - access("WAREHOUSE_ID"=999)

Note
-----
   - SQL plan baseline "SQL_PLAN_2xntgfb5926y7e4aeac26" used for this statement
--
-- clean up
--
@drop_baselines.sql
-- Drop the created index.
DROP INDEX SOE.INV2_WAREH_IX;
--
-- Manually evolve SQL plans into baselines using the Task model
-- by creating a SPM Evolve Advisor task which will all unaccepted plans
-- so far we have used DBMS_SPM.EVOLVE_SQL_PLAN_BASELINE to accept unaccepted plans 
--
-- Disable the automatic evolve process in the SPM Evolve advisor.
--
exec DBMS_SPM.SET_EVOLVE_TASK_PARAMETER(TASK_NAME => 'SYS_AUTO_SPM_EVOLVE_TASK', PARAMETER => 'ACCEPT_PLANS', VALUE => 'FALSE');
--
-- enable automatic SQL capture (optional)
--
ALTER SYSTEM SET OPTIMIZER_CAPTURE_SQL_PLAN_BASELINES=true;
--
-- flush the Shared Pool and Buffer cache
--
ALTER SYSTEM FLUSH SHARED_POOL;
ALTER SYSTEM FLUSH BUFFER_CACHE;
--
-- login as SOE and run the workload scripts twice.
--
set linesize 180
@execute_workload.sql
@execute_workload.sql
--
-- in the SOE window
--
CREATE INDEX SOE.CUST_LANGTER_IX ON CUSTOMERS(NLS_LANGUAGE,NLS_TERRITORY) NOLOGGING TABLESPACE SOETBS COMPUTE STATISTICS;
--
ALTER SYSTEM FLUSH SHARED_POOL;
ALTER SYSTEM FLUSH BUFFER_CACHE;
--
-- execute the workload again
--
@execute_workload.sql
--
-- In SYS window, check if unaccepted plan(s) have been added (but not evolved).
--
-- check their number:
SELECT COUNT(*) FROM DBA_SQL_PLAN_BASELINES WHERE PARSING_SCHEMA_NAME='SOE' AND ACCEPTED='NO';
--
  COUNT(*)
----------
         1
-- you can view its details:
@display_soe_baselines.sql
--
-- observe that there is a new plan in the SQL baseline which is not yet Accepted.
-- 
SQL_HANDLE           SQL_TEXT                                           PLAN_NAME                      ENA ACC FIX  COST ELAPSED_TIME ORIGIN
-------------------- -------------------------------------------------- ------------------------------ --- --- --- ----- ------------ --------------------
SQL_89b76415724b04a5 SELECT                                             SQL_PLAN_8mdv42pt4q1558d54e0d0 YES NO  NO      2            0 AUTO-CAPTURE
                        CUSTOMER_ID,
                        CUST_FIRST_NAME,
                        CUST_LAST_NAME,
                        NLS_LANGUAGE,
                        NLS_TERRITORY
                     FROM
                        CUSTOMERS C WHERE NLS_LANGUAGE=:V1 AND NLS_TERRITORY=:V2
--
-- create a Evolve advisor task that evolves all the unaccepted plans
--
set serveroutput on
VARIABLE V_TASK_NAME VARCHAR2(100);
DECLARE
V_PLAN_LIST DBMS_SPM.NAME_LIST := DBMS_SPM.NAME_LIST();
I NUMBER := 1;
BEGIN
-- construct list of unacceptable plans
   FOR P IN (SELECT PLAN_NAME FROM DBA_SQL_PLAN_BASELINES WHERE PARSING_SCHEMA_NAME='SOE' AND ACCEPTED='NO') LOOP
            V_PLAN_LIST(I) := P.PLAN_NAME;
         I := I + 1 ;
   END LOOP;
-- evolve the list
:  V_TASK_NAME := DBMS_SPM.CREATE_EVOLVE_TASK( PLAN_LIST =>V_PLAN_LIST, DESCRIPTION=>'Evolve SOE plans.');
   DBMS_OUTPUT.PUT_LINE(:V_TASK_NAME);
END;
/
--
-- to obtain further information about the created task:
--
col TASK_NAME format a10
col ADVISOR_NAME format a20
col DESCRIPTION format a20
col HOW_CREATED format a10
SELECT TASK_NAME, TASK_ID, ADVISOR_NAME, DESCRIPTION, HOW_CREATED FROM DBA_ADVISOR_TASKS
ORDER BY CREATED DESC FETCH FIRST 1 ROW ONLY ;
--
TASK_NAME     TASK_ID ADVISOR_NAME         DESCRIPTION          HOW_CREATE
---------- ---------- -------------------- -------------------- ----------
TASK_116          116 SPM Evolve Advisor   Evolve SOE plans.    CMD
--
-- ensure all unaccepted plans are evolved 
--                     
SELECT COUNT(*) FROM DBA_SQL_PLAN_BASELINES WHERE PARSING_SCHEMA_NAME='SOE' AND ACCEPTED='NO';
--
-- run the scrip again to display all baselines
-- 
@display_soe_baselines.sql
--
-- SQL_PLAN_8mdv42pt4q1558d54e0d0 plan is now accepted. Compare the cost between last two accepted plans. 
-- Second one is using Index hence has less costly.
-- 
--
SQL_HANDLE           SQL_TEXT                                           PLAN_NAME                      ENA ACC FIX  COST ELAPSED_TIME ORIGIN
-------------------- -------------------------------------------------- ------------------------------ --- --- --- ----- ------------ --------------------
SQL_0692bd3e196ddb0b SELECT                                             SQL_PLAN_0d4px7scqvqsbdaaa8792 YES YES NO   4908            0 AUTO-CAPTURE
                        ORDER_ID,
                        ORDER_DATE,
                        ORDER_TOTAL,
                        CUSTOMER_ID
                     FROM ORDERS WHERE ORDER_DATE BETWEEN TO_DATE(:V1,
                     'DD-MON-YYYY') AND TO_DATE(:V2, 'DD-MON-YYYY')

SQL_1c420c270e9af177 SELECT                                             SQL_PLAN_1shhc4w79pwbra631a3ef YES YES NO   4872            0 AUTO-CAPTURE
                        E.ENAME, SUM(O.ORDER_TOTAL) ORDER_TOTALS, AVG(O.O
                     RDER_TOTAL) AVERAGE_ORDER_TOTAL , COUNT(O.ORDER_ID
                     ) ORDERS_COUNT
                     FROM
                        ORDERS O, EMP E
                     WHERE
                        E.EMP_NO = O.SALES_REP_ID
                     GROUP BY E.ENAME
                     HAVING SUM(O.ORDER_TOTAL) > 10000
                     ORDER BY SUM(O.ORDER_TOTAL)

SQL_7200042bbd33328d SELECT                                             SQL_PLAN_740045fym6cnddaaa8792 YES YES NO   4915            0 AUTO-CAPTURE
                        ORDER_ID,
                        ORDER_DATE,
                        ORDER_TOTAL
                     FROM ORDERS WHERE ORDER_DATE BETWEEN TO_DATE(:V1,
                     'DD-MON-YYYY') AND TO_DATE(:V2, 'DD-MON-YYYY')

SQL_89b76415724b04a5 SELECT                                             SQL_PLAN_8mdv42pt4q15564541f84 YES YES NO    214            0 AUTO-CAPTURE
                        CUSTOMER_ID,
                        CUST_FIRST_NAME,
                        CUST_LAST_NAME,
                        NLS_LANGUAGE,
                        NLS_TERRITORY
                     FROM
                        CUSTOMERS C WHERE NLS_LANGUAGE=:V1 AND NLS_TERRIT
                     ORY=:V2

SQL_89b76415724b04a5 SELECT                                             SQL_PLAN_8mdv42pt4q1558d54e0d0 YES YES NO      2            0 AUTO-CAPTURE
                        CUSTOMER_ID,
                        CUST_FIRST_NAME,
                        CUST_LAST_NAME,
                        NLS_LANGUAGE,
                        NLS_TERRITORY
                     FROM
                        CUSTOMERS C WHERE NLS_LANGUAGE=:V1 AND NLS_TERRITORY=:V2
--
-- clean up
--
ALTER SYSTEM SET OPTIMIZER_CAPTURE_SQL_PLAN_BASELINES=false;
exec DBMS_SPM.SET_EVOLVE_TASK_PARAMETER(TASK_NAME => 'SYS_AUTO_SPM_EVOLVE_TASK', PARAMETER => 'ACCEPT_PLANS', VALUE => 'TRUE');
DELETE SQLLOG$;
DROP TABLE SOE.INVENTORIES2;
DROP INDEX SOE.CUST_LANGTER_IX;
@drop_baselines.sql