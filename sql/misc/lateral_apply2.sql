/* LATERAL Inline Views, CROSS APPLY and OUTER APPLY Joins */
/* Data Setup */
CREATE TABLE DEPARTMENTS (
    DEPARTMENT_ID NUMBER(2) CONSTRAINT DEPARTMENTS_PK PRIMARY KEY,
    DEPARTMENT_NAME VARCHAR2(14),
    LOCATION VARCHAR2(13)
);

INSERT INTO DEPARTMENTS VALUES (
    10,
    'ACCOUNTING',
    'NEW YORK'
);

INSERT INTO DEPARTMENTS VALUES (
    20,
    'RESEARCH',
    'DALLAS'
);

INSERT INTO DEPARTMENTS VALUES (
    30,
    'SALES',
    'CHICAGO'
);

INSERT INTO DEPARTMENTS VALUES (
    40,
    'OPERATIONS',
    'BOSTON'
);

COMMIT;

CREATE TABLE EMPLOYEES (
    EMPLOYEE_ID NUMBER(4) CONSTRAINT EMPLOYEES_PK PRIMARY KEY,
    EMPLOYEE_NAME VARCHAR2(10),
    JOB VARCHAR2(9),
    MANAGER_ID NUMBER(4),
    HIREDATE DATE,
    SALARY NUMBER(7, 2),
    COMMISSION NUMBER(7, 2),
    DEPARTMENT_ID NUMBER(2) CONSTRAINT EMP_DEPARTMENT_ID_FK REFERENCES DEPARTMENTS(DEPARTMENT_ID)
);

INSERT INTO EMPLOYEES VALUES (
    7369,
    'SMITH',
    'CLERK',
    7902,
    TO_DATE('17-12-1980', 'dd-mm-yyyy'),
    800,
    NULL,
    20
);

INSERT INTO EMPLOYEES VALUES (
    7499,
    'ALLEN',
    'SALESMAN',
    7698,
    TO_DATE('20-2-1981', 'dd-mm-yyyy'),
    1600,
    300,
    30
);

INSERT INTO EMPLOYEES VALUES (
    7521,
    'WARD',
    'SALESMAN',
    7698,
    TO_DATE('22-2-1981', 'dd-mm-yyyy'),
    1250,
    500,
    30
);

INSERT INTO EMPLOYEES VALUES (
    7566,
    'JONES',
    'MANAGER',
    7839,
    TO_DATE('2-4-1981', 'dd-mm-yyyy'),
    2975,
    NULL,
    20
);

INSERT INTO EMPLOYEES VALUES (
    7654,
    'MARTIN',
    'SALESMAN',
    7698,
    TO_DATE('28-9-1981', 'dd-mm-yyyy'),
    1250,
    1400,
    30
);

INSERT INTO EMPLOYEES VALUES (
    7698,
    'BLAKE',
    'MANAGER',
    7839,
    TO_DATE('1-5-1981', 'dd-mm-yyyy'),
    2850,
    NULL,
    30
);

INSERT INTO EMPLOYEES VALUES (
    7782,
    'CLARK',
    'MANAGER',
    7839,
    TO_DATE('9-6-1981', 'dd-mm-yyyy'),
    2450,
    NULL,
    10
);

INSERT INTO EMPLOYEES VALUES (
    7788,
    'SCOTT',
    'ANALYST',
    7566,
    TO_DATE('13-JUL-87', 'dd-mm-rr')-85,
    3000,
    NULL,
    20
);

INSERT INTO EMPLOYEES VALUES (
    7839,
    'KING',
    'PRESIDENT',
    NULL,
    TO_DATE('17-11-1981', 'dd-mm-yyyy'),
    5000,
    NULL,
    10
);

INSERT INTO EMPLOYEES VALUES (
    7844,
    'TURNER',
    'SALESMAN',
    7698,
    TO_DATE('8-9-1981', 'dd-mm-yyyy'),
    1500,
    0,
    30
);

INSERT INTO EMPLOYEES VALUES (
    7876,
    'ADAMS',
    'CLERK',
    7788,
    TO_DATE('13-JUL-87', 'dd-mm-rr')-51,
    1100,
    NULL,
    20
);

INSERT INTO EMPLOYEES VALUES (
    7900,
    'JAMES',
    'CLERK',
    7698,
    TO_DATE('3-12-1981', 'dd-mm-yyyy'),
    950,
    NULL,
    30
);

INSERT INTO EMPLOYEES VALUES (
    7902,
    'FORD',
    'ANALYST',
    7566,
    TO_DATE('3-12-1981', 'dd-mm-yyyy'),
    3000,
    NULL,
    20
);

INSERT INTO EMPLOYEES VALUES (
    7934,
    'MILLER',
    'CLERK',
    7782,
    TO_DATE('23-1-1982', 'dd-mm-yyyy'),
    1300,
    NULL,
    10
);

