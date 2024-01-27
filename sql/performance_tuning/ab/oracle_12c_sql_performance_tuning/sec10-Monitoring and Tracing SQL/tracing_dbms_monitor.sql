--
-- Open two SQLplus windows
sqlplus tkyte/oracle@db19c01
sqlplus soe/oracle@db19c01
--
-- In tkyte window check the TIMES_STATISTICS parameter. It should be TRUE.
SHOW PARAMETER TIMED_STATISTICS
--
-- Obtain the trace folder from tkyte window.
SELECT VALUE FROM V$DIAG_INFO WHERE NAME = 'Diag Trace';
--
VALUE
----------------------------------------------------
/u01/app/oracle/diag/rdbms/cdb01/cdb01/trace
--
-- Add a new environment variable for trace directory in DB server in .bash_profile (if not existing already).
export TRACE_DIR=/u01/app/oracle/diag/rdbms/cdb01/cdb01/trace
--
-- rerun .bash__profile
. .bash_profile
--
-- In the client window (SOE) add client identifier
exec DBMS_SESSION.SET_IDENTIFIER('SOE1');
--
-- In the Tkyte window enable statistics gathering for the SOE1 client identifier
-- 
exec DBMS_MONITOR.CLIENT_ID_STAT_ENABLE(CLIENT_ID => 'SOE1');
--
col PRIMARY_ID format a10
col QUALIFIER_ID1 format a15
col QUALIFIER_ID2 format a15
SELECT 
	AGGREGATION_TYPE, 
	PRIMARY_ID, 
	QUALIFIER_ID1, 
	QUALIFIER_ID2
FROM 
	DBA_ENABLED_AGGREGATIONS;
--
AGGREGATION_TYPE      PRIMARY_ID QUALIFIER_ID1   QUALIFIER_ID2
--------------------- ---------- --------------- ---------------
CLIENT_ID             SOE1	
--
-- In the client window (SOE) submit the SQL
--
SELECT * FROM CUSTOMERS FETCH FIRST 9000 ROWS ONLY;
--
-- In tkyte window observe the stat
col STAT_NAME format a40
col STAT_NAME_IN_MICRO_SEC format a50
SELECT 
	STAT_NAME, 
	VALUE
FROM 
	V$CLIENT_STATS
WHERE 
	CLIENT_IDENTIFIER = 'SOE1' AND VALUE <>0;
--
STAT_NAME                                     VALUE
---------------------------------------- ----------
user calls                                      602 /* Number of user calls such as login, parse, fetch, or execute */
DB time                                      227422
DB CPU                                       264536
parse count (total)                              22 /* Total number of parse calls (hard + soft + describe) */
parse time elapsed                            29848
execute count                                   411 /* Total number of calls (user and recursive) that executed SQL statements */
sql execute elapsed time                      54353 /* Amount of elapsed time SQL statements are executing. Fetch + Execute */
opened cursors cumulative                       411
session logical reads                          2330
workarea executions - optimal                    25
session cursor cache hits                       398
--
-- Terminate the SOE session and login again as SOE. 
-- Set the client identifier again
exec DBMS_SESSION.SET_IDENTIFIER('SOE1');
--
-- In tkyte window observe the stat
col STAT_NAME format a40
col STAT_NAME_IN_MICRO_SEC format a50
SELECT 
	STAT_NAME, 
	VALUE
FROM 
	V$CLIENT_STATS
WHERE 
	CLIENT_IDENTIFIER = 'SOE1' AND VALUE <>0;
