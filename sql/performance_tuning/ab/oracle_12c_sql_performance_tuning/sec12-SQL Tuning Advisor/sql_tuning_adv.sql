--
-- Using SQL Tuning Advisor
-- Auto SQL Tuning Advisor job runs only at CDB level and does not run at PDB level in multitenant environment.
-- In a PDB, the Automatic SQL Tuning Advisor job is enabled:


--
-- However, the below code snippet of AUTO_SQL_TUNING_PROG shows the that it is disabled at PDB level.
SELECT PROGRAM_ACTION FROM DBA_SCHEDULER_PROGRAMS WHERE PROGRAM_NAME = 'AUTO_SQL_TUNING_PROG';
--
DECLARE
	  ename             VARCHAR2(30);
    exec_task         BOOLEAN;
BEGIN
         -- check if tuning pack is enabled
         exec_task := prvt_advisor.is_pack_enabled(dbms_management_packs.TUNING_PACK);

         -- check if we are in a pdb,
         -- since auto sqltune is not run in a pdb
         IF (exec_task AND -- tuning pack enabled
         sys_context('userenv', 'con_id') <> 0 AND -- not in non-cdb
         sys_context('userenv', 'con_id') <> 1  ) THEN -- not in root
           exec_task := FALSE;
         END IF;

         -- execute auto sql tuning task
         IF (exec_task) THEN
           ename := dbms_sqltune.execute_tuning_task(
                      'SYS_AUTO_SQL_TUNING_TASK');
         END IF;
END;
--
-- Setting up data
--
DROP TABLE SOE.ORDERS2;
CREATE TABLE 
	SOE.ORDERS2 
		(ORDER_ID NUMBER(12), ORDER_DATE TIMESTAMP(6) WITH LOCAL TIME ZONE, 
			ORDER_TOTAL NUMBER(8,2),ORDER_MODE VARCHAR2(8), 
			CUSTOMER_ID NUMBER(12), ORDER_STATUS NUMBER(2), 
			SALES_REP_ID NUMBER(6)
		);
--		
INSERT INTO SOE.ORDERS2 
	SELECT 
		ORDER_ID, ORDER_DATE, ORDER_TOTAL, ORDER_MODE,
		CUSTOMER_ID, ORDER_STATUS, SALES_REP_ID 
	FROM 
		SOE.ORDERS WHERE ORDER_TOTAL BETWEEN 10000 AND 15000;
--		
COMMIT;
--
--
-- If Statistics Level is Typical or ALL Automatic SQL Tuning Task is enabled by default.
-- If Statistics Level is BASIC Automatic SQL Tuning Task is disabled.
-- Login to CDB as SYS or a common user.
--
col CLIENT_NAME FORMAT a20
SELECT CLIENT_NAME, STATUS
FROM DBA_AUTOTASK_CLIENT WHERE CLIENT_NAME = 'sql tuning advisor';
--
CLIENT_NAME          STATUS
-------------------- --------
sql tuning advisor   ENABLED
--
-- Query the current Automatic SQL Tuning task settings
--
col PARAMETER_NAME FORMAT a25
col VALUE FORMAT a10
SELECT PARAMETER_NAME, PARAMETER_VALUE AS "VALUE"
FROM DBA_ADVISOR_PARAMETERS
WHERE ((TASK_NAME = 'SYS_AUTO_SQL_TUNING_TASK') AND
((PARAMETER_NAME LIKE '%PROFILE%') OR
(PARAMETER_NAME = 'LOCAL_TIME_LIMIT') OR
(PARAMETER_NAME = 'EXECUTION_DAYS_TO_EXPIRE')));
--
PARAMETER_NAME            VALUE
------------------------- ----------
EXECUTION_DAYS_TO_EXPIRE  30 -- in days
LOCAL_TIME_LIMIT          1200 -- per-statement time out (seconds)
ACCEPT_SQL_PROFILES       FALSE
MAX_SQL_PROFILES_PER_EXEC 20
MAX_AUTO_SQL_PROFILES     10000
--
-- Set SQL Tuning Task parameters
--
BEGIN
DBMS_SQLTUNE.SET_TUNING_TASK_PARAMETER ( TASK_NAME => 'SYS_AUTO_SQL_TUNING_TASK'
, PARAMETER => 'LOCAL_TIME_LIMIT' , VALUE => 1000 );
END;
/
-- verify:
SELECT PARAMETER_NAME, PARAMETER_VALUE AS "VALUE"
FROM DBA_ADVISOR_PARAMETERS
WHERE (TASK_NAME = 'SYS_AUTO_SQL_TUNING_TASK') AND (PARAMETER_NAME =
'LOCAL_TIME_LIMIT');
--
PARAMETER_NAME            VALUE
------------------------- ----------
LOCAL_TIME_LIMIT          1000
--
-- Run the following query to obtain information about the automatic 
-- maintenance task that kicks off the Automatic SQL Tuning Advisor
-- Observe the retrieved window group name.
--
set linesize 180
col "Auto SQL Tuning Task" format a100
SELECT 'STATUS: '|| STATUS || chr(10) || 'WINDOW_GROUP: '||WINDOW_GROUP ||
chr(10)|| 'MEAN_JOB_DURATION: '||MEAN_JOB_DURATION || chr(10)|| 'MEAN_JOB_CPU: '
|| MEAN_JOB_CPU ||chr(10)|| 'MAX_DURATION_LAST_7_DAYS: '||
MAX_DURATION_LAST_7_DAYS || chr(10)|| 'MAX_DURATION_LAST_30_DAYS:
'||MAX_DURATION_LAST_30_DAYS|| chr(10) as "Auto SQL Tuning Task"
FROM DBA_AUTOTASK_CLIENT
WHERE CLIENT_NAME='sql tuning advisor';
--
Auto SQL Tuning Task
----------------------------------------------------------------------------------------------------
STATUS: ENABLED
WINDOW_GROUP: ORA$AT_WGRP_SQ
MEAN_JOB_DURATION: +000000000 00:00:16.135135135
MEAN_JOB_CPU: +000000000 00:00:04.232162162
MAX_DURATION_LAST_7_DAYS: +000 00:00:16
MAX_DURATION_LAST_30_DAYS:
+000 00:00:27
--
-- Using the Window Group Name, run the following query to know the window of each run and next run date and time.
--
col WINDOW_NAME format a20
col REPEAT_INTERVAL format a55
col DURATION format a15
SELECT 
	WINDOW_NAME, 
	REPEAT_INTERVAL, 
	DURATION, 
	ENABLED,
	NEXT_START_DATE
