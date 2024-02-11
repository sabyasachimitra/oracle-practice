-- the following create view statement will throw error because ORADEV21 does not have SELECT 
-- privilege on any of the underlying table. ORADEV21 inherits SELECT ANY TABLE from DEVELOPER
-- role but role privilege does not rech underlying objects through intermediate objects like views
--
-- Solution: 
-- as SYS grant SELECT access to the underlying tables to ORADEV21
--
create or replace type pid_pname_type as object 
(
    pid number(6),
    pname varchar2(125)
);
--
create or replace type pid_pname_col_type as table of pid_pname_type;
--
create or replace view customer_products as
select
    oc.customer_id,
    max(oc.cust_first_name) as customer_name,
    cast (
        collect (
                pid_pname_type(op.product_id, op.PRODUCT_NAME)
                order by op.product_id
        ) as pid_pname_col_type
    ) as product_col
from 
oe.orders o 
inner join 
oe.order_items oi 
on o.order_id = oi.order_id
inner join
oe.CUSTOMERS oc
on oc.CUSTOMER_ID = o.customer_id
inner join
oe.products op
on op.PRODUCT_ID = oi.PRODUCT_ID
group by oc.customer_id;
--
select * from customer_products;