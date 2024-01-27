--You can set Optimizer Statistics gathering preference at various levels such as Table, Schema, Database, or Global. 
--These settings becomes default when you do not specify any value in DBMS_STAT procedures. 
--You can also configure if these settings should override the specified settings in DBMS_STAT.
--
--Get the Optimizer Statistics gathering preference
-- 
--At Global level:: Using DBMS_STATS.GET_PREFS procedure
--
--Get default value of ESTIMATE_PERCENT (Global).
col EST_PERCENT format a30
SELECT DBMS_STATS.GET_PREFS (PNAME =>'ESTIMATE_PERCENT') EST_PERCENT FROM DUAL;
--
EST_PERCENT
------------------------------
DBMS_STATS.AUTO_SAMPLE_SIZE
--
--Get Default value at table level.
col STALE_PERCENT_ORDERS format a30
SELECT DBMS_STATS.GET_PREFS (PNAME =>'STALE_PERCENT', OWNNAME=>'SOE', TABNAME=>'ORDERS') EST_PERCENT_ORDERS FROM DUAL;
--
--STALE_PERCENT determines the percentage of rows in a table that have to change before the statistics 
--on that table are deemed stale and should be regathered.
EST_PERCENT_ORDERS
------------------------------
10
--
col METHOD_OPT format a30
SELECT DBMS_STATS.GET_PREFS (PNAME =>'METHOD_OPT') METHOD_OPT FROM DUAL;
--
--Histogram will be collected for all columns
METHOD_OPT
------------------------------
FOR ALL COLUMNS SIZE AUTO
--
--
--Get Default value at Schema level
SELECT DBMS_STATS.GET_PREFS (PNAME =>'METHOD_OPT', OWNNAME=>'SOE') METHOD_OPT FROM DUAL;
--
--
--Setting Optimizer Statistics Preference.
--
--Setting at Optimizer Statistics preference at Table Level
--SET_TABLE_PREFS::Sets Statistics gathering preference for the specified table when DBMS_STATS options are default.
--Makes the ESTIMATE PERCENT options default to 30%.
--
exec DBMS_STATS.SET_TABLE_PREFS (OWNNAME =>'SOE', TABNAME=>'ORDERS', PNAME =>'ESTIMATE_PERCENT', PVALUE =>'30');
--
--Check if it's changed
SELECT DBMS_STATS.GET_PREFS(PNAME =>'ESTIMATE_PERCENT', OWNNAME=>'SOE', TABNAME=>'ORDERS') EST_PERCENT_ORDERS FROM DUAL;
--
EST_PERCENT_ORDERS
------------------------------
  30.000000
--
--Gather stat for the table
exec DBMS_STATS.GATHER_TABLE_STATS (OWNNAME=>'SOE', TABNAME=>'ORDERS');
--
col TARGET format a40
col OPERATION format a40
col START_TIME format a17
col END_TIME format a17
--
SELECT OPERATION, TARGET, NOTES, START_TIME, END_TIME FROM DBA_OPTSTAT_OPERATIONS WHERE TARGET LIKE '%ORDERS%';
--
--Output::ESTIMATE_PERCENT has changed to 30.
--Note that this query will only show you the GATHER_*_STATS parameter value passed. The value in force may be difference.
<params><param name="ownname" val="SOE"/><param name="pname" val="ESTIMATE_PERCENT"/>
<param name="pvalue" val="30"/><param name="tabname" val="ORDERS"/></params>
--
--Setting at Optimizer Statistics preference at Schema Level
--SET_SCHEMA_PREFS::It calls SET_TABLE_PREFS for each table in the Schema. 
--It will not effect any new table created after it's run
--
--Set Estimate Percent to 20%
exec DBMS_STATS.SET_SCHEMA_PREFS(OWNNAME =>'SOE', PNAME =>'ESTIMATE_PERCENT', PVALUE => '20');
--
--Check Orders and Customer Tables' ESTIMATE_PERCENT now.
col EST_PERCENT format a30
SELECT DBMS_STATS.GET_PREFS(PNAME =>'ESTIMATE_PERCENT', OWNNAME=>'SOE', TABNAME=>'ORDERS') EST_PERCENT FROM DUAL;
--
--Changed from 30 to 20.
EST_PERCENT
------------------------------
  20.000000
--Check the Global preference.
SELECT DBMS_STATS.GET_PREFS(PNAME =>'ESTIMATE_PERCENT') EST_PERCENT FROM DUAL;
--
--It's AUTO_SAMPLE_SIZE.
EST_PERCENT
------------------------------
DBMS_STATS.AUTO_SAMPLE_SIZE
--
--Now create a new Table and check its ESTIMATE_PERCENT value.
--
CREATE TABLE SOE.ORDERS2 AS SELECT * FROM SOE.ORDERS WHERE 1<>1;
--
SELECT DBMS_STATS.GET_PREFS(PNAME =>'ESTIMATE_PERCENT', OWNNAME=>'SOE', TABNAME=>'ORDERS2') EST_PERCENT FROM DUAL;
--
--Since the table is created anew Global preference takes precedence over Schema/Table Settings.
EST_PERCENT
------------------------------
DBMS_STATS.AUTO_SAMPLE_SIZE
--
--If you set Schema level settings to NULL, Global settings takes place for the existing tables too.
--
exec DBMS_STATS.SET_SCHEMA_PREFS ( OWNNAME =>'SOE', PNAME =>'ESTIMATE_PERCENT', PVALUE =>NULL);
--
--Check ESTIMATE_PERCENT for an existing table.
SELECT DBMS_STATS.GET_PREFS(PNAME =>'ESTIMATE_PERCENT', OWNNAME=>'SOE', TABNAME=>'ORDERS') EST_PERCENT FROM DUAL;
--
--It's now reverted to AUTO_SAMPLE_SIZE from 20.
EST_PERCENT
------------------------------
DBMS_STATS.AUTO_SAMPLE_SIZE
--
--You can also delete the preference by using DELETE_*_PREFS procedure. Effect is same.
--
--Change the Schema settings first.
exec DBMS_STATS.SET_SCHEMA_PREFS(OWNNAME =>'SOE', PNAME =>'ESTIMATE_PERCENT', PVALUE => '20');
--
SELECT DBMS_STATS.GET_PREFS(PNAME =>'ESTIMATE_PERCENT', OWNNAME=>'SOE', TABNAME=>'ORDERS') EST_PERCENT FROM DUAL;
--
EST_PERCENT
------------------------------
  20.000000
