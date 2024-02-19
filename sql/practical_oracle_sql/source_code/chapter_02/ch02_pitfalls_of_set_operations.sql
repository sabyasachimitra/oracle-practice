/* ***************************************************** **
   ch02_pitfalls_of_set_operations.sql
   
   Companion script for Practical Oracle SQL, Apress 2020
   by Kim Berg Hansen, https://www.kibeha.dk
   Use at your own risk
   *****************************************************
   
   Chapter 2
   Pitfalls of Set Operations
   
   To be executed in schema PRACTICAL
** ***************************************************** */

/* -----------------------------------------------------
   sqlcl formatting setup
   ----------------------------------------------------- */

-- Unlike most other chapters, this chapter manually formats
-- columns instead of using sqlformat ansiconsole

set pagesize 80
set linesize 80
set sqlformat
alter session set nls_date_format = 'YYYY-MM-DD';

column c_id          format 99999
column customer_name format a15
column b_id          format 99999
column brewery_name  format a18
column p_id          format 9999
column product_name  format a17
column c_or_b_id     format 99999
column c_or_b_name   format a18
column ordered       format a10
column qty           format 999
column product_coll  format a40
column multiset_coll format a60
column rn            format 9

/* -----------------------------------------------------
   Chapter 2 example code
   ----------------------------------------------------- */

-- Listing 2-2. Data for two customers and their orders

SELECT
   CUSTOMER_ID AS C_ID, CUSTOMER_NAME, ORDERED
 , PRODUCT_ID  AS P_ID, PRODUCT_NAME , QTY
FROM PRACTICAL.CUSTOMER_ORDER_PRODUCTS
WHERE CUSTOMER_ID IN (50042, 50741)
ORDER BY CUSTOMER_ID, PRODUCT_ID;
--
/*
  C_ID CUSTOMER_NAME     ORDERED         P_ID PRODUCT_NAME           QTY
________ _________________ ____________ _______ ___________________ ______
   50042 The White Hart    15-JAN-19       4280 Hoppy Crude Oil        110
   50042 The White Hart    22-MAR-19       4280 Hoppy Crude Oil         80
   50042 The White Hart    02-MAR-19       4280 Hoppy Crude Oil         60
   50042 The White Hart    22-MAR-19       5430 Hercule Trippel         40
   50042 The White Hart    15-JAN-19       6520 Der Helle Kumpel       140
   50741 Hygge og Humle    18-JAN-19       4280 Hoppy Crude Oil         60
   50741 Hygge og Humle    12-MAR-19       4280 Hoppy Crude Oil         90
   50741 Hygge og Humle    18-JAN-19       6520 Der Helle Kumpel        40
   50741 Hygge og Humle    26-FEB-19       6520 Der Helle Kumpel        40
   50741 Hygge og Humle    26-FEB-19       6600 Hazy Pink Cloud         16
   50741 Hygge og Humle    29-MAR-19       7950 Pale Rider Rides        50
   50741 Hygge og Humle    12-MAR-19       7950 Pale Rider Rides       100
*/   
	
-- Listing 2-3. Data for two breweries and the products bought from them

SELECT
   BREWERY_ID AS B_ID, BREWERY_NAME
 , PRODUCT_ID AS P_ID, PRODUCT_NAME
FROM PRACTICAL.BREWERY_PRODUCTS
WHERE BREWERY_ID IN (518, 523)
ORDER BY BREWERY_ID, PRODUCT_ID;
--
/*
 B_ID BREWERY_NAME             P_ID PRODUCT_NAME
_______ _____________________ _______ ___________________
    518 Balthazar Brauerei       5310 Monks and Nuns
    518 Balthazar Brauerei       5430 Hercule Trippel
    518 Balthazar Brauerei       6520 Der Helle Kumpel
    523 Happy Hoppy Hippo        6600 Hazy Pink Cloud
    523 Happy Hoppy Hippo        7790 Summer in India
    523 Happy Hoppy Hippo        7870 Ghost of Hops
*/    

-- Listing 2-4. Concatenating the results of two queries
/* 
   UNION ALL of products bought by customer 50741 and sold by brewery 523
*/

