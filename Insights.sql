create database Bank_CRM;
use Bank_CRM;

CREATE TABLE Bank_Churn (
    CustomerId BIGINT PRIMARY KEY,
    CreditScore INT,
    Tenure INT,
    Balance DECIMAL(15, 2),
    NumOfProducts INT,
    HasCrCard INT,
    IsActiveMember INT,
    Exited INT
);
CREATE TABLE CustomerInfo (
    CustomerId BIGINT PRIMARY KEY,
    Surname VARCHAR(50),
    Age INT,
    GenderID INT,
    EstimatedSalary DECIMAL(10,2),
    GeographyID INT,
    Bank_DOJ DATE
);
drop table ActiveCustomer;

CREATE TABLE ActiveCustomer (
    ActiveID INT PRIMARY KEY,
    ActiveCategory VARCHAR(50)
);
INSERT INTO ActiveCustomer (ActiveID, ActiveCategory) 
VALUES 
(1, 'Active Member'),
(0, 'Inactive Member');


CREATE TABLE CreditCard (
    CreditID INT PRIMARY KEY,
    Category VARCHAR(50)
);
INSERT INTO CreditCard (CreditID, Category) 
VALUES 
(1, 'credit card holder'),
(0, 'non credit card holder');

CREATE TABLE ExitCustomer (
    ExitID INT PRIMARY KEY,
    ExitCategory VARCHAR(50)
);
INSERT INTO ExitCustomer (ExitID, ExitCategory) 
VALUES 
(1, 'Exit'),
(0, 'Retain');



CREATE TABLE Gender (
    GenderID INT PRIMARY KEY,
    GenderCategory VARCHAR(50)
);


CREATE TABLE Geography (
    GeographyID INT PRIMARY KEY,
    GeographyLocation VARCHAR(50)
);

delimiter $$
create procedure display_tables()
begin
select * from customerinfo;
select * from bank_churn;
select * from creditcard;
select * from exitcustomer;
select * from gender;
select * from geography;
select * from activecustomer;
end $$
delimiter ;
call display_tables;
-- -----------------------------------------------------------------Objective Questions ----------------------------------------------------------------------------------
/*
Answer for Q.2.	Identify the top 5 customers with the highest Estimated Salary in the last quarter of the year. */

select c.CustomerId, c.Surname, c.EstimatedSalary,
 g.GeographyLocation, c.Bank_DOJ from customerinfo c 
join geography g 
on c.GeographyID = g.GeographyID
where month(c.Bank_DOJ) in (10,11,12)
order by c.EstimatedSalary desc 
limit 5;

call display_tables;
/*
Answer for Q.3. Calculate the average number of products used by customers who have a credit card.   */

select round(avg(NumOfProducts)) as avg_products_used 
from bank_churn
where HasCrCard = 1;

/*
4.	Determine the churn rate by gender for the most recent year in the dataset.             */

with most_recent_year as (select max(year(Bank_DOJ)) as recent_year from customerinfo)
select g.GenderCategory, 
concat(round(sum(case when br.Exited = 1 then 1 else 0 end)*100 /count(br.CustomerId),2),"%") 
as churn_rate
 from customerinfo c 
join gender g 
on c.GenderID = g.GenderID
join bank_churn br 
on c.CustomerId = br.CustomerId
where year(c.Bank_DOJ) = (select recent_year from most_recent_year)
group by g.GenderCategory;


/*
Answer for Q.5  Compare the average credit score of customers who have exited and those who remain.    */

select (select avg(CreditScore)  from bank_churn
where Exited = 1 ) as avg_credit_exited_score, 
(select avg(CreditScore)  from bank_churn
where Exited = 0) as avg_credit_retained_score;

/*
Answer for Q.6  Which gender has a higher average estimated salary, and how does it relate to the number of active accounts? */

select g.GenderCategory, c.GenderID,
 round(avg(c.EstimatedSalary),2) 
 as average_estimated_salary from customerinfo c 
join gender g 
on c.GenderID = g.GenderID
group by g.GenderCategory, c.GenderID;

/*
Answer for Q.7.	Segment the customers based on their credit score and identify the segment with the highest exit rate.   */

