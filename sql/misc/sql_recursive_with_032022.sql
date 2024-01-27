--
-- Simple Recursive Subquery Factoring WITH
--
WITH org_chart (
    employee_id,
    first_name,
    last_name,
    manager_id
) AS (
    SELECT
        e.employee_id,
        e.first_name,
        e.last_name,
        e.manager_id
    FROM
        hr.employees e
    WHERE
        manager_id IS NULL
    UNION ALL
    SELECT
        e.employee_id,
        e.first_name,
        e.last_name,
        e.manager_id
    FROM
             org_chart o
        INNER JOIN hr.employees e ON o.employee_id = e.manager_id
)
SELECT
    *
FROM
    org_chart;
--
--
-- Recursive Subquery Factoring WITH level
-- there is no level clause in Recursive with so we need to improvise it
-- notice the difference in output. Here we are going across the tree instead of going
-- down the tree as we see in connect by. First all reportees under Steven (100) 
-- are displayed and then next reportee and its team members (reportees) are displayed
--
WITH org_chart (
    employee_id,
    first_name,
    last_name,
    manager_id,
    tree
) AS (
    SELECT
        e.employee_id,
        e.first_name,
        e.last_name,
        e.manager_id,
        1
    FROM
        hr.employees e
    WHERE
        manager_id IS NULL
    UNION ALL
    SELECT
        e.employee_id,
        e.first_name,
        e.last_name,
        e.manager_id,
        tree + 1
    FROM
             org_chart o
        INNER JOIN hr.employees e ON o.employee_id = e.manager_id
)
SELECT
    *
FROM
    org_chart;   
--
/********************************************************************************/
/* There is no SYS_CONNECT_BY_PATH in Recursive With so we need to improvise it */
/********************************************************************************/
WITH org_chart (
    employee_id,
    first_name,
    last_name,
    manager_id,
    hierarchy
) AS (
    SELECT
        e.employee_id,
        e.first_name,
        e.last_name,
        e.manager_id,
        to_char(e.employee_id) /* this is required for data type match */
    FROM
        hr.employees e
    WHERE
        manager_id IS NULL
    UNION ALL
    SELECT
        e.employee_id,
        e.first_name,
        e.last_name,
        e.manager_id,
        o.hierarchy
        || ','
        || e.employee_id
    FROM
             org_chart o
        INNER JOIN hr.employees e ON o.employee_id = e.manager_id
)
SELECT
    *
FROM
    org_chart;
--
/****************************************************************************************/
-- Search Methods:
-- Breadth First Search : It first goes to the root and shows all the children of the root
-- it then goes down to the next parent (under root) and shows all its leaf nodes
-- so BFS shows all children of a node before it shows the next parent.
-- For example,it starts with CEO, and shows all its reportees, i.e. CIO, COO and CFO
-- it then goes to CIO and shows all the VPs reporting to CIO and then to COO and so on
-- BFS is the default search method of RECURSIVE WITH
--
-- Depth First Search: It starts traversing from the root and goes all the way 
-- down to the leaf node with no more leaf nodes. It then goes back to the parent 
-- and go down to other leaf nodes (with no more leaf nodes) and so on. 
-- For example, it starts with the CEO, then goes to the CIO and shows its first VP 
-- and then goes back to the CIO again and get the next VP and so on. 
-- Once finished, it goes back to CEO and from CEO to COO and shows its first VP and so on.
-- DFS is the default search method of CONNECT BY
/****************************************************************************************/
/********************************************/
/* Sort Depth First Search (DFS)            */
/********************************************/
WITH org_chart (
    employee_id,
    first_name,
    last_name,
    manager_id,
    hierarchy
) AS (
    SELECT
        e.employee_id,
        e.first_name,
        e.last_name,
        e.manager_id,
        to_char(e.employee_id) /* this is required for data type match */
    FROM
        hr.employees e
    WHERE
        manager_id IS NULL
    UNION ALL
    SELECT
        e.employee_id,
        e.first_name,
        e.last_name,
        e.manager_id,
        o.hierarchy
        || ','
        || e.employee_id
    FROM
             org_chart o
        INNER JOIN hr.employees e ON o.employee_id = e.manager_id
)
    SEARCH DEPTH FIRST BY first_name, last_name SET sort_id
SELECT
    *
FROM
    org_chart;
/******************************************************************/
/* Sort Breadth First Search (BFS) - This is the default          */
/******************************************************************/
WITH org_chart (
    employee_id,
    first_name,
    last_name,
    manager_id,
    hierarchy,
    tree_level
) AS (
    SELECT
        e.employee_id,
        e.first_name,
        e.last_name,
        e.manager_id,
        to_char(e.employee_id), /* this is required for data type match */
        1
    FROM
        hr.employees e
    WHERE
        manager_id IS NULL
    UNION ALL
    SELECT
        e.employee_id,
        e.first_name,
        e.last_name,
        e.manager_id,
        o.hierarchy
        || ','
        || e.employee_id,
        tree_level + 1
    FROM
             org_chart o
        INNER JOIN hr.employees e ON o.employee_id = e.manager_id
)
    SEARCH BREADTH FIRST BY first_name, last_name SET sort_id