--
-- Observe that the staistics is now updated - Stat in V$CLIENT_STATS is always cummulative for each client identifier.	
--
STAT_NAME                                     VALUE
---------------------------------------- ----------
user calls                                     1187
DB time                                      507365
DB CPU                                       579919
parse count (total)                              23
parse time elapsed                            29926
execute count                                   412
sql execute elapsed time                      86375
opened cursors cumulative                       412
session logical reads                          3051
redo size                                       132
workarea executions - optimal                    25
session cursor cache hits                       398
db block changes                                  1
--
-- Disabling Statistics for Client identifier
--
exec DBMS_MONITOR.CLIENT_ID_STAT_DISABLE(CLIENT_ID => 'SOE1');
--
-- This will return no rows
--
SELECT STAT_NAME, VALUE
FROM V$CLIENT_STATS
WHERE CLIENT_IDENTIFIER = 'SOE1' AND VALUE <>0;
--
--
-- Enabling Tracing for a Session
-- 
-- In the Tkyte window get the SESSION_ID and SERIAL# of the SOE session.
SELECT SID, SERIAL# FROM V$SESSION WHERE USERNAME = 'SOE';
--
       SID    SERIAL#
---------- ----------
       295      64725
--
-- Enable tracing for the SOE session in the Tkyte session.       
--
DEFINE v_sid = 295
DEFINE v_serial = 64725
BEGIN
	DBMS_MONITOR.SESSION_TRACE_ENABLE( SESSION_ID => &v_sid, SERIAL_NUM => &v_serial, WAITS => TRUE, BINDS => FALSE);
END;
/
--
-- Get the tracefile name (Tkyte window)
--
SELECT 
	P.TRACEFILE
FROM 
	V$SESSION S
JOIN 
	V$PROCESS P 
ON 
	S.PADDR = P.ADDR
WHERE 
	S.SID = &V_SID;
--
TRACEFILE
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
/u01/app/oracle/diag/rdbms/cdb01/cdb01/trace/cdb01_ora_28688.trc
--
-- In the client window (SOE) run the following query
SELECT * FROM EMP;
--
-- Open the tracefile in Putty session
vim /u01/app/oracle/diag/rdbms/cdb01/cdb01/trace/cdb01_ora_28688.trc
--
-- Disable tracing in Tkyte window
--
BEGIN
	DBMS_MONITOR.SESSION_TRACE_DISABLE( SESSION_ID => &v_sid, SERIAL_NUM => &v_serial);
END;
/
--
-- Enabling Tracing for Multiple Sessions
-- 
-- In the SOE window connect to another session and set a Module called PROCESS_ORDERS.
conn soe/oracle@db19c01
exec DBMS_APPLICATION_INFO.SET_MODULE( MODULE_NAME => 'PROCESS_ORDERS', ACTION_NAME=>NULL);
--
-- In the SOE window set a tracefile identifier call PORDERS.
ALTER SESSION SET TRACEFILE_IDENTIFIER = 'PORDERS';
--
-- In the Tkyte window enable tracing for the module PROCESS_ORDERS. You can provide SERVICE_NAME if there are multiple services
ALTER SYSTEM FLUSH SHARED_POOL;
exec DBMS_MONITOR.SERV_MOD_ACT_TRACE_ENABLE(SERVICE_NAME=>'db19c01', MODULE_NAME=>'PROCESS_ORDERS');
--
col PRIMARY_ID format a10
col QUALIFIER_ID1 format a15
SELECT 
	TRACE_TYPE, 
	PRIMARY_ID,
	QUALIFIER_ID1,
	WAITS,BINDS,
	PLAN_STATS
FROM 
	DBA_ENABLED_TRACES;
--
TRACE_TYPE            PRIMARY_ID QUALIFIER_ID1   WAITS BINDS PLAN_STATS
--------------------- ---------- --------------- ----- ----- ----------
SERVICE_MODULE        db19c01    PROCESS_ORDERS  TRUE  FALSE FIRST_EXEC
--
-- In the SOE window run the following set of SQL. The SQL re-connets to the database twice to simulate multiple session
--
SELECT /*+ USE_NL(A B) NO_PARALLEL */ COUNT(*) FROM CUSTOMERS A, EMP B ;
--
SELECT 
	CUSTOMERS.CUSTOMER_ID,
	InitCap(CUST_FIRST_NAME) FIRST_NAME,
	InitCap(CUST_LAST_NAME) LAST_NAME,
	ENAME ACCOUNT_MANAGER,
	ROUND(MONTHS_BETWEEN(SYSDATE,CUSTOMER_SINCE)/12,1) CUSTOMER_YEARS,
	TO_CHAR(SUM(ORDER_TOTAL),'999,999,999') TOTAL
