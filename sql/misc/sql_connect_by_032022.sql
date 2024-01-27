--
-- simple CONNECT BY
--
SELECT
    e.employee_id,
    e.first_name,
    e.last_name,
    e.manager_id
FROM
    hr.employees e
START WITH
    e.manager_id IS NULL
CONNECT BY
    PRIOR e.employee_id = e.manager_id;

--
-- connect by with metadata
-- level will show the depth of each row in the tree
-- notice that we are travering the tree down. In Recursive With it will be across.
--
SELECT
    e.employee_id,
    e.first_name,
    e.last_name,
    e.manager_id,
    level tree_depth
FROM
    hr.employees e
START WITH
    e.manager_id IS NULL
CONNECT BY
    PRIOR e.employee_id = e.manager_id;
--
-- In connect by it's not obvisous what is the hierarchy of an employee
-- we need to figure it our from previous records by manager id. 
-- SYS_CONNECT_BY_PATH will show the hierarchy 
--
SELECT
    e.employee_id,
    e.first_name,
    e.last_name,
    e.manager_id,
    sys_connect_by_path(e.employee_id, ',') hirerarchy
FROM
    hr.employees e
START WITH
    e.manager_id IS NULL
CONNECT BY
    PRIOR e.employee_id = e.manager_id;
--
-- remove the leading comma by ltrim
--
SELECT
    e.employee_id,
    e.first_name,
    e.last_name,
    e.manager_id,
    ltrim(sys_connect_by_path(e.employee_id, ','), ',') hirerarchy
FROM
    hr.employees e
START WITH
    e.manager_id IS NULL
CONNECT BY
    PRIOR e.employee_id = e.manager_id;
--
-- Sorting Methods:
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
--
-- Sorting Hierarchial Results in CONNECT BY
--
-- DFS Sort: ORDER SIBLINGS BY orders sibligs under a non-leaf node
-- ** Never Use plain ORDER by in Hierarchial Query **
-- you can see that it starts with Steven King (100), then shows its first reportee 
-- in alphabetical order, Adam Fripp (121) and then all Adam's reportees 
-- (i.e., Alexis, Bull, Anthony, James and so on). It then picks the
-- next reportee (alphabetical order) under Steven called Allberto (147) who is a sibling
-- of Adam (121) and shows its reportees in order. It goes the next reportee of Steven 
-- and so on.
--
-- Sorting DFS 
--
SELECT
    e.employee_id,
    e.first_name,
    e.last_name,
    e.manager_id,
    ltrim(sys_connect_by_path(e.employee_id, ','), ',') hirerarchy
FROM
    hr.employees e
START WITH
    e.manager_id IS NULL
CONNECT BY
    PRIOR e.employee_id = e.manager_id
ORDER SIBLINGS BY
    first_name,
    last_name;
--
-- Sorting BFS 
--
SELECT
    e.employee_id,
    e.first_name,
    e.last_name,
    e.manager_id,
    ltrim(sys_connect_by_path(e.employee_id, ','), ',') hirerarchy
FROM
    hr.employees e
START WITH
    e.manager_id IS NULL
CONNECT BY
    PRIOR e.employee_id = e.manager_id
ORDER BY LEVEL, manager_id, employee_id;

--
-- Getting all leaves only
-- CONNECT_BY_ISLEAF will return 1 if the node is a non-leaf and 0 otherwise
--
SELECT
    e.employee_id,
    e.first_name,
    e.last_name,
    e.manager_id,
    ltrim(sys_connect_by_path(e.employee_id, ','), ',') hirerarchy
FROM
    hr.employees e
WHERE
    CONNECT_BY_ISLEAF = 1
START WITH
    e.manager_id IS NULL
CONNECT BY
    PRIOR e.employee_id = e.manager_id
ORDER SIBLINGS BY
    first_name,
    last_name;