SELECT PRODUCT_ID AS P_ID, PRODUCT_NAME
FROM PRACTICAL.CUSTOMER_ORDER_PRODUCTS
WHERE CUSTOMER_ID = 50741
UNION ALL
SELECT PRODUCT_ID AS P_ID, PRODUCT_NAME
FROM PRACTICAL.BREWERY_PRODUCTS
WHERE BREWERY_ID = 523;
--
/*
 P_ID PRODUCT_NAME
_______ ___________________
   4280 Hoppy Crude Oil
   4280 Hoppy Crude Oil
   6520 Der Helle Kumpel
   6520 Der Helle Kumpel
   6600 Hazy Pink Cloud
   7950 Pale Rider Rides
   7950 Pale Rider Rides
   6600 Hazy Pink Cloud
   7790 Summer in India
   7870 Ghost of Hops
*/   
-- Listing 2-5. Different columns from the two queries

SELECT
   CUSTOMER_ID AS C_OR_B_ID, CUSTOMER_NAME AS C_OR_B_NAME
 , PRODUCT_ID AS P_ID, PRODUCT_NAME
FROM PRACTICAL.CUSTOMER_ORDER_PRODUCTS
WHERE CUSTOMER_ID = 50741
UNION ALL
SELECT
   BREWERY_ID, BREWERY_NAME
 , PRODUCT_ID AS P_ID, PRODUCT_NAME
FROM PRACTICAL.BREWERY_PRODUCTS
WHERE BREWERY_ID = 523;

-- Attempting to order by a table column leads to ORA-00904: "PRODUCT_ID": invalid identifier

SELECT
   CUSTOMER_ID AS C_OR_B_ID, CUSTOMER_NAME AS C_OR_B_NAME
 , PRODUCT_ID AS P_ID, PRODUCT_NAME
FROM PRACTICAL.CUSTOMER_ORDER_PRODUCTS
WHERE CUSTOMER_ID = 50741
UNION ALL
SELECT
   BREWERY_ID, BREWERY_NAME
 , PRODUCT_ID AS P_ID, PRODUCT_NAME
FROM PRACTICAL.BREWERY_PRODUCTS
WHERE BREWERY_ID = 523
ORDER BY PRODUCT_ID;

-- Ordering by column alias works

SELECT
   CUSTOMER_ID AS C_OR_B_ID, CUSTOMER_NAME AS C_OR_B_NAME
 , PRODUCT_ID AS P_ID, PRODUCT_NAME
FROM PRACTICAL.CUSTOMER_ORDER_PRODUCTS
WHERE CUSTOMER_ID = 50741
UNION ALL
SELECT
   BREWERY_ID, BREWERY_NAME
 , PRODUCT_ID AS P_ID, PRODUCT_NAME
FROM PRACTICAL.BREWERY_PRODUCTS
WHERE BREWERY_ID = 523
ORDER BY P_ID;

-- Listing 2-6. Union is a true set operation that implicitly performs a distinct of the query result

SELECT PRODUCT_ID AS P_ID, PRODUCT_NAME
FROM PRACTICAL.CUSTOMER_ORDER_PRODUCTS
WHERE CUSTOMER_ID = 50741
UNION
SELECT PRODUCT_ID AS P_ID, PRODUCT_NAME
FROM PRACTICAL.BREWERY_PRODUCTS
WHERE BREWERY_ID = 523
ORDER BY P_ID;
--
-- Output: Using UNION instead of UNION ALL will remove the duplicates as UNION is a true set operator
/*
P_ID PRODUCT_NAME        
_______ ___________________
   4280 Hoppy Crude Oil
   6520 Der Helle Kumpel
   6600 Hazy Pink Cloud
   7790 Summer in India
   7870 Ghost of Hops
   7950 Pale Rider Rides
*/   
-- Where union is the distinct joined results, intersect is the distinct common results

SELECT PRODUCT_ID AS P_ID, PRODUCT_NAME
FROM PRACTICAL.CUSTOMER_ORDER_PRODUCTS
WHERE CUSTOMER_ID = 50741
INTERSECT
SELECT PRODUCT_ID AS P_ID, PRODUCT_NAME
FROM PRACTICAL.BREWERY_PRODUCTS
WHERE BREWERY_ID = 523
ORDER BY P_ID;
--
/*
 P_ID PRODUCT_NAME
_______ __________________
   6600 Hazy Pink Cloud
*/   

-- Minus is the set subtraction - also known as except

