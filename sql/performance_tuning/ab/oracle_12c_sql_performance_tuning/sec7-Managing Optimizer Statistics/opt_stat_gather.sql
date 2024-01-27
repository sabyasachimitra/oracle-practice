--Getting information about the Oracle Automatic maintenance task that gather Object statistics
--
set linesize 180
col "Auto Optimizer Stats Info." format a100
--DBA_AUTOTASK_CLIENT displays statistical data for each automated maintenance task over 7-day and 30-day periods.
--WINDOW_GROUP column displays the Window group used to schedule the job.
--
SELECT 'STATUS: '|| STATUS || chr(10) || 'WINDOW_GROUP: '||WINDOW_GROUP ||
chr(10)|| 'MEAN_JOB_DURATION: '||MEAN_JOB_DURATION || chr(10)|| 'MEAN_JOB_CPU: '
|| MEAN_JOB_CPU ||chr(10)|| 'MAX_DURATION_LAST_7_DAYS: '||
MAX_DURATION_LAST_7_DAYS || chr(10)|| 'MAX_DURATION_LAST_30_DAYS:
'||MAX_DURATION_LAST_30_DAYS|| chr(10) as "Auto Optimizer Stats Info."
FROM 
	DBA_AUTOTASK_CLIENT
WHERE CLIENT_NAME='auto optimizer stats collection';
--
--Using the WINDOW_GROUP we can retrieve the Scheduler Windows
--DBA_SCHEDULER_WINDOWS:: displays information about all the Scheduler windows.
--
col WINDOW_NAME format a20
col REPEAT_INTERVAL format a55
col DURATION format a15
--
SELECT 
	WINDOW_NAME, 
	REPEAT_INTERVAL, 
	DURATION, 
	ENABLED
FROM 
	DBA_SCHEDULER_WINDOWS
WHERE '"SYS"."' || WINDOW_NAME ||'"' IN 
									(SELECT MEMBER_NAME FROM DBA_SCHEDULER_GROUP_MEMBERS WHERE GROUP_NAME='ORA$AT_WGRP_OS')
ORDER BY NEXT_START_DATE;
--
--Saturday and Sunday Window starts from 6 AM in the morning for 20 hours.
--Weekday window starts every weekday at 10 PM for 20 hours.
--
WINDOW_NAME          REPEAT_INTERVAL                                         DURATION        ENABL
-------------------- ------------------------------------------------------- --------------- -----
SATURDAY_WINDOW      freq=daily;byday=SAT;byhour=6;byminute=0; bysecond=0    +000 20:00:00   TRUE
SUNDAY_WINDOW        freq=daily;byday=SUN;byhour=6;byminute=0; bysecond=0    +000 20:00:00   TRUE
MONDAY_WINDOW        freq=daily;byday=MON;byhour=22;byminute=0; bysecond=0   +000 04:00:00   TRUE
TUESDAY_WINDOW       freq=daily;byday=TUE;byhour=22;byminute=0; bysecond=0   +000 04:00:00   TRUE
WEDNESDAY_WINDOW     freq=daily;byday=WED;byhour=22;byminute=0; bysecond=0   +000 04:00:00   TRUE
THURSDAY_WINDOW      freq=daily;byday=THU;byhour=22;byminute=0; bysecond=0   +000 04:00:00   TRUE
FRIDAY_WINDOW        freq=daily;byday=FRI;byhour=22;byminute=0; bysecond=0   +000 04:00:00   TRUE
--
--DBA can enable/disable and change the Automatic task Scheduler window time and duration.
--Suppose you want to change the Saturday window so that it opens at 10 PM and duration to 10 hours 30 minutes.
--
BEGIN
	DBMS_SCHEDULER.DISABLE(NAME => 'SYS.SATURDAY_WINDOW'); /* first::disable the window */
	DBMS_SCHEDULER.SET_ATTRIBUTE(NAME => 'SYS.SATURDAY_WINDOW', ATTRIBUTE => 'DURATION', VALUE => numtodsinterval(630, 'minute'));
	DBMS_SCHEDULER.SET_ATTRIBUTE(NAME => 'SYS.SATURDAY_WINDOW', ATTRIBUTE => 'REPEAT_INTERVAL', 
															VALUE => 'freq=daily;byday=SAT;byhour=22;byminute=0; bysecond=0');
	DBMS_SCHEDULER.ENABLE( name => 'SYS.SATURDAY_WINDOW');
