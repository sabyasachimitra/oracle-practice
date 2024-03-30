
/* ***************************************************** **
   recur_subq_fact.sql
   
   Demonstration of recursive subquery factoring
   Database: Oracle
   Version: 21c
   Courtsey and credit: Tim Hall - oracle-base.com.
   Link: https://oracle-base.com/articles/11g/recursive-subquery-factoring-11gr2
   *****************************************************
*/
--
-- data setup 
--
DROP TABLE employee;
--
CREATE TABLE employee (
  emp_id        NUMBER,
  mgr_id NUMBER,
  emp_name VARCHAR2 (30),
  emp_role VARCHAR2 (20),
  CONSTRAINT employee_pk PRIMARY KEY (emp_id),
  CONSTRAINT employee_fk FOREIGN KEY (mgr_id) REFERENCES employee(emp_id)
);
--
ALTER TABLE employee ADD SAL NUMBER(10);
--
CREATE INDEX employee_mgr_id_idx ON employee(mgr_id);
--
INSERT INTO employee VALUES (1, NULL, 'John Smith', 'Project Director', 180000);
INSERT INTO employee VALUES (2, 1, 'Dave Huxley', 'Dev Manager1', 58000);
INSERT INTO employee VALUES (3, 2, 'Sarah Davis', 'Dev Lead1', 50000);
INSERT INTO employee VALUES (4, 2, 'Millet Carr', 'Dev Lead2', 52000);
INSERT INTO employee VALUES (5, 4, 'Var De Jose', 'Developer1', 38000);
INSERT INTO employee VALUES (6, 4, 'Tamaera Kane', 'Developer2', 39000);
INSERT INTO employee VALUES (13, 3, 'Kenny Jones', 'Developer3', 39000);
INSERT INTO employee VALUES (14, 3, 'Ivana Clark', 'Developer4', 39000);
INSERT INTO employee VALUES (7, 1, 'Rita Sanchez', 'Test Manager1', 57000);
INSERT INTO employee VALUES (8, 7, 'Alex Kellett', 'Tester1', 50000);
INSERT INTO employee VALUES (15, 7, 'Kelly Sane', 'Tester2', 53000);
INSERT INTO employee VALUES (9, 1, 'Eugene Grasin', 'Sr. DBA', 164000);
INSERT INTO employee VALUES (10, 9, 'Steven Hinkley', 'Architect', 111000);
INSERT INTO employee VALUES (11, 10, 'Weihong Wang', 'Jr. Architect', 60000);
INSERT INTO employee VALUES (12, 9, 'Elton Morrison', 'Data Architect', 121000);
COMMIT;
--
-- Dev Manager1 - 315,000
--
SELECT * FROM EMPLOYEE;
--
/*
   EMP_ID    MGR_ID EMP_NAME          EMP_ROLE                  SAL
_________ _________ _________________ ___________________ _________
        1           John Smith        Project Director       180000
        2         1 Dave Huxley       Dev Manager1            58000
        3         2 Sarah Davis       Dev Lead1               50000
        4         2 Millet Carr       Dev Lead2               52000
        5         4 Var De Jose       Developer1              38000
        6         4 Tamaera Kane      Developer2              39000
       13         3 Kenny Jones       Developer3              39000
       14         3 Ivana Clark       Developer4              39000
        7         1 Rita Sanchez      Test Manager1           57000
        8         7 Alex Kellett      Tester1                 50000
       15         7 Kelly Sane        Tester2                 53000
        9         1 Eugene Grasin     Sr. DBA                164000
       10         9 Steven Hinkley    Architect              111000
       11        10 Weihong Wang      Jr. Architect           60000
       12         9 Elton Morrison    Data Architect       121000
*/       
--
-- Basic example
--
WITH e1 (emp_id, mgr_id, emp_name, emp_role) AS 
(
    -- Anchor member.
    SELECT 
        emp_id,
        mgr_id,
        emp_name,
        emp_role
    FROM employee 
    WHERE mgr_ID IS NULL
    UNION ALL
    -- Recursive member.
    SELECT 
        e2.emp_id,
        e2.mgr_id,
        e2.emp_name,
        e2.emp_role
    FROM employee e2, e1
    WHERE e2.mgr_id = e1.emp_id
)
SELECT emp_id, mgr_id, emp_name, emp_role FROM e1;
--
-- Unsorted output
--
/*
   EMP_ID    MGR_ID EMP_NAME          EMP_ROLE
_________ _________ _________________ ___________________
        1           John Smith        Project Director
        2         1 Dave Huxley       Dev Manager1
        7         1 Rita Sanchez      Test Manager1
        9         1 Eugene Grasin     Sr. DBA
        3         2 Sarah Davis       Dev Lead1
        4         2 Millet Carr       Dev Lead2
        8         7 Alex Kellett      Tester1
       15         7 Kelly Sane        Tester2
       10         9 Steven Hinkley    Architect
       12         9 Elton Morrison    Data Architect
       13         3 Kenny Jones       Developer3
       14         3 Ivana Clark       Developer4
        5         4 Var De Jose       Developer1
        6         4 Tamaera Kane      Developer2
       11        10 Weihong Wang      Jr. Architect
*/       
--
-- SEARCH clause - Ordering rows.
--
-- BREADTH FIRST BY : Sibling rows are returned before child rows are processed.
--
WITH e1 (emp_id, mgr_id, emp_name, emp_role) AS 
(
    -- Anchor member.
    SELECT 
        emp_id,
        mgr_id,
        emp_name,
        emp_role
    FROM employee 
    WHERE mgr_ID IS NULL
    UNION ALL
    -- Recursive member.
    SELECT 
        e2.emp_id,
        e2.mgr_id,
        e2.emp_name,
        e2.emp_role
    FROM employee e2, e1
    WHERE e2.mgr_id = e1.emp_id
)
SEARCH BREADTH FIRST BY mgr_id SET order_breadth
SELECT emp_id, mgr_id, emp_name, emp_role FROM e1 ORDER BY order_breadth;
--
-- All siblings are returned first. Project Director(1) is returned first followed by all its children (siblings). 
-- Then the children of its first child (Dev Manager1) are returned followed by the children of its second 
-- child (Test Manager1) and so on.
--
/*
    EMP_ID    MGR_ID EMP_NAME          EMP_ROLE
_________ _________ _________________ ___________________
        1           John Smith        Project Director
        2         1 Dave Huxley       Dev Manager1
        7         1 Rita Sanchez      Test Manager1
        9         1 Eugene Grasin     Sr. DBA
        3         2 Sarah Davis       Dev Lead1
        4         2 Millet Carr       Dev Lead2
        8         7 Alex Kellett      Tester1
       15         7 Kelly Sane        Tester2
       10         9 Steven Hinkley    Architect
       12         9 Elton Morrison    Data Architect
       13         3 Kenny Jones       Developer3
       14         3 Ivana Clark       Developer4
        5         4 Var De Jose       Developer1
        6         4 Tamaera Kane      Developer2
       11        10 Weihong Wang      Jr. Architect
*/
--
-- DEPTH FIRST BY : Child rows are returned before siblings are processed.
--
WITH e1 (emp_id, mgr_id, emp_name, emp_role) AS 
(
    -- Anchor member.
    SELECT 
        emp_id,
        mgr_id,
        emp_name,
        emp_role
    FROM employee 
    WHERE mgr_ID IS NULL
    UNION ALL
    -- Recursive member.
    SELECT 
        e2.emp_id,
        e2.mgr_id,
        e2.emp_name,
        e2.emp_role
    FROM employee e2, e1
    WHERE e2.mgr_id = e1.emp_id
)
SEARCH DEPTH FIRST BY mgr_id SET order_depth
SELECT emp_id, mgr_id, emp_name, emp_role FROM e1 ORDER BY order_depth;
--
-- Chindren are returned first before siblings. Project Director(1) is returned first then its first child 
-- Dev Manager1(2) followed by its first child Dev Lead1(3). Dev Lead1(3) is followed its 2 children Developer3(13) 
-- and 4(14). Developer3 and 4 don't have any children so Oracle proceeds to next child of Dev Manager1(2), 
-- Dev Lead2 (4) which has two children Developer1(5) and Developer2(6). Same traversing method is followed for the
-- remaining children of Project Director(1).
--
/*
   EMP_ID    MGR_ID EMP_NAME          EMP_ROLE
_________ _________ _________________ ___________________
        1           John Smith        Project Director
        2         1 Dave Huxley       Dev Manager1
        3         2 Sarah Davis       Dev Lead1
       13         3 Kenny Jones       Developer3
       14         3 Ivana Clark       Developer4
        4         2 Millet Carr       Dev Lead2
        5         4 Var De Jose       Developer1
        6         4 Tamaera Kane      Developer2
        7         1 Rita Sanchez      Test Manager1
        8         7 Alex Kellett      Tester1
       15         7 Kelly Sane        Tester2
        9         1 Eugene Grasin     Sr. DBA
       10         9 Steven Hinkley    Architect
       11        10 Weihong Wang      Jr. Architect
       12         9 Elton Morrison    Data Architect
*/       
--
--
WITH e1 (emp_id, mgr_id, emp_name, emp_role, sal, lvl) AS 
(
    -- Anchor member.
    SELECT 
        emp_id,
        mgr_id,
        emp_name,
        emp_role,
        sal,
        1 AS lvl
    FROM employee 
    WHERE mgr_ID IS NULL
    UNION ALL
    -- Recursive member.
    SELECT 
        e2.emp_id,
        e2.mgr_id,
        e2.emp_name,
        e2.emp_role,
        e2.sal,
        e1.lvl + 1 AS lvl
    FROM employee e2, e1
    WHERE e2.mgr_id = e1.emp_id
)
SEARCH DEPTH FIRST BY mgr_id SET order_depth
SELECT 
    emp_id, 
    mgr_id, 
    lpad(' ', 2*(e1.lvl-1)) || emp_name AS name, 
    lpad(' ', 2*(e1.lvl-1)) || emp_role AS role, 
    sal,
    lpad(' ', 2*(e1.lvl-1)) || lvl AS org_position