SELECT PRODUCT_ID AS P_ID, PRODUCT_NAME
FROM PRACTICAL.CUSTOMER_ORDER_PRODUCTS
WHERE CUSTOMER_ID = 50741
MINUS
SELECT PRODUCT_ID AS P_ID, PRODUCT_NAME
FROM PRACTICAL.BREWERY_PRODUCTS
WHERE BREWERY_ID = 523
ORDER BY P_ID;
--
-- Output:
/* First query result set */
/*
P_ID PRODUCT_NAME
_______ ___________________
   4280 Hoppy Crude Oil
   4280 Hoppy Crude Oil
   6520 Der Helle Kumpel
   6520 Der Helle Kumpel
   6600 Hazy Pink Cloud
   7950 Pale Rider Rides
   7950 Pale Rider Rides
*/
--
/* Second query result set */
/*
 P_ID PRODUCT_NAME
_______ __________________
   6600 Hazy Pink Cloud
   7790 Summer in India
   7870 Ghost of Hops
*/
-- The output displays all records returned by the first query (CUSTOMER_ID = 50741) EXCEPT
-- the ones present in the second query (BREWERY_ID = 523). Since ALL is not used duplicates 
-- are removed from the output resilt set.
--
/*
   P_ID PRODUCT_NAME
_______ ___________________
   4280 Hoppy Crude Oil
   6520 Der Helle Kumpel
   7950 Pale Rider Rides
*/   
--
-- Listing 2-7. The customer product data viewed as a collection type
/*
   Data in a column of a nested table type is known as a collection when used in PL/SQL
   (that has several types of collections). Within SQL operations, it is known as a multiset.
*/   
--
SELECT
   CUSTOMER_ID AS C_ID, CUSTOMER_NAME
 , PRODUCT_COLL
FROM PRACTICAL.CUSTOMER_ORDER_PRODUCTS_OBJ
WHERE CUSTOMER_ID IN (50042, 50741)
ORDER BY CUSTOMER_ID;
--
-- product id and name have duplicates because quantity and ordered columns are not included.
/*
 C_ID CUSTOMER_NAME   PRODUCT_COLL(ID, NAME)
------ --------------- ----------------------------------------
 50042 The White Hart  ID_NAME_COLL_TYPE
                           (
                           ID_NAME_TYPE(4280, 'Hoppy Crude Oil'), 
                           ID_NAME_TYPE(4280, 'Hoppy Crude Oil'), 
                           ID_NAME_TYPE(4280, 'Hoppy Crude Oil'), 
                           ID_NAME_TYPE(5430, 'Hercule Trippel'), 
                           ID_NAME_TYPE(6520, 'Der Helle Kumpel')
                           )

 50741 Hygge og Humle  ID_NAME_COLL_TYPE
                           (
                           ID_NAME_TYPE(4280, 'Hoppy Crude Oil'), 
                           ID_NAME_TYPE(4280, 'Hoppy Crude Oil'), 
                           ID_NAME_TYPE(6520, 'Der Helle Kumpel'), 
                           ID_NAME_TYPE(6520, 'Der Helle Kumpel'), 
                           ID_NAME_TYPE(6600, 'Hazy Pink Cloud'), 
                           ID_NAME_TYPE(7950, 'Pale Rider Rides'), 
                           ID_NAME_TYPE(7950, 'Pale Rider Rides')
                           )
*/                       
-- Listing 2-8. Doing union as a multiset operation on the collections

SELECT
   WHITEHART.PRODUCT_COLL
   MULTISET UNION
   HYGGEHUMLE.PRODUCT_COLL
      AS MULTISET_COLL
FROM PRACTICAL.CUSTOMER_ORDER_PRODUCTS_OBJ WHITEHART
CROSS JOIN PRACTICAL.CUSTOMER_ORDER_PRODUCTS_OBJ HYGGEHUMLE
WHERE WHITEHART.CUSTOMER_ID = 50042
AND HYGGEHUMLE.CUSTOMER_ID = 50741;
--
/*
/*
MULTISET_COLL(ID, NAME)
------------------------------------------------------------
ID_NAME_COLL_TYPE(
ID_NAME_TYPE(4280, 'Hoppy Crude Oil'), 
ID_NAME_TYPE(4280, 'Hoppy Crude Oil'), 
ID_NAME_TYPE(4280, 'Hopp y Crude Oil'), 
ID_NAME_TYPE(5430, 'Hercule Trippel'), 
ID_NAME_TYPE(6520, 'Der Helle Kumpel'), 
ID_NAME_TYPE(4280, 'Hoppy Crude Oil'), 
ID_NAME_TYPE(4280, 'Hoppy Crude Oil'), 
ID_NAME_TYPE(6520, 'Der Helle Kumpel'), 
ID_NAME_TYPE(6520, 'Der Helle Kumpel'), 
ID_NAME_TYPE(6600, 'Hazy Pink Cloud'), 
ID_NAME_TYPE(7950, 'Pale Rider Rides'), 
ID_NAME_TYPE(7950, 'Pale Ride r Rides'))
*/