SELECT
    *
FROM
    org_chart;
--    
/*****************************************************/
/*        display if employee has reportee           */
/*****************************************************/
--
WITH org_chart (
    employee_id,
    first_name,
    last_name,
    manager_id,
    hierarchy,
    tree_level
) AS (
    SELECT
        e.employee_id,
        e.first_name,
        e.last_name,
        e.manager_id,
        to_char(e.employee_id),         /* this is required for data type match */
        1
    FROM
        hr.employees e
    WHERE
        manager_id IS NULL
    UNION ALL
    SELECT
        e.employee_id,
        e.first_name,
        e.last_name,
        e.manager_id,
        o.hierarchy
        || ','
        || e.employee_id,
        tree_level + 1
    FROM
             org_chart o
        INNER JOIN hr.employees e ON o.employee_id = e.manager_id
)
    SEARCH DEPTH FIRST BY manager_id SET mid /*DFS is mandatory if you want get all leaves*/
SELECT
    employee_id,
    first_name,
    last_name,
    manager_id,
    hierarchy,
    CASE
        WHEN LEAD(tree_level, 1, 1)
             OVER(
            ORDER BY
                mid
             ) <= tree_level THEN
            1
        ELSE
            0
    END AS has_no_reportee,
    tree_level,
    mid
FROM
    org_chart;  
--
/***********************************/
/*        get only leaf nodes      */
/***********************************/
--
WITH org_chart (
    employee_id,
    first_name,
    last_name,
    manager_id,
    hierarchy,
    tree_level
) AS (
    SELECT
        e.employee_id,
        e.first_name,
        e.last_name,
        e.manager_id,
        to_char(e.employee_id),         /* this is required for data type match */
        1
    FROM
        hr.employees e
    WHERE
        manager_id IS NULL
    UNION ALL
    SELECT
        e.employee_id,
        e.first_name,
        e.last_name,
        e.manager_id,
        o.hierarchy
        || ','
        || e.employee_id,
        tree_level + 1
    FROM
             org_chart o
        INNER JOIN hr.employees e ON o.employee_id = e.manager_id
)
    SEARCH DEPTH FIRST BY manager_id SET mid, /*DFS is mandatory if you want get all leaves*/ leaves AS (
    SELECT
        employee_id,
        first_name,
        last_name,
        manager_id,
        hierarchy,
        CASE
            WHEN LEAD(tree_level, 1, 1)
                 OVER(
                ORDER BY
                    mid
                 ) <= tree_level THEN
                1
            ELSE
                0
        END AS has_no_reportee
    FROM
        org_chart
)
SELECT
    *
FROM
    leaves
WHERE
    has_no_reportee = 1;
--
-- Detecting Infinite While Loop
--
-- Preparing data
--
update hr.employees 
set manager_id = null
where employee_id = 100;
commit;
--
-- run the below SQL 
--
WITH org_chart (
    employee_id,
    first_name,
    last_name,
    manager_id,
    hierarchy
) AS (
    SELECT
        e.employee_id,
        e.first_name,
        e.last_name,
        e.manager_id,
        to_char(e.employee_id) /* this is required for data type match */
    FROM
        hr.employees e
    WHERE
        manager_id = 100
    UNION ALL
    SELECT
        e.employee_id,
        e.first_name,
        e.last_name,
        e.manager_id,
        o.hierarchy
        || ','
        || e.employee_id
    FROM
             org_chart o
        INNER JOIN hr.employees e ON o.employee_id = e.manager_id
) CYCLE manager_id
    SET is_loop to 'Y' DEFAULT 'N'
SELECT
    *
FROM
    org_chart;
--
--
-- restore previous state
--
UPDATE hr.employees
SET
    manager_id = null
WHERE
    employee_id = 100;

COMMIT;
--
-- Other useful uses of RECURSIVE WITH: Detecting Anomalies - Duplicates.
--
WITH org_chart (
    employee_id,
    first_name,
    last_name,
    manager_id,
    hierarchy,
    phone_number,
    department_id
) AS (
    SELECT
        e.employee_id,
        e.first_name,
        e.last_name,
        e.manager_id,
        to_char(e.employee_id) /* this is required for data type match */,
        e.phone_number,
        e.department_id
    FROM
        hr.employees e
    WHERE
        employee_id = 100
    UNION ALL
    SELECT
        e.employee_id,
        e.first_name,
        e.last_name,
        e.manager_id,
        o.hierarchy
        || ','
        || e.employee_id,
        e.phone_number,
        e.department_id
    FROM
             org_chart o
        INNER JOIN hr.employees e ON o.employee_id = e.manager_id
) CYCLE phone_number
    SET is_loop to 'Y' DEFAULT 'N'
SELECT
    *
FROM
    org_chart;
--
select phone_number
, count(*) from hr.employees
group by phone_number;
--
select * from hr.employees where employee_id = 122;