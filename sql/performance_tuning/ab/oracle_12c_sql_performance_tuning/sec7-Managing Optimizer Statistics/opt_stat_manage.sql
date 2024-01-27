--Managing Optimizer Statistics
--
--Example::1 Pending Statistics
--
--drop SOE.ORDERS2
--
SET AUTOT OFF
DROP TABLE SOE.ORDERS2 PURGE;
--
--Create a new table SOE.ORDERS2
CREATE TABLE SOE.ORDERS2 ( ORDER_ID NUMBER(12), ORDER_DATE TIMESTAMP(6) WITH LOCAL TIME ZONE, ORDER_TOTAL NUMBER(8,2));
--
INSERT INTO SOE.ORDERS2 SELECT ORDER_ID, ORDER_DATE, ORDER_TOTAL FROM SOE.ORDERS WHERE ORDER_TOTAL <>0 FETCH FIRST 42000 ROWS ONLY;
--
COMMIT;
--
CREATE INDEX SOE.ORDERS2_TOTAL_IX ON SOE.ORDERS2(ORDER_TOTAL);
--
--Gather stat
exec DBMS_STATS.GATHER_TABLE_STATS(OWNNAME=>'SOE', TABNAME=>'ORDERS2', CASCADE=>TRUE);
--
--Check the number of rows.
SELECT NUM_ROWS FROM DBA_TAB_STATISTICS WHERE TABLE_NAME='ORDERS2' AND OWNER = 'SOE';
--
  NUM_ROWS
----------
     42000
--
--
SET AUTOT ON
SELECT * FROM SOE.ORDERS2 WHERE ORDER_TOTAL<=34;
--
--------------------------------------------------------------------------------------------------------
| Id  | Operation                           | Name             | Rows  | Bytes | Cost (%CPU)| Time     |
--------------------------------------------------------------------------------------------------------
|   0 | SELECT STATEMENT                    |                  |    21 |   420 |    22   (0)| 00:00:01 |
|   1 |  TABLE ACCESS BY INDEX ROWID BATCHED| ORDERS2          |    21 |   420 |    22   (0)| 00:00:01 |
|*  2 |   INDEX RANGE SCAN                  | ORDERS2_TOTAL_IX |    21 |       |     2   (0)| 00:00:01 |
--------------------------------------------------------------------------------------------------------
--
--Delete some rows
SET AUTOT OFF
DELETE SOE.ORDERS2 WHERE ORDER_TOTAL>35;
--
COMMIT;
--
SET AUTOT TRACE EXP
SELECT * FROM SOE.ORDERS2 WHERE ORDER_TOTAL<=34;
--
--Execution plan did not change as Stats is not updated
--------------------------------------------------------------------------------------
| Id  | Operation         | Name             | Rows  | Bytes | Cost (%CPU)| Time     |
--------------------------------------------------------------------------------------
|   0 | SELECT STATEMENT  |                  |     1 |     5 |     2   (0)| 00:00:01 |
|   1 |  SORT AGGREGATE   |                  |     1 |     5 |            |          |
|*  2 |   INDEX RANGE SCAN| ORDERS2_TOTAL_IX |    21 |   105 |     2   (0)| 00:00:01 |
--------------------------------------------------------------------------------------
--
SET AUTOT OFF
--Set the statistics not to be published.
exec DBMS_STATS.SET_TABLE_PREFS('SOE','ORDERS2','PUBLISH','FALSE');
--
--and gerenerate the Stat (the stat gathered will not be published)
exec DBMS_STATS.GATHER_TABLE_STATS('SOE','ORDERS2', CASCADE=>TRUE);
--
--Compare between table statistics and pending statistics (not yet published).
SELECT NUM_ROWS FROM DBA_TAB_STATISTICS WHERE TABLE_NAME='ORDERS2';
--
--Even though the Stat is generated it is not published so table statistics remain the same.
 NUM_ROWS
----------
     42000
--
--Pending Stat.
SELECT NUM_ROWS FROM DBA_TAB_PENDING_STATS WHERE TABLE_NAME='ORDERS2';
--
  NUM_ROWS
----------
        22
--
--Allow the optimizer use the pending stat instead of current statistics
ALTER SESSION SET OPTIMIZER_USE_PENDING_STATISTICS=TRUE;
--
--generate the Explain plan now.
SET AUTOT TRACE EXP
SELECT * FROM SOE.ORDERS2 WHERE ORDER_TOTAL<=34;
--
--Execution plan is changed now reflecting the cardinality almost correct (21 Vs 12).
--------------------------------------------------------------------------------------------------------
| Id  | Operation                           | Name             | Rows  | Bytes | Cost (%CPU)| Time     |
--------------------------------------------------------------------------------------------------------
|   0 | SELECT STATEMENT                    |                  |    12 |   228 |    13   (0)| 00:00:01 |
|   1 |  TABLE ACCESS BY INDEX ROWID BATCHED| ORDERS2          |    12 |   228 |    13   (0)| 00:00:01 |
|*  2 |   INDEX RANGE SCAN                  | ORDERS2_TOTAL_IX |    12 |       |     2   (0)| 00:00:01 |
--------------------------------------------------------------------------------------------------------
--
--Since we are happy with the current Statistics, we can publish the stat.
SET AUTOT OFF
exec DBMS_STATS.PUBLISH_PENDING_STATS('SOE','ORDERS2');
--
SELECT NUM_ROWS FROM DBA_TAB_STATISTICS WHERE TABLE_NAME='ORDERS2';
--
--Current statistics reflect the Pending stat now.
  NUM_ROWS