FROM 
	DBA_SCHEDULER_WINDOWS DW
INNER JOIN 
	DBA_SCHEDULER_GROUP_MEMBERS DM
ON DW.WINDOW_NAME = REGEXP_SUBSTR(MEMBER_NAME, '\w+_\w+') AND
DM.GROUP_NAME='ORA$AT_WGRP_SQ'
ORDER BY DW.NEXT_START_DATE;
--
WINDOW_NAME          REPEAT_INTERVAL                                         DURATION        ENABL NEXT_START_DATE
-------------------- ------------------------------------------------------- --------------- ----- ---------------------------------------------------------------------------
WEDNESDAY_WINDOW     freq=daily;byday=WED;byhour=22;byminute=0; bysecond=0   +000 04:00:00   TRUE  17-AUG-22 10.00.00.000000 PM ASIA/CALCUTTA
THURSDAY_WINDOW      freq=daily;byday=THU;byhour=22;byminute=0; bysecond=0   +000 04:00:00   TRUE  18-AUG-22 10.00.00.000000 PM ASIA/CALCUTTA
FRIDAY_WINDOW        freq=daily;byday=FRI;byhour=22;byminute=0; bysecond=0   +000 04:00:00   TRUE  19-AUG-22 10.00.00.000000 PM ASIA/CALCUTTA
SATURDAY_WINDOW      freq=daily;byday=SAT;byhour=6;byminute=0; bysecond=0    +000 20:00:00   TRUE  20-AUG-22 06.00.00.000000 AM ASIA/CALCUTTA
SUNDAY_WINDOW        freq=daily;byday=SUN;byhour=6;byminute=0; bysecond=0    +000 20:00:00   TRUE  21-AUG-22 06.00.00.000000 AM ASIA/CALCUTTA
MONDAY_WINDOW        freq=daily;byday=MON;byhour=22;byminute=0; bysecond=0   +000 04:00:00   TRUE  22-AUG-22 10.00.00.000000 PM ASIA/CALCUTTA
TUESDAY_WINDOW       freq=daily;byday=TUE;byhour=22;byminute=0; bysecond=0   +000 04:00:00   TRUE  23-AUG-22 10.00.00.000000 PM ASIA/CALCUTTA

--
-- Generate a Text report to show all SQL statements that were analyzed in the 
-- most recent execution, including the recommendations that were not implemented.
-- report is based on the most recent execution.
--
set autot off
set linesize 200
set long 1000000 longchunksize 10000000
SPOOL C:\Users\Sabya\Documents\Technical\Udemy\barakhasqltuning\sql\sec11\sql_tuning_adv_rpt.txt
SELECT DBMS_AUTO_SQLTUNE.REPORT_AUTO_TUNING_TASK
FROM DUAL;
SPOOL OFF
--
-- Generate Automatic SQL Tuning Advisor Report based on a specific execution history. 
-- Run the following query to get all Execution History.
--
col EXEC_NAME format a10
col EXEC_START format a25
col EXEC_END format a20
col PERIOD_M format 999.99
col ERROR format a5
SELECT 
	EXECUTION_NAME EXEC_NAME, 
	TO_CHAR(EXECUTION_START,'DY DD-MON-YY HH24:MI:SS') EXEC_START, 
	TO_CHAR(EXECUTION_END,'DD-MON-YY HH24:MI:SS') EXEC_END,
	(EXECUTION_END-EXECUTION_START)*24*60 PERIOD_M , 
	STATUS,
	ERROR_MESSAGE ERROR
FROM 
	DBA_ADVISOR_EXECUTIONS