-- created procedure for displaying below 2 tables
call customer_segment;
-- ------------------------------------------------------customers with there segments ---------------------------------------------------
select c.CustomerId, c.Surname, case when br.CreditScore between 0 and 300 then "Low"
									  when br.CreditScore between 301 and 600 then "Medium"
                                      when br.CreditScore between 601 and 900 then "High" end as Credit_score_range from bank_churn br 
join customerinfo c 
on br.CustomerId = c.CustomerId;
-- segment with there exit rate 
SELECT 
    CASE 
        WHEN br.CreditScore BETWEEN 300 AND 579 THEN 'Low'
        WHEN br.CreditScore BETWEEN 580 AND 669 THEN 'Medium'
        ELSE 'High'
    END AS Credit_Score_Segment,
    COUNT(CASE WHEN br.Exited = 1 THEN c.CustomerId END) * 100.0 / COUNT(c.CustomerId) AS Exit_Rate
FROM Customerinfo c 
join bank_churn br 
on c.CustomerId = br.CustomerId
GROUP BY Credit_Score_Segment
ORDER BY Exit_Rate DESC;

/* 
Answer for Question 8.	Find out which geographic region has the highest number of active customers with a tenure greater than 5 years.  */

select g.GeographyID, g.GeographyLocation, 
sum(case when br.IsActiveMember = 1 then 1 else 0 end) as active_customers 
from customerinfo  c 
join bank_churn br 
on c.CustomerId = br.CustomerId 
join geography g 
on c.GeographyID = g.GeographyID
where br.Tenure>5
group by g.GeographyID, g.GeographyLocation
order by active_customers desc
limit 1 ;

/*
Answer for Q.13.	13.	Identify any potential outliers in terms of balance among customers who have remained with the bank  */
 
call potential_outliers;
delimiter $$
create procedure potential_outliers()
begin
select c.customerid, c.surname, br.balance from customerinfo c 
join bank_churn br 
on c.customerId = br.customerid
where br.exited = 0 and(br.Balance between 0 and 1000 or br.balance between 200000 and 300000)
order by br.balance desc;
with creta as (select c.customerid, c.surname, br.balance from customerinfo c 
join bank_churn br 
on c.customerId = br.customerid
where br.exited = 0 and(br.Balance between 0 and 1000 or br.balance between 200000 and 300000)
order by br.balance desc)
select sum(case when balance between 0 and 1000 then 1 else 0 end) as min_balance_count,
       sum(case when balance between 200000 and 300000 then 1 else 0 end) as max_balance_count from creta;
end $$
delimiter ;
/* 
Answer for Q.15.  Using SQL, write a query to find out the gender-wise average income of males and females in each geography id. 
Also, rank the gender according to the average value.      */

select  g.GenderCategory, ge.GeographyID,
 round(avg(c.EstimatedSalary),2) as average_salary, 
dense_rank() over(partition by ge.GeographyID order by avg(c.EstimatedSalary)) as 'rank' 
from customerinfo c 
join gender g 
on c.GenderID = g.GenderID 
join geography ge 
on c.GeographyID = ge.GeographyID
group by  g.GenderCategory,ge.GeographyID;

/*
Answer for Q.16 	Using SQL, write a query to find out the average tenure of the people who have exited in each age bracket (18-30, 30-50, 50+).   */
call display_tables;

select case when c.Age between 18 and 30 then "18-30"
			when c.Age between 30 and 50 then "30-50"
            when c.Age>50 then "50+" end as age_range, 
            round(avg(br.Tenure),1) as average_tenure from  customerinfo c 
join bank_churn br 
on c.CustomerId = br.CustomerId
where br.Exited = 1
group by age_range;

/*
Answer for Q.17	Is there any direct correlation between salary and the balance of the customers? And is it different for people who have exited or not? */
call display_tables;
select c.Customerid,c.surname, round(avg(c.estimatedsalary),2) as avg_salary, 
round(avg(br.balance),2) as avg_balance from customerinfo c 
join bank_churn br 
on c.customerid = br.customerid
where br.exited = 0
group by c.customerid,c.surname 
order by c.customerid desc
limit 10;

select c.Customerid,c.surname, round(avg(c.estimatedsalary),2) as avg_salary, 
round(avg(br.balance),2) as avg_balance from customerinfo c 
join bank_churn br 
on c.customerid = br.customerid
where br.exited = 1
group by c.customerid,c.surname 
order by c.customerid desc
limit 10;

