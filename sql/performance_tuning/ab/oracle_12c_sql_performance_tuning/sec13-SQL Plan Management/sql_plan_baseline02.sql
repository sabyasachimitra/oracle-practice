-- 
-- Examining How SQL Base Plans are used
--
-- log in as tkyte and issue the following commands
--
show parameter OPTIMIZER_USE_SQL_PLAN_BASELINES
--
NAME                                 TYPE        VALUE
------------------------------------ ----------- ---------
optimizer_use_sql_plan_baselines     boolean     TRUE
--
-- verify that there are no records in SQLLOG$
SELECT * FROM SQLLOG$;
--
             SIGNATURE     BATCH#
---------------------- ----------
   3374092715901918151          1
   7558992703032858492          1
--
-- view the plans stored in SQL Plan Baselines
--
@display_baseline_plans.sql
-- 
-- observe the access path of the execution plan.
--
PLAN_TABLE_OUTPUT
-------------------------------------------------------------------------------

-------------------------------------------------------------------------------
SQL handle: SQL_2ed32f72ca911bc7
SQL text: SELECT * FROM INVENTORIES2 WHERE WAREHOUSE_ID=999
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
Plan name: SQL_PLAN_2xntgfb5926y7071e6496         Plan id: 119432342
Enabled: YES     Fixed: NO      Accepted: YES     Origin: AUTO-CAPTURE
Plan rows: From dictionary
--------------------------------------------------------------------------------

Plan hash value: 999836115

------------------------------------------
| Id  | Operation         | Name         |
------------------------------------------
|   0 | SELECT STATEMENT  |              |
|   1 |  TABLE ACCESS FULL| INVENTORIES2 |
------------------------------------------
--
-- open another window and login as SOE
--
SET AUTOTRACE ON
SELECT * FROM INVENTORIES2 WHERE WAREHOUSE_ID=999;
--
Execution Plan
----------------------------------------------------------
Plan hash value: 999836115

----------------------------------------------------------------------------------
| Id  | Operation         | Name         | Rows  | Bytes | Cost (%CPU)| Time     |
----------------------------------------------------------------------------------
|   0 | SELECT STATEMENT  |              |   850 | 11050 |    42   (0)| 00:00:01 |
|*  1 |  TABLE ACCESS FULL| INVENTORIES2 |   850 | 11050 |    42   (0)| 00:00:01 |
----------------------------------------------------------------------------------
--
-- in SOE window
--
CREATE INDEX INV2_WAREH_IX ON INVENTORIES2(WAREHOUSE_ID) COMPUTE STATISTICS;
--
ALTER SYSTEM FLUSH SHARED_POOL;
--
-- run the query again
--
SET AUTOTRACE ON
SELECT * FROM INVENTORIES2 WHERE WAREHOUSE_ID=999;
SET AUTOTRACE OFF
--
-- observe that the index has not been used yet.
-- observe that the SQL has used the SQL baseline (which does not use the index).
----------------------------------------------------------
Execution Plan
----------------------------------------------------------
Plan hash value: 999836115

----------------------------------------------------------------------------------
| Id  | Operation         | Name         | Rows  | Bytes | Cost (%CPU)| Time     |
----------------------------------------------------------------------------------
|   0 | SELECT STATEMENT  |              |   850 | 11050 |    42   (0)| 00:00:01 |
|*  1 |  TABLE ACCESS FULL| INVENTORIES2 |   850 | 11050 |    42   (0)| 00:00:01 |
----------------------------------------------------------------------------------

Predicate Information (identified by operation id):
---------------------------------------------------

   1 - filter("WAREHOUSE_ID"=999)

Note
-----
   - SQL plan baseline "SQL_PLAN_2xntgfb5926y7071e6496" used for this statement
