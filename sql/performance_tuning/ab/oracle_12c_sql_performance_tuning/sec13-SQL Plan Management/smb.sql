/* Managing SQL Management Base */
-- SMB stores Statement logs, plan histories, SQL plan baselines and SQL profiles 
-- in the SYSAUX tablespace. 
-- Use the DBMS_SPM.CONFIGURE procedure to set configuration options for the SMB
-- DBA_SQL_MANAGEMENT_CONFIG view shows the current configuration settings for the SMB. 
--
-- The current SMB space limit is 10% of SYSAUX tablespace
SELECT PARAMETER_VALUE AS "%_LIMIT"
FROM DBA_SQL_MANAGEMENT_CONFIG
WHERE PARAMETER_NAME = 'SPACE_BUDGET_PERCENT';
--
-- To change it:
exec DBMS_SPM.CONFIGURE(PARAMETER_NAME=>'SPACE_BUDGET_PERCENT', PARAMETER_VALUE=>15);
-- 
-- Check if it has reflected
--
SELECT PARAMETER_VALUE AS "%_LIMIT"
FROM DBA_SQL_MANAGEMENT_CONFIG
WHERE PARAMETER_NAME = 'SPACE_BUDGET_PERCENT';
--
-- restore it to original value
--
exec DBMS_SPM.CONFIGURE(PARAMETER_NAME=>'SPACE_BUDGET_PERCENT', PARAMETER_VALUE=>10);
--
-- Plan Retention policy in the SMB
--
-- Default is 53 weeks
--
SELECT PARAMETER_VALUE
FROM DBA_SQL_MANAGEMENT_CONFIG
WHERE PARAMETER_NAME = 'PLAN_RETENTION_WEEKS';
-- 
-- Change it to 10 weeks.
--
exec DBMS_SPM.CONFIGURE(PARAMETER_NAME=>'PLAN_RETENTION_WEEKS', PARAMETER_VALUE=>10);
--
-- Verify if it's applied
--
SELECT PARAMETER_VALUE
FROM DBA_SQL_MANAGEMENT_CONFIG
WHERE PARAMETER_NAME = 'PLAN_RETENTION_WEEKS';