/*
Answer for Q.18	Is there any correlation between the salary and the Credit score of customers?  */
call display_tables;
select c.Customerid,c.surname,round(avg(c.estimatedsalary),2) as avg_salary, 
round(avg(br.creditscore),2) as avg_credit_score from customerinfo c 
join bank_churn br 
on c.customerid = br.customerid 
group by c.CustomerId,c.surname
order by c.customerid desc
limit 10;

/*
Answer for Q.19.	Rank each bucket of credit score as per the number of customers who have churned the bank.   */
with credit_buckets as (
select c.CustomerId, c.Surname, br.CreditScore,br.Exited,br.HasCrCard,
case when br.CreditScore between 801 and 900 then "Excellent"
	 when br.CreditScore between 701 and 800 then "Good"
     when br.CreditScore between 601 and 700 then "Fair"
     when br.CreditScore between 501 and 600 then "Poor"
     when br.CreditScore<500 then "Very Poor"
     end as Bucket from customerinfo c 
join bank_churn br 
on c.CustomerId = br.CustomerId
)
select  Bucket, count(CustomerId) as Customer_count, 
dense_rank() over(order by count(CustomerId) desc) as bucket_rank from credit_buckets
where Exited =1
group by Bucket
order by bucket_rank;

/*
Amswer for Q.20.	According to the age buckets find the number of customers who have a credit card.
 Also retrieve those buckets that have lesser than average number of credit cards per bucket.  */
 
call bucket_tables;
 
 /*
 Answer for Q.21.	 Rank the Locations as per the number of people who have churned the bank and average balance of the customers.  */
 call display_tables;
 
with creta as (
select g.GeographyId,g.GeographyLocation, 
sum(case when br.Exited = 1 then 1 end) as churned_customers,
avg(br.balance) as avg_balance from customerinfo c 
join bank_churn br 
on c.CustomerId = br.CustomerId
join geography g 
on c.GeographyID = g.GeographyID
group by g.GeographyId,g.GeographyLocation
)
select GeographyLocation, churned_customers, avg_balance, 
dense_rank() over( order by churned_customers, avg_balance asc) as "rank"
from creta;

 /*
 22.	As we can see that the “CustomerInfo” table has the CustomerID and Surname,
 now if we have to join it with a table where the primary key is also a combination of CustomerID and Surname,
 come up with a column where the format is “CustomerID_Surname”.   */
 
 select concat(CustomerId,"_",Surname) as CustomerId_Surname,
 Age, GenderID, EstimatedSalary, GeographyID, Bank_DOJ from customerinfo;
 
/*
Answer for Question 23.	Without using “Join”, can we get the “ExitCategory” from ExitCustomers table to Bank_Churn table? If yes do this using SQL.   */
-- Yes we can

select bc.*,(select ec.ExitCategory from exitcustomer ec 
where ec.ExitID = bc.Exited) as exit_category from bank_churn bc ;

/*
Answer for Question 25.	Write the query to get the customer IDs, their last name, and whether 
they are active or not for the customers whose surname ends with “on”.      */
call display_tables;

select c.CustomerId, c.Surname, 
case when br.IsActiveMember = 1 then "Active" else "Inactive" 
end as Customer_status  from customerinfo c 
join bank_churn br 
on c.CustomerId = br.CustomerId 
where c.Surname like "%on";

/*
26.	Can you observe any data disrupency in the Customer’s data? As a hint it’s present in the IsActiveMember and Exited columns.
 One more point to consider is that the data in the Exited Column is absolutely correct and accurate.   */
 call display_tables;
 with creta as (select CustomerId, IsActiveMember, Exited,
 case when Exited = 1 and IsActiveMember = 1 then "Impossible"
 end as checking from bank_churn)
 select count(CustomerId) from creta
 where checking = "Impossible";


-- ------------------------------------------------------------------------Subjective Questions -----------------------------------------------------------------------------

/*
Answer for Q.2.	Product Affinity Study: Which bank products or services are most commonly used together, and how might this influence cross-selling strategies?  */
select br.NumOfProducts, c.Category, 
count(br.CustomerId) as customer_count from bank_churn br 
join creditcard c
on br.HasCrCard = c.CreditId
group by br.NumOfProducts,c.Category
order by customer_count desc;