-- Multiset union all is the same as multiset union
-- UNION ALL in multiset operator gives the same result 
-- Unlike UNION operator MULTISET UNION by default does not remove duplicates
--
SELECT
   WHITEHART.PRODUCT_COLL
   MULTISET UNION ALL
   HYGGEHUMLE.PRODUCT_COLL
      AS MULTISET_COLL
FROM PRACTICAL.CUSTOMER_ORDER_PRODUCTS_OBJ WHITEHART
CROSS JOIN PRACTICAL.CUSTOMER_ORDER_PRODUCTS_OBJ HYGGEHUMLE
WHERE WHITEHART.CUSTOMER_ID = 50042
AND HYGGEHUMLE.CUSTOMER_ID = 50741;
--
/*
MULTISET_COLL(ID, NAME)
------------------------------------------------------------
ID_NAME_COLL_TYPE(
ID_NAME_TYPE(4280, 'Hoppy Crude Oil'), 
ID_NAME_TYPE(4280, 'Hoppy Crude Oil'), 
ID_NAME_TYPE(4280, 'Hoppy Crude Oil'), 
ID_NAME_TYPE(5430, 'Hercule Trippel'), 
ID_NAME_TYPE(6520, 'Der Helle Kumpel'), 
ID_NAME_TYPE(4280, 'Hoppy Crude Oil'), 
ID_NAME_TYPE(4280, 'Hoppy Crude Oil'), 
ID_NAME_TYPE(6520, 'Der Helle Kumpel'), 
ID_NAME_TYPE(6520, 'Der Helle Kumpel'), 
ID_NAME_TYPE(6600, 'Hazy Pink Cloud'), 
ID_NAME_TYPE(7950, 'Pale Rider Rides'), 
ID_NAME_TYPE(7950, 'Pale Rider Rides')
)
*/
--
-- MULTISET DISTINCT works like UNION. It moves duplicate rows
--
SELECT
   WHITEHART.PRODUCT_COLL
   MULTISET UNION DISTINCT
   HYGGEHUMLE.PRODUCT_COLL
      AS MULTISET_COLL
FROM PRACTICAL.CUSTOMER_ORDER_PRODUCTS_OBJ WHITEHART
CROSS JOIN PRACTICAL.CUSTOMER_ORDER_PRODUCTS_OBJ HYGGEHUMLE
WHERE WHITEHART.CUSTOMER_ID = 50042
AND HYGGEHUMLE.CUSTOMER_ID = 50741;
--
/*
MULTISET_COLL(ID, NAME)
------------------------------------------------------------
ID_NAME_COLL_TYPE(
ID_NAME_TYPE(4280, 'Hoppy Crude Oil'), 
ID_NAME_TYPE(5430, 'Hercule Trippel'), 
ID_NAME_TYPE(6520, 'Der Helle Kumpel'), 
ID_NAME_TYPE(6600, 'Hazy Pink Cloud'), 
ID_NAME_TYPE(7950, 'Pale Rider Rides')
)
--
*/
-- For multiset an intersect all is possible

SELECT
   WHITEHART.PRODUCT_COLL
   MULTISET INTERSECT ALL
   HYGGEHUMLE.PRODUCT_COLL
      AS MULTISET_COLL
FROM PRACTICAL.CUSTOMER_ORDER_PRODUCTS_OBJ WHITEHART
CROSS JOIN PRACTICAL.CUSTOMER_ORDER_PRODUCTS_OBJ HYGGEHUMLE
WHERE WHITEHART.CUSTOMER_ID = 50042
AND HYGGEHUMLE.CUSTOMER_ID = 50741;
--
/*
MULTISET_COLL(ID, NAME)
------------------------------------------------------------
ID_NAME_COLL_TYPE
         (
         ID_NAME_TYPE(4280, 'Hoppy Crude Oil'), 
         ID_NAME_TYPE(4280, 'Hoppy Crude Oil'), 
         ID_NAME_TYPE(6520, 'Der Helle Kumpel')
         )
*/

-- As well as an intersect distinct

SELECT
   WHITEHART.PRODUCT_COLL
   MULTISET INTERSECT DISTINCT
   HYGGEHUMLE.PRODUCT_COLL
      AS MULTISET_COLL
