CREATE DATABASE RETAIL;
USE RETAIL;

SELECT *FROM PRODUCT_dim;
select * from customer_dim;
select *from store_dim;
select *from calendar_dim;
select *from fact_sales;
select* from inventory_fact;

-- use case 1 - Cleaning and standardizing


select

 SELECT ProductID,
       productname,
       UPPER(TRIM(category)) AS cleancategory,
       Brand,
       costprice,
       sellingprice
FROM product_dim;

select saleid,productid,customerid,storeid,cast(date as DATE) as salesdate,
quantity,discount
from fact_sales;

-- usecase2 - handaling nulls , missing records & data correction

select InventoryID, date , productID, openingstock,purchaseQty,SalesQty,
coalesce(closingstock, 0) as closingstock
from inventory_fact;

select customerID, name, gender,city,state,age,cast(joindate as date) as joindare,
coalesce(loyaltytier,'silver') as loyaltytier
from customer_dim;

select s.storeid,s.storename,
coalesce(s.region,r.defaultregion)as region
from store_dim
left join region_referance r on s.storename=r.storename;

-- usecase3 joining table

select s.saleid,s.salesdate,s.quantity,p.productname,p.category,c.name,c.city,st.region,st.storename
from fact_sales s
join product_dim p on s.productid=p.productid
join customer_dim c on s.customerid=c.customerid
join store_dim st on s.storeid=st.storeid;

-- case 4 date year year formate
select 
 date,year(date),Year,
month(date) as month,
monthname(date) as monthname,
day(date) as day,
quarter(date) as quarter,
week(date) as weekofyear,
format(date,'mmm-yyyy') as yearmonth
from calendar_dim;

-- use case aggression table
select salesdate,productid,storeid,sum(quantity) as TotalQty
from fact_sales
group by salesdate,productid,storeid
order by TotalQty desc;

select s.salesdate,p.productid,p.productname,s.storeid,sum(s.quantity) as TotalQty
from fact_sales s
join product_dim p on s.productid=p.productid
group by s.salesdate,p.productid,s.storeid,p.productname
order by TotalQty desc;

select year(salesdate) as year,
month(salesdate) as month,
productid,storeid,sum(quantity) as totalqty
from fact_sales
group by year,month,productid,storeid;

-- use case 6 bussiness kpis


select p.productid,p.productname, round(sum(p.sellingprice)/sum(s.quantity),0) as ASP
from fact_sales s
join  product_dim p on s.productid=p.productid
group by p.productid ,p.productname
order by ASP desc;

select p.category,sum(p.sellingprice) as category_sales,
(sum(sellingprice)*100.0 /(select sum(totalamount) from fact_sales)) as contribution_pct
from fact_sales s
join product_dim p on s.productid=p.productid
group by category;

SELECT
    p.category,
    SUM(s.totalamount) AS category_sales,
    ROUND(
        SUM(s.totalamount) * 100.0 /
        SUM(SUM(s.totalamount)) OVER (),
        2
    ) AS contribution_pct
FROM fact_sales s
JOIN product_dim p
    ON s.productid = p.productid
GROUP BY p.category;

select customerid, count(*) as purchasecount
from fact_sales
group by customerid
having count(*)>5;

-- usecase7 incemental load query

Insert into fact_sales 
select*from fact_sales
where date > (select max(date) from fact_sales);

-- usecase 8 scd (slowly changing dimension) 

select p.productid,p.productname, s.salesdate,coalesce(p.sellingprice,s.discount) as EffectivePrice
from fact_sales s
join product_dim p 
on s.productid=p.productid
and s.salesdate between '2024-01-01' and '2024-10-28'; 


-- Data Quality
select saleid, count(*)
from fact_sales
group by saleid 
having count(*)>1;

select * from fact_sales
where quantity<0;

select s.productid
from fact_sales s 
left join product_dim p 
on s.productid=p.productid
where p.productid is NULL ;

-- Final Fact table
select * from fact_sales
order by saleid asc;