COMMIT;
--
/* 
    Display employee and department tables. 
*/
--
SELECT * FROM DEPARTMENT;
/*
    DEPARTMENT_ID DEPARTMENT_NAME    LOCATION
    ________________ __________________ ___________
                10 ACCOUNTING         NEW YORK
                20 RESEARCH           DALLAS
                30 SALES              CHICAGO
                40 OPERATIONS         BOSTON
*/
--
SELECT EMPLOYEE_ID, EMPLOYEE_NAME, DEPARTMENT_ID FROM EMPLOYEES;
--
/*
    EMPLOYEE_ID EMPLOYEE_NAME       SALARY    DEPARTMENT_ID
    ______________ ________________ _________ ________________
            7369 SMITH                  800               20
            7499 ALLEN                 1600               30
            7521 WARD                  1250               30
            7566 JONES                 2975               20
            7654 MARTIN                1250               30
            7698 BLAKE                 2850               30
            7782 CLARK                 2450               10
            7788 SCOTT                 3000               20
            7839 KING                  5000               10
            7844 TURNER                1500               30
            7876 ADAMS                 1100               20
            7900 JAMES                  950               30
            7902 FORD                  3000               20
            7934 MILLER                1300               10
*/    
--
/*
    1)  CROSS JOIN LATERAL/JOIN LATERAL/CROSS APPLY: They're used alternatively and have the same 
        functionality. JOIN LATERAL needs ON clause. 
    2)  OUTER APPLY/LEFT JOIN LATERAL/RIGHT JOIN LATERAL: They work similar to OUTER JOIN
*/      
/* LATERAL Inline Views */
--
/*  The following query will give ORA-00904: "D"."DEPARTMENT_ID": invalid identifier error because 
    it is not possible to reference tables outside of an inline view definition. In 
    this example we try to reference the DEPARTMENT_ID column from the DEPARTMENTS 
    table, which results in a error.
*/
SELECT DEPARTMENT_NAME, EMPLOYEE_NAME
FROM   DEPARTMENTS D
       CROSS JOIN (
                   SELECT EMPLOYEE_NAME
                   FROM   EMPLOYEES E
                   WHERE  E.DEPARTMENT_ID = D.DEPARTMENT_ID
                  )
ORDER BY 1, 2;
--
/* 
    SQL Error: ORA-00904: "D"."DEPARTMENT_ID": invalid identifier
*/    
--
/* A LATERAL inline view allows us to reference the table on the left 
   of the inline view definition in the FROM clause, allowing the inline 
   view to be correlated. This is also known as left correlation.
*/
--
SELECT DEPARTMENT_NAME, EMPLOYEE_NAME
FROM   DEPARTMENTS D
       CROSS JOIN LATERAL (SELECT EMPLOYEE_NAME
                           FROM   EMPLOYEES E
                           WHERE  E.DEPARTMENT_ID = D.DEPARTMENT_ID)
ORDER BY 1, 2;
/*
    DEPARTMENT_NAME    EMPLOYEE_NAME
    __________________ ________________
    ACCOUNTING         CLARK
    ACCOUNTING         KING
    ACCOUNTING         MILLER
    RESEARCH           ADAMS
    RESEARCH           FORD
    RESEARCH           JONES
    RESEARCH           SCOTT
    RESEARCH           SMITH
    SALES              ALLEN
    SALES              BLAKE
    SALES              JAMES
    SALES              MARTIN
    SALES              TURNER
    SALES              WARD
*/
--
/* 
    Alternatively, we can use join with lateral and give a dummy ON condition
*/
SELECT DEPARTMENT_NAME, EMPLOYEE_NAME
FROM   DEPARTMENTS D
       JOIN LATERAL (SELECT EMPLOYEE_NAME
                           FROM   EMPLOYEES E
                           WHERE  E.DEPARTMENT_ID = D.DEPARTMENT_ID)
        ON 1=1
ORDER BY 1, 2;
--
-- CROSS APPLY
--
/*  The CROSS APPLY join is a variant of the ANSI CROSS JOIN with correlation support.
    It returns all rows from the left hand table, where at least one row is returned 
    by the table reference or collection expression on the right. 
    The right side of the APPLY can reference columns from tables in 
    the FROM clause to the left. The example below uses a correlated inline view.

*/
SELECT DEPARTMENT_NAME, EMPLOYEE_ID, EMPLOYEE_NAME
FROM   DEPARTMENTS D
       CROSS APPLY (SELECT EMPLOYEE_ID, EMPLOYEE_NAME
                    FROM   EMPLOYEES E
                    WHERE  SALARY >= 2000
                    AND    E.DEPARTMENT_ID = D.DEPARTMENT_ID)