FROM PRACTICAL.CUSTOMER_ORDER_PRODUCTS_OBJ WHITEHART
CROSS JOIN PRACTICAL.CUSTOMER_ORDER_PRODUCTS_OBJ HYGGEHUMLE
WHERE WHITEHART.CUSTOMER_ID = 50042
AND HYGGEHUMLE.CUSTOMER_ID = 50741;
--
/*
MULTISET_COLL(ID, NAME)
------------------------------------------------------------
ID_NAME_COLL_TYPE
         (
         ID_NAME_TYPE(4280, 'Hoppy Crude Oil'), 
         ID_NAME_TYPE(6520, 'Der Helle Kumpel')
         )
*/
--
-- How MULTISET EXCEPT works
-- 
SELECT
   WHITEHART.PRODUCT_COLL
FROM PRACTICAL.CUSTOMER_ORDER_PRODUCTS_OBJ WHITEHART
WHERE WHITEHART.CUSTOMER_ID = 50042;
--
/*
PRODUCT_COLL(ID, NAME)
----------------------------------------
ID_NAME_COLL_TYPE
         (
         ID_NAME_TYPE(4280, 'Hoppy Crude Oil'), 
         ID_NAME_TYPE(4280, 'Hoppy Crude Oil'), 
         ID_NAME_TYPE(4280, 'Hoppy Crude Oil'), 
         ID_NAME_TYPE(5430, 'Hercule Trippel'), 
         ID_NAME_TYPE(6520, 'Der Helle Kumpel')
         )
*/
--
SELECT
   HYGGEHUMLE.PRODUCT_COLL
FROM PRACTICAL.CUSTOMER_ORDER_PRODUCTS_OBJ HYGGEHUMLE
WHERE HYGGEHUMLE.CUSTOMER_ID = 50741;
--
/*
PRODUCT_COLL(ID, NAME)
----------------------------------------
ID_NAME_COLL_TYPE(
   ID_NAME_TYPE(4280, 'Hoppy Crude Oil'), 
   ID_NAME_TYPE(4280, 'Hoppy Crude Oil'), 
   ID_NAME_TYPE(6520, 'Der Helle Kumpel'), 
   ID_NAME_TYPE(6520, 'Der Helle Kumpel'), 
   ID_NAME_TYPE(6600, 'Hazy Pink Cloud'), 
   ID_NAME_TYPE(7950, 'Pale Rider Rides'), 
   ID_NAME_TYPE(7950, 'Pale Rider Rides')
   )
*/
--
/*
   Display All Product ID and Names of customer Whiteheart except those Product IDs and 
   Names which are present in Hyggehumle Customer. 
   Hoppy Crude Oil product appears 3 times for WHITEHART while 2 times for HYGGEHUMLE hence
   in the below output it appears 3-2 = 1 or only once.
   Hercule Trippel appeard only for WHITEHART hence it's in the output. 

   Note: 'Der Helle Kumpel' is not diplayed because it's present in the first result set once
   and present twice in the second result set.

*/

SELECT
   WHITEHART.PRODUCT_COLL
   MULTISET EXCEPT ALL
   HYGGEHUMLE.PRODUCT_COLL
      AS MULTISET_COLL
FROM PRACTICAL.CUSTOMER_ORDER_PRODUCTS_OBJ WHITEHART
CROSS JOIN PRACTICAL.CUSTOMER_ORDER_PRODUCTS_OBJ HYGGEHUMLE
WHERE WHITEHART.CUSTOMER_ID = 50042
AND HYGGEHUMLE.CUSTOMER_ID = 50741;
--
/*
MULTISET_COLL(ID, NAME)
------------------------------------------------------------
ID_NAME_COLL_TYPE
   (
   ID_NAME_TYPE(4280, 'Hoppy Crude Oil'), 
   ID_NAME_TYPE(5430, 'Hercule Trippel')
   )
*/
--
-- Let us now reverse it - Display all product ID and names from HYGGEHUMLE
-- except those which are present in WHITEHART.
-- 'Der Helle Kumpel' is present twice in HYGGEHUMLE and once in WHITEHART hence only 1 occurence. 
-- 'Hazy Pink Cloud' occurs only in HYGGEHUMLE hence it occurs in output as well.
-- 'Pale Rider Rides' only occurs twice in HYGGEHUMLE hence it occurs as many times in output.

