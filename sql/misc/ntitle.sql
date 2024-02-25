with salesman_performance as (
SELECT 
	salesman_id, 
	EXTRACT(YEAR FROM order_date) ORDER_YEAR, 
	SUM(quantity*unit_price) QTY
FROM 
	ot.orders
INNER JOIN 
	ot.order_items USING (order_id)
WHERE 
	salesman_id IS NOT NULL
GROUP BY 
	salesman_id, 
	EXTRACT(YEAR FROM order_date)
)
select * from salesman_performance;
--
/*
  SALESMAN_ID    ORDER_YEAR           QTY
______________ _____________ _____________
            61          2017    1586804.44
            64          2017     545057.39
            55          2017    1990776.95
            60          2017    2092044.24
            62          2016    3356475.95
            60          2016    1141693.07
            64          2015       2162571
            57          2016    1581218.17
            55          2015    1353992.22
            56          2016    1419133.07
            62          2017    3768957.03
            61          2016    1665326.79
            54          2016     723944.61
            59          2015    2707819.75

   SALESMAN_ID    ORDER_YEAR           QTY
______________ _____________ _____________
            56          2017    1335817.98
            57          2017    1310656.91
            57          2015     630829.45
            59          2017     277585.23
            62          2015     955899.32
            64          2016    1119945.84
            55          2016     180693.02
            59          2016     914768.01
            64          2013     514267.91
            54          2017    1160350.79
*/            
--
with salesman_performance as (
SELECT 
	salesman_id, 
	EXTRACT(YEAR FROM order_date) ORDER_YEAR, 
	SUM(quantity*unit_price) QTY
FROM 
	ot.orders
INNER JOIN 
	ot.order_items USING (order_id)
WHERE 
	salesman_id IS NOT NULL
GROUP BY 
	salesman_id, 
	EXTRACT(YEAR FROM order_date)
)
SELECT 
	salesman_id, 
	qty,
	NTILE(3) OVER(
		ORDER BY qty asc
	) quartile
FROM 
	salesman_performance
WHERE 
	order_year = 2017;
--
/*
   SALESMAN_ID           QTY    QUARTILE
______________ _____________ ___________
            59     277585.23           1
            64     545057.39           1
            54    1160350.79           1
            57    1310656.91           2
            56    1335817.98           2
            61    1586804.44           2
            55    1990776.95           3
            60    2092044.24           3
            62    3768957.03           3	
*/            