FROM 
	ORDERS, CUSTOMERS, EMP
WHERE 
	CUSTOMERS.CUSTOMER_ID = ORDERS.CUSTOMER_ID AND EMP_NO = ACCOUNT_MGR_ID
GROUP BY
	CUSTOMERS.CUSTOMER_ID,
	InitCap(CUST_FIRST_NAME),
	InitCap(CUST_LAST_NAME),
	ENAME,
	ROUND(MONTHS_BETWEEN(SYSDATE,CUSTOMER_SINCE)/12,1)
ORDER BY 
	SUM(ORDER_TOTAL) DESC;
--	
conn soe/oracle@db19c01
EXEC DBMS_APPLICATION_INFO.SET_MODULE( MODULE_NAME => 'PROCESS_ORDERS', ACTION_NAME=>NULL);
--
ALTER SESSION SET TRACEFILE_IDENTIFIER = 'PORDERS';
--
VARIABLE month_year VARCHAR2(7)
EXEC :month_year := '01-2010'
SELECT /* my query */ TO_CHAR(SUM(ORDER_TOTAL),'999,999,999') TOTAL FROM
SOE.ORDERS WHERE TO_CHAR(ORDER_DATE,'MM-RRRR') =:month_year;
EXEC :month_year := '02-2010';
SELECT /* my query */ TO_CHAR(SUM(ORDER_TOTAL),'999,999,999') TOTAL FROM
SOE.ORDERS WHERE TO_CHAR(ORDER_DATE,'MM-RRRR') =:month_year;
EXEC :month_year := '03-2010';
SELECT /* my query */ TO_CHAR(SUM(ORDER_TOTAL),'999,999,999') TOTAL FROM
SOE.ORDERS WHERE TO_CHAR(ORDER_DATE,'MM-RRRR') =:month_year;
EXEC :month_year := '04-2010';
SELECT /* my query */ TO_CHAR(SUM(ORDER_TOTAL),'999,999,999') TOTAL FROM
SOE.ORDERS WHERE TO_CHAR(ORDER_DATE,'MM-RRRR') =:month_year;
--
conn soe/oracle@db19c01
EXEC DBMS_APPLICATION_INFO.SET_MODULE( MODULE_NAME => 'PROCESS_ORDERS', ACTION_NAME=>NULL);
--
ALTER SESSION SET TRACEFILE_IDENTIFIER = 'PORDERS';
--
SELECT /*+ USE_NL(A B) NO_PARALLEL */ COUNT(*) FROM CUSTOMERS A, EMP B ;
DECLARE
	V NUMBER;
BEGIN
	FOR I IN 1..100 LOOP
		SELECT COUNT(*) INTO V FROM CUSTOMERS WHERE CUSTOMER_ID=I;
	END LOOP;
