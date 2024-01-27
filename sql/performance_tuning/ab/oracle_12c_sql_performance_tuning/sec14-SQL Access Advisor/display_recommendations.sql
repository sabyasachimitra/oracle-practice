/* SQL Access Advisor */

/* The scripts retrieve the recommendations of the task name as saved in the variable */
/*  V_TASK_NAME. The script retrieves its data from the DBA_* views.                  */

set long 100000
set pagesize 50000
col "RECOMMENDATION DETAILS" format a180
SELECT
    'TYPE: '
    || type
    || CHR(10)
    || 'RANK: '
    || rank
    || CHR(10)
    || 'BENEFIT :'
    || benefit
    || CHR(10)
    || 'BENEFIT_TYPE: '
    || benefit_type
    || CHR(10)
    || 'COMMAND:
'
    || command
    || CHR(10)
    || 'ATTR1: '
    || attr1
    || CHR(10)
    || 'ATTR2: '
    || attr2
    || CHR(10)
    || 'ATTR3: '
    || attr3
    || CHR(10)
    || 'ATTR4: '
    || attr4
    || CHR(10)
    || 'ATTR5:
'
    || attr5
    || CHR(10)
    || 'ATTR6: '
    || attr6
    || CHR(10)
    || 'MESSAGE' "RECOMMENDATION
DETAILS"
FROM
    dba_advisor_recommendations r,
    dba_advisor_actions         a
WHERE
        r.task_name = :v_task_name
    AND r.task_id = a.task_id
ORDER BY
    rank;
set pagesize 24