--
--Delete the schema level preference
exec DBMS_STATS.DELETE_SCHEMA_PREFS(OWNNAME =>'SOE', PNAME =>'ESTIMATE_PERCENT');
--
SELECT DBMS_STATS.GET_PREFS(PNAME =>'ESTIMATE_PERCENT', OWNNAME=>'SOE', TABNAME=>'ORDERS') EST_PERCENT FROM DUAL;
--
--It's changed now to Global Settings.
EST_PERCENT
------------------------------
DBMS_STATS.AUTO_SAMPLE_SIZE
--
--Setting at Optimizer Statistics preference at Table Level
--SET_TABLE_PREFS::It calls SET_TABLE_PREFS for Table.
--It will not effect any new table created after it's run.
--
col EST_PERCENT format a30
SELECT DBMS_STATS.GET_PREFS(PNAME =>'ESTIMATE_PERCENT', OWNNAME=>'SOE', TABNAME=>'ORDERS2') EST_PERCENT FROM DUAL;
--
EST_PERCENT
------------------------------
DBMS_STATS.AUTO_SAMPLE_SIZE
--
exec DBMS_STATS.SET_TABLE_PREFS (OWNNAME=>'SOE', TABNAME=>'ORDERS2', PNAME =>'ESTIMATE_PERCENT', PVALUE => '40');
--
--If you delete the preference or set to NULL, it would assume the global setting.
--
exec DBMS_STATS.DELETE_TABLE_PREFS(OWNNAME =>'SOE', TABNAME=>'ORDERS2', PNAME =>'ESTIMATE_PERCENT');
--
--PREFERENCE_OVERRIDES_PARAMETER (As of Oracle 12.2)
--When it's FALSE (default): GATHER_*_STATS (parameters) overrides -> TABLE Preference overrides -> Glocal Preference.
--When it's TRUE: TABLE Preference overrides -> Glocal Preference overrides -> GATHER_*_STATS (parameters).
--
--Scope::Global, Database, Table and Schema.
--
--Set PREFERENCE_OVERRIDES_PARAMETER to TRUE
exec DBMS_STATS.SET_GLOBAL_PREFS ( PNAME =>'PREFERENCE_OVERRIDES_PARAMETER', PVALUE=>'TRUE');
--
col PREF_OVERD_PARAM format a20
SELECT DBMS_STATS.GET_PREFS ( PNAME =>'PREFERENCE_OVERRIDES_PARAMETER') PREF_OVERD_PARAM FROM DUAL;
--
CREATE TABLE SOE.ORDERS2 ( ORDER_ID NUMBER(12), ORDER_DATE TIMESTAMP(6) WITH
LOCAL TIME ZONE, ORDER_TOTAL NUMBER(8,2));
--
INSERT INTO SOE.ORDERS2 SELECT ORDER_ID, ORDER_DATE, ORDER_TOTAL FROM
SOE.ORDERS;
COMMIT;
--
col EST_PERCENT format a30
SELECT DBMS_STATS.GET_PREFS (PNAME =>'ESTIMATE_PERCENT', OWNNAME=> 'SOE', TABNAME=>'ORDERS2') EST_PERCENT
FROM DUAL;
--
EST_PERCENT
------------------------------
DBMS_STATS.AUTO_SAMPLE_SIZE
--
--Set ESTIMATE_PERCENT of the table to 25
--
exec DBMS_STATS.SET_TABLE_PREFS (OWNNAME=>'SOE', TABNAME=>'ORDERS2', PNAME =>'ESTIMATE_PERCENT', PVALUE => '25');
--
SELECT DBMS_STATS.GET_PREFS(OWNNAME=>'SOE', TABNAME=>'ORDERS2', PNAME =>'ESTIMATE_PERCENT') EST_PERCENT FROM DUAL;
--
EST_PERCENT
------------------------------
  25.000000
--
--Gather statistics with Estimate Percent of 50% sample.
exec DBMS_STATS.GATHER_TABLE_STATS(OWNNAME=>'SOE', TABNAME=>'ORDERS2', ESTIMATE_PERCENT=> 50);
--
--After the Stat is collected check the Sample Size.
SELECT SAMPLE_SIZE/NUM_ROWS*100 PERCENT_SAMPLE_USED FROM DBA_TAB_STATISTICS
WHERE OWNER='SOE' AND TABLE_NAME='ORDERS2';
--
PERCENT_SAMPLE_USED
-------------------
                 25
--
exec DBMS_STATS.SET_GLOBAL_PREFS ( PNAME =>'PREFERENCE_OVERRIDES_PARAMETER', PVALUE=>'FALSE');