WHERE TASK_NAME = 'SYS_AUTO_SQL_TUNING_TASK'
ORDER BY EXECUTION_ID ASC;
--
-- The Auto SQL Tuning Advisor Task runs every weekday and weekends.
--
EXEC_NAME  EXEC_START                EXEC_END             PERIOD_M STATUS      ERROR
---------- ------------------------- -------------------- -------- ----------- -----
EXEC_1003  SAT 23-JUL-22 20:12:48    23-JUL-22 20:12:52        .07 COMPLETED
EXEC_1010  SUN 24-JUL-22 09:47:05    24-JUL-22 09:47:13        .13 COMPLETED
EXEC_1025  MON 25-JUL-22 22:10:35    25-JUL-22 22:10:46        .18 COMPLETED
EXEC_1032  FRI 29-JUL-22 00:30:05    29-JUL-22 00:30:30        .42 COMPLETED
EXEC_1037  FRI 29-JUL-22 22:00:01    29-JUL-22 22:00:06        .08 COMPLETED
EXEC_1045  SAT 30-JUL-22 14:14:50    30-JUL-22 14:15:06        .27 COMPLETED
EXEC_1059  SUN 31-JUL-22 10:23:55    31-JUL-22 10:24:11        .27 COMPLETED
EXEC_1080  TUE 02-AUG-22 22:00:02    02-AUG-22 22:00:03        .02 COMPLETED
EXEC_1095  WED 03-AUG-22 22:00:00    03-AUG-22 22:00:06        .10 COMPLETED
EXEC_1110  THU 04-AUG-22 22:00:02    04-AUG-22 22:00:13        .18 COMPLETED
EXEC_1120  SUN 14-AUG-22 14:55:48    14-AUG-22 14:55:58        .17 COMPLETED
EXEC_1133  MON 15-AUG-22 22:00:00    15-AUG-22 22:00:12        .20 COMPLETED
EXEC_1139  WED 17-AUG-22 22:00:00    17-AUG-22 22:00:16        .27 COMPLETED
--
-- If you want to generate a report for a particular execution, run the following query with the EXEC_NAME
--
define v_execname='EXEC_1032'
VARIABLE v_report CLOB;
BEGIN
	:v_report := DBMS_SQLTUNE.REPORT_AUTO_TUNING_TASK ( BEGIN_EXEC => '&v_execname', END_EXEC => '&v_execname', TYPE => 'TEXT',
							 LEVEL => 'TYPICAL', SECTION => 'ALL', OBJECT_ID => NULL, RESULT_LIMIT => NULL );
END;
/
SPOOL C:\Users\Sabya\Documents\Technical\Udemy\barakhasqltuning\sql\sec11\sql_tuning_adv_rpt_exec.txt
PRINT :v_report
SPOOL OFF
--
-- Manually invoking Auto SQL Tuning Advisor Task and note the EXEC_NAME
--
SET SERVEROUTPUT ON
DECLARE
	v_return VARCHAR2(20);
BEGIN
	v_return := DBMS_AUTO_SQLTUNE.EXECUTE_AUTO_TUNING_TASK;
	DBMS_OUTPUT.put_line(v_return);
END;
/
-- Output :: EXEC_NAME
--
EXEC_1144
--
SELECT 
	EXECUTION_NAME EXEC_NAME, 
	TO_CHAR(EXECUTION_START,'DY DD-MON-YY HH24:MI:SS') EXEC_START, 
	TO_CHAR(EXECUTION_END,'DD-MON-YY HH24:MI:SS') EXEC_END,
	(EXECUTION_END-EXECUTION_START)*24*60 PERIOD_M , STATUS,ERROR_MESSAGE ERROR
FROM 
	DBA_ADVISOR_EXECUTIONS
WHERE TASK_NAME = 'SYS_AUTO_SQL_TUNING_TASK' AND EXECUTION_NAME ='&enter_exec_name';
--
--
EXEC_NAME  EXEC_START                EXEC_END             PERIOD_M STATUS      ERROR
---------- ------------------------- -------------------- -------- ----------- -----
EXEC_1144  THU 18-AUG-22 00:41:22    18-AUG-22 00:41:23        .02 COMPLETED
--
--
-- User Defined SQL Tuning Advisor Task (creation, configuring, running, tracking and accepting recommendations)
-- Log in as soe user to db19c01 database
--
VARIABLE V_TOTAL NUMBER
EXEC :V_TOTAL := 10050;
SET AUTOT ON
SELECT COUNT(*) FROM SOE.ORDERS2 WHERE ORDER_TOTAL <:V_TOTAL;
--
  COUNT(*)
----------
      1762

Execution Plan
----------------------------------------------------------
Plan hash value: 508073128

------------------------------------------------------------------------------
| Id  | Operation          | Name    | Rows  | Bytes | Cost (%CPU)| Time     |
------------------------------------------------------------------------------
|   0 | SELECT STATEMENT   |         |     1 |    13 |   310   (1)| 00:00:01 |
|   1 |  SORT AGGREGATE    |         |     1 |    13 |            |          |
|*  2 |   TABLE ACCESS FULL| ORDERS2 | 10625 |   134K|   310   (1)| 00:00:01 |
------------------------------------------------------------------------------

Predicate Information (identified by operation id):
---------------------------------------------------

   2 - filter("ORDER_TOTAL"<TO_NUMBER(:V_TOTAL))

Note
-----
   - dynamic statistics used: dynamic sampling (level=2)


Statistics
----------------------------------------------------------
         69  recursive calls
          8  db block gets
       1249  consistent gets
       1086  physical reads
       1212  redo size
        360  bytes sent via SQL*Net to client
        418  bytes received via SQL*Net from client
          2  SQL*Net roundtrips to/from client
          7  sorts (memory)
          0  sorts (disk)
          1  rows processed
--
-- Create a new SQL Tuning Advisor task
--
SET AUTOT OFF
DECLARE
	V_TASK_NAME VARCHAR2(30);
	V_SQLTEXT CLOB;