END;
/
--
SELECT 
	WINDOW_NAME, 
	REPEAT_INTERVAL, 
	DURATION, 
	ENABLED
FROM 
	DBA_SCHEDULER_WINDOWS
WHERE '"SYS"."' || WINDOW_NAME ||'"' IN 
									(SELECT MEMBER_NAME FROM DBA_SCHEDULER_GROUP_MEMBERS WHERE GROUP_NAME='ORA$AT_WGRP_OS')
ORDER BY NEXT_START_DATE;
--
WINDOW_NAME          REPEAT_INTERVAL                                         DURATION        ENABL
-------------------- ------------------------------------------------------- --------------- -----
SATURDAY_WINDOW      freq=daily;byday=SAT;byhour=22;byminute=0; bysecond=0   +000 10:30:00   TRUE
--
--Next::check the program run by the Automatic maintenance task.
--DBA_SCHEDULER_PROGRAMS::displays information about all the Scheduler programs.
--
col PROGRAM_INFO format a90
--
SELECT 'Action: ' || PROGRAM_ACTION ||chr(10)|| 'Comments: ' || COMMENTS
PROGRAM_INFO FROM DBA_SCHEDULER_PROGRAMS WHERE PROGRAM_NAME='GATHER_STATS_PROG';
--
PROGRAM_INFO
------------------------------------------------------------------------------------------
Action: dbms_stats.gather_database_stats_job_proc
Comments: Oracle defined automatic optimizer statistics collection program
--
--Retrieve the history log of the optimizer statistics gathering task. The job gets automatically created when the Window opens
--and dropped when the Window closes but job history is preserved.
--
col JOB_NAME format a22
col OPERATION format a12
col STATUS format a10
SELECT TO_CHAR(LOG_DATE,'DD-MM-YYYY HH24:MI:SS') AS LOG_DATE, JOB_NAME,
OPERATION, STATUS
FROM DBA_SCHEDULER_JOB_LOG
WHERE JOB_NAME LIKE 'ORA$AT%OPT%' 
ORDER BY LOG_DATE DESC fetch first 10 rows only;
--
--Retrieve list of statistics gathering operations performed at the schema and database level.
--This includes GATHER_TABLE_STAT operations on tables (by job or manually by developer/DBA) and databases. 
SELECT 'Operation: ' || OPERATION ||chr(10)||
'Target: ' || TARGET ||chr(10)||
'Start Time: ' || START_TIME ||chr(10)||
'End Time: ' || END_TIME ||chr(10)||
'Status: ' || STATUS ||chr(10)||
'Job Name: ' || JOB_NAME ||chr(10)||
'Notes: ' || NOTES "Stats Operations"
FROM DBA_OPTSTAT_OPERATIONS
WHERE TARGET NOT LIKE 'SYS%'
ORDER BY ID DESC;
--
--Retrieve the objects that were processed by the statistics gathering operations.
--
col TARGET format a40
col TARGET_TYPE format a11
col START_TIME format a17
col END_TIME format a17
col DURATION format a11
--
SELECT TARGET, TARGET_TYPE, TO_CHAR(START_TIME,'Mon-dd HH24:MI:SS') START_TIME,
TO_CHAR(END_TIME,'Mon-dd HH24:MI:SS') END_TIME,
SUBSTR(TO_CHAR(END_TIME-START_TIME,'HH:MI:SS'),12,8) DURATION, STATUS
FROM DBA_OPTSTAT_OPERATION_TASKS
WHERE TARGET NOT LIKE '%SYS%'
--AND END_TIME-START_TIME >= INTERVAL '10' SECOND
ORDER BY OPID DESC, START_TIME DESC fetch first 10 rows only;
--
TARGET                                   TARGET_TYPE START_TIME        END_TIME          DURATION    STATUS
---------------------------------------- ----------- ----------------- ----------------- ----------- ----------
"SH"."SALES_TRANSACTIONS_EXT"            TABLE       May-22 18:31:44   May-22 18:31:47   00:00:02    FAILED
"TKYTE"."DISORGANIZED_PK"                INDEX       May-22 00:15:13   May-22 00:15:13   00:00:00    COMPLETED
"TKYTE"."DISORGANIZED"                   TABLE       May-22 00:15:12   May-22 00:15:13   00:00:00    COMPLETED
"SOE"."DEPT_IX"                          INDEX       May-22 00:15:12   May-22 00:15:12   00:00:00    COMPLETED
"TKYTE"."COLOCATED_PK"                   INDEX       May-22 00:15:12   May-22 00:15:12   00:00:00    COMPLETED
"SOE"."EMP_PK"                           INDEX       May-22 00:15:12   May-22 00:15:12   00:00:00    COMPLETED
"TKYTE"."COLOCATED"                      TABLE       May-22 00:15:12   May-22 00:15:12   00:00:00    COMPLETED
"SOE"."I1"                               INDEX       May-22 00:15:12   May-22 00:15:12   00:00:00    COMPLETED
"SOE"."EMP"                              TABLE       May-22 00:15:11   May-22 00:15:12   00:00:00    COMPLETED
"SH"."SALES_TRANSACTIONS_EXT"            TABLE       May-22 00:15:06   May-22 00:15:07   00:00:00    FAILED
--
--Impact of stale statistics on Optimizer Access Methods.
--
--Create a new table called SOE.ORDERS2 same as SOE.ORDERS.
CREATE TABLE soe.ORDERS2 (
	ORDER_ID NUMBER(12),
	ORDER_DATE TIMESTAMP(6) WITH LOCAL TIME ZONE,
	ORDER_MODE VARCHAR2(8),
	CUSTOMER_ID NUMBER(12),
	ORDER_STATUS NUMBER(2),
	ORDER_TOTAL NUMBER(8,2),
	SALES_REP_ID NUMBER(6),
	NOTES VARCHAR2(15)
);
--
--Insert first 40000 records into SOE.ORDERS2 from SOE.ORDERS
--
INSERT INTO SOE.ORDERS2 SELECT ORDER_ID, ORDER_DATE, ORDER_MODE, CUSTOMER_ID,
ORDER_STATUS, ORDER_TOTAL, SALES_REP_ID,
DBMS_RANDOM.STRING('a',ROUND(DBMS_RANDOM.VALUE(5,15))) FROM SOE.ORDERS fetch first
40000 rows only;
--
--Generate Table Stat
--
exec DBMS_STATS.GATHER_TABLE_STATS(OWNNAME=>'SOE', TABNAME=>'ORDERS2');
--
--Check if stat is generated
SELECT NUM_ROWS, BLOCKS, LAST_ANALYZED FROM DBA_TAB_STATISTICS WHERE
TABLE_NAME = 'ORDERS2';
--
--Impact of missing Stat in Execution Plan.
--Generate the execution plan of the following query
SET AUTOTRACE TRACEONLY
SELECT * FROM SOE.ORDERS2 WHERE ORDER_ID BETWEEN 60000 AND 80000;
--
--Difference betwen actual rows returned (7506) and estimated rows (12409) is arounf 5K.
7506 rows selected.