SELECT
   HYGGEHUMLE.PRODUCT_COLL
   MULTISET EXCEPT ALL
   WHITEHART.PRODUCT_COLL
      AS MULTISET_COLL
FROM PRACTICAL.CUSTOMER_ORDER_PRODUCTS_OBJ WHITEHART
CROSS JOIN PRACTICAL.CUSTOMER_ORDER_PRODUCTS_OBJ HYGGEHUMLE
WHERE WHITEHART.CUSTOMER_ID = 50042
AND HYGGEHUMLE.CUSTOMER_ID = 50741;
--
/*
MULTISET_COLL(ID, NAME)
------------------------------------------------------------
ID_NAME_COLL_TYPE
      (
      ID_NAME_TYPE(6520, 'Der Helle Kumpel'), 
      ID_NAME_TYPE(6600, 'Hazy Pink Cloud'), 
      ID_NAME_TYPE(7950, 'Pale Rider Rides'), 
      ID_NAME_TYPE(7950, 'Pale Rider Rides')
      )
*/

-- EXCEPT DISTINCT removes duplicates from input set first and then apply EXCEPT

SELECT
   HYGGEHUMLE.PRODUCT_COLL
   MULTISET EXCEPT DISTINCT
   WHITEHART.PRODUCT_COLL
      AS MULTISET_COLL
FROM PRACTICAL.CUSTOMER_ORDER_PRODUCTS_OBJ WHITEHART
CROSS JOIN PRACTICAL.CUSTOMER_ORDER_PRODUCTS_OBJ HYGGEHUMLE
WHERE WHITEHART.CUSTOMER_ID = 50042
AND HYGGEHUMLE.CUSTOMER_ID = 50741;
--
/*
MULTISET_COLL(ID, NAME)
------------------------------------------------------------
ID_NAME_COLL_TYPE 
      (
      ID_NAME_TYPE(6600, 'Hazy Pink Cloud'), 
      ID_NAME_TYPE(7950, 'Pale Rider Rides')
      )
*/

-- Listing 2-9. Minus is like multiset except distinct

SELECT PRODUCT_ID AS P_ID, PRODUCT_NAME
FROM PRACTICAL.CUSTOMER_ORDER_PRODUCTS
WHERE CUSTOMER_ID = 50741
MINUS
SELECT PRODUCT_ID AS P_ID, PRODUCT_NAME
FROM PRACTICAL.CUSTOMER_ORDER_PRODUCTS
WHERE CUSTOMER_ID = 50042
ORDER BY P_ID;
--
/*
 P_ID PRODUCT_NAME
----- -----------------
 6600 Hazy Pink Cloud
 7950 Pale Rider Rides
 */

-- Listing 2-10. Emulating minus all using multiset except all

SELECT
   MINUS_ALL_TABLE.ID   AS P_ID
 , MINUS_ALL_TABLE.NAME AS PRODUCT_NAME
FROM TABLE(
   CAST(
      MULTISET(
         SELECT PRODUCT_ID, PRODUCT_NAME
         FROM PRACTICAL.CUSTOMER_ORDER_PRODUCTS
         WHERE CUSTOMER_ID = 50741
      )
      AS ID_NAME_COLL_TYPE
   )
   MULTISET EXCEPT ALL
   CAST(
      MULTISET(
         SELECT PRODUCT_ID, PRODUCT_NAME
         FROM PRACTICAL.CUSTOMER_ORDER_PRODUCTS
         WHERE CUSTOMER_ID = 50042
      )
      AS ID_NAME_COLL_TYPE
   )
) MINUS_ALL_TABLE
ORDER BY P_ID;

-- Listing 2-11. Emulating minus all using analytic row_number function

SELECT
   PRODUCT_ID AS P_ID
 , PRODUCT_NAME
 , ROW_NUMBER() OVER (
      PARTITION BY PRODUCT_ID, PRODUCT_NAME
      ORDER BY ROWNUM
   ) AS RN
FROM PRACTICAL.CUSTOMER_ORDER_PRODUCTS
WHERE CUSTOMER_ID = 50741
MINUS
SELECT
   PRODUCT_ID AS P_ID
 , PRODUCT_NAME
 , ROW_NUMBER() OVER (
      PARTITION BY PRODUCT_ID, PRODUCT_NAME
      ORDER BY ROWNUM
   ) AS RN
FROM PRACTICAL.CUSTOMER_ORDER_PRODUCTS
WHERE CUSTOMER_ID = 50042
ORDER BY P_ID;

/* ***************************************************** */