BEGIN
	V_SQLTEXT := 'SELECT * FROM SOE.ORDERS2 WHERE ORDER_TOTAL <:V_TOTAL';
	V_TASK_NAME := DBMS_SQLTUNE.CREATE_TUNING_TASK (
	SQL_TEXT => V_SQLTEXT,
	BIND_LIST => SQL_BINDS(ANYDATA.CONVERTNUMBER(10050)),
	USER_NAME => 'SOE',
	SCOPE => 'COMPREHENSIVE',
	TIME_LIMIT => NULL,
	TASK_NAME => 'STA_ORDERS2_TASK',
	DESCRIPTION => 'A sample STA tuning task');
END;
/
--
-- Verify that the task is created and save the task ID
--
col TASK_ID FORMAT 999999
col TASK_NAME FORMAT a25
col STATUS_MESSAGE FORMAT a33
SELECT TASK_ID, TASK_NAME, STATUS, STATUS_MESSAGE FROM USER_ADVISOR_LOG WHERE
TASK_NAME='STA_ORDERS2_TASK';
--
TASK_ID TASK_NAME                 STATUS      STATUS_MESSAGE
------- ------------------------- ----------- ---------------------------------
    101 STA_ORDERS2_TASK          INITIAL
--
VARIABLE v_tid NUMBER;
exec :v_tid := 101
--
-- Display all the task parameters and their values
--
col PARAMETER_NAME FORMAT a25
col VALUE FORMAT a15
SELECT 
	PARAMETER_NAME, PARAMETER_VALUE AS "VALUE"
FROM 
	USER_ADVISOR_PARAMETERS
WHERE TASK_NAME = 'STA_ORDERS2_TASK' AND PARAMETER_VALUE != 'UNUSED'
ORDER BY PARAMETER_NAME;
--
PARAMETER_NAME            VALUE
------------------------- ---------------
DAYS_TO_EXPIRE            30
DEFAULT_EXECUTION_TYPE    TUNE SQL
EXECUTION_DAYS_TO_EXPIRE  UNLIMITED
JOURNALING                INFORMATION
MODE                      COMPREHENSIVE
SQL_LIMIT                 -1
SQL_PERCENTAGE            1
TARGET_OBJECTS            1
TEST_EXECUTE              AUTO
TIME_LIMIT                1800
--
-- Change the TIME_LIMIT parameter to 300
--
BEGIN
	DBMS_SQLTUNE.SET_TUNING_TASK_PARAMETER (TASK_NAME => 'STA_ORDERS2_TASK', PARAMETER => 'TIME_LIMIT', VALUE => 300);
END;
/
--
SELECT 
	PARAMETER_NAME, PARAMETER_VALUE AS "VALUE"
FROM 
	DBA_ADVISOR_PARAMETERS
WHERE TASK_NAME = 'STA_ORDERS2_TASK' AND PARAMETER_VALUE != 'UNUSED' AND PARAMETER_NAME = 'TIME_LIMIT'
ORDER BY PARAMETER_NAME;
--
PARAMETER_NAME            VALUE
------------------------- ---------------
TIME_LIMIT                300
--
-- Execute the task
--
exec DBMS_SQLTUNE.EXECUTE_TUNING_TASK(TASK_NAME=>'STA_ORDERS2_TASK');
--
-- Check the status of the task with the following two queries
--
SELECT STATUS FROM USER_ADVISOR_TASKS WHERE TASK_NAME = 'STA_ORDERS2_TASK';
--
STATUS
-----------
COMPLETED
--
SELECT TASK_ID, TASK_NAME, STATUS, STATUS_MESSAGE FROM USER_ADVISOR_LOG WHERE
TASK_NAME='STA_ORDERS2_TASK';
--
TASK_ID TASK_NAME                 STATUS      STATUS_MESSAGE
------- ------------------------- ----------- ---------------------------------
    101 STA_ORDERS2_TASK          COMPLETED
--
-- Log in as tkye in a different session and run the following query to check the status of a task 
-- This can be monitored from the same session by soe too.
--
col ADVISOR_NAME FORMAT a20
col SOFAR FORMAT 999
col TOTALWORK FORMAT 999
SELECT 
	TASK_ID, 
	ADVISOR_NAME, 
	SOFAR, 
	TOTALWORK, 
	ROUND(SOFAR/TOTALWORK*100,2) "%_COMPLETE"
FROM V$ADVISOR_PROGRESS
WHERE TASK_ID = 101;
--
   TASK_ID ADVISOR_NAME         SOFAR TOTALWORK %_COMPLETE
---------- -------------------- ----- --------- ----------
       101 SQL Tuning Advisor       1         1        100

-- Create the SQL Tuning task report and check the recommendation
--
SET LONG 50000
SET LONGCHUNKSIZE 1000
SET LINESIZE 100
SELECT DBMS_SQLTUNE.REPORT_TUNING_TASK( OWNER_NAME => 'SOE',TASK_NAME => 'STA_ORDERS2_TASK' ) FROM DUAL;
--
DBMS_SQLTUNE.REPORT_TUNING_TASK(OWNER_NAME=>'SOE',TASK_NAME=>'STA_ORDERS2_TASK')
----------------------------------------------------------------------------------------------------
GENERAL INFORMATION SECTION
-------------------------------------------------------------------------------
Tuning Task Name   : STA_ORDERS2_TASK
Tuning Task Owner  : SOE
Workload Type      : Single SQL Statement
Scope              : COMPREHENSIVE
Time Limit(seconds): 300
Completion Status  : COMPLETED
Started at         : 08/19/2022 00:36:30
Completed at       : 08/19/2022 00:36:31