END;
/
--
-- In the Tykte window, disable tracing
--
exec DBMS_MONITOR.SERV_MOD_ACT_TRACE_DISABLE(SERVICE_NAME=>'db19c01', MODULE_NAME=>'PROCESS_ORDERS');
--
-- During the monitoring period, the client made three sessions. Each session has a trace file. So we need to consolidate
-- those files into a single file so that we can use the output using tkprof utility. To merge the files we'll use trcsess
-- utility.
cd $TRACE_DIR
--
ls *PORDERS.trc
--
cdb01_ora_7201_PORDERS.trc  cdb01_ora_7472_PORDERS.trc  cdb01_ora_7478_PORDERS.trc
--
-- Consolidate (merge) the trace files using trcsess utility
--
trcsess output="$TRACE_DIR/PROCESS_ORDERS.trc" module="PROCESS_ORDERS"
ls -alh PROCESS_ORDERS.trc
--
-- A consolidated file is generated
-rw-r--r--. 1 oracle oinstall 730K Jul 31 00:53 PROCESS_ORDERS.trc
--
-- Using tkprof Utility
--
-- If you just issue tkprof command without using any options, you get all its options.
Usage: tkprof tracefile outputfile [explain= ] [table= ]
              [print= ] [insert= ] [sys= ] [sort= ]
  table=schema.tablename   Use 'schema.tablename' with 'explain=' option.
  explain=user/password    Connect to ORACLE and issue EXPLAIN PLAN.
  print=integer    List only the first 'integer' SQL statements.
  pdbtrace=user/password   Connect to ORACLE to retrieve SQL trace records.
  aggregate=yes|no
  insert=filename  List SQL statements and data inside INSERT statements.
  sys=no           TKPROF does not list SQL statements run as user SYS.
  record=filename  Record non-recursive statements found in the trace file.
  waits=yes|no     Record summary for any wait events found in the trace file.
  sort=option      Set of zero or more of the following sort options:
    prscnt  number of times parse was called
    prscpu  cpu time parsing
    prsela  elapsed time parsing
    prsdsk  number of disk reads during parse
    prsqry  number of buffers for consistent read during parse
    prscu   number of buffers for current read during parse
    prsmis  number of misses in library cache during parse
    execnt  number of execute was called
    execpu  cpu time spent executing
    exeela  elapsed time executing
    exedsk  number of disk reads during execute
    exeqry  number of buffers for consistent read during execute
    execu   number of buffers for current read during execute
    exerow  number of rows processed during execute
    exemis  number of library cache misses during execute
    fchcnt  number of times fetch was called
    fchcpu  cpu time spent fetching
    fchela  elapsed time fetching
    fchdsk  number of disk reads during fetch
    fchqry  number of buffers for consistent read during fetch
    fchcu   number of buffers for current read during fetch
    fchrow  number of rows fetched
    userid  userid of user that parsed the cursor
--
-- use tkprof utility to convert the PROCESS_ORDERS.trc to a readble format (process_orders.log)

tkprof PROCESS_ORDERS.trc PROCESS_ORDERS.log SYS=no waits=yes aggregate=yes sort="(exeela,prsela,fchela)"
--
vim PROCESS_ORDERS.log
--
Trace file: PROCESS_ORDERS.trc
Sort options: exeela  prsela  fchela
********************************************************************************
count    = number of times OCI procedure was executed
cpu      = cpu time in seconds executing
elapsed  = elapsed time in seconds executing
disk     = number of physical reads of buffers from disk
query    = number of buffers gotten for consistent read
current  = number of buffers gotten in current mode (usually for update)
rows     = number of rows processed by the fetch or execute call
********************************************************************************

SQL ID: 0jbdc3jrgntx0 Plan Hash: 1471189219

SELECT /*+ USE_NL(A B) NO_PARALLEL */ COUNT(*)
FROM
 CUSTOMERS A, EMP B


call     count       cpu    elapsed       disk      query    current        rows
------- ------  -------- ---------- ---------- ---------- ----------  ----------
Parse        2      0.00       0.01          0          0          0           0
Execute      2      0.00       0.00          0          0          0           0
Fetch        4      4.70       5.51        101     174056          0           2
------- ------  -------- ---------- ---------- ---------- ----------  ----------
total        8      4.70       5.52        101     174056          0           2

Misses in library cache during parse: 1
Optimizer mode: ALL_ROWS
Parsing user id: 108
Number of plan statistics captured: 2

