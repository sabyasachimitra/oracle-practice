--
-- Demonstrating Monitoring and Tracing Database Operations using DBMS_MONITOR
--
-- Prerequisities
--
SHOW PARAMETER STATISTICS_LEVEL
--
-- Must be TYPICAL or ALL
--
NAME                                 TYPE        VALUE
------------------------------------ ----------- ------------------------------
client_statistics_level              string      TYPICAL
statistics_level                     string      TYPICAL
--
SHOW PARAMETER CONTROL_MANAGEMENT_PACK_ACCESS
--
-- Must be DIAGNOSTIC+TUNING (licensed option)
--
NAME                                 TYPE        VALUE
------------------------------------ ----------- ------------------------------
control_management_pack_access       string      DIAGNOSTIC+TUNING
--
-- Monitoring a Simple Operation in SQL*Plus
-- Note:: a simple database operation is monitored only when SQL/PLSQL statment consumed at least 5 seconds of CPU or I/O time
-- in a single execution OR /*+ MONITOR */ hint is used in the statement OR SQL statement executes in parallel.
-- Queries that consume more than 5 seconds of CPU or I/O time can be monitored from V$SQL_MONITOR.
--
-- Start another SQLPLUS client session with SOE user id and create the following function
--
CREATE OR REPLACE FUNCTION SOE.CONSUME_CPU(N NUMBER) RETURN NUMBER
IS
-- this function keeps consuming from CPU till N seconds is elapsed
	V TIMESTAMP;
	X NUMBER ;
	SECONDS NUMBER;
BEGIN
	V := SYSTIMESTAMP;
	SECONDS := 0 ;
	WHILE SECONDS < N LOOP
		SECONDS := (EXTRACT( MINUTE from SYSTIMESTAMP - V )*60) + EXTRACT( SECOND from SYSTIMESTAMP - V );
		X := SQRT(DBMS_RANDOM.VALUE(1,10000));
	END LOOP;
	RETURN SECONDS;
END;
/
--
-- In Client window run the function for 80 seconds
--
SELECT /* MY QUERY 1 */ CONSUME_CPU(80) FROM DUAL;
--
-- In the Admin window (User = TKYTE), run the following SQL to monitor the SQL.
-- Keep running the SQL multiple times to observe the change in CPU time and DISK Reads.
--
SELECT
	'REPORT_ID: ' || REPORT_ID ||CHR(10) || 'STATUS: ' || STATUS ||CHR(10) ||
	'USERNAME: ' || USERNAME || CHR(10) || 'SQL_TEXT: ' || SQL_TEXT || CHR(10) ||
	'CPU_TIME: ' || CPU_TIME || CHR(10) ||'DISK_READS: '|| DISK_READS AS "Monitoring Tasks"
FROM
	V$SQL_MONITOR
WHERE USERNAME='SOE' AND SQL_TEXT LIKE '%MY QUERY 1%';
--
Monitoring Tasks
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
REPORT_ID: 0
STATUS: EXECUTING
USERNAME: SOE
SQL_TEXT: SELECT /* MY QUERY 1 */ CONSUME_CPU(80) FROM DUAL
CPU_TIME: 15008158
DISK_READS: 147


tkyte@DB19C01> /

Monitoring Tasks
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
REPORT_ID: 0
STATUS: EXECUTING
USERNAME: SOE
SQL_TEXT: SELECT /* MY QUERY 1 */ CONSUME_CPU(80) FROM DUAL
CPU_TIME: 23987776
DISK_READS: 147
..........
Monitoring Tasks
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
REPORT_ID: 0
STATUS: DONE (ALL ROWS)
USERNAME: SOE
SQL_TEXT: SELECT /* MY QUERY 1 */ CONSUME_CPU(80) FROM DUAL
CPU_TIME: 78051252
DISK_READS: 147
--
-- Clean Up
--
DROP FUNCTION SOE.CONSUME_CPU;
--
-- Monitoring Composite DB operations in Real-Time in SQL*Plus
-- Note :: Composite DB operations can be monitored only when you started an operation with DBMS_SQL_MONITOR.BEGIN_OPERATION
-- AND (the operation has consumed consumed at least 5 seconds of CPU or I/O time OR
-- Tracking for the operations is forced by setting FORCE_TRACKING to Y in BEGIN_OPERATION)
--
-- Get the SID and SERIAL# from V$SESSION of the Client session
SELECT SID, SERIAL# FROM V$SESSION WHERE AUDSID = SYS_CONTEXT('USERENV', 'SESSIONID');

       SID    SERIAL#
