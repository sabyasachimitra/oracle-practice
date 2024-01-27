/* Using SQL Access Advisor with Cursor Cache */
/* This procedure is useful when the workload is being executed on the database and you would like the */
/* advisor to work on the executed workload. You do not have list of the SQL statements executed by the workload. */
--
/* Instead of loading the STS from a list of SQL statements we will load them from the Oracle cursor cache */
--
/* Create a STS */
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
/* Run the workload. The following queries simulate our workload example. */
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
/* display recommendations */
@display_myrecommendations.sql
--
--
Procedure created.

=========================================
Task_name = SAA_TASK
Action ID: 1
Command : CREATE MATERIALIZED VIEW LOG
Attr1 (name) : "SOE"."EMP"
Attr2 (tablespace):
Attr3 : ROWID, SEQUENCE
Attr4 :  INCLUDING NEW VALUES
Attr5 :
----------------------------------------
Action ID: 3
Command : CREATE MATERIALIZED VIEW LOG
Attr1 (name) : "SOE"."ORDERS"
Attr2 (tablespace):
Attr3 : ROWID, PRIMARY KEY, SEQUENCE
Attr4 :  INCLUDING NEW VALUES
Attr5 :
----------------------------------------
Action ID: 5
Command : CREATE MATERIALIZED VIEW
Attr1 (name) : "SOE"."MV$$_008D0000"
Attr2 (tablespace):
Attr3 : REFRESH FAST WITH PRIMARY KEY
Attr4 : ENABLE QUERY REWRITE
Attr5 :
----------------------------------------
Action ID: 6
Command : GATHER TABLE STATISTICS
Attr1 (name) : "SOE"."MV$$_008D0000"
Attr2 (tablespace):
Attr3 : -1
Attr4 :
Attr5 :
----------------------------------------
Action ID: 7
Command : CREATE MATERIALIZED VIEW
Attr1 (name) : "SOE"."MV$$_008D0001"
Attr2 (tablespace):
Attr3 : REFRESH FAST WITH ROWID
Attr4 : ENABLE QUERY REWRITE
Attr5 :
----------------------------------------
Action ID: 8
Command : GATHER TABLE STATISTICS
Attr1 (name) : "SOE"."MV$$_008D0001"
Attr2 (tablespace):
Attr3 : -1
Attr4 :
Attr5 :
----------------------------------------
Action ID: 9
Command : CREATE INDEX
Attr1 (name) : "SOE"."MV$$_008D0000_IDX$$_008
Attr2 (tablespace):
Attr3 : "SOE"."MV$$_008D0000"
Attr4 : BTREE
Attr5 :
----------------------------------------
Action ID: 10
Command : CREATE INDEX
Attr1 (name) : "SOE"."MV$$_008D0001_IDX$$_008
Attr2 (tablespace):
Attr3 : "SOE"."MV$$_008D0001"
Attr4 : BTREE
Attr5 :
----------------------------------------
Action ID: 11
Command : CREATE INDEX
Attr1 (name) : "SOE"."CUSTOMERS2_IDX$$_008D00
Attr2 (tablespace):
Attr3 : "SOE"."CUSTOMERS2"
Attr4 : BTREE
Attr5 :
----------------------------------------
=========END RECOMMENDATIONS============"
--
--
/* Generate the script to implement the advisor recommendations. */
@display_task_script.sql
--

SCRIPT
--------------------------------------------------------------------------------
Rem  SQL Access Advisor: Version 19.0.0.0.0 - Production
Rem
Rem  Username:        SOE
Rem  Task:            SAA_TASK
Rem  Execution date:
Rem

CREATE MATERIALIZED VIEW LOG ON
    "SOE"."EMP"
    WITH ROWID, SEQUENCE("EMP_NO","ENAME")
    INCLUDING NEW VALUES;

CREATE MATERIALIZED VIEW LOG ON
    "SOE"."ORDERS"
    WITH ROWID, PRIMARY KEY, SEQUENCE("ORDER_TOTAL","SALES_REP_ID")
    INCLUDING NEW VALUES;

CREATE MATERIALIZED VIEW "SOE"."MV$$_008D0000"
    REFRESH FAST WITH PRIMARY KEY
    ENABLE QUERY REWRITE
    AS SELECT "SOE"."ORDERS"."CUSTOMER_ID" M1, "SOE"."ORDERS"."ORDER_DATE" M2, "
SOE"."ORDERS"."ORDER_ID"
       M3, "SOE"."ORDERS"."ORDER_TOTAL" M4 FROM "SOE"."ORDERS";

begin
  dbms_stats.gather_table_stats('"SOE"','"MV$$_008D0000"',NULL,dbms_stats.auto_s
ample_size);
end;
/

CREATE MATERIALIZED VIEW "SOE"."MV$$_008D0001"
    REFRESH FAST WITH ROWID
    ENABLE QUERY REWRITE
    AS SELECT "SOE"."EMP"."ENAME" C1, COUNT("SOE"."ORDERS"."ORDER_ID") M1, SUM("
SOE"."ORDERS"."ORDER_TOTAL")
       M2, COUNT("SOE"."ORDERS"."ORDER_TOTAL") M3, COUNT(*) M4 FROM "SOE"."EMP",

       "SOE"."ORDERS" WHERE "SOE"."ORDERS"."SALES_REP_ID" = "SOE"."EMP"."EMP_NO"

       GROUP BY "SOE"."EMP"."ENAME";

begin
  dbms_stats.gather_table_stats('"SOE"','"MV$$_008D0001"',NULL,dbms_stats.auto_s
ample_size);
end;
/

CREATE INDEX "SOE"."MV$$_008D0000_IDX$$_008D0000"
    ON "SOE"."MV$$_008D0000"
    ("M2")
    COMPUTE STATISTICS;

CREATE INDEX "SOE"."MV$$_008D0001_IDX$$_008D0001"
    ON "SOE"."MV$$_008D0001"
    ("M2")
    COMPUTE STATISTICS;

CREATE INDEX "SOE"."CUSTOMERS2_IDX$$_008D0002"
    ON "SOE"."CUSTOMERS2"
    ("NLS_LANGUAGE","NLS_TERRITORY")
    COMPUTE STATISTICS;
--    
/* To cleanup, delete the task and its linked STS */
exec DBMS_ADVISOR.DELETE_TASK(:V_TASK_NAME);
-- this command deletes the SQL in the STS but not the STS itself.
exec DBMS_SQLTUNE.DELETE_SQLSET(:STS_WRKLD_NAME);
-- this command deletes the STS
exec DBMS_SQLTUNE.DROP_SQLSET(:STS_WRKLD_NAME);