-------------------------------------------------------------------------------
Schema Name   : SOE
Container Name: DB19C01
SQL ID        : am219fatany97
SQL Text      : SELECT * FROM SOE.ORDERS2 WHERE ORDER_TOTAL <:V_TOTAL
Bind Variables: :
 1 -  (NUMBER):10050

-------------------------------------------------------------------------------
FINDINGS SECTION (1 finding)
-------------------------------------------------------------------------------

1- Statistics Finding
---------------------
  Table "SOE"."ORDERS2" was not analyzed.

  Recommendation
  --------------
  - Consider collecting optimizer statistics for this table.
    execute dbms_stats.gather_table_stats(ownname => 'SOE', tabname =>
            'ORDERS2', estimate_percent => DBMS_STATS.AUTO_SAMPLE_SIZE,
            method_opt => 'FOR ALL COLUMNS SIZE AUTO');

  Rationale
  ---------
    The optimizer requires up-to-date statistics for the table in order to
    select a good execution plan.

-------------------------------------------------------------------------------
EXPLAIN PLANS SECTION
-------------------------------------------------------------------------------

1- Original
-----------
Plan hash value: 893590499

-----------------------------------------------------------------------------
| Id  | Operation         | Name    | Rows  | Bytes | Cost (%CPU)| Time     |
-----------------------------------------------------------------------------
|   0 | SELECT STATEMENT  |         |  1626 |   133K|   309   (1)| 00:00:01 |
|*  1 |  TABLE ACCESS FULL| ORDERS2 |  1626 |   133K|   309   (1)| 00:00:01 |
-----------------------------------------------------------------------------

Predicate Information (identified by operation id):
---------------------------------------------------

   1 - filter("ORDER_TOTAL"<:V_TOTAL)

-------------------------------------------------------------------------------
--
-- Run the gather statistics as per the SQL Tuning Advisor
--
execute dbms_stats.gather_table_stats(ownname => 'SOE', tabname => 'ORDERS2', estimate_percent => DBMS_STATS.AUTO_SAMPLE_SIZE, method_opt => 'FOR ALL COLUMNS SIZE AUTO');
--
-- Execute the SQL Tuning Task again
exec DBMS_SQLTUNE.EXECUTE_TUNING_TASK(TASK_NAME=>'STA_ORDERS2_TASK');
--
SET LONG 5000
SET LONGCHUNKSIZE 1000
SET LINESIZE 100
SELECT DBMS_SQLTUNE.REPORT_TUNING_TASK('STA_ORDERS2_TASK' ) FROM DUAL;
--
-- There is no recommendation now
--
DBMS_SQLTUNE.REPORT_TUNING_TASK('STA_ORDERS2_TASK')
----------------------------------------------------------------------------------------------------
GENERAL INFORMATION SECTION
-------------------------------------------------------------------------------
Tuning Task Name   : STA_ORDERS2_TASK
Tuning Task Owner  : SOE
Workload Type      : Single SQL Statement
Execution Count    : 2
Current Execution  : EXEC_517
Execution Type     : TUNE SQL
Scope              : COMPREHENSIVE
Time Limit(seconds): 300
Completion Status  : COMPLETED
Started at         : 08/19/2022 20:43:39
Completed at       : 08/19/2022 20:43:40

-------------------------------------------------------------------------------
Schema Name   : SOE
Container Name: DB19C01
SQL ID        : am219fatany97
SQL Text      : SELECT * FROM SOE.ORDERS2 WHERE ORDER_TOTAL <:V_TOTAL
Bind Variables: :
 1 -  (NUMBER):10050

-------------------------------------------------------------------------------
There are no recommendations to improve the statement.

-------------------------------------------------------------------------------
--
-- You can generate a script to run the recommendations
--
SELECT DBMS_SQLTUNE.SCRIPT_TUNING_TASK(TASK_NAME=>'STA_ORDERS2_TASK', REC_TYPE=>'ALL') script FROM DUAL;
--
-- Run the SQL again
--
VARIABLE V_TOTAL NUMBER
EXEC :V_TOTAL := 10050;
SET AUTOT ON
SELECT COUNT(*) FROM SOE.ORDERS2 WHERE ORDER_TOTAL <:V_TOTAL;
SET AUTOT OFF
--
--
  COUNT(*)
----------
      1762

-- As you can see thre is not much improvement in Execution plan even after implementing 
-- the recommendation. This is an example why SQL Tuning Advisor is not always sufficient.

Execution Plan
----------------------------------------------------------
Plan hash value: 508073128

------------------------------------------------------------------------------
| Id  | Operation          | Name    | Rows  | Bytes | Cost (%CPU)| Time     |
------------------------------------------------------------------------------
|   0 | SELECT STATEMENT   |         |     1 |     5 |   310   (1)| 00:00:01 |
|   1 |  SORT AGGREGATE    |         |     1 |     5 |            |          |
|*  2 |   TABLE ACCESS FULL| ORDERS2 | 10031 | 50155 |   310   (1)| 00:00:01 |
------------------------------------------------------------------------------

Predicate Information (identified by operation id):
---------------------------------------------------

   2 - filter("ORDER_TOTAL"<TO_NUMBER(:V_TOTAL))