--
@display_soe_baselines.sql
-- 
-- observe that the plan of the second query is not yet accepted (ACC = NO) even though 
-- it's enabled and its cost ls 8x less than the first plan.
SQL_HANDLE           SQL_TEXT                                           ENA ACC FIX  COST DISK_READS BUFFER_GETS    FETCHES ELAPSED_TIME ORIGIN
-------------------- -------------------------------------------------- --- --- --- ----- ---------- ----------- ---------- ------------ -----------------------------
SQL_2ed32f72ca911bc7 SELECT * FROM INVENTORIES2 WHERE WAREHOUSE_ID=999  YES YES NO     42          0           0          0            0 AUTO-CAPTURE
SQL_2ed32f72ca911bc7 SELECT * FROM INVENTORIES2 WHERE WAREHOUSE_ID=999  YES NO  NO      5          0           0          0            0 AUTO-CAPTURE
--
-- 
-- run the following script to get the SQL execution plans of the two SQL queries
--
@display_baseline_plans.sql
--
--------------------------------------------------------------------------------
SQL handle: SQL_2ed32f72ca911bc7
SQL text: SELECT * FROM INVENTORIES2 WHERE WAREHOUSE_ID=999
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
Plan name: SQL_PLAN_2xntgfb5926y7071e6496         Plan id: 119432342
Enabled: YES     Fixed: NO      Accepted: YES     Origin: AUTO-CAPTURE
Plan rows: From dictionary
--------------------------------------------------------------------------------

Plan hash value: 999836115

------------------------------------------
| Id  | Operation         | Name         |
------------------------------------------
|   0 | SELECT STATEMENT  |              |
|   1 |  TABLE ACCESS FULL| INVENTORIES2 |
------------------------------------------
--
-- observe that the second query plan has used the index.
--
--------------------------------------------------------------------------------
SQL handle: SQL_2ed32f72ca911bc7
SQL text: SELECT * FROM INVENTORIES2 WHERE WAREHOUSE_ID=999
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
Plan name: SQL_PLAN_2xntgfb5926y7e4aeac26         Plan id: 3836652582
Enabled: YES     Fixed: NO      Accepted: NO      Origin: AUTO-CAPTURE
Plan rows: From dictionary
--------------------------------------------------------------------------------

Plan hash value: 2186172278

-------------------------------------------------------------
| Id  | Operation                           | Name          |
-------------------------------------------------------------
|   0 | SELECT STATEMENT                    |               |
|   1 |  TABLE ACCESS BY INDEX ROWID BATCHED| INVENTORIES2  |
|   2 |   INDEX RANGE SCAN                  | INV2_WAREH_IX |
-------------------------------------------------------------
--
--
-- SQL Plan Evolution :: You may have some unaccepted plans in SQL Plan history. The SQL plans in SQL Plan history come from 
-- SQL Plan capture process. The unaccepted plans could have the same or lower cost than the existing plans in baseline.
--
-- Plan Evolution is a process whereby lower or same cost plans in SQL Plan history are verified and accepted in 
-- SQL Plan Baseline and this enabling the Optimizer to use them when the SQL gets executed.
--
-- By default, SYS_AUTO_SPM_EVOLVE_TASK task runs daily in the scheduled maintenance window as part of Autimatic SQL Tuning advisor.
--
-- SPM Evolve task can be enabled or disabled by enabling or disabling the Automatic SQL Tuning Advisor
--
-- display SPM Evolve task parameters
--
linesize 180
col PARAMETER_NAME format a30
col VALUE format a30
col DESCRIPTION format a85
SELECT PARAMETER_NAME, PARAMETER_VALUE AS "VALUE", DESCRIPTION
FROM DBA_ADVISOR_PARAMETERS
WHERE TASK_NAME = 'SYS_AUTO_SPM_EVOLVE_TASK'
AND PARAMETER_VALUE<>'UNUSED';
--
PARAMETER_NAME                 VALUE                          DESCRIPTION
------------------------------ ------------------------------ -------------------------------------------------------------------------------------
ALTERNATE_PLAN_LIMIT           UNLIMITED
ALTERNATE_PLAN_SOURCE          AUTO
ALTERNATE_PLAN_BASELINE        AUTO
ACCEPT_PLANS                   TRUE                           TRUE if SQL plan baselines should be accepted by the task, FALSE otherwise
DAYS_TO_EXPIRE                 UNLIMITED                      The expiration time in days for the current SQL Access Advisor task
JOURNALING                     INFORMATION                    Specifies logging of messages to the advisor journal
MODE                           COMPREHENSIVE                  Specifies either a limited or comprehensive analysis operation, where limited runs in
                                                               less time but may produce slightly lower quality results

