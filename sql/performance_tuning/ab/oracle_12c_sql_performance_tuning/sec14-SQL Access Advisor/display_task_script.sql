/* Generate SQL script to implement the recommendation */
--
SET LONG 100000
SET PAGESIZE 50000
SELECT
    dbms_advisor.get_task_script(:v_task_name) AS script
FROM
    dual;
SET PAGESIZE 24