ORDER BY 1, 2, 3;    
/*
    DEPARTMENT_NAME       EMPLOYEE_ID EMPLOYEE_NAME
    __________________ ______________ ________________
    ACCOUNTING                   7782 CLARK
    ACCOUNTING                   7839 KING
    RESEARCH                     7566 JONES
    RESEARCH                     7788 SCOTT
    RESEARCH                     7902 FORD
    SALES                        7698 BLAKE
*/
--
/* 
    Note that the same functionality can also be achieved using EXISTS operator but we cannot 
    refer to columns of the inner corelated view to the right which we can do in CROSS APPLY. 
    The following query will throw error: SQL Error: ORA-00904: "EMPLOYEE_NAME": invalid identifier.
*/
SELECT DEPARTMENT_NAME, EMPLOYEE_ID, EMPLOYEE_NAME
FROM   DEPARTMENTS D
       WHERE EXISTS (SELECT EMPLOYEE_ID, EMPLOYEE_NAME
                    FROM   EMPLOYEES E
                    WHERE  SALARY >= 2000
                    AND    E.DEPARTMENT_ID = D.DEPARTMENT_ID)
ORDER BY 1;
--
/* 
    OUTER APPLY - The OUTER APPLY join is a variant of the LEFT OUTER JOIN with correlation support. 
    The usage is similar to the CROSS APPLY join, but it returns all rows from the table on the left 
    side of the join.
    For example, below query will display all records from departments table along with the 
    corresponding records from employyes tables only if the employee's salary is > 2000. If salary
    is less than or equals to 200 then it will display NULL for the EMPLOYEE_ID and EMPLOYEE_NAME columns
*/
--
SELECT DEPARTMENT_NAME, EMPLOYEE_ID, EMPLOYEE_NAME
FROM   DEPARTMENTS D
       OUTER APPLY (SELECT EMPLOYEE_ID, EMPLOYEE_NAME
                    FROM   EMPLOYEES E
                    WHERE  SALARY > 2000
                    AND    E.DEPARTMENT_ID = D.DEPARTMENT_ID)
ORDER BY 1, 2, 3;
--
/*
DEPARTMENT_NAME       EMPLOYEE_ID EMPLOYEE_NAME
__________________ ______________ ________________
ACCOUNTING                   7782 CLARK
ACCOUNTING                   7839 KING
OPERATIONS
RESEARCH                     7566 JONES
RESEARCH                     7788 SCOTT
RESEARCH                     7902 FORD
SALES                        7698 BLAKE
*/
--
/* 
    The same functionality can be achived using LEFT JOIN LATERAL. 
*/
SELECT DEPARTMENT_NAME, EMPLOYEE_ID, EMPLOYEE_NAME
FROM   DEPARTMENTS D
       LEFT JOIN LATERAL (SELECT EMPLOYEE_ID, EMPLOYEE_NAME
                          FROM   EMPLOYEES E
                          WHERE  SALARY > 2000
                          AND    E.DEPARTMENT_ID = D.DEPARTMENT_ID) E
                 ON E.DEPARTMENT_ID = D.DEPARTMENT_ID
ORDER BY 1, 2, 3;
--
/*
    DEPARTMENT_NAME       EMPLOYEE_ID EMPLOYEE_NAME
    __________________ ______________ ________________
    ACCOUNTING                   7782 CLARK
    ACCOUNTING                   7839 KING
    OPERATIONS
    RESEARCH                     7566 JONES
    RESEARCH                     7788 SCOTT
    RESEARCH                     7902 FORD
    SALES                        7698 BLAKE
*/
--
/* 
    Alternatively, we can remove the join condition inside the lateral inline 
    view and get the same result. But if we use LEFT OUTER LATERAL we must use ON clause.
    In all three cases Oracle use same kind of exeution plan.
*/    
select department_name, employee_id, employee_name
from   departments d
       left join lateral (select employee_id, employee_name
                          from   employees e
                          where  salary > 2000
                          ) e
                 on e.department_id = d.department_id
order by 1, 2, 3;
--
/*
    We can use more than one tables in lateral joins
*/
SELECT DEPARTMENT_NAME, L.LOCATION_ID, EMPLOYEE_ID, FIRST_NAME, CITY
FROM   HR.DEPARTMENTS D
        OUTER APPLY (SELECT EMPLOYEE_ID, FIRST_NAME
                    FROM   HR.EMPLOYEES E
                    WHERE  E.DEPARTMENT_ID = D.DEPARTMENT_ID) 
        RIGHT JOIN LATERAL (
                    SELECT LOCATION_ID, CITY
                    FROM HR.LOCATIONS L
                    ) L     
            ON L.LOCATION_ID = D.LOCATION_ID
ORDER BY 1, 2, 3;
--
-- output has been trimmed
--
/*
DEPARTMENT_NAME       LOCATION_ID    EMPLOYEE_ID FIRST_NAME    CITY
__________________ ______________ ______________ _____________ ______________________
Shipping                     1500            191 Randall       South San Francisco
Shipping                     1500            192 Sarah         South San Francisco
Shipping                     1500            193 Britney       South San Francisco
Shipping                     1500            194 Samuel        South San Francisco
Shipping                     1500            195 Vance         South San Francisco
Shipping                     1500            196 Alana         South San Francisco
Shipping                     1500            197 Kevin         South San Francisco
Shipping                     1500            198 Donald        South San Francisco
Shipping                     1500            199 Douglas       South San Francisco
Treasury                     1700                              Seattle
                             1000                              Roma
                             1100                              Venice
                             1200                              Tokyo
                             1300                              Hiroshima
*/                             