Execution Plan
----------------------------------------------------------
Plan hash value: 893590499
-----------------------------------------------------------------------------
| Id  | Operation         | Name    | Rows  | Bytes | Cost (%CPU)| Time     |
-----------------------------------------------------------------------------
|   0 | SELECT STATEMENT  |         | 12409 |   545K|   102   (0)| 00:00:01 |
|*  1 |  TABLE ACCESS FULL| ORDERS2 | 12409 |   545K|   102   (0)| 00:00:01 |
-----------------------------------------------------------------------------
--Delete 50% of ORDERS2 table.
DELETE SOE.ORDERS2 WHERE MOD(ORDER_ID,2)=0;
COMMIT;
--
--Table State remain the same.
SELECT NUM_ROWS, BLOCKS, LAST_ANALYZED FROM DBA_TAB_STATISTICS WHERE
TABLE_NAME = 'ORDERS2';
--
  NUM_ROWS     BLOCKS LAST_ANAL
---------- ---------- ---------
     40000        370 22-MAY-22
--
SET AUTOTRACE TRACEONLY
SELECT * FROM SOE.ORDERS2 WHERE ORDER_ID BETWEEN 60000 AND 80000;
--
--Difference betwen actual rows returned (3753) and estimated rows (12409) is around 8K.
3753 rows selected.
Execution Plan
----------------------------------------------------------
Plan hash value: 893590499
-----------------------------------------------------------------------------
| Id  | Operation         | Name    | Rows  | Bytes | Cost (%CPU)| Time     |
-----------------------------------------------------------------------------
|   0 | SELECT STATEMENT  |         | 12409 |   545K|   102   (0)| 00:00:01 |
|*  1 |  TABLE ACCESS FULL| ORDERS2 | 12409 |   545K|   102   (0)| 00:00:01 |
-----------------------------------------------------------------------------
--