Statistics
----------------------------------------------------------
          1  recursive calls
          0  db block gets
       1073  consistent gets
          0  physical reads
          0  redo size
        360  bytes sent via SQL*Net to client
        418  bytes received via SQL*Net from client
          2  SQL*Net roundtrips to/from client
          0  sorts (memory)
          0  sorts (disk)
          1  rows processed
--
-- To improve the query create an index 
--
CREATE INDEX SOE.ORDERS2_TOTAL_IX ON SOE.ORDERS2(ORDER_TOTAL);
--
EXEC :V_TOTAL := 10050;
SET AUTOT ON
SELECT COUNT(*) FROM SOE.ORDERS2 WHERE ORDER_TOTAL <:V_TOTAL;
SET AUTOT OFF
--
--
-- The Cost reduced substantially. The consistent get reduced by around 1000 times. 
--
Execution Plan
----------------------------------------------------------
Plan hash value: 1414358200

--------------------------------------------------------------------------------------
| Id  | Operation         | Name             | Rows  | Bytes | Cost (%CPU)| Time     |
--------------------------------------------------------------------------------------
|   0 | SELECT STATEMENT  |                  |     1 |     5 |     6   (0)| 00:00:01 |
|   1 |  SORT AGGREGATE   |                  |     1 |     5 |            |          |
|*  2 |   INDEX RANGE SCAN| ORDERS2_TOTAL_IX | 10031 | 50155 |     6   (0)| 00:00:01 |
--------------------------------------------------------------------------------------

Predicate Information (identified by operation id):
---------------------------------------------------

   2 - access("ORDER_TOTAL"<TO_NUMBER(:V_TOTAL))

Statistics
----------------------------------------------------------
          1  recursive calls
          0  db block gets
          5  consistent gets
          4  physical reads
          0  redo size
        360  bytes sent via SQL*Net to client
        418  bytes received via SQL*Net from client
          2  SQL*Net roundtrips to/from client
          0  sorts (memory)
          0  sorts (disk)
          1  rows processed

--
-- Drop the task
--
exec DBMS_SQLTUNE.DROP_TUNING_TASK(TASK_NAME => 'STA_ORDERS2_TASK');
--
-- Create SQL Tuning Task from Cusrsor Cache using SQL ID
--
-- Run the following SQL
--
DROP TABLE SOE.ORDERS2;
CREATE TABLE 
	SOE.ORDERS2 
		(ORDER_ID NUMBER(12), ORDER_DATE TIMESTAMP(6) WITH LOCAL TIME ZONE, 
			ORDER_TOTAL NUMBER(8,2),ORDER_MODE VARCHAR2(8), 
			CUSTOMER_ID NUMBER(12), ORDER_STATUS NUMBER(2), 
			SALES_REP_ID NUMBER(6)
		);
--
INSERT INTO SOE.ORDERS2 
	SELECT 
		ORDER_ID, ORDER_DATE, ORDER_TOTAL, ORDER_MODE,
		CUSTOMER_ID, ORDER_STATUS, SALES_REP_ID 
	FROM 
		SOE.ORDERS;
--		
COMMIT;
--
SET FEEDBACK ON SQL_ID;
SELECT /* ORDERS2_SUM */ SUM(ORDER_TOTAL) FROM SOE.ORDERS2;
--
SUM(ORDER_TOTAL)
----------------
      9906451075

1 row selected.

SQL_ID: b61jmhp49zjtp
--
SET FEEDBACK OFF SQL_ID;
--
-- Create the SQL Tuning Task from Cursor cach using the SQL ID
--
DECLARE
  v_sql_tune_task_id  VARCHAR2(100);
BEGIN
  v_sql_tune_task_id := DBMS_SQLTUNE.create_tuning_task (
                          sql_id      => 'b61jmhp49zjtp',
                          scope       => DBMS_SQLTUNE.scope_comprehensive,
                          time_limit  => 1000,
                          task_name   => 'test_tuning_task',
                          description => 'Tuning task for the SQL statement with the ID:b61jmhp49zjtp from the cursor cache');
  DBMS_OUTPUT.put_line('v_sql_tune_task_id: ' || v_sql_tune_task_id);
END;
/
--
-- Execute the Tuning task
--
EXECUTE DBMS_SQLTUNE.execute_tuning_task(task_name => 'test_tuning_task'); 
--
-- Get the SQL Tuning task report
--
SET LONG 5000
SET LONGCHUNKSIZE 1000
SET LINESIZE 100
SELECT DBMS_SQLTUNE.REPORT_TUNING_TASK('test_tuning_task' ) FROM DUAL;
--
--
----------------------------------------------------------------------------------------------------
GENERAL INFORMATION SECTION
-------------------------------------------------------------------------------
Tuning Task Name   : test_tuning_task
Tuning Task Owner  : SOE
Workload Type      : Single SQL Statement
Scope              : COMPREHENSIVE
Time Limit(seconds): 1000
Completion Status  : COMPLETED
Started at         : 08/23/2022 01:25:39
Completed at       : 08/23/2022 01:25:39

-------------------------------------------------------------------------------
Schema Name   : SOE
Container Name: DB19C01
SQL ID        : b61jmhp49zjtp
SQL Text      : SELECT /* ORDERS2_SUM */ SUM(ORDER_TOTAL) FROM SOE.ORDERS2

-------------------------------------------------------------------------------
FINDINGS SECTION (1 finding)
-------------------------------------------------------------------------------

