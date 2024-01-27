--Managing Historical Optimizer Statistics
--
--Retriveing Current Statistics History Retention Value
SELECT 'The retention setting is ' || DBMS_STATS.GET_STATS_HISTORY_RETENTION || ' days' "Statistics History Retention" FROM DUAL;
--
--Default Retention period is 31 days.
--
Statistics History Retention
------------------------------------
The retention setting is 31 days
--
--Retrieve the oldest date (timestamp) when the statistics was available. User cannot restore statistics earlier than this date.
--
SELECT 'Earliest restore date is ' || DBMS_STATS.GET_STATS_HISTORY_AVAILABILITY "Oldest Available Statistics" FROM DUAL;
--
Oldest Available Statistics
------------------------------------------------------------------
Earliest restore date is 29-MAY-22 10.30.22.654243000 AM +05:30
--
--Change the Statistcs Retention level to 7 days
--
exec DBMS_STATS.ALTER_STATS_HISTORY_RETENTION(7)
--
SELECT 'The retention setting is ' || DBMS_STATS.GET_STATS_HISTORY_RETENTION || ' days' "Statistics History Retention" FROM DUAL;
--
--Check if changing the retention level affects the oldest timestamp when stat history is available.
--
SELECT 'Earliest restore date is ' || DBMS_STATS.GET_STATS_HISTORY_AVAILABILITY "Oldest Available Statistics" FROM DUAL;
--
--Changing the retention period to a narrower time frame window does not purge the statistics.
--However, the database eventually purges the history statistics to the retention period time (every 10 minutes).
Oldest Available Statistics
--------------------------------------------------------------------
Earliest restore date is 29-MAY-22 10.30.22.654243000 AM +05:30
--
--You can manually purge the statistics however.
set timing on
exec DBMS_STATS.PURGE_STATS( SYSDATE-7 )
set timing off
--
SELECT 'Earliest restore date is ' || DBMS_STATS.GET_STATS_HISTORY_AVAILABILITY "Oldest Available Statistics" FROM DUAL;
--
--It's changed now.
Oldest Available Statistics
------------------------------------------------------------------
Earliest restore date is 22-JUN-22 03.09.11.000000000 PM +05:30
--
--Managing Space used by Optimizer Statistics
--
--Optimizer Stat history is stored in SYSAUX tablespace. To check how much space is consumed by Optimize Stat in SYSAUX:
col OCCUPANT_DESC format a55
col MOVE_PROCEDURE format a15
col MOVE_PROCEDURE_DESC format a25
SELECT OCCUPANT_DESC, SPACE_USAGE_KBYTES/1024 MB, MOVE_PROCEDURE,
MOVE_PROCEDURE_DESC FROM V$SYSAUX_OCCUPANTS WHERE OCCUPANT_NAME = 'SM/OPTSTAT';
--
--25 MB of space is consumed by Optimizer stat.
OCCUPANT_DESC                                                   MB MOVE_PROCEDURE  MOVE_PROCEDURE_DESC
------------------------------------------------------- ---------- --------------- -------------------------
Server Manageability - Optimizer Statistics History         25.125                 *** MOVE PROCEDURE NOT APPLICABLE ***
--
--To know what are the tables in which Histograms are stored.
show parameter block_size
--
NAME                                 TYPE        VALUE
------------------------------------ ----------- ------------------------------
db_block_size                        integer     8192
--
col TABLE_NAME format a30
SELECT TABLE_NAME, BLOCKS*8/1024 MB
FROM DBA_TABLES
WHERE TABLE_NAME LIKE 'WRI$_OPTSTAT%HISTORY'
ORDER BY BLOCKS;
--
TABLE_NAME                             MB
------------------------------ ----------
WRI$_OPTSTAT_AUX_HISTORY         .0390625
WRI$_OPTSTAT_IND_HISTORY         .1015625
WRI$_OPTSTAT_TAB_HISTORY           .15625
WRI$_OPTSTAT_HISTHEAD_HISTORY    1.265625
WRI$_OPTSTAT_HISTGRM_HISTORY    5.6953125
--
--Reporting Past Statistics gathering Operations
--
SET LINES 200 PAGES 0
SET LONG 100000
COLUMN REPORT FORMAT A200
VARIABLE MY_REPORT CLOB;
BEGIN
	:MY_REPORT := DBMS_STATS.REPORT_STATS_OPERATIONS(DETAIL_LEVEL => 'TYPICAL', SINCE => SYSDATE-7, UNTIL => SYSDATE, FORMAT => 'HTML');
END;
/
spool C:\Users\Sabya\Documents\Technical\Udemy\barakhasqltuning\sql\sec7\myreport.html
print :MY_REPORT
spool off
--
--Generate report for a single Operation ID
--
SET LINES 200 PAGES 0
SET LONG 100000
COLUMN REPORT FORMAT A200
VARIABLE MY_REPORT CLOB;
BEGIN
	:MY_REPORT :=DBMS_STATS.REPORT_SINGLE_STATS_OPERATION (OPID => 1076 , FORMAT => 'HTML');
END;
/
spool C:\Users\Sabya\Documents\Technical\Udemy\barakhasqltuning\sql\sec7\ops_1076_report.html
print :MY_REPORT
spool off
--