TARGET_OBJECTS                 1                              Deprecated Parameter
TIME_LIMIT                     3600                           The maximum time that an analysis can execute
DEFAULT_EXECUTION_TYPE         SPM EVOLVE                     Tune the performance of SQL statements
EXECUTION_DAYS_TO_EXPIRE       30                             Specifies the expiration time in days for individual executions of the current task
--
-- -- Starting Automatic Evolve Advisor task manually
--
variable v varchar2(100)
exec :V := DBMS_SPM.EXECUTE_EVOLVE_TASK (task_name => 'SYS_AUTO_SPM_EVOLVE_TASK');
-- print out the name of the new execution
print :v
--
-- Display the baseline contents.
@display_soe_baselines.sql
--
-- observe that the second SQL base plna is accepted now (after running the SPM Evolve task).
--
SQL_HANDLE           SQL_TEXT                                           ENA ACC FIX  COST DISK_READS BUFFER_GETS    FETCHES ELAPSED_TIME ORIGIN
-------------------- -------------------------------------------------- --- --- --- ----- ---------- ----------- ---------- ------------ -----------------------------
SQL_2ed32f72ca911bc7 SELECT * FROM INVENTORIES2 WHERE WAREHOUSE_ID=999  YES YES NO     42          0           0          0            0 AUTO-CAPTURE
SQL_2ed32f72ca911bc7 SELECT * FROM INVENTORIES2 WHERE WAREHOUSE_ID=999  YES YES NO      5          0           0          0            0 AUTO-CAPTURE
--
EXEC_575
--
-- run the SQL in client window again
--
SET AUTOTRACE ON
SELECT * FROM INVENTORIES2 WHERE WAREHOUSE_ID=999;
--
-- observe that the optimizer has now used the INDEX access path (as part of new SQL Base Plan).
--
Execution Plan
----------------------------------------------------------
Plan hash value: 2186172278

-----------------------------------------------------------------------------------------------------
| Id  | Operation                           | Name          | Rows  | Bytes | Cost (%CPU)| Time     |
-----------------------------------------------------------------------------------------------------
|   0 | SELECT STATEMENT                    |               |   850 | 11050 |     5   (0)| 00:00:01 |
|   1 |  TABLE ACCESS BY INDEX ROWID BATCHED| INVENTORIES2  |   850 | 11050 |     5   (0)| 00:00:01 |
|*  2 |   INDEX RANGE SCAN                  | INV2_WAREH_IX |   850 |       |     2   (0)| 00:00:01 |
-----------------------------------------------------------------------------------------------------

Predicate Information (identified by operation id):
---------------------------------------------------

   2 - access("WAREHOUSE_ID"=999)

Note
-----
   - SQL plan baseline "SQL_PLAN_2xntgfb5926y7e4aeac26" used for this statement