1- Statistics Finding
---------------------
  Table "SOE"."ORDERS2" was not analyzed.

  Recommendation
  --------------
  - Consider collecting optimizer statistics for this table.
    execute dbms_stats.gather_table_stats(ownname => 'SOE', tabname =>
            'ORDERS2', estimate_percent => DBMS_STATS.AUTO_SAMPLE_SIZE,
            method_opt => 'FOR ALL COLUMNS SIZE AUTO');

  Rationale
  ---------
    The optimizer requires up-to-date statistics for the table in order to
    select a good execution plan.

-------------------------------------------------------------------------------
EXPLAIN PLANS SECTION
-------------------------------------------------------------------------------

1- Original
-----------
Plan hash value: 508073128

------------------------------------------------------------------------------
| Id  | Operation          | Name    | Rows  | Bytes | Cost (%CPU)| Time     |
------------------------------------------------------------------------------
|   0 | SELECT STATEMENT   |         |     1 |    13 |  1956   (1)| 00:00:01 |
|   1 |  SORT AGGREGATE    |         |     1 |    13 |            |          |
|   2 |   TABLE ACCESS FULL| ORDERS2 |  1460K|    18M|  1956   (1)| 00:00:01 |
------------------------------------------------------------------------------
--
--
-- Create SQL Tuning Task from SQL Tuning Set
--
-- Create SQL Tuning Set (in Tkyte Window)
--
exec DBMS_SQLTUNE.DROP_SQLSET( SQLSET_NAME => 'SOE_WKLD_STS',SQLSET_OWNER=>'SOE');
exec DBMS_SQLTUNE.CREATE_SQLSET (SQLSET_NAME => 'SOE_WKLD_STS', SQLSET_OWNER=>'SOE', DESCRIPTION => 'SOE Workload to tune' );
--
-- Check if SQL Tuning Set is created.
--
col NAME FORMAT a15
col COUNT FORMAT 99999
col DESCRIPTION FORMAT a40
SELECT 
	NAME, 
	STATEMENT_COUNT AS "SQLCNT", 
	DESCRIPTION 
FROM 
	DBA_SQLSET WHERE
NAME='SOE_WKLD_STS';
--
-- In the Tkyte window run the following to initiate the capture of Shared SQL area into the SQL Tuning set every 3 seconds 
-- for 120 seconds. During the capture period, the SQL statements that satisfy the condition in the command below and running 
-- in the shared pool are captured and loaded into the STS.
--
BEGIN
	DBMS_SQLTUNE.CAPTURE_CURSOR_CACHE_SQLSET( SQLSET_NAME => 'SOE_WKLD_STS', SQLSET_OWNER=>'SOE',
	TIME_LIMIT => 120, REPEAT_INTERVAL => 3, BASIC_FILTER =>' UPPER(PARSING_SCHEMA_NAME) = ''SOE'' AND MODULE = ''TESTING_SESSION''',
	CAPTURE_MODE => DBMS_SQLTUNE.MODE_REPLACE_OLD_STATS);
END;
/
--
-- In the Client window (SOE), set the Module Name by which the block of SQL will be identified by SQL Tuning Capture.
--
BEGIN
	DBMS_APPLICATION_INFO.SET_MODULE( MODULE_NAME => 'TESTING_SESSION', ACTION_NAME=>NULL);
END;
/
--
DECLARE 
	v_month_year VARCHAR2(7);
	v VARCHAR2(20);
BEGIN
	v_month_year := '01-2010';
	SELECT /* my query */ TO_CHAR(SUM(ORDER_TOTAL),'999,999,999') TOTAL into v FROM
	SOE.ORDERS WHERE TO_CHAR(ORDER_DATE,'MM-RRRR') =v_month_year;
	v_month_year := '02-2010';
	SELECT /* my query */ TO_CHAR(SUM(ORDER_TOTAL),'999,999,999') TOTAL into v FROM
	SOE.ORDERS WHERE TO_CHAR(ORDER_DATE,'MM-RRRR') =v_month_year;
	v_month_year := '03-2010';
	SELECT /* my query */ TO_CHAR(SUM(ORDER_TOTAL),'999,999,999') TOTAL into v FROM
	SOE.ORDERS WHERE TO_CHAR(ORDER_DATE,'MM-RRRR') =v_month_year;
	v_month_year := '04-2010';
	SELECT /* my query */ TO_CHAR(SUM(ORDER_TOTAL),'999,999,999') TOTAL into v FROM
	SOE.ORDERS WHERE TO_CHAR(ORDER_DATE,'MM-RRRR') =v_month_year;
END;
/
--
-- Get the captured SQL ID, SQL Text, Elapsed Time, Buffer Gets and Execution count statistics
--
set linesize 180
col SQL_TEXT FORMAT a30
col ELAPSED FORMAT 999999999
SELECT 
	SQL_ID, 
	SQL_TEXT, 
	ELAPSED_TIME AS "ELAPSED",
	CPU_TIME,
	BUFFER_GETS, EXECUTIONS AS EXEC
FROM 
	TABLE( DBMS_SQLTUNE.SELECT_SQLSET(SQLSET_NAME => 'SOE_WKLD_STS' , SQLSET_OWNER=>'SOE'));
