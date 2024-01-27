--Optimizer Statistics Advisor inspects how Optimizer Stat is gathered
--automatically diagnoses problems in existing practices for gathering
--statistics, and provides recommendations to follow best practices.
--Optimizer Statistics Advisor runs as an Automatic Task in Oracle.
--
--To check if the AUTO_STATS_ADVISOR_TASK and INDIVIDUAL_STATS_ADVISOR_TASK tasks are already created.
--
--login as SYSDBA
SELECT NAME, CTIME, HOW_CREATED
FROM SYS.WRI$_ADV_TASKS
WHERE OWNER_NAME = 'SYS'
AND NAME IN ('AUTO_STATS_ADVISOR_TASK','INDIVIDUAL_STATS_ADVISOR_TASK');
--
NAME                                 CTIME     HOW_CREATED
----------------------------------- --------- ------------
AUTO_STATS_ADVISOR_TASK             17-APR-19  CMD
INDIVIDUAL_STATS_ADVISOR_TASK       17-APR-19  CMD
--
--If the tasks are not created, you can create it using:
exec DBMS_STATS.INIT_PACKAGE();
--
--Verify if the tasks have been registered to the database
col ADVISOR_NAME format a20
col LAST_EXECUTION format a20
SELECT ADVISOR_NAME, LAST_EXECUTION
FROM DBA_ADVISOR_TASKS WHERE TASK_NAME='AUTO_STATS_ADVISOR_TASK';
--
ADVISOR_NAME         LAST_EXECUTION
-------------------- --------------------
Statistics Advisor   EXEC_344
--
--run the following SQL to check if Optimizer Statistics Advisor task has run since last 2 days.
col EXECUTION_NAME FORMAT A20
col EXECUTION_END FORMAT A20
col EXECUTION_TYPE FORMAT A20
SELECT EXECUTION_NAME,
EXECUTION_START,
EXECUTION_END,
EXECUTION_TYPE,
STATUS
FROM DBA_ADVISOR_EXECUTIONS
WHERE TASK_NAME = 'AUTO_STATS_ADVISOR_TASK'
AND EXECUTION_END >= SYSDATE-2
ORDER BY 3;
--
EXECUTION_NAME       EXECUTION EXECUTION_END        EXECUTION_TYPE       STATUS
-------------------- --------- -------------------- -------------------- -----------
EXEC_332             28-JUN-22 28-JUN-22            STATISTICS           COMPLETED
EXEC_334             29-JUN-22 29-JUN-22            STATISTICS           COMPLETED
EXEC_344             30-JUN-22 30-JUN-22            STATISTICS           COMPLETED
--
--You can run the task manually also
select DBMS_STATS.EXECUTE_ADVISOR_TASK('AUTO_STATS_ADVISOR_TASK') from dual;
--
col ADVISOR_NAME format a20
col LAST_EXECUTION format a20
SELECT ADVISOR_NAME, LAST_EXECUTION
FROM DBA_ADVISOR_TASKS WHERE TASK_NAME='AUTO_STATS_ADVISOR_TASK';
--
--new task has been executed.
ADVISOR_NAME         LAST_EXECUTION
-------------------- --------------------
Statistics Advisor   EXEC_345
--
--create a report from the last execution of the Optimizer Statistics Advisor task.
SET LINES 200 PAGES 0
SET LONG 100000
COLUMN REPORT FORMAT A300
VARIABLE MY_REPORT CLOB;
BEGIN
	:MY_REPORT := DBMS_STATS.REPORT_ADVISOR_TASK(TASK_NAME =>'AUTO_STATS_ADVISOR_TASK', EXECUTION_NAME=> NULL, TYPE=>'TEXT', SECTION=>'ALL', LEVEL=>'ALL');
END;
/
--
DECLARE
	v_tname VARCHAR2(128) := 'AUTO_ADV_1';
	v_ename VARCHAR2(128) := NULL;
	v_report CLOB := null;
	v_script CLOB := null;
	v_implementation_result CLOB;
BEGIN
	v_tname := DBMS_STATS.CREATE_ADVISOR_TASK(v_tname);
	v_ename := DBMS_STATS.EXECUTE_ADVISOR_TASK(v_tname);
END;
/

SELECT NAME, CTIME, HOW_CREATED
FROM SYS.WRI$_ADV_TASKS
WHERE OWNER_NAME = 'TKYTE';
AND NAME IN ('AUTO_STATS_ADVISOR_TASK','INDIVIDUAL_STATS_ADVISOR_TASK');
--
SELECT DBMS_STATS.report_advisor_task('AUTO_ADV_1') AS REPORT FROM   dual;
--
SPOOL C:\Users\Sabya\Documents\Technical\Udemy\barakhasqltuning\sql\sec7\stat_adv.html
SET LONG 1000000
COLUMN report FORMAT A200
SET LINESIZE 250
SET PAGESIZE 1000
SELECT DBMS_STATS.REPORT_ADVISOR_TASK(task_name => 'AUTO_STATS_ADVISOR_TASK', execution_name => NULL , type => 'HTML' , section => 'ALL' ) AS report FROM DUAL;
SPOOL OFF
--
SET LONG 1000000
SET LONGCHUNKSIZE 100000 
SET SERVEROUTPUT ON
SET LINE 300
SET PAGES 1000
DECLARE
  v_tname   VARCHAR2(128) := 'TEST_TASK_MIKE1';
  v_ename   VARCHAR2(128) := NULL;
  v_report  CLOB := NULL;
  v_script  CLOB := NULL;
BEGIN
  v_tname  := DBMS_STATS.CREATE_ADVISOR_TASK(v_tname);
  v_ename  := DBMS_STATS.EXECUTE_ADVISOR_TASK(v_tname);
  v_report := DBMS_STATS.REPORT_ADVISOR_TASK(v_tname);
  DBMS_OUTPUT.PUT_LINE(v_report);
END;
/