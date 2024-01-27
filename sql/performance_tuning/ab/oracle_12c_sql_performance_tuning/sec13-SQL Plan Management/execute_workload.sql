-- a sample workload
SELECT 
	E.ENAME, SUM(O.ORDER_TOTAL) ORDER_TOTALS, AVG(O.ORDER_TOTAL) AVERAGE_ORDER_TOTAL , COUNT(O.ORDER_ID) ORDERS_COUNT
FROM 
	ORDERS O, EMP E
WHERE 
	E.EMP_NO = O.SALES_REP_ID
GROUP BY E.ENAME
HAVING SUM(O.ORDER_TOTAL) > 10000
ORDER BY SUM(O.ORDER_TOTAL);
--
VARIABLE V1 VARCHAR2(15);
VARIABLE V2 VARCHAR2(15);
exec :V1:='01-JAN-2010'
exec :V2:='31-DEC-2010'
--
SELECT 
	ORDER_ID, 
	ORDER_DATE, 
	ORDER_TOTAL, 
	CUSTOMER_ID 
FROM ORDERS WHERE ORDER_DATE BETWEEN TO_DATE(:V1, 'DD-MON-YYYY') AND TO_DATE(:V2, 'DD-MON-YYYY');
--
exec :V1:='01-JAN-2011'
exec :V2:='31-DEC-2011'
SELECT 
	ORDER_ID, 
	ORDER_DATE, 
	ORDER_TOTAL 
FROM ORDERS WHERE ORDER_DATE BETWEEN TO_DATE(:V1, 'DD-MON-YYYY') AND TO_DATE(:V2, 'DD-MON-YYYY');
--
exec :V1:='IA'
exec :V2:='New York'
SELECT 
	CUSTOMER_ID, 
	CUST_FIRST_NAME, 
	CUST_LAST_NAME, 
	NLS_LANGUAGE, 
	NLS_TERRITORY
FROM 
	CUSTOMERS C WHERE NLS_LANGUAGE=:V1 AND NLS_TERRITORY=:V2;
--	
exec :V1:='KG'
exec :V2:='Florida'
SELECT 
	CUSTOMER_ID, 
	CUST_FIRST_NAME, 
	CUST_LAST_NAME, 
	NLS_LANGUAGE, 
	NLS_TERRITORY
FROM 
	CUSTOMERS C WHERE NLS_LANGUAGE=:V1 AND NLS_TERRITORY=:V2;