--
-- List Managers (with child nodes) and General Employees (with no child nodes)
--
SELECT
    e.employee_id,
    e.first_name,
    e.last_name,
    e.manager_id,
    ltrim(sys_connect_by_path(e.employee_id, ','), ',') hirerarchy,
    CASE
        WHEN CONNECT_BY_ISLEAF = 0 THEN
            'Manager'
        ELSE
            'General Employee'
    END                                                 AS rank
FROM
    hr.employees e
START WITH
    e.manager_id IS NULL
CONNECT BY
    PRIOR e.employee_id = e.manager_id
ORDER SIBLINGS BY
    first_name,
    last_name;
--
-- Showing the root (in this case CEO) in each record
-- 
SELECT
    e.employee_id,
    e.first_name,
    e.last_name,
    e.manager_id,
    ltrim(sys_connect_by_path(e.employee_id, ','), ',')        hirerarchy,
    CASE
        WHEN CONNECT_BY_ISLEAF = 0 THEN
            'Manager'
        ELSE
            'General Employee'
    END                                                        AS rank,
    CONNECT_BY_ROOT concat(concat(first_name, ' '), last_name) AS ceo
FROM
    hr.employees e
START WITH
    e.manager_id IS NULL
CONNECT BY
    PRIOR e.employee_id = e.manager_id
ORDER SIBLINGS BY
    first_name,
    last_name;
--
/*******************************************/
/*       get leaves along with root        */
/*       get all lowest level emp with CEO */
/*******************************************/
--
with leaves as (
SELECT
    e.employee_id,
    e.first_name,
    e.last_name,
    e.manager_id,
    ltrim(sys_connect_by_path(e.employee_id, ','), ',')        hirerarchy,
    CONNECT_BY_ISLEAF leaf,
    CONNECT_BY_ROOT concat(concat(first_name, ' '), last_name) AS ceo
FROM
    hr.employees e
START WITH
    e.manager_id IS NULL
CONNECT BY
    PRIOR e.employee_id = e.manager_id
ORDER SIBLINGS BY
    first_name,
    last_name
) 
select * from leaves where leaf = 1 or ceo =  concat(concat(first_name, ' '), last_name);
--
-- Detecting Infinite While Loop
--
-- Preparing data
--
update hr.employees 
set manager_id = 202
where employee_id = 100;
commit;
--
-- run the below CONNECT BY
-- The SQL has failed with ORA-01436 error.
--
SELECT
    e.employee_id,
    e.first_name,
    e.last_name,
    e.manager_id,
    ltrim(sys_connect_by_path(e.employee_id, ','), ',') hirerarchy
FROM
    hr.employees e
START WITH
    e.manager_id = 100
CONNECT BY
    PRIOR e.employee_id = e.manager_id;
--
-- Add NOCYCLE keyword before PRIOR to avoid the error and infinitte loop
--
SELECT
    e.employee_id,
    e.first_name,
    e.last_name,
    e.manager_id,
    ltrim(sys_connect_by_path(e.employee_id, ','), ',') hirerarchy
FROM
    hr.employees e
START WITH
    e.manager_id = 202
CONNECT BY NOCYCLE
    PRIOR e.employee_id = e.manager_id;
--
-- How do you identify the record causing the loop
-- CONNECT_BY_ISCYCLE points to the record causing the loop.
--
SELECT
    e.employee_id,
    e.first_name,
    e.last_name,
    e.manager_id,
    ltrim(sys_connect_by_path(e.employee_id, ','), ',') hirerarchy
    ,
    CASE
    WHEN CONNECT_BY_ISCYCLE = 1 
        THEN 'Yes'
    ELSE 'No'
    END IS_LOOP
FROM
    hr.employees e
START WITH
    e.manager_id = 202
CONNECT BY NOCYCLE
    PRIOR e.employee_id = e.manager_id;
--
-- restore previous state
--
UPDATE hr.employees
SET
    manager_id = null
WHERE
    employee_id = 100;

COMMIT;