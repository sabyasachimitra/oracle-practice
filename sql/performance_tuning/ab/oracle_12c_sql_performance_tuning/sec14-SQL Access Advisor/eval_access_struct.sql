/* Evaluating Existing Access Structures */
/* After you create access structure (index, IOT, MV) you can evaluate if the workload will  */
/* use this structure. You need to run the advisor in a mode called "evaluation" mode*/
--
/* Create Access Structure */
-- 
CREATE BITMAP INDEX "SOE"."CUSTOMERS2_NLSLANG_IX" ON
    "SOE"."CUSTOMERS2" (
        "NLS_LANGUAGE"
    )
        COMPUTE STATISTICS;

CREATE BITMAP INDEX "SOE"."CUSTOMERS2_TERR_IX" ON
    "SOE"."CUSTOMERS2" (
        "NLS_TERRITORY"
    )
        COMPUTE STATISTICS;
--
VARIABLE STS_WRKLD_NAME VARCHAR2(20);
VARIABLE TASK_ID NUMBER;
exec :STS_WRKLD_NAME := 'STS_CURSOR';
exec DBMS_SQLTUNE.CREATE_SQLSET(:STS_WRKLD_NAME, 'STS from Cursor Cache');
--
/* Create a SQL Tuning Advisor task. */
--
VARIABLE V_TASK_NAME VARCHAR2(20)
exec :V_TASK_NAME := 'SAA_TASK';
VARIABLE TASK_ID VARCHAR2(50)
exec DBMS_ADVISOR.CREATE_TASK(ADVISOR_NAME=>'SQL Access Advisor', TASK_ID=>:TASK_ID, TASK_NAME=>:V_TASK_NAME, TASK_DESC=>'Use the SQL Access Advisor on Cursor Cache statements');
--
ALTER SYSTEM FLUSH SHARED_POOL;
--
SELECT
    e.ename,
    SUM(o.order_total) order_totals,
    AVG(o.order_total) average_order_total,
    COUNT(o.order_id)  orders_count
FROM
    orders o,
    emp    e
WHERE
    e.emp_no = o.sales_rep_id
GROUP BY
    e.ename
HAVING
    SUM(o.order_total) > 10000
ORDER BY
    SUM(o.order_total);
--    
VARIABLE V1 VARCHAR2(15);
VARIABLE V2 VARCHAR2(15);
exec :V1:='01-JAN-2010'
exec :V2:='31-DEC-2010'
--
SELECT
    order_id,
    order_date,
    order_total,
    customer_id
FROM
    orders
WHERE
    order_date BETWEEN to_date(:v1, 'DD-MON-YYYY') AND to_date(:v2, 'DD-MON-YYYY');
--    
exec :V1:='01-JAN-2011'
exec :V2:='31-DEC-2011'
--
SELECT
    order_id,
    order_date,
    order_total
FROM
    orders
WHERE
    order_date BETWEEN to_date(:v1, 'DD-MON-YYYY') AND to_date(:v2, 'DD-MON-YYYY');
--    
exec :V1:='IA'
exec :V2:='New York'
--
SELECT
    customer_id,
    cust_first_name,
    cust_last_name,
    nls_language,
    nls_territory
FROM
    customers2 c
WHERE
        nls_language = :v1
    AND nls_territory = :v2;
--    
exec :V1:='KG'
exec :V2:='Florida'
--
SELECT
    customer_id,
    cust_first_name,
    cust_last_name,
    nls_language,
    nls_territory
FROM
    customers2 c
WHERE
        nls_language = :v1
    AND nls_territory = :v2;
--
/* Apply a filter on the task so that only needed statements are applicable for tuning advisor */
--
-- SQL submitted by SOE user is applicable for tuning
--
exec DBMS_ADVISOR.SET_TASK_PARAMETER(:V_TASK_NAME,'VALID_USERNAME_LIST',('SOE'));    
--
exec DBMS_ADVISOR.SET_TASK_PARAMETER(:V_TASK_NAME,'SQL_LIMIT','50'); 
--
-- run the advisor in evaluation mode
--
exec DBMS_ADVISOR.SET_TASK_PARAMETER(:V_TASK_NAME,'ANALYSIS_SCOPE','EVALUATION');
--
/* Load SQL in cusrsor cache into the STS */
DECLARE
    v_sts_cursor dbms_sqltune.sqlset_cursor;
BEGIN
    OPEN v_sts_cursor FOR SELECT
                              value(p)
                          FROM
                              TABLE ( dbms_sqltune.select_cursor_cache ) p;
-- Load the statements into STS
    dbms_sqltune.load_sqlset(:sts_wrkld_name, v_sts_cursor);
    CLOSE v_sts_cursor;
END;
/
--
/* display the information about the SQL statements loaded into SQL tuning sets */ 
--
col SQL_ID format a13
col SCHEMA format a5
col COMMAND_TYPE format 99
col PRIORITY format 9
col SQL_TEXT format a50
SELECT
    sql_id,
    parsing_schema_name     schema,
    command_type,
    priority,
    substr(sql_text, 1, 50) sql_text
FROM
    TABLE ( dbms_sqltune.select_sqlset(:sts_wrkld_name) );
--
/* link the STS to the task */
-- onece the STS is linked, you cannot load anymore SQL into the STS.
--
exec DBMS_ADVISOR.ADD_STS_REF(:V_TASK_NAME, 'SOE', :STS_WRKLD_NAME); 
--
/* Execute the task */
exec DBMS_ADVISOR.EXECUTE_TASK(:V_TASK_NAME);   
--
@display_myrecommendations.sql
--
Procedure created.
=========================================
Task_name = SAA_TASK
Action ID: 1
Command : RETAIN INDEX
Attr1 (name) : "SOE"."CUSTOMERS2_TERR_IX"
Attr2 (tablespace):
Attr3 : "SOE"."CUSTOMERS2"
Attr4 : BITMAP
Attr5 :
----------------------------------------
Action ID: 2
Command : RETAIN INDEX
Attr1 (name) : "SOE"."CUSTOMERS2_NLSLANG_IX"
Attr2 (tablespace):
Attr3 : "SOE"."CUSTOMERS2"
Attr4 : BITMAP
Attr5 :
----------------------------------------
=========END RECOMMENDATIONS============
--
-- Drop the indexes that you created earlier.
DROP INDEX "SOE"."CUSTOMERS2_NLSLANG_IX";
DROP INDEX "SOE"."CUSTOMERS2_TERR_IX";
-- Delete the task and its linked STS.1
exec DBMS_ADVISOR.DELETE_TASK(:V_TASK_NAME)
exec DBMS_SQLTUNE.DELETE_SQLSET(:STS_WRKLD_NAME)
-- drop the sample tables
DROP TABLE SOE.SOE_WORKLOAD;
DROP TABLE SOE.CUSTOMERS2;