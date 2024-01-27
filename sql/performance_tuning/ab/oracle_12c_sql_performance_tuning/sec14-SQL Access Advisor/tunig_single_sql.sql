/* Tuning Single Statement */
-- connect as soe/soe@db19c01
DROP TABLE CUSTOMERS2;
CREATE TABLE CUSTOMERS2 AS SELECT * FROM CUSTOMERS;
ALTER TABLE CUSTOMERS2 ADD CONSTRAINT CUSTOMERS2_PK PRIMARY KEY (CUSTOMER_ID);
--
/* Execute the following SQL to make the SQL Access Advisor generates */
/* recommendations for a /* single SQL statement (run the code as sysdba or tkyte - dba) */
--
VARIABLE V_TASK_NAME VARCHAR2(20)
exec :V_TASK_NAME :='MY_QTUNE_TASK'
VARIABLE V_SQL VARCHAR2(2000)
exec :V_SQL := 'SELECT COUNT(*) FROM CUSTOMERS2 WHERE NLS_LANGUAGE=''IA'''
exec DBMS_ADVISOR.QUICK_TUNE(ADVISOR_NAME=>DBMS_ADVISOR.SQLACCESS_ADVISOR,TASK_NAME=> :V_TASK_NAME,ATTR1=>:V_SQL, ATTR2=>'SOE',DESCRIPTION=>'Tune a single query.');
--
/* view the recommendations */
/* the rwecommendation includes creation of an Index on the NLS_LANGUAGE column */
@display_recommendations.sql
--
RECOMMENDATION
DETAILS
--------------------------------------------------------------------------------
TYPE: ACTIONS
RANK: 1
BENEFIT :91
BENEFIT_TYPE:
COMMAND:
CREATE INDEX
ATTR1: "SOE"."CUSTOMERS2_IDX$$_00820000"
ATTR2:
ATTR3: "SOE"."CUSTOMERS2"
ATTR4: BTREE
ATTR5:
("NLS_LANGUAGE")
ATTR6:
MESSAGE
--
/* run the below script to generate the script to implement the recommendation */
@display_task_script.sql
--
SCRIPT
--------------------------------------------------------------------------------
Rem  SQL Access Advisor: Version 19.0.0.0.0 - Production
Rem
Rem  Username:        TKYTE
Rem  Task:            MY_QTUNE_TASK
Rem  Execution date:
Rem

CREATE INDEX "SOE"."CUSTOMERS2_IDX$$_00820000"
    ON "SOE"."CUSTOMERS2"
    ("NLS_LANGUAGE")
    COMPUTE STATISTICS;
--
-- Clean up task
exec DBMS_ADVISOR.DELETE_TASK (:V_TASK_NAME)