----------
        22
SELECT NUM_ROWS FROM DBA_TAB_PENDING_STATS WHERE TABLE_NAME='ORDERS2';
--
--Pending stat is deleted.
no rows selected
--
DROP TABLE SOE.ORDERS2 PURGE;
--
--Example::2 Locking Optimizer Statistics
--
DROP TABLE SOE.ORDERS2 PURGE;
--
CREATE TABLE SOE.ORDERS2 ( ORDER_ID NUMBER(12), ORDER_DATE TIMESTAMP(6) WITH LOCAL TIME ZONE, ORDER_TOTAL NUMBER(8,2));
--
INSERT INTO SOE.ORDERS2 SELECT ORDER_ID, ORDER_DATE, ORDER_TOTAL FROM SOE.ORDERS WHERE ORDER_TOTAL >100;
--
COMMIT;
--
CREATE INDEX SOE.ORDERS2_TOTAL_IX ON SOE.ORDERS2(ORDER_TOTAL);
--
exec DBMS_STATS.GATHER_TABLE_STATS(OWNNAME=>'SOE', TABNAME=>'ORDERS2', CASCADE=>TRUE);
--
--Check if Statistics is locked or not.
col STATTYPE_LOCKED format a20
SELECT STATTYPE_LOCKED, NUM_ROWS FROM DBA_TAB_STATISTICS WHERE TABLE_NAME='ORDERS2';
--
--Statistics not locked.
STATTYPE_LOCKED        NUM_ROWS
-------------------- ----------
                        1304324
--
--Lock table stat.
exec DBMS_STATS.LOCK_TABLE_STATS('SOE','ORDERS2');
--
--Statistics are locked now.
SELECT STATTYPE_LOCKED FROM DBA_TAB_STATISTICS WHERE TABLE_NAME='ORDERS2' AND OWNER = 'SOE';
--
STATTYPE_LOCKED
--------------------
ALL
--
SELECT STATTYPE_LOCKED FROM DBA_IND_STATISTICS WHERE TABLE_NAME='ORDERS2' AND OWNER = 'SOE';
--
STATTYPE_LOCKED
--------------------
ALL
--
--Try gather stat now
exec DBMS_STATS.GATHER_TABLE_STATS(OWNNAME=>'SOE', TABNAME=>'ORDERS2', CASCADE=>TRUE);
--
--Gather Stat fails as Stat is locked.
ERROR at line 1:
ORA-20005: object statistics are locked (stattype = ALL)
--
--Delete some of the records
DELETE SOE.ORDERS2 WHERE ORDER_TOTAL>115;
--
COMMIT;
--
--Check the execution plan
--
SET AUTOT ON
SELECT * FROM SOE.ORDERS2;
--
-----------------------------------------------------------------------------
| Id  | Operation         | Name    | Rows  | Bytes | Cost (%CPU)| Time     |
-----------------------------------------------------------------------------
|   0 | SELECT STATEMENT  |         |  1304K|    24M|  1135   (1)| 00:00:01 |
|   1 |  TABLE ACCESS FULL| ORDERS2 |  1304K|    24M|  1135   (1)| 00:00:01 |
-----------------------------------------------------------------------------
--
SET AUTOT OFF
--
--Unlock and refresh the statistics
exec DBMS_STATS.UNLOCK_TABLE_STATS('SOE', 'ORDERS2');
exec DBMS_STATS.GATHER_TABLE_STATS(OWNNAME=>'SOE', TABNAME=>'ORDERS2', CASCADE=>TRUE);
--
--Check the execution plan again
SET AUTOT ON
SELECT * FROM SOE.ORDERS2;
--
--It now reflects the correct cardinality.
-----------------------------------------------------------------------------
| Id  | Operation         | Name    | Rows  | Bytes | Cost (%CPU)| Time     |
-----------------------------------------------------------------------------
|   0 | SELECT STATEMENT  |         |   276 |  5520 |  1127   (1)| 00:00:01 |
|   1 |  TABLE ACCESS FULL| ORDERS2 |   276 |  5520 |  1127   (1)| 00:00:01 |
-----------------------------------------------------------------------------
--
SET AUTOT OFF
DROP TABLE SOE.ORDERS2 PURGE;
--
-- Example: 3:: Transporting Optimizer Statistics
--
-- In real life scenario we will transport Optimizer Statistics from one database to another 
-- but for sake of learning we will delete the stat of the same table and traport it to it.
--
--Create table SOE.ORDERS2
CREATE TABLE SOE.ORDERS2 ( ORDER_ID NUMBER(12), ORDER_DATE TIMESTAMP(6) WITH LOCAL TIME ZONE, ORDER_TOTAL NUMBER(8,2));
--
INSERT INTO SOE.ORDERS2 SELECT ORDER_ID, ORDER_DATE, ORDER_TOTAL FROM SOE.ORDERS WHERE ORDER_TOTAL >100;
--
COMMIT;
--
CREATE INDEX SOE.ORDERS2_TOTAL_IX ON SOE.ORDERS2(ORDER_TOTAL);
--
exec DBMS_STATS.GATHER_TABLE_STATS(OWNNAME=>'SOE', TABNAME=>'ORDERS2', CASCADE=>TRUE);
--
--Create a table (SOE_STATS) that can be used to store table statistics in it.
--It can be used to store Schema and DB statistics.
exec DBMS_STATS.CREATE_STAT_TABLE(OWNNAME=>'SOE',STATTAB=>'SOE_STATS');
--
-- Export the table statistics to this newly created table (SOE_STATS).
exec DBMS_STATS.EXPORT_TABLE_STATS(OWNNAME=>'SOE', TABNAME=>'ORDERS2', STATTAB=>'SOE_STATS', STATID=>NULL, STATOWN=>'SOE', CASCADE=>TRUE);
--
--export the SOE.SOE_STATS to Oracle directory using expdp utility.
expdp tkyte/oracle@db19c01 directory=DATA_PUMP_DIR dumpfile=SOE_STATS.dmp tables=SOE.SOE_STATS
--
--Delete the statistics of SOE.ORDERS2 table. In Real Life, we would import the statistics to a different database or schema.
--
exec DBMS_STATS.DELETE_TABLE_STATS (OWNNAME=>'SOE', TABNAME=>'ORDERS2');
--
SELECT NUM_ROWS FROM DBA_TAB_STATISTICS WHERE TABLE_NAME='ORDERS2' AND OWNER = 'SOE';
--
  NUM_ROWS
