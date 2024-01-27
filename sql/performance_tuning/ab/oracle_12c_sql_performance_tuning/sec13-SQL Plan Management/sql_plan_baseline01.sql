--
-- Examining SQL Plan Capture
--
-- login as SYS in db19c01 pdb.
-- Unless otherwise specified all the following commands will be executed as SYS in db19c01
--
-- run the following script to drop any existing SQL Base lines
@drop_baselines.sql
--
-- open another session and log in soe in db19c01
-- run the following SQL to create test data
--
DROP TABLE SOE.INVENTORIES2;
CREATE TABLE SOE.INVENTORIES2
AS SELECT * FROM SOE.INVENTORIES
WHERE (WAREHOUSE_ID BETWEEN 1 AND 55) OR (WAREHOUSE_ID BETWEEN 990 AND 999)
ORDER BY WAREHOUSE_ID;
--
-- in SYS window run the following SQL statement
--
ALTER SYSTEM FLUSH SHARED_POOL;
ALTER SYSTEM FLUSH BUFFER_CACHE;
--
-- Enabling automatic baseline capture makes the Database create SQL Baseline for every SQL statement which executes twice or 
-- more, including the internally executed ones. This leads to generating enormous number of baselines.
--
SHOW PARAMETER OPTIMIZER_CAPTURE_SQL_PLAN_BASELINES
--
NAME                                 TYPE        VALUE
------------------------------------ ----------- --------
optimizer_capture_sql_plan_baselines boolean     FALSE
--
-- verify if SQLLOG$ has any records:: SQLLOG$ keeps all the SQL statements if OPTIMIZER_CAPTURE_SQL_PLAN_BASELINES is TRUE.
--
SELECT * FROM SQLLOG$;
--
-- Instead of enabling the automatic baselines for all the SQL statements, 
-- we will use filters to control which statements to consider for baselines.
-- 
-- In the following steps , you will create filters that make the optimizer create baselines 
-- only for the SQL statements executed by soe and exclude those that contain the comments 'EXCLUDE ME'.
--
-- Remove any existing filters for the parsing schema and the SQL text.
-- These steps are optional and to be used only if you want to remove any existing 
-- SQL baseline configuation based on Schema name/SQL text.
--
exec DBMS_SPM.CONFIGURE(PARAMETER_NAME=>'AUTO_CAPTURE_PARSING_SCHEMA_NAME',PARAMETER_VALUE=>NULL,ALLOW=>TRUE);
--
exec DBMS_SPM.CONFIGURE(PARAMETER_NAME=>'AUTO_CAPTURE_SQL_TEXT',PARAMETER_VALUE=>NULL ,ALLOW=>TRUE);
--
-- Apply a filter so that only SQL statements which are parsed by SOE schema are captured in SQL Baseline
--
exec DBMS_SPM.CONFIGURE('AUTO_CAPTURE_PARSING_SCHEMA_NAME','SOE',TRUE);
--
-- Exclude any statement that contains the text 'EXCLUDE ME' from consideration for automatic capture.
--
exec DBMS_SPM.CONFIGURE('AUTO_CAPTURE_SQL_TEXT','%EXCLUDE ME%',false);
--
-- Verify the applied filters have been created.
col PARAMETER_NAME format a32
col PARAMETER_VALUE format a32
--
SELECT 
	PARAMETER_NAME, 
	PARAMETER_VALUE
FROM 
	DBA_SQL_MANAGEMENT_CONFIG
WHERE PARAMETER_NAME LIKE '%AUTO%';
--
--
PARAMETER_NAME                   PARAMETER_VALUE
-------------------------------- --------------------------------
AUTO_CAPTURE_ACTION
AUTO_CAPTURE_MODULE
AUTO_CAPTURE_PARSING_SCHEMA_NAME parsing_schema IN (SOE)
AUTO_CAPTURE_SQL_TEXT            (sql_text NOT LIKE %EXCLUDE ME%)
AUTO_SPM_EVOLVE_TASK             OFF
AUTO_SPM_EVOLVE_TASK_INTERVAL    3600
AUTO_SPM_EVOLVE_TASK_MAX_RUNTIME 1800
--
-- Now you can enable the automatic capture of repeatable SQL statements.
-- Note :: this paremeter can be set at the session level
--
ALTER SYSTEM SET OPTIMIZER_CAPTURE_SQL_PLAN_BASELINES=true;
--
-- In SOE window 
SELECT * FROM INVENTORIES2 WHERE WAREHOUSE_ID=998;
SELECT * FROM INVENTORIES2 WHERE WAREHOUSE_ID=999;
--
-- In SYS window:: Verify that at least two SQL statement signatures are registered in the SQL Statement log
--
col SIGNATURE format 999999999999999999999
SELECT * FROM SQLLOG$;
--
             SIGNATURE     BATCH#
