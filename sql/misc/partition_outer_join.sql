/* 
       PARTITION OUTER JOIN BY - Partition outer join is used for data desnfication. 
*/       
--
/*
       Prepare test data
*/
CREATE TABLE fct_tbl
(
  cust_id     VARCHAR2(10),
  sales_month     DATE,
  sales_vol     NUMBER
);
/* 
       We are creating a table with three columns: customer_id, month of sales and volume of sales.
       customer_id: either 0 or 1. 
       sales_month: the months could be from 01 through 04 because the LEVEL is mod by 4.
*/
INSERT INTO fct_tbl
SELECT 
  'CUST_'||mod(LEVEL,2) cust_id,
  add_months(trunc(SYSDATE, 'YY'), mod(LEVEL, 4)) sales_month,
  level  sales_vol
FROM dual
CONNECT BY LEVEL < 100;

COMMIT;

