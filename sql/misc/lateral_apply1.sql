/* LATERAL Inline Views, CROSS APPLY and OUTER APPLY Joins */
/*
    1)  CROSS JOIN LATERAL/JOIN LATERAL/CROSS APPLY: They're used alternatively and have the same 
        functionality. JOIN LATERAL needs ON clause. 
         
    2)  OUTER APPLY/LEFT JOIN LATERAL/RIGHT JOIN LATERAL: They work similar to OUTER JOIN

    3) A LATERAL inline view allows us to reference the table on the left of the inline view 
       definition in the FROM clause, allowing the inline view to be correlated. This is also 
       known as left correlation.
*/   
/* Data Setup */
CREATE TABLE TEST_A
(
  A_ID NUMBER,
  A_ID1 NUMBER
);
--
CREATE TABLE TEST_B
(
  B_ID NUMBER,
  B_ID1 NUMBER
);
--
BEGIN
  FOR I IN 1..10
  LOOP
    INSERT INTO TEST_A VALUES(I, I);
  END LOOP;

  FOR I IN 1..5
  LOOP
    INSERT INTO TEST_B VALUES(I, I);
  END LOOP;
--
  FOR I IN 6..10
  LOOP
    INSERT INTO TEST_B VALUES(I, NULL);
  END LOOP;

  COMMIT;
END;
/
--
SELECT * FROM TEST_A;
--
/*
   A_ID    A_ID1
_______ ________
      1        1
      2        2
      3        3
      4        4
      5        5
      6        6
      7        7
      8        8
      9        9
     10       10
*/
--
SELECT * FROM TEST_B;   
--
/*
   B_ID    B_ID1
_______ ________
      1        1
      2        2
      3        3
      4        4
      5        5
      6
      7
      8
      9
     10
*/     
--
/* Following query will throw error in pre-12c Oracle databases */
--
SELECT
    *
FROM
    TEST_A A,
    (
        SELECT
            *
        FROM
            TEST_B B
        WHERE
            B.B_ID1=A.A_ID1
    );
--                            
/*
Error at Command Line : 3 Column : 43
Error report -
SQL Error: ORA-00904: "A"."A_ID1": invalid identifier
00904. 00000 -  "%s: invalid identifier"
*Cause:
*Action:
*/
/* CROSS APPLY - works similar to inner join with inline views */
SELECT
    *
FROM
    TEST_A A
    CROSS APPLY (
        SELECT
            *
        FROM
            TEST_B B
        WHERE
            B.B_ID1=A.A_ID1
    );
--
/*
   A_ID    A_ID1    B_ID    B_ID1
_______ ________ _______ ________
      1        1       1        1
      2        2       2        2
      3        3       3        3
      4        4       4        4
      5        5       5        5
*/
/* The above query is equivalent to the following one, which is a plain inner join */
--
SELECT
    *
FROM
    TEST_A A,
    TEST_B B
WHERE
    B.B_ID1=A.A_ID1;
--
/* The above query is equivalent to the following one - CROSS JOIN LATERAL */
--
SELECT
    *
FROM
    TEST_A A
    CROSS JOIN LATERAL (
        SELECT
            *
        FROM
            TEST_B B
        WHERE
            B.B_ID1=A.A_ID1
    );
--
/*
   A_ID    A_ID1    B_ID    B_ID1
_______ ________ _______ ________
      1        1       1        1
      2        2       2        2
      3        3       3        3
      4        4       4        4
      5        5       5        5
*/
--
/* OUTER APPLY - works like Outer join */
--
SELECT * FROM TEST_A A OUTER APPLY 
                           (SELECT * FROM TEST_B B WHERE B.B_ID1 = A.A_ID1);
/*                           
   A_ID    A_ID1    B_ID    B_ID1
_______ ________ _______ ________
      1        1       1        1
      2        2       2        2
      3        3       3        3
      4        4       4        4
      5        5       5        5
      6        6
      7        7
      8        8
     10       10
      9        9   
*/      
--
/* LATERAL - works like normal inner join with inline view */
--
SELECT * FROM TEST_A A, LATERAL (SELECT * FROM TEST_B B WHERE A.A_ID1 = B.B_ID1);
--
/*
   A_ID    A_ID1    B_ID    B_ID1
_______ ________ _______ ________
      1        1       1        1
      2        2       2        2
      3        3       3        3
      4        4       4        4
      5        5       5        5
*/  
--
/* The following query is works similar to Inner Join */
--    
SELECT * FROM TEST_A A CROSS JOIN LATERAL (SELECT * FROM TEST_B B WHERE A.A_ID1 = B.B_ID1);
--
/*
  A_ID    A_ID1    B_ID    B_ID1
_______ ________ _______ ________
      1        1       1        1
      2        2       2        2
      3        3       3        3
      4        4       4        4
      5        5       5        5
*/      