--
--
-- Display a report about the last execution performed by the advisor.
--
set long 1000000 pagesize 1000 longchunksize 100
SELECT DBMS_SPM.REPORT_AUTO_EVOLVE_TASK FROM DUAL;
--
--
REPORT_AUTO_EVOLVE_TASK
----------------------------------------------------------------------------------------------------
GENERAL INFORMATION SECTION
---------------------------------------------------------------------------------------------

 Task Information:
 ---------------------------------------------
 Task Name            : SYS_AUTO_SPM_EVOLVE_TASK
 Task Owner           : SYS
 Description          : Automatic SPM Evolve Task
 Execution Name       : EXEC_575
 Execution Type       : SPM EVOLVE
 Scope                : COMPREHENSIVE
 Status               : COMPLETED
 Started              : 09/17/2022 01:03:35
 Finished             : 09/17/2022 01:03:35
 Last Updated         : 09/17/2022 01:03:35
 Global Time Limit    : 3600
 Per-Plan Time Limit  : UNUSED
 Number of Errors     : 0
---------------------------------------------------------------------------------------------

SUMMARY SECTION
---------------------------------------------------------------------------------------------
  Number of plans processed  : 1
  Number of findings         : 2
  Number of recommendations  : 1
  Number of errors           : 0
---------------------------------------------------------------------------------------------

DETAILS SECTION
---------------------------------------------------------------------------------------------
 Object ID          : 2
 Test Plan Name     : SQL_PLAN_2xntgfb5926y7e4aeac26
 Base Plan Name     : SQL_PLAN_2xntgfb5926y7071e6496
 SQL Handle         : SQL_2ed32f72ca911bc7
 Parsing Schema     : SOE
 Test Plan Creator  : SOE
 SQL Text           : SELECT * FROM INVENTORIES2 WHERE WAREHOUSE_ID=999

Execution Statistics:
-----------------------------
                    Base Plan                     Test Plan
                    ----------------------------  ----------------------------
 Elapsed Time (s):  .000043                       .000001
 CPU Time (s):      .000006                       .000001
 Buffer Gets:       14                            0
 Optimizer Cost:    42                            5
 Disk Reads:        0                             0
 Direct Writes:     0                             0
 Rows Processed:    0                             0
 Executions:        10                            10


FINDINGS SECTION
---------------------------------------------------------------------------------------------

Findings (2):
-----------------------------
 1. The plan was verified in 0.15100 seconds. It passed the benefit criterion
    because its verified performance was 46.65616 times better than that of the
    baseline plan.
 2. The plan was automatically accepted.

Recommendation:
-----------------------------
 Consider accepting the plan. Execute
 dbms_spm.accept_sql_plan_baseline(task_name => 'SYS_AUTO_SPM_EVOLVE_TASK',
 object_id => 2, task_owner => 'SYS');


EXPLAIN PLANS SECTION
---------------------------------------------------------------------------------------------

Baseline Plan
-----------------------------
 Plan Id          : 128
 Plan Hash Value  : 119432342

-----------------------------------------------------------------------------
| Id  | Operation           | Name         | Rows | Bytes | Cost | Time     |
-----------------------------------------------------------------------------
|   0 | SELECT STATEMENT    |              |  850 | 11050 |   42 | 00:00:01 |
| * 1 |   TABLE ACCESS FULL | INVENTORIES2 |  850 | 11050 |   42 | 00:00:01 |
-----------------------------------------------------------------------------

Predicate Information (identified by operation id):
------------------------------------------
* 1 - filter("WAREHOUSE_ID"=999)


Test Plan
-----------------------------
 Plan Id          : 129
 Plan Hash Value  : 3836652582

------------------------------------------------------------------------------------------------
| Id  | Operation                             | Name          | Rows | Bytes | Cost | Time     |
------------------------------------------------------------------------------------------------
|   0 | SELECT STATEMENT                      |               |  850 | 11050 |    5 | 00:00:01 |
|   1 |   TABLE ACCESS BY INDEX ROWID BATCHED | INVENTORIES2  |  850 | 11050 |    5 | 00:00:01 |
| * 2 |    INDEX RANGE SCAN                   | INV2_WAREH_IX |  850 |       |    2 | 00:00:01 |
------------------------------------------------------------------------------------------------