--
SQL_ID        SQL_TEXT                          ELAPSED   CPU_TIME BUFFER_GETS       EXEC
------------- ------------------------------ ---------- ---------- ----------- ----------
79gu0duz8amhv SELECT                               9099       2403         636          1
              SQL_ID,
              SQL_TEXT,
              ELAPSED_TIME AS "ELAPSED",
              CPU_TIME,
              BUFFER_GETS, EXECUTIONS AS EXE
              C
              FROM
              TABLE( DBMS_SQLTUNE.SELECT_SQL
              SET(SQLSET_NAME => 'SOE_WKLD_S
              TS' , SQLSET_OWNER=>'SOE'))

c5k9qkxn0t7px DECLARE                           1739698     920055       70815          1
              v_month_year VARCHAR2(7);
              v VARCHAR2(20);
              BEGIN
              v_month_year := '01-2010';
              SELECT /* my query */ TO_CHAR(
              SUM(ORDER_TOTAL),'999,999,999'
              ) TOTAL into v FROM
              SOE.ORDERS WHERE TO_CHAR(ORDER
              _DATE,'MM-RRRR') =v_month_year
              ;
              v_month_year := '02-2010';
              SELECT /* my query */ TO_CHAR(
              SUM(ORDER_TOTAL),'999,999,999'
              ) TOTAL into v FROM
              SOE.ORDERS WHERE TO_CHAR(ORDER
              _DATE,'MM-RRRR') =v_month_year
              ;
              v_month_year := '03-2010';
              SELECT /* my query */ TO_CHAR(
              SUM(ORDER_TOTAL),'999,999,999'
              ) TOTAL into v FROM
              SOE.ORDERS WHERE TO_CHAR(ORDER
              _DATE,'MM-RRRR') =v_month_year
              ;
              v_month_year := '04-2010';
              SELECT /* my query */ TO_CHAR(
              SUM(ORDER_TOTAL),'999,999,999'
              ) TOTAL into v FROM
              SOE.ORDERS WHERE TO_CHAR(ORDER
              _DATE,'MM-RRRR') =v_month_year
              ;
              END;

fv1fkng67w2ru SELECT TO_CHAR(SUM(ORDER_TOTAL    1733217     917379       70754          4
              ),'999,999,999') TOTAL FROM SO
              E.ORDERS WHERE TO_CHAR(ORDER_D
              ATE,'MM-RRRR') =:B1
--
-- Run the following query to check the SQL statements in STS
--
col SQL_TEXT FORMAT a160
SELECT SQL_TEXT FROM DBA_SQLSET_STATEMENTS WHERE SQLSET_NAME='SOE_WKLD_STS';
--
-- Create a SQL Tuning Task based on the SQL Tuning Set
--
DECLARE
  v_sql_tune_task_id  VARCHAR2(100);
BEGIN
  v_sql_tune_task_id := DBMS_SQLTUNE.create_tuning_task (
                          sqlset_name => 'SOE_WKLD_STS',
                          sqlset_owner => 'SOE',
                          scope       => DBMS_SQLTUNE.scope_comprehensive,
                          time_limit  => 1000,
                          task_name   => 'SOE_WKLD_STS_TASK',
                          description => 'Tuning task for a particular SQL tuning set.');
  DBMS_OUTPUT.put_line('v_sql_tune_task_id: ' || v_sql_tune_task_id);
END;
/
--
-- Verify that the task is created and save the task ID
--
col TASK_ID FORMAT 999999
col TASK_NAME FORMAT a25
col STATUS_MESSAGE FORMAT a33
SELECT TASK_ID, TASK_NAME, STATUS, STATUS_MESSAGE FROM USER_ADVISOR_LOG WHERE
TASK_NAME='SOE_WKLD_STS_TASK';
--
TASK_ID TASK_NAME                 STATUS      STATUS_MESSAGE
------- ------------------------- ----------- ---------------------------------
    104 SOE_WKLD_STS_TASK         INITIAL
--
VARIABLE v_tid NUMBER;
exec :v_tid := 104
--
-- Execute the SQL Tuning Task
--
exec DBMS_SQLTUNE.EXECUTE_TUNING_TASK(TASK_NAME=>'SOE_WKLD_STS_TASK');
--
-- 
-- Check the status of the Task
--
col ADVISOR_NAME FORMAT a20
col SOFAR FORMAT 999
col TOTALWORK FORMAT 999
SELECT 
	TASK_ID, 
	ADVISOR_NAME, 
	SOFAR, 
	TOTALWORK, 
	ROUND(SOFAR/TOTALWORK*100,2) "%_COMPLETE"
FROM V$ADVISOR_PROGRESS
WHERE TASK_ID = 104;
--
TASK_ID ADVISOR_NAME         SOFAR TOTALWORK %_COMPLETE
------- -------------------- ----- --------- ----------
    104 SQL Tuning Advisor       5         5        100
--
-- Create the SQL Tuning task report and check the recommendation
--
SET LONG 50000
SET LONGCHUNKSIZE 1000
SET LINESIZE 100
SELECT DBMS_SQLTUNE.REPORT_TUNING_TASK( OWNER_NAME => 'TKYTE',TASK_NAME => 'SOE_WKLD_STS_TASK' ) FROM DUAL;
--
-- Drop the SQL Tuning Task before deleting the SQL Tuning set to avoid ORA-13757 error.
-- 
exec DBMS_SQLTUNE.DROP_TUNING_TASK(TASK_NAME => 'SOE_WKLD_STS_TASK');
--
-- Delete the STS
--
exec DBMS_SQLTUNE.DROP_SQLSET( SQLSET_NAME => 'SOE_WKLD_STS',SQLSET_OWNER=>'SOE');
--