Rows (1st) Rows (avg) Rows (max)  Row Source Operation
---------- ---------- ----------  ---------------------------------------------------
         1          1          1  SORT AGGREGATE (cr=87028 pr=50 pw=0 time=2758668 us starts=1)
  40172937   40172937   40172937   NESTED LOOPS  (cr=87028 pr=50 pw=0 time=9437174 us starts=1 cost=22803 size=0 card=40172937)
       879        879        879    INDEX FAST FULL SCAN EMP_PK (cr=6 pr=2 pw=0 time=3159 us starts=1 cost=2 size=0 card=879)(object id 73177)
  40172937   40172937   40172937    INDEX FAST FULL SCAN CUSTOMERS_PK (cr=87022 pr=48 pw=0 time=3799390 us starts=879 cost=26 size=0 card=45703)(object id 73173)
Elapsed times include waiting on following events:
  Event waited on                             Times   Max. Wait  Total Waited
  ----------------------------------------   Waited  ----------  ------------
  SQL*Net message to client                       4        0.00          0.00
  PGA memory operation                            3        0.00          0.00
  Disk file operations I/O                        2        0.00          0.00
  asynch descriptor resize                        1        0.00          0.00
  db file sequential read                         2        0.00          0.00
  db file scattered read                          2        0.00          0.00
  SQL*Net message from client                     4        2.11          2.14
********************************************************************************

SELECT
CUSTOMERS.CUSTOMER_ID,
InitCap(CUST_FIRST_NAME) FIRST_NAME,
InitCap(CUST_LAST_NAME) LAST_NAME,
ENAME ACCOUNT_MANAGER,
ROUND(MONTHS_BETWEEN(SYSDATE,CUSTOMER_SINCE)/12,1) CUSTOMER_YEARS,
TO_CHAR(SUM(ORDER_TOTAL),'999,999,999') TOTAL
FROM
ORDERS, CUSTOMERS, EMP
WHERE
CUSTOMERS.CUSTOMER_ID = ORDERS.CUSTOMER_ID AND EMP_NO = ACCOUNT_MGR_ID
GROUP BY
CUSTOMERS.CUSTOMER_ID,
InitCap(CUST_FIRST_NAME),
InitCap(CUST_LAST_NAME),
ENAME,
ROUND(MONTHS_BETWEEN(SYSDATE,CUSTOMER_SINCE)/12,1)
ORDER BY
SUM(ORDER_TOTAL) DESC
call     count       cpu    elapsed       disk      query    current        rows
------- ------  -------- ---------- ---------- ---------- ----------  ----------
Parse        1      0.00       0.00          0          0          0           0
Execute      1      0.00       0.00          0          0          0           0
Fetch     1322      1.73       2.11      18134      18402          0       19810
------- ------  -------- ---------- ---------- ---------- ----------  ----------
total     1324      1.73       2.12      18134      18402          0       19810

Misses in library cache during parse: 1
Optimizer mode: ALL_ROWS
Parsing user id: 108
Number of plan statistics captured: 1

Rows (1st) Rows (avg) Rows (max)  Row Source Operation
---------- ---------- ----------  ---------------------------------------------------
     19810      19810      19810  SORT ORDER BY (cr=18402 pr=18134 pw=0 time=2102687 us starts=1 cost=47005 size=83828340 card=1352070)
     19810      19810      19810   HASH GROUP BY (cr=18402 pr=18134 pw=0 time=2081294 us starts=1 cost=47005 size=83828340 card=1352070)
   1347831    1347831    1347831    HASH JOIN  (cr=18402 pr=18134 pw=0 time=770651 us starts=1 cost=6570 size=83828340 card=1352070)
       879        879        879     TABLE ACCESS FULL EMP (cr=8 pr=0 pw=0 time=153 us starts=1 cost=5 size=17580 card=879)
   1352070    1352070    1352070     HASH JOIN  (cr=18394 pr=18134 pw=0 time=1040148 us starts=1 cost=6560 size=56786940 card=1352070)
     45703      45703      45703      NESTED LOOPS  (cr=764 pr=506 pw=0 time=50455 us starts=1 cost=6560 size=56786940 card=1352070)
     45703      45703      45703       NESTED LOOPS  (cr=764 pr=506 pw=0 time=38963 us starts=1)
     45703      45703      45703        STATISTICS COLLECTOR  (cr=764 pr=506 pw=0 time=25175 us starts=1)
     45703      45703      45703         TABLE ACCESS FULL CUSTOMERS (cr=764 pr=506 pw=0 time=12572 us starts=1 cost=214 size=1462496 card=45703)
         0          0          0        INDEX RANGE SCAN ORD_CUSTOMER_IX (cr=0 pr=0 pw=0 time=0 us starts=0)(object id 73171)
         0          0          0       TABLE ACCESS BY INDEX ROWID ORDERS (cr=0 pr=0 pw=0 time=0 us starts=0 cost=4835 size=300 card=30)
   1352070    1352070    1352070      TABLE ACCESS FULL ORDERS (cr=17630 pr=17628 pw=0 time=274343 us starts=1 cost=4835 size=13520700 card=1352070)