Predicate Information (identified by operation id):
------------------------------------------
* 2 - access("WAREHOUSE_ID"=999)
--
--
-- Making baseline as Fixed:: when you make a SQL Baseline plan Fixed, it's always picked up 
-- by the Optimizer among all other Accepted plans. 
-- 
-- display the plans:
--
@display_baseline_plans.sql
--
-------------------------------------------------------------
SQL handle: SQL_2ed32f72ca911bc7
SQL text: SELECT * FROM INVENTORIES2 WHERE WAREHOUSE_ID=999
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
Plan name: SQL_PLAN_2xntgfb5926y7071e6496         Plan id: 119432342
Enabled: YES     Fixed: NO      Accepted: YES     Origin: AUTO-CAPTURE
Plan rows: From dictionary
--------------------------------------------------------------------------------

Plan hash value: 999836115

------------------------------------------
| Id  | Operation         | Name         |
------------------------------------------
|   0 | SELECT STATEMENT  |              |
|   1 |  TABLE ACCESS FULL| INVENTORIES2 |
------------------------------------------

--------------------------------------------------------------------------------
SQL handle: SQL_2ed32f72ca911bc7
SQL text: SELECT * FROM INVENTORIES2 WHERE WAREHOUSE_ID=999
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
Plan name: SQL_PLAN_2xntgfb5926y7e4aeac26         Plan id: 3836652582
Enabled: YES     Fixed: NO      Accepted: YES     Origin: AUTO-CAPTURE
Plan rows: From dictionary
--------------------------------------------------------------------------------

Plan hash value: 2186172278

-------------------------------------------------------------
| Id  | Operation                           | Name          |
-------------------------------------------------------------
|   0 | SELECT STATEMENT                    |               |
|   1 |  TABLE ACCESS BY INDEX ROWID BATCHED| INVENTORIES2  |
|   2 |   INDEX RANGE SCAN                  | INV2_WAREH_IX |
--------------------------------------------------------------------------------
--
-- identify the plan you want Fix.
-- and mark it as fixed as follows
--
set serveroutput on
DECLARE
CNT PLS_INTEGER;
BEGIN
   CNT := DBMS_SPM.ALTER_SQL_PLAN_BASELINE ( SQL_HANDLE =>'&Enter_SQL_HANDLE',PLAN_NAME => '&Enter_Plan_Name', ATTRIBUTE_NAME =>'fixed',ATTRIBUTE_VALUE =>'YES');
   IF CNT > 0 THEN
      DBMS_OUTPUT.PUT_LINE('SQL FIXED mark is successfully set.');
   END IF;
END;
/
SQL FIXED mark is successfully set.
--
-- verify if the SQL plan is fixed now.
--
@display_soe_baselines.sql
--
SQL_HANDLE           SQL_TEXT                                           ENA ACC FIX  COST DISK_READS BUFFER_GETS    FETCHES ELAPSED_TIME ORIGIN
-------------------- -------------------------------------------------- --- --- --- ----- ---------- ----------- ---------- ------------ -----------------------------
SQL_fa263bf03f6bae7f SELECT DISTINCT SID FROM V$MYSTAT                  YES YES NO      1          0           0          0            0 AUTO-CAPTURE
SQL_2ed32f72ca911bc7 SELECT * FROM INVENTORIES2 WHERE WAREHOUSE_ID=999  YES YES NO     42          0           0          0            0 AUTO-CAPTURE
SQL_2ed32f72ca911bc7 SELECT * FROM INVENTORIES2 WHERE WAREHOUSE_ID=999  YES YES YES     5          0           0          0            0 AUTO-CAPTURE
--
-- Clean up
--
-- Disable the automatic SQL plan capture
ALTER SYSTEM SET OPTIMIZER_CAPTURE_SQL_PLAN_BASELINES=false;
-- Delete all the baselines.
@drop_baselines.sql
-- Drop the created index.
DROP INDEX soe.INV2_WAREH_IX;
