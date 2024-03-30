
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
DROP TABLE EMPLOYEE;
DROP TABLE MANAGER;
--
CREATE TABLE EMPLOYEE (
    EMP_ID NUMBER,
    EMP_NAME VARCHAR2(30),
    EMP_ROLE VARCHAR2 (10)
);
ALTER TABLE EMPLOYEE ADD CONSTRAINT EMPLOYEE_PK PRIMARY KEY (EMP_ID)
  USING INDEX  ENABLE;
--
CREATE TABLE EMPPLOYEE_RELATIONS (
   MGR_ID NUMBER,
   EMP_ID NUMBER,
   

)
--

--
SELECT * FROM EMPLOYEE;
--
WITH RECURSIVE_PR (
   PACKAGING_ID, CONTAINS_ID, QTY, LVL
) AS (
   SELECT
      PR.PACKAGING_ID
    , PR.CONTAINS_ID
    , PR.QTY
    , 1 AS LVL
   FROM PRACTICAL.PACKAGING_RELATIONS PR
   WHERE PR.PACKAGING_ID NOT IN (
      SELECT C.CONTAINS_ID FROM PRACTICAL.PACKAGING_RELATIONS C
   )
   UNION ALL
   SELECT
      PR.PACKAGING_ID
    , PR.CONTAINS_ID
    , RPR.QTY * PR.QTY AS QTY
    , RPR.LVL + 1      AS LVL
   FROM RECURSIVE_PR RPR
   JOIN PRACTICAL.PACKAGING_RELATIONS PR
      ON PR.PACKAGING_ID = RPR.CONTAINS_ID
)
   SEARCH DEPTH FIRST BY CONTAINS_ID SET RPR_ORDER
SELECT
  *
FROM RECURSIVE_PR RPR
ORDER BY RPR.RPR_ORDER;
--
/*
--
/*
  PACKAGING_ID    CONTAINS_ID    QTY
_______________ ______________ ______
            511            501      3
            511            502      2
            521            502     72
            522            501     36
            523            502     30
            524            511      8
            531            521     12
            532            522     20
            533            522     10
            533            523     20
            534            523     20
            534            524     16
--
--
/*
  CONTAINS_ID CONTAINS_NAME
______________ ________________
           501 Bottle 330cl
           502 Bottle 500cl
           511 Gift Carton
           521 Box Large
           522 Box Medium
           523 Box Small
           524 Gift Box
           531 Pallet of L
           532 Pallet of M
           533 Pallet Mix MS
           534 Pallet Mix SG
*/
--
--
/*
   PACKAGING_ID    CONTAINS_ID    QTY    LVL    RPR_ORDER
_______________ ______________ ______ ______ ____________
            531            521     12      1            1
            521            502    864      2            2
            532            522     20      1            3
            522            501    720      2            4
            533            522     10      1            5
            522            501    360      2            6
            533            523     20      1            7
            523            502    600      2            8
            534            523     20      1            9
            523            502    600      2           10
            534            524     16      1           11
            524            511    128      2           12
            511            501    384      3           13
            511            502    256      3           14
*/            













































































































































 














































