Elapsed times include waiting on following events:
  Event waited on                             Times   Max. Wait  Total Waited
  ----------------------------------------   Waited  ----------  ------------
  SQL*Net message to client                    1322        0.00          0.00
  PGA memory operation                          136        0.00          0.00
  db file scattered read                          4        0.00          0.02
  db file sequential read                         1        0.00          0.00
  ASM IO for non-blocking poll                  143        0.00          0.00
  direct path read                                6        0.00          0.03
  SQL*Net message from client                  1322        0.00          2.52
********************************************************************************

SELECT /* my query */ TO_CHAR(SUM(ORDER_TOTAL),'999,999,999') TOTAL FROM
SOE.ORDERS WHERE TO_CHAR(ORDER_DATE,'MM-RRRR') =:month_year

call     count       cpu    elapsed       disk      query    current        rows
------- ------  -------- ---------- ---------- ---------- ----------  ----------
Parse        4      0.00       0.00          0          0          0           0
Execute      4      0.00       0.00          0          0          0           0
Fetch        8      0.85       1.92      17627      70521          0           4
------- ------  -------- ---------- ---------- ---------- ----------  ----------
total       16      0.85       1.92      17627      70521          0           4

Misses in library cache during parse: 1
Misses in library cache during execute: 1
Optimizer mode: ALL_ROWS
Parsing user id: 108
Number of plan statistics captured: 3

Rows (1st) Rows (avg) Rows (max)  Row Source Operation
---------- ---------- ----------  ---------------------------------------------------
         1          1          1  SORT AGGREGATE (cr=17630 pr=5876 pw=0 time=531111 us starts=1)
      8871       8672       8960   TABLE ACCESS FULL ORDERS (cr=17630 pr=5876 pw=0 time=134052 us starts=1 cost=4856 size=216336 card=13521)

Elapsed times include waiting on following events:
  Event waited on                             Times   Max. Wait  Total Waited
  ----------------------------------------   Waited  ----------  ------------
  SQL*Net message to client                       8        0.00          0.00
  PGA memory operation                            1        0.00          0.00
  Disk file operations I/O                        2        0.00          0.00
  asynch descriptor resize                        1        0.00          0.00
  db file scattered read                        139        0.00          0.44
  SQL*Net message from client                     8        0.00          0.03
********************************************************************************

DECLARE
V NUMBER;
BEGIN
FOR I IN 1..100 LOOP
SELECT COUNT(*) INTO V FROM CUSTOMERS WHERE CUSTOMER_ID=I;
END LOOP;
END;

call     count       cpu    elapsed       disk      query    current        rows
------- ------  -------- ---------- ---------- ---------- ----------  ----------
Parse        1      0.08       0.00          0          0          0           0
Execute      1      0.00       0.00          0          0          0           1
Fetch        0      0.00       0.00          0          0          0           0
------- ------  -------- ---------- ---------- ---------- ----------  ----------
total        2      0.08       0.00          0          0          0           1