select case when Balance = 0 then "No Balance"
	when Balance>0 and Balance<50000 then "Low Balance"
	when Balance>50000 and Balance<150000 then "Medium Balance"
	else "High Balance" end as Balance_category, NumOfProducts,
	count(CustomerId) as customer_count from bank_churn
where NumOfProducts>1
group by Balance_category, NumOfProducts
order by customer_count desc;

/*
Answer for Q.3.	Geographic Market Trends: How do economic indicators in different geographic regions correlate with the number of
 active accounts and customer churn rates?    */
 
 select g.GeographyLocation, 
 concat(round(sum(case when br.Exited=1 then 1 else 0 end)*100/count(br.CustomerId),2),"%") 
 as churn_rate from bank_churn br 
 join customerinfo c 
 on br.CustomerId = c.CustomerId
 join geography g 
 on c.GeographyID = g.GeographyID
 group by g.GeographyLocation
 order by churn_rate desc;
 
 select g.GeographyLocation, 
 sum(case when br.IsActiveMember=1 then 1 else 0 end) as Active_customer_count,
 sum(case when br.IsActiveMember=0 then 1 else 0 end) as Inactive_customer_count
 from bank_churn br 
 join customerinfo c 
 on br.CustomerId = c.CustomerId
 join geography g 
 on c.GeographyID = g.GeographyID
 group by g.GeographyLocation
 order by Active_customer_count desc;
 
/*
Answer for Q.4.	Risk Management Assessment: Based on customer profiles, which demographic segments appear to pose the highest financial risk to the bank, and why?  */

call display_tables;
select c.CustomerId, c.Surname, g.GenderCategory, gr.GeographyLocation, 
br.NumOfProducts, a.ActiveCategory from customerinfo c 
join bank_churn br 
on c.CustomerId = br.CustomerId
join gender g 
on c.GenderID = g.GenderID
join geography gr 
on c.GeographyID = gr.GeographyID
join activecustomer a 
on br.IsActiveMember = a.ActiveCategory
where (br.CreditScore<600 or br.Balance<10000)
     or (br.NumOfProducts>2 and br.Balance>50000)
     or(br.Exited = 1)
     or(br.IsActiveMember = 0);
     
select g.GenderCategory,gr.GeographyLocation, sum(case when br.Exited =  1 then 1 else 0  end) as churned_customers,
concat(round(sum(case when br.Exited =  1 then 1 else 0  end)*100/count(c.CustomerId),1),"%") as churn_rate,
concat(round(sum(case when br.Balance<10000  then 1 else 0  end)*100/count(c.CustomerId),1),"%") as 
low_balnce_customers_rate,
concat(round(sum(case when br.Balance>50000 and br.NumOfProducts>=2 then 1 else 0  end)*100/count(c.CustomerId),1),"%") as
 over_leverage_customers_rate,
concat(round(sum(case when br.IsActiveMember =  1 then 1 else 0  end)*100/count(c.CustomerId),1),"%") as
 Active_customer_rate
from customerinfo c 
join bank_churn br 
on c.CustomerId = br.CustomerId
join geography gr
on c.GeographyID = gr.GeographyID
join gender g 
on c.GenderID = g.GenderID
group by g.GenderCategory, gr.GeographyLocation
order by churn_rate;

/*
5.	Customer Tenure Value Forecast: How would you use the available data to model and predict the lifetime (tenure) value in the bank of different customer segments?  */

select g.GenderCategory, gr.GeographyLocation,
avg(br.Tenure) as avg_tenure, avg(br.Balance) as avg_balance, 
avg(c.EstimatedSalary) as avg_salary,
avg(br.CreditScore) as avg_credit_score,
sum(case when br.NumOfProducts>2 then 1 else 0 end) as high_product_users,
sum(case when br.IsActiveMember = 1 then 1 else 0 end) as active_customer
from customerinfo c 
join bank_churn br 
on c.CustomerId = br.CustomerId
join gender g 
on C.GenderID = g.GenderID 
join geography gr 
on c.GeographyID = gr.GeographyID
group by g.GenderCategory, gr.GeographyLocation;

