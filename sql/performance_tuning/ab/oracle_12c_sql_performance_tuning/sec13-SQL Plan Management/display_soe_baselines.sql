-- retrieve the baselines created for the SQL statements parsed by SOE
set linesize 180
col SQL_HANDLE format a20
col SQL_TEXT format a50
col PLAN_NAME format a30
col COST format 9999
col ELAPSED_TIME format 9999
col ORIGIN format a20
SELECT 
	SQL_HANDLE, 
	SQL_TEXT, 
	PLAN_NAME,
	ENABLED, 
	ACCEPTED, 
	FIXED, 
	OPTIMIZER_COST COST,
	ELAPSED_TIME,
	ORIGIN 
 FROM DBA_SQL_PLAN_BASELINES WHERE PARSING_SCHEMA_NAME='SOE';