---------- ----------
       277      13807
--
-- In the Tkyte window run the following and enter the SID and SERIAL# and note down the OP_ID
--
VARIABLE OP_ID NUMBER;
BEGIN
	:OP_ID := DBMS_SQL_MONITOR.BEGIN_OPERATION (DBOP_NAME => 'ORA.SOE.TOPCUSTOMERS', SESSION_ID=> &Enter_SID, SESSION_SERIAL=> &Enter_Serial, FORCED_TRACKING => 'Y'); -- or DBMS_SQL_MONITOR.FORCE_TRACKING
END;
/
print :OP_ID
--
     OP_ID
----------
         2
--
-- Run the following to query V$SQL_MONITOR to monitor the session activity
--
set linesize 180
col STATUS format a20
col USERNAME format a20
col MODULE format a20
col ACTION format a20
SELECT
	DBOP_EXEC_ID,
	DBOP_NAME,
	IN_DBOP_NAME,
	STATUS,
	USERNAME,
	MODULE,
	ACTION
FROM
	V$SQL_MONITOR
WHERE (DBOP_NAME='ORA.SOE.TOPCUSTOMERS' OR IN_DBOP_NAME='ORA.SOE.TOPCUSTOMERS') AND DBOP_EXEC_ID= :OP_ID;
--
-- DBOP_NAME represents an Operation in the database
-- IN_DBOP_NAME represents a task that belongs to the operation (DBOP_NAME) such a query
-- Since no query is running now the IN_DBOP_NAME is blank
--
DBOP_EXEC_ID DBOP_NAME            IN_DBOP_NAME         STATUS               USERNAME             MODULE               ACTION
------------ -------------------- -------------------- -------------------- -------------------- -------------------- --------------------
           2 ORA.SOE.TOPCUSTOMERS                      EXECUTING            SOE                  SQL*Plus
--
-- Run the following small query in the client session (SOE) to check if it is monitored
--
SELECT SYSDATE FROM DUAL;
--
-- Run the following query to see if the SQL is monitored (in Tykyte session)
--
SELECT 'DBOP_NAME: ' || DBOP_NAME ||CHR(10) || 'IN_DBOP_NAME: ' || IN_DBOP_NAME
|| CHR(10) || 'SQL_ID: ' || SQL_ID || CHR(10) || 'SQL_TEXT: ' || SQL_TEXT AS
"Operation Tasks"
FROM V$SQL_MONITOR
WHERE (DBOP_NAME='ORA.SOE.TOPCUSTOMERS' OR IN_DBOP_NAME='ORA.SOE.TOPCUSTOMERS')
ORDER BY DBOP_NAME;
--
-- Since the SQL did not run for at least 5 seconds it was not monitored
--
Operation Tasks
------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
DBOP_NAME: ORA.SOE.TOPCUSTOMERS
IN_DBOP_NAME:
SQL_ID:
SQL_TEXT:
--
-- Run the folllowing query and and check if it's monitored
--
SET TIMING ON
SELECT
	CUSTOMERS.CUSTOMER_ID,
	InitCap(CUST_FIRST_NAME) FIRST_NAME,
	InitCap(CUST_LAST_NAME) LAST_NAME,
	ENAME ACCOUNT_MANAGER,
	ROUND(MONTHS_BETWEEN(SYSDATE,CUSTOMER_SINCE)/12,1) CUSTOMER_YEARS,
	TO_CHAR(SUM(ORDER_TOTAL),'999,999,999') TOTAL
FROM
	ORDERS, CUSTOMERS, EMP
WHERE CUSTOMERS.CUSTOMER_ID = ORDERS.CUSTOMER_ID AND EMP_NO = ACCOUNT_MGR_ID
GROUP BY
	CUSTOMERS.CUSTOMER_ID,
	InitCap(CUST_FIRST_NAME),
	InitCap(CUST_LAST_NAME),
	ENAME,
	ROUND(MONTHS_BETWEEN(SYSDATE,CUSTOMER_SINCE)/12,1)