---------------------- ----------
   3374092715901918151          1
   7558992703032858492          1
--
-- Join the SQLLOG$ with V$SQL or GV$SQL (Shared SQL Area) to obtain the SQL statements.
--
set linesize 180
col PARSING_SCHEMA format a14
col SQL_ID format a14
col SQL_TEXT format a80
--
SELECT 
	PARSING_SCHEMA_NAME PARSING_SCHEMA, 
	S.SQL_ID, 
	SUBSTR(SQL_TEXT,1,100) SQL_TEXT
FROM 
V$SQL S, SQLLOG$ L
WHERE L.SIGNATURE=S.EXACT_MATCHING_SIGNATURE(+);
--
PARSING_SCHEMA SQL_ID         SQL_TEXT
-------------- -------------- ---------------------------------------------------
SOE            6762sxt9g34v6  SELECT * FROM INVENTORIES2 WHERE WAREHOUSE_ID=999
SOE            20k1cgvyv7r0h  SELECT * FROM INVENTORIES2 WHERE WAREHOUSE_ID=998
--
-- run the following script to check if SQL baselines have been created by the Optimizer
-- observe that no SQL baseline was created because SQL statements were executed only once.
--
@display_soe_baselines.sql
--
no rows selected
--
-- run the following SQL again in SOE window
--
SELECT * FROM INVENTORIES2 WHERE WAREHOUSE_ID=999;
--
-- run the following script to verify that baseline is created
--
@display_soe_baselines.sql
--
-- observe that the baseline is created, plan is accepted, enabled but not fixed.  
-- ENABLED: An enabled plan is eligible for use by the optimizer. Disabled plans 
-- are not used by the optimizer regardless of the other flag values.
--
-- FIXED: A fixed plan is preferred by the optimizer. It must be accepted. 
-- Fixed plans are used even if their costs are higher than nonfixed accepted plans.
--
-- ACCEPTED: Accepted plans are saved in the baseline and thus available for use by the optimizer.
-- Unaccepted plans are saved in the plan history but the optimizer does not use them.
--
SQL_HANDLE           SQL_TEXT                                           ENA ACC FIX  COST DISK_READS BUFFER_GETS    FETCHES ELAPSED_TIME ORIGIN
-------------------- -------------------------------------------------- --- --- --- ----- ---------- ----------- ---------- ------------ -------------
SQL_2ed32f72ca911bc7 SELECT * FROM INVENTORIES2 WHERE WAREHOUSE_ID=999  YES YES NO     42          0           0          0            0 AUTO-CAPTURE
--
-- excute the following query in SOE window
--
SELECT /* EXCLUDE ME */ * FROM soe.INVENTORIES2 WHERE WAREHOUSE_ID=997;
--
-- check if the SQL is registered or not.
SELECT PARSING_SCHEMA_NAME, S.SQL_ID, SUBSTR(SQL_TEXT,1,100) SQL_TEXT
FROM V$SQL S, SQLLOG$ L
WHERE L.SIGNATURE=S.EXACT_MATCHING_SIGNATURE(+) AND SQL_TEXT LIKE '%997%';
--
-- because a SQL with /* EXCLUDE ME */ is excluded in SQL baseline
no rows selected
--
-- if you face any issue run the following commands to reset and clean up 
ALTER SYSTEM SET OPTIMIZER_CAPTURE_SQL_PLAN_BASELINES=false;
TRUNCATE TABLE SQLLOG$;
ALTER SYSTEM FLUSH SHARED_POOL;
ALTER SYSTEM FLUSH BUFFER_CACHE;
@drop_baselines.sql