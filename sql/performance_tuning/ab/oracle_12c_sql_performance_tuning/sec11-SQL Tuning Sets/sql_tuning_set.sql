--
-- Creating SQL Tuning Set
-- 
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
NAME                SQLCNT DESCRIPTION
--------------- ---------- ----------------------------------------
SOE_WKLD_STS             0 SOE Workload to tune
--
-- In the Tkyte window run the following to initiate the capture of Shared SQL area into the SQL Tuning set every 3 seconds 
-- for 120 seconds. During the capture period, the SQL statements that satisfy the condition in the command below and running 
-- in the shared pool are captured and loaded into the STS.
-- Setting CAPTURE_MODE to MODE_ACCUMULATE_STATS accumulates the statistics of the same statement, if it runs more than once 
-- during the capture session. This option is expensive though. If the server from which you are capturing the SQL cursor is 
-- under heavy load. MODE_REPLACE_OLD_STATS replace the old statistics and less performance impact on the server.
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
	SOE.ORDERS2 WHERE TO_CHAR(ORDER_DATE,'MM-RRRR') =v_month_year;
	v_month_year := '02-2010';
	SELECT /* my query */ TO_CHAR(SUM(ORDER_TOTAL),'999,999,999') TOTAL into v FROM
	SOE.ORDERS2 WHERE TO_CHAR(ORDER_DATE,'MM-RRRR') =v_month_year;
	v_month_year := '03-2010';
	SELECT /* my query */ TO_CHAR(SUM(ORDER_TOTAL),'999,999,999') TOTAL into v FROM
	SOE.ORDERS2 WHERE TO_CHAR(ORDER_DATE,'MM-RRRR') =v_month_year;
	v_month_year := '04-2010';
	SELECT /* my query */ TO_CHAR(SUM(ORDER_TOTAL),'999,999,999') TOTAL into v FROM
	SOE.ORDERS2 WHERE TO_CHAR(ORDER_DATE,'MM-RRRR') =v_month_year;
END;
/
--
DECLARE
V NUMBER;
BEGIN
	FOR I IN 1..100 LOOP
	-- this is a select statement that gets executed 100 times
	SELECT COUNT(*) INTO V FROM CUSTOMERS WHERE CUSTOMER_ID=I;
	END LOOP;
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
29tnr4hdwp1g9 DECLARE                              4954        836         423          1
              V NUMBER;
              BEGIN
              FOR I IN 1..100 LOOP
              -- this is a select statement
              that gets executed 100 times
              SELECT COUNT(*) INTO V FROM CU
              STOMERS WHERE CUSTOMER_ID=I;
              END LOOP;
              END;

c5k9qkxn0t7px DECLARE                           1081900     886196       71183          1
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
--
-- Run the following query to check the SQL statements in STS
--
col SQL_TEXT FORMAT a160
SELECT SQL_TEXT FROM DBA_SQLSET_STATEMENTS WHERE SQLSET_NAME='SOE_WKLD_STS';
--
-- Delete the STS
--
exec DBMS_SQLTUNE.DROP_SQLSET( SQLSET_NAME => 'SOE_WKLD_STS',SQLSET_OWNER=>'SOE');
--
-- Loading STS by Capturing the Cursor Cache at Once
-- The following steps will load the SQL statements which already exist in the Cursor cache.
--
-- In main (tkyte) window.
ALTER SYSTEM FLUSH SHARED_POOL;
exec DBMS_SQLTUNE.CREATE_SQLSET ( SQLSET_NAME => 'SOE_WKLD_STS' , SQLSET_OWNER=>'SOE', DESCRIPTION => 'SOE Workload to tune');
--
-- In cliant (SOE) window run the following SQL.
--
BEGIN
	DBMS_APPLICATION_INFO.SET_MODULE( MODULE_NAME => 'TESTING_SESSION', ACTION_NAME=>NULL);
END;
/
--
DECLARE
V NUMBER;
BEGIN
	FOR I IN 1..100 LOOP
		-- this is a select statement that gets executed 100 times
		SELECT COUNT(*) INTO V FROM CUSTOMERS WHERE CUSTOMER_ID=I;
	END LOOP;
END;
/
--
-- In Tkyte window load the SQL statement in the cursor cache.
--
DECLARE
	C_SQLAREA_CURSOR DBMS_SQLTUNE.SQLSET_CURSOR;
BEGIN
	OPEN C_SQLAREA_CURSOR FOR SELECT VALUE(P) FROM TABLE(DBMS_SQLTUNE.SELECT_CURSOR_CACHE( 'MODULE = ''TESTING_SESSION'' AND PARSING_SCHEMA_NAME = ''SOE''')
) P;
-- load the STS
	DBMS_SQLTUNE.LOAD_SQLSET ( SQLSET_NAME => 'SOE_WKLD_STS' , SQLSET_OWNER=>'SOE', POPULATE_CURSOR => C_SQLAREA_CURSOR );
END;
/
--
-- Now get the SQL statements and execution statistics loaded.
--
set linesize 180
col SQL_TEXT FORMAT a50
col SCH FORMAT a3
col EXEC format 9999
col ELAPSED FORMAT 999999999
SELECT 
	SQL_TEXT, 
	CPU_TIME,
	ELAPSED_TIME AS "ELAPSED", 
	BUFFER_GETS, 
	EXECUTIONS AS EXEC