----------

--
--Drop the Staging Statistics table.
exec DBMS_STATS.DROP_STAT_TABLE('SOE','SOE_STATS');
--
--import the SOE.ORDERS2 table statistics from the dump file. SOE.SOE_STATS will be created and statistics loaded from dump file.
impdp tkyte/oracle@db19c01 directory=DATA_PUMP_DIR dumpfile=SOE_STATS.dmp tables=SOE.SOE_STATS
--
--Import table statistics into Data Dictionary.
exec DBMS_STATS.IMPORT_TABLE_STATS(OWNNAME=>'SOE', TABNAME=>'ORDERS2', STATTAB=>'SOE_STATS',STATID=>NULL,STATOWN=>'SOE');
--
SELECT NUM_ROWS FROM DBA_TAB_STATISTICS WHERE TABLE_NAME='ORDERS2' AND OWNER = 'SOE';
--
  NUM_ROWS
----------
   1304324
--
--Perform clean up
exec DBMS_STATS.DROP_STAT_TABLE('SOE','SOE_STATS');
DROP TABLE SOE.ORDERS2 PURGE;
rm /u01/app/oracle/admin/cdb01/dpdump/CBC7BE136B294E92E0536B38A8C04874/SOE_STATS.dmp
--
--
--Example: 3:: Setting Artificial Optimizer Statistics
--
--Craete a new table same as SOE.CUSTOMERS
CREATE TABLE SOE.CUSTOMERS2 AS SELECT * FROM SOE.CUSTOMERS WHERE CUSTOMER_ID=12732;
--
exec DBMS_STATS.GATHER_TABLE_STATS('SOE', 'CUSTOMERS2', CASCADE=>TRUE);
--
--Get Explain Plan
SET AUTOT ON EXP
SELECT * FROM SOE.CUSTOMERS2 WHERE CUSTOMER_ID=12732;
--
--------------------------------------------------------------------------------
| Id  | Operation         | Name       | Rows  | Bytes | Cost (%CPU)| Time     |
--------------------------------------------------------------------------------
|   0 | SELECT STATEMENT  |            |     1 |   117 |     3   (0)| 00:00:01 |
|*  1 |  TABLE ACCESS FULL| CUSTOMERS2 |     1 |   117 |     3   (0)| 00:00:01 |
--------------------------------------------------------------------------------
--
--Set Artificial Statistics for the table.
SET AUTOT OFF
exec DBMS_STATS.SET_TABLE_STATS( OWNNAME => 'SOE' , TABNAME => 'CUSTOMERS2' , NUMROWS => 100000 , NUMBLKS => 10000);
--
--Get Explain Plan
SET AUTOT ON EXP
SELECT * FROM SOE.CUSTOMERS2 WHERE CUSTOMER_ID=12732;
--
--The cost has increased significantly.
--------------------------------------------------------------------------------
| Id  | Operation         | Name       | Rows  | Bytes | Cost (%CPU)| Time     |
--------------------------------------------------------------------------------
|   0 | SELECT STATEMENT  |            |   100K|    11M|  2714   (1)| 00:00:01 |
|*  1 |  TABLE ACCESS FULL| CUSTOMERS2 |   100K|    11M|  2714   (1)| 00:00:01 |
--------------------------------------------------------------------------------
--