/*
Answer for Q. 7.	Customer Exit Reasons Exploration: Can you identify common characteristics or trends among customers 
who have exited that could explain their reasons for leaving?  */
select 
    g.GeographyLocation as Geography, 
    gen.GenderCategory as Gender,
    round(avg(c.Age), 2) as Avg_Age, 
    round(avg(bc.CreditScore), 0) as Avg_CreditScore, 
    round(avg(bc.Balance), 2) as Avg_Balance,
    round(avg(c.EstimatedSalary), 2) as Avg_EstimatedSalary,
    count(case when bc.NumOfProducts = 1 then 1 end) as Single_Product_Users,
    count(case when bc.IsActiveMember = 0 then 1 end) as Inactive_Customers,
    count(case when bc.HasCrCard = 0 then 1 end) as No_CreditCard_Users,
    ex.ExitCategory as Exit_Reason,
    COUNT(bc.CustomerId) as Total_Exited_Customers
from bank_churn bc
join customerinfo c on bc.CustomerId = c.CustomerId
left join geography g on c.GeographyID = g.GeographyID
left join gender gen on c.GenderID = gen.GenderID
left join exitcustomer ex on bc.Exited = ex.ExitID
where bc.Exited = 1  
group by g.GeographyLocation, gen.GenderCategory, ex.ExitCategory
order by Total_Exited_Customers desc;

/*
Answer for Q.8.	Are 'Tenure', 'NumOfProducts', 'IsActiveMember', and 'EstimatedSalary' important for predicting if a customer will leave the bank?  */
-- Tenure
select 
    bc.Tenure,
    count(*) as Total_Customers,
    sum(case when bc.Exited = 1 then 1 else 0 end) AS Churned_Customers,
    round(sum(case when bc.Exited = 1 then 1 else 0 end) * 100.0 / count(*), 2) as Churn_Rate
from bank_churn bc
group by bc.Tenure
order by bc.Tenure;
-- NumOfProducts
select 
    bc.NumOfProducts,
	count(*) as Total_Customers,
    sum(case when bc.Exited = 1 then 1 else 0 end) AS Churned_Customers,
    round(sum(case when bc.Exited = 1 then 1 else 0 end) * 100.0 / count(*), 2) as Churn_Rate
from Bank_Churn bc
group by bc.NumOfProducts
order by bc.NumOfProducts;

select 
    bc.IsActiveMember,
	count(*) as Total_Customers,
    sum(case when bc.Exited = 1 then 1 else 0 end) AS Churned_Customers,
    round(sum(case when bc.Exited = 1 then 1 else 0 end) * 100.0 / count(*), 2) as Churn_Rate
from Bank_Churn bc
group by bc.IsActiveMember
order by bc.IsActiveMember;

/*
Answer for Q.9.	Utilize SQL queries to segment customers based on demographics and account details.  */

select 
    a.ActiveCategory, 
    count(b.CustomerId) as Total_Customers
from bank_churn b
join activecustomer a on b.IsActiveMember = a.ActiveID
group by a.ActiveCategory
order by Total_Customers desc;

select 
    NumOfProducts, 
    count(CustomerId) as Total_Customers
from bank_churn
group by NumOfProducts
order by NumOfProducts asc;

select g.GeographyLocation, count(c.CustomerId) as Total_Customers
from customerinfo c
join geography g on c.GeographyID = g.GeographyID
group by g.GeographyLocation
order by Total_Customers desc;

/*
Answer for Q.11.	What is the current churn rate per year and overall as well in the bank? 
Can you suggest some insights to the bank about which kind of customers are more likely to churn and what different strategies can be used to decrease the churn rate? */
call display_tables;

select year(c.Bank_DOJ) as cust_year, 
concat(round(sum(case when br.Exited = 1 then 1 else 0 end)*100/count(c.CustomerId),2),"%")  
as yearly_churn_rate
from customerinfo c 
join bank_churn br 
on c.CustomerId = br.CustomerId
group by cust_year;

select concat(round(sum(case when Exited = 1 then 1 else 0 end)*100/count(CustomerId),2),"%") as overall_churn_rate from bank_churn;

select c.CustomerId, c.Surname, c.EstimatedSalary, 
br.Balance, br.CreditScore, a.ActiveCategory from customerinfo c 
join bank_churn br 
on c.CustomerId = br.CustomerId
join activecustomer a
on br.IsActiveMember = a.ActiveID
where br.CreditScore<500 and Balance <10000 and 
br.IsActiveMember = 0 and br.HasCrCard = 0;


-- Answer for Q.14 
alter table Bank_Churn  
change column HasCrCard Has_creditcard int;

select * from bank_churn;




























