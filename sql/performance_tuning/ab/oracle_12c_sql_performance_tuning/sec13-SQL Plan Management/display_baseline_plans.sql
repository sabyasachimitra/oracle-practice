-- display plans stored in the SQL plan baselines for the specified query
SELECT 
	PLAN_TABLE_OUTPUT
FROM 
	DBA_SQL_PLAN_BASELINES B,
	TABLE( DBMS_XPLAN.DISPLAY_SQL_PLAN_BASELINE(B.SQL_HANDLE,B.PLAN_NAME,'BASIC') ) T
WHERE 
	B.PARSING_SCHEMA_NAME='SOE' AND SQL_TEXT LIKE '%999%'
ORDER BY B.SIGNATURE;