FROM 
	TABLE( DBMS_SQLTUNE.SELECT_SQLSET(SQLSET_NAME => 'SOE_WKLD_STS' , SQLSET_OWNER=>'SOE'));
--
SQL_TEXT                                             CPU_TIME    ELAPSED BUFFER_GETS  EXEC
-------------------------------------------------- ---------- ---------- ----------- -----
 		                                               19346      61392         701     1
--
-- Transporting SQL Tuning Set.
--
-- Create a Staging table for SQL Tuning Set from Tkyte Window.
exec DBMS_SQLTUNE.CREATE_STGTAB_SQLSET ( TABLE_NAME => 'SOE_WKLD_TABLE' , SCHEMA_NAME => 'SOE' );
--
-- In the Tkyte window. 
-- Populate the STS Stage table with the SQL Tunig set loaded in the previous step.
BEGIN
	DBMS_SQLTUNE.PACK_STGTAB_SQLSET(SQLSET_NAME => 'SOE_WKLD_STS', SQLSET_OWNER => 'SOE' , STAGING_TABLE_NAME => 'SOE_WKLD_TABLE'
	, STAGING_SCHEMA_OWNER => 'SOE');
END;
/
--verify:
SELECT COUNT(DISTINCT SQL_ID) FROM SOE.SOE_WKLD_TABLE;
--
-- Clean Up
DROP TABLE SOE.SOE_WKLD_TABLE;
exec DBMS_SQLTUNE.DROP_SQLSET( SQLSET_NAME =>'SOE_WKLD_STS',SQLSET_OWNER=>'SOE');
--
--
-- Multiple Schemas
--
-- Create SQL Set.
ALTER SYSTEM FLUSH SHARED_POOL;
exec DBMS_SQLTUNE.CREATE_SQLSET ( SQLSET_NAME => 'OE_HR_SCH_STS' , SQLSET_OWNER=>'SOE', DESCRIPTION => 'OE Workload to tune');
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
NAME='OE_HR_SCH_STS';
--
DECLARE
	C_SQLAREA_CURSOR DBMS_SQLTUNE.SQLSET_CURSOR;
BEGIN
	OPEN C_SQLAREA_CURSOR FOR SELECT VALUE(P) FROM TABLE(DBMS_SQLTUNE.SELECT_CURSOR_CACHE( 'MODULE = ''OE_LOAD_SESSION'' AND PARSING_SCHEMA_NAME = ''SOE''')
) P;
-- load the STS
	DBMS_SQLTUNE.LOAD_SQLSET ( SQLSET_NAME => 'OE_HR_SCH_STS' , SQLSET_OWNER=>'SOE', POPULATE_CURSOR => C_SQLAREA_CURSOR );
END;
/
--
BEGIN
	DBMS_APPLICATION_INFO.SET_MODULE( MODULE_NAME => 'OE_LOAD_SESSION', ACTION_NAME=>NULL);
END;
/
--
SELECT 
    OE.ORDER_ID,
    OE.ORDER_DATE,
    OE.ORDER_STATUS,
    OE.SALES_REP_ID,
    EMP.FIRST_NAME AS "SALES_REP_FIRST_NAME",
    EMP.LAST_NAME AS "SALES_REP_LAST_NAME",
    EMP.SALARY AS "SALES_REP_SAL"
FROM 
    OE.ORDERS OE
INNER JOIN
    HR.EMPLOYEES EMP
ON EMP.EMPLOYEE_ID = OE.SALES_REP_ID;
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
	TABLE( DBMS_SQLTUNE.SELECT_SQLSET(SQLSET_NAME => 'OE_HR_SCH_STS' , SQLSET_OWNER=>'SOE'));
--

SQL_ID        SQL_TEXT                          ELAPSED   CPU_TIME BUFFER_GETS  EXEC
------------- ------------------------------ ---------- ---------- ----------- -----
0ycjr3pu43svc SELECT                              21174      16476         832     2
                  OE.ORDER_ID,
                  OE.ORDER_DATE,
                  OE.ORDER_STATUS,
                  OE.SALES_REP_ID,
                  EMP.FIRST_NAME AS "SALES_REP_FIRST_NAME",
                  EMP.LAST_NAME AS "SALES_REP_LAST_NAME",
                  EMP.SALARY AS "SALES_REP_SAL"
              FROM
                  OE.ORDERS OE
              INNER JOIN
                  HR.EMPLOYEES EMP
              ON EMP.EMPLOYEE_ID = OE.SALES_
              REP_ID

a2ufta0tgw5t4 BEGIN                                4214       2218         152     1
              DBMS_APPLICATION_INFO.SET_MODU
              LE( MODULE_NAME => 'OE_LOAD_SE
              SSION', ACTION_NAME=>NULL);
              END;	
--
exec DBMS_SQLTUNE.DROP_SQLSET( SQLSET_NAME =>'OE_HR_SCH_STS',SQLSET_OWNER=>'SOE');	