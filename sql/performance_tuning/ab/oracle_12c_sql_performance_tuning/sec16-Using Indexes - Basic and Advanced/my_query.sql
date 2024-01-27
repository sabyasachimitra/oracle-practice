--
/* Star Transformation */
--
/* This script is a practice Star Schema Query */
/* The practice is based on the following star schema query which joins  */
/* ORDERS (fact table) with CUSTOMERS (dimension table) and EMP (dimension table) */
--
SELECT /*+ NO_PARALLEL STAR_TRANSFORMATION( O SUBQUERIES( (E) TEMP_TABLE(C))) */
    O.CUSTOMER_ID,
    CUST_FIRST_NAME ||', '|| CUST_LAST_NAME CUST_NAME,
    SUM(O.ORDER_TOTAL)
FROM
    ORDERS    O,
    CUSTOMERS C,
    EMP       E
WHERE
    (O.CUSTOMER_ID=C.CUSTOMER_ID)
    AND (O.SALES_REP_ID = E.EMP_NO)
    AND C.CUSTOMER_CLASS='Regular'
    AND E.JOB_CODE='SL02'
    AND E.ENAME LIKE 'DT%' 
    AND ORDER_DATE BETWEEN TO_DATE ('01-01-2007', 'DD-MM-YYYY') 
    AND TO_DATE ('31-12-2007', 'DD-MM-YYYY')   
GROUP BY
    O.CUSTOMER_ID,
    CUST_FIRST_NAME
        ||', '
        || CUST_LAST_NAME;
--        