Misses in library cache during parse: 1
Optimizer mode: ALL_ROWS
Parsing user id: 108

Elapsed times include waiting on following events:
  Event waited on                             Times   Max. Wait  Total Waited
  ----------------------------------------   Waited  ----------  ------------
  SQL*Net message to client                       1        0.00          0.00
********************************************************************************
SQL ID: gnd6vb2vgv9yc Plan Hash: 3730350280

SELECT COUNT(*)
FROM
 CUSTOMERS WHERE CUSTOMER_ID=:B1


call     count       cpu    elapsed       disk      query    current        rows
------- ------  -------- ---------- ---------- ---------- ----------  ----------
Parse        1      0.00       0.00          0          0          0           0
Execute    100      0.00       0.00          0          0          0           0
Fetch      100      0.00       0.00          0        200          0         100
------- ------  -------- ---------- ---------- ---------- ----------  ----------
total      201      0.00       0.00          0        200          0         100

Misses in library cache during parse: 1
Misses in library cache during execute: 1
Optimizer mode: ALL_ROWS
Parsing user id: 108     (recursive depth: 1)
Number of plan statistics captured: 1

Rows (1st) Rows (avg) Rows (max)  Row Source Operation
---------- ---------- ----------  ---------------------------------------------------
         1          1          1  SORT AGGREGATE (cr=2 pr=0 pw=0 time=59 us starts=1)
         1          1          1   INDEX UNIQUE SCAN CUSTOMERS_PK (cr=2 pr=0 pw=0 time=20 us starts=1 cost=1 size=5 card=1)(object id 73173)

********************************************************************************

SQL ID: f14fz7r28n7bb Plan Hash: 0

BEGIN :month_year := '03-2010'; END;


call     count       cpu    elapsed       disk      query    current        rows
------- ------  -------- ---------- ---------- ---------- ----------  ----------
Parse        1      0.00       0.00          0          0          0           0
Execute      1      0.00       0.00          0          0          0           1
Fetch        0      0.00       0.00          0          0          0           0
------- ------  -------- ---------- ---------- ---------- ----------  ----------
total        2      0.00       0.00          0          0          0           1
Misses in library cache during parse: 1
Misses in library cache during execute: 1
Optimizer mode: ALL_ROWS
Parsing user id: 108

Elapsed times include waiting on following events:
  Event waited on                             Times   Max. Wait  Total Waited
  ----------------------------------------   Waited  ----------  ------------
  SQL*Net message to client                       1        0.00          0.00
  SQL*Net message from client                     1        0.00          0.00
********************************************************************************

SQL ID: g84rh273s18cg Plan Hash: 0

BEGIN :month_year := '04-2010'; END;


call     count       cpu    elapsed       disk      query    current        rows
------- ------  -------- ---------- ---------- ---------- ----------  ----------
Parse        1      0.00       0.00          0          0          0           0
Execute      1      0.00       0.00          0          0          0           1
Fetch        0      0.00       0.00          0          0          0           0
------- ------  -------- ---------- ---------- ---------- ----------  ----------
total        2      0.00       0.00          0          0          0           1

Misses in library cache during parse: 1
Misses in library cache during execute: 1
Optimizer mode: ALL_ROWS
Parsing user id: 108

Elapsed times include waiting on following events:
  Event waited on                             Times   Max. Wait  Total Waited
  ----------------------------------------   Waited  ----------  ------------
  SQL*Net message to client                       1        0.00          0.00
  SQL*Net message from client                     1        0.00          0.00
********************************************************************************

SQL ID: 1xsy79xnt2avk Plan Hash: 0

BEGIN :month_year := '01-2010'; END;
--
-- Re-run tkprof utility after adding the explain parameter
--
-- When you add this parameter, tkprof connects to the database using the user provided to the parameter
-- *.trc files can be opened with SQL Developer. It provides List View, Statistics View and List View.