ORDER BY SUM(ORDER_TOTAL) DESC;
--
Elapsed: 00:00:04.90
--
-- Run the following query to see if the SQL is monitored.
-- Since the query did not run for at least 5 seconds, it was not monitored
--
SELECT 'DBOP_NAME: ' || DBOP_NAME ||CHR(10) || 'IN_DBOP_NAME: ' || IN_DBOP_NAME
|| CHR(10) || 'SQL_ID: ' || SQL_ID || CHR(10) || 'SQL_TEXT: ' || SQL_TEXT AS
"Operation Tasks"
FROM V$SQL_MONITOR
-- WHERE (DBOP_NAME='ORA.SOE.TOPCUSTOMERS' OR IN_DBOP_NAME='ORA.SOE.TOPCUSTOMERS')
ORDER BY DBOP_NAME;
--
-- Since the query did not run for at least 5 seconds, it was not monitored
--
-- Run the query again with MONITOR hint
SET TIMING ON
SELECT /*+ MONITOR */
	CUSTOMERS.CUSTOMER_ID,
	InitCap(CUST_FIRST_NAME) FIRST_NAME,
	InitCap(CUST_LAST_NAME) LAST_NAME,
	ENAME ACCOUNT_MANAGER,
	ROUND(MONTHS_BETWEEN(SYSDATE,CUSTOMER_SINCE)/12,1) CUSTOMER_YEARS,
	TO_CHAR(SUM(ORDER_TOTAL),'999,999,999') TOTAL
FROM
	ORDERS, CUSTOMERS, EMP
WHERE CUSTOMERS.CUSTOMER_ID = ORDERS.CUSTOMER_ID AND EMP_NO = ACCOUNT_MGR_ID
GROUP BY
	CUSTOMERS.CUSTOMER_ID,
	InitCap(CUST_FIRST_NAME),
	InitCap(CUST_LAST_NAME),
	ENAME,
	ROUND(MONTHS_BETWEEN(SYSDATE,CUSTOMER_SINCE)/12,1)
ORDER BY SUM(ORDER_TOTAL) DESC;
--
SELECT
	'DBOP_NAME: ' || DBOP_NAME || CHR(10) || 'IN_DBOP_NAME: ' || IN_DBOP_NAME
	|| CHR(10) || 'Elapsed Time: ' || ELAPSED_TIME || CHR(10) || 'CPU Time: ' || CPU_TIME
	|| CHR(10) || 'Fetches: ' || FETCHES || CHR(10) || 'Buffer Gets: ' || BUFFER_GETS
	|| CHR(10) || 'Disk Reads : ' || DISK_READS || CHR(10) || 'SQL_ID: ' || SQL_ID || CHR(10)
	|| 'SQL_TEXT: ' || SQL_TEXT AS "Operation Tasks"
FROM
	V$SQL_MONITOR
WHERE (DBOP_NAME='ORA.SOE.TOPCUSTOMERS' OR IN_DBOP_NAME='ORA.SOE.TOPCUSTOMERS')
ORDER BY DBOP_NAME;
--
Operation Tasks
------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
DBOP_NAME: ORA.SOE.TOPCUSTOMERS
IN_DBOP_NAME:
SQL_ID:
SQL_TEXT:

DBOP_NAME:
IN_DBOP_NAME: ORA.SOE.TOPCUSTOMERS
SQL_ID: 4nqpcyb2atx9v
SQL_TEXT: SELECT /*+ MONITOR */
CUSTOMERS.CUSTOMER_ID,
InitCap(CUST_FIRST_NAME) FIRST_NAME,
InitCap(CUST_LAST_NAME) LAST_NAME,
ENAME ACCOUNT_MANAGER,
ROUND(MONTHS_BETWEEN(SYSDATE,CUSTOMER_SINCE)/12,1) CUSTOMER_YEARS,
TO_CHAR(SUM(ORDER_TOTAL),'999,999,999') TOTAL
FROM
ORDERS, CUSTOMERS, EMP
WHERE CUSTOMERS.CUSTOMER_ID = ORDERS.CUSTOMER_ID AND EMP_NO = ACCOUNT_MGR_ID
GROUP BY
CUSTOMERS.CUSTOMER_ID,
InitCap(CUST_FIRST_NAME),
InitCap(CUST_LAST_NAME),
ENAME,
ROUND(MONTHS_BETWEEN(SYSDATE,CUSTOMER_SINCE)/12,1)
ORDER BY SUM(ORDER_TOTAL) DESC
--
column DBOP_NAME format a20
column IN_DBOP_NAME format a20
column SQL_ID format a13
column BUFFER_GETS format 99999999
column DISK_READS format 99999999
column CPU_TIME format 99999999
column ELAPSED_TIME format 99999999
column SQL_EXEC_START format a10
SELECT
	DBOP_NAME,
	IN_DBOP_NAME,
	SQL_ID,
	BUFFER_GETS,
	DISK_READS,
	DISK_READS,
	CPU_TIME,
	ELAPSED_TIME,
	SQL_EXEC_START
FROM
	V$SQL_MONITOR
WHERE (DBOP_NAME='ORA.SOE.TOPCUSTOMERS' OR IN_DBOP_NAME='ORA.SOE.TOPCUSTOMERS')
ORDER BY DBOP_NAME;
--
DBOP_NAME            IN_DBOP_NAME         SQL_ID        BUFFER_GETS DISK_READS DISK_READS  CPU_TIME ELAPSED_TIME SQL_EXEC_S
-------------------- -------------------- ------------- ----------- ---------- ---------- --------- ------------ ----------
ORA.SOE.TOPCUSTOMERS                                          17627        139        139   1515237      2052436
ORA.SOE.TOPCUSTOMERS                                              0          0          0       415         2891
ORA.SOE.TOPCUSTOMERS 											4nqpcyb2atx9v       18403        139        139   1127417      1729598 24-JUL-22
--
-- Run the following query which is time consuming (from SOE client session).
--
SET TIMING ON
SELECT /*+ USE_NL(A B) NO_PARALLEL */ COUNT(*) FROM CUSTOMERS A, CUSTOMERS B
WHERE A.CUSTOMER_ID<13000 AND B.CUSTOMER_ID<13000;
--
-- And monitor the Execution Real-time (from TKYTE session).
SELECT
	'DBOP_NAME: ' || DBOP_NAME ||CHR(10) || 'IN_DBOP_NAME: ' || IN_DBOP_NAME
	|| CHR (10) || 'Buffer Gets: ' || BUFFER_GETS || CHR(10) || 'Disk Reads: ' || DISK_READS
	|| CHR(10) || 'CPU Time: ' || TO_CHAR(CPU_TIME/1000000,'000.00') || CHR(10)
	|| 'Elapsed Time: ' || TO_CHAR(ELAPSED_TIME/1000000,'000.00') || CHR(10)
	|| 'Status: ' || STATUS || CHR(10) || 'SQL_ID: ' || SQL_ID || CHR(10) || 'SQL_TEXT: ' || SQL_TEXT AS "Operation Tasks"
FROM V$SQL_MONITOR
WHERE (DBOP_NAME='ORA.SOE.TOPCUSTOMERS' OR IN_DBOP_NAME='ORA.SOE.TOPCUSTOMERS')
ORDER BY DBOP_NAME;
--
-- Get the SQL_ID of the SQL statement from the output of the above SQL
-- and run the following query to display the real-time execution plan ((from TKYTE session)
-- of the monitored query. Re-run the query using / to change in the plan and OUTPUT_ROWS.
--
DEFINE v_sql_id = 'c4rjkr10vt8gs'
--
COL ID FORMAT 999
COL OPERATION FORMAT A40
COL OBJECT FORMAT A18
COL STATUS FORMAT A8
SET COLSEP '|'
SET LINES 180
SELECT
	P.ID,
	RPAD(' ',P.DEPTH*2, ' ') || P.OPERATION OPERATION,
	P.OBJECT_NAME OBJECT,
	P.CARDINALITY CARD,
	P.COST COST,
	SUBSTR(M.STATUS,1,4) STATUS,
	M.OUTPUT_ROWS
FROM
	V$SQL_PLAN P, V$SQL_PLAN_MONITOR M
WHERE
	P.SQL_ID=M.SQL_ID AND P.CHILD_ADDRESS=M.SQL_CHILD_ADDRESS AND P.PLAN_HASH_VALUE=M.SQL_PLAN_HASH_VALUE
	AND P.ID=M.PLAN_LINE_ID AND M.SQL_ID='&V_SQL_ID'
ORDER BY P.ID;
--
-- End the monitoring (from TKYTE session).
--
BEGIN
	DBMS_SQL_MONITOR.END_OPERATION (DBOP_NAME => 'ORA.SOE.TOPCUSTOMERS', DBOP_EID => :OP_ID);
END;
/
--
--
SELECT SID, SERIAL# FROM V$SESSION WHERE AUDSID = SYS_CONTEXT('USERENV', 'SESSIONID');
--
       SID    SERIAL#
---------- ----------
       300      62976
--
--
VARIABLE OP_ID NUMBER;
BEGIN
	:OP_ID := DBMS_SQL_MONITOR.BEGIN_OPERATION (DBOP_NAME => 'ORA.SH.CUSTOMERS', SESSION_ID=> &Enter_SID,
	SESSION_SERIAL=> &Enter_Serial, FORCED_TRACKING => 'Y'); -- or DBMS_SQL_MONITOR.FORCE_TRACKING
END;
/
print :OP_ID
--
     OP_ID
----------
         3
--
SELECT /*+ MONITOR */
	C.CUST_ID,
	C.CUST_LAST_NAME,
	C.CUST_FIRST_NAME,
	S.PROD_ID,
	P.PROD_NAME,
	S.TIME_ID
FROM
	SH.SALES S,
	SH.CUSTOMERS C,
	SH.PRODUCTS P
WHERE
	S.CUST_ID = C.CUST_ID AND S.PROD_ID = P.PROD_ID
ORDER BY C.CUST_ID, S.TIME_ID;
--
set linesize 180
column DBOP_NAME format a20
column IN_DBOP_NAME format a20
column SQL_ID format a13
column BUFFER_GETS format 99999999
column DISK_READS format 999999
column CPU_TIME format 99999999
column ELAPSED_TIME format 99999999
column SQL_EXEC_START format a10
SELECT
	DBOP_NAME,
	IN_DBOP_NAME,
	SQL_ID,
	BUFFER_GETS,
	DISK_READS,
	DISK_READS,
	TO_CHAR(CPU_TIME/1000000,'000.00') AS CPU_SEC,
	TO_CHAR(ELAPSED_TIME/1000000,'000.00') AS ELA_SEC,
	SQL_EXEC_START
FROM
	V$SQL_MONITOR
WHERE (DBOP_NAME='ORA.SH.CUSTOMERS' OR IN_DBOP_NAME='ORA.SH.CUSTOMERS')
ORDER BY SQL_EXEC_START DESC;
--
COL ID FORMAT 999
COL OPERATION FORMAT A40
COL OBJECT FORMAT A18
COL STATUS FORMAT A8
SET COLSEP '|'
SET LINES 180
SELECT
	P.ID,
	RPAD(' ',P.DEPTH*2, ' ') || P.OPERATION OPERATION,
	P.OBJECT_NAME OBJECT,
	P.CARDINALITY CARD,
	P.COST COST,
	SUBSTR(M.STATUS,1,4) STATUS,
	M.OUTPUT_ROWS
FROM
	V$SQL_PLAN P, V$SQL_PLAN_MONITOR M
WHERE
	P.SQL_ID=M.SQL_ID AND P.CHILD_ADDRESS=M.SQL_CHILD_ADDRESS AND P.PLAN_HASH_VALUE=M.SQL_PLAN_HASH_VALUE
	AND P.ID=M.PLAN_LINE_ID AND M.SQL_ID='1w6n2z4fjyw4k'
ORDER BY P.ID;


SELECT
	'DBOP_NAME: ' || DBOP_NAME ||CHR(10) || 'IN_DBOP_NAME: ' || IN_DBOP_NAME
	|| CHR (10) || 'Buffer Gets: ' || BUFFER_GETS || CHR(10) || 'Disk Reads: ' || DISK_READS
	|| CHR(10) || 'CPU Time: ' || TO_CHAR(CPU_TIME/1000000,'000.00') || CHR(10)
	|| 'Elapsed Time: ' || TO_CHAR(ELAPSED_TIME/1000000,'000.00') || CHR(10)
	|| 'Status: ' || STATUS || CHR(10) || 'SQL_ID: ' || SQL_ID || CHR(10) || 'SQL_TEXT: ' || SQL_TEXT AS "Operation Tasks"
FROM V$SQL_MONITOR
WHERE (DBOP_NAME='ORA.SH.CUSTOMERS' OR IN_DBOP_NAME='ORA.SH.CUSTOMERS')
ORDER BY DBOP_NAME;
--

BEGIN
	DBMS_SQL_MONITOR.END_OPERATION (DBOP_NAME => 'ORA.SH.CUSTOMERS', DBOP_EID => :OP_ID);
END;
/
SQL Id: 1w6n2z4fjyw4k
SQL Execution Id: 16777216
SQL Execution Start: 25-Jul-2022 02:50:58

--