FROM 
    e1 
ORDER BY order_depth;
--
/*
   EMP_ID    MGR_ID NAME                  ROLE                         SAL ORG_POSITION
_________ _________ _____________________ ______________________ _________ _______________
        1           John Smith            Project Director          180000 1
        2         1   Dave Huxley           Dev Manager1             58000   2
        3         2     Sarah Davis           Dev Lead1              50000     3
       13         3       Kenny Jones           Developer3           39000       4
       14         3       Ivana Clark           Developer4           39000       4
        4         2     Millet Carr           Dev Lead2              52000     3
        5         4       Var De Jose           Developer1           38000       4
        6         4       Tamaera Kane          Developer2           39000       4
        7         1   Rita Sanchez          Test Manager1            57000   2
        8         7     Alex Kellett          Tester1                50000     3
       15         7     Kelly Sane            Tester2                53000     3
        9         1   Eugene Grasin         Sr. DBA                 164000   2
       10         9     Steven Hinkley        Architect             111000     3
       11        10       Weihong Wang          Jr. Architect        60000       4
       12         9     Elton Morrison        Data Architect        121000     3
*/       
--
--
WITH e1 (emp_id, mgr_id, emp_name, emp_role, sal, lvl) AS 
(
    -- Anchor member.
    SELECT 
        emp_id,
        mgr_id,
        emp_name,
        emp_role,
        sal,
        1 AS lvl
    FROM employee 
    WHERE mgr_ID IS NULL
    UNION ALL
    -- Recursive member.
    SELECT 
        e2.emp_id,
        e2.mgr_id,
        e2.emp_name,
        e2.emp_role,
        e2.sal,
        e1.lvl + 1 AS lvl
    FROM employee e2, e1
    WHERE e2.mgr_id = e1.emp_id
)
SEARCH DEPTH FIRST BY mgr_id SET order_depth
SELECT 
    e.mgr_id, 
    lpad(' ', 2*(e1.lvl-1)) || e.emp_name AS mgr_name, 
    lpad(' ', 2*(e1.lvl-1)) || e.emp_role AS mgr_role, 
    e.sal AS MGR_SAL,
    e1.emp_id,
    e1.emp_name,
    e1.emp_role,
    e1.sal AS emp_sal,
    lpad(' ', 2*(e1.lvl-1)) || lvl AS org_position
FROM 
    e1 
INNER JOIN
    employee e 
ON e1.mgr_id = e.emp_id        
ORDER BY order_depth;
--
--
/*
MGR_ID, MGR_NAME, MGR_ROLE, EMP_ID, EMP_NAME, EMP_ROLE, ORG_POS, SAL
----------------------------------------------------------------------



*/

