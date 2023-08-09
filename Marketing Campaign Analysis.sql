/* TITLE: Marketing Campaign Analysis
   FILE: campaign_performance.csv, keyword_data.csv, site_data.csv, user_demographics.csv, user_sales_level.csv
   CREATED BY: Irene Zhu
   CONCEPTS USED: Window Functions, Aggregate Functions, Joins, Sub Query/Temp Table, TOP/LIMIT
*/

/* Step 1: Identify key metrics
   Seasonality: Sales volume, Keyword search volume, Web traffic
   Campaign Performance: Attributed sales, Conversion rate, ROAS
*/

/* Step 2: Collect data from database
   Sales volume & Web traffic: site_data.csv
   Keyword search volume: keyword_data.csv
   Attributed sales & Conversion rate & ROAS: campaign_performance.csv

*/

/* Step 3: Write SQL queries */
---Sales Volume & Website Traffic Trends
select month(date) as month, 
    sum(sales) as sales,
    sum(sessions) as sessions
from site_data
where client = 'A'
group by month(date);

---Number of customers from both genders
select d.gender, 
    count(*) as count_genders 
from campaign_performance p inner join user_demographics d on p.customer_id = p.customer_id
group by gender;

---Related Keywords Search Volume
select date, 
    sum(search_volume) as searches 
from keyword_data
where lower(keyword) in ('a', 'eyeliner', 'lipstick', 'lipgloss', 'eyeshadow', 'foundation', 'highlighter', 'eyebrow', 'lotion', 'facewash', 'serum')
group by date;

---Campaign Effectiveness by Channel
select channel,
    sum(attributed_sales) as revenue,
    sum(conversions)/sum(impressions) as conv_rate,
    sum(attributed_sales)/sum(spend) as ROAS,
    sum(attributed_sales)-sum(spend) as net_profit
from campaign_performance
where client = 'A' 
    and (date between '2022-01-01' and '2022-12-31')
group by channel;

---Union Different Tables
select channel, 
    sum(attributed_sales) as revenue
from search_campaign
where date between '2022-01-01' and '2022-12-31' 
    and client = 'A'
group by channel
Union all
select channel, 
    sum(attributed_sales) as revenue
from social_campaign
where (date between '2022-01-01' and '2022-12-31') 
    and client = 'A'
group by channel;

/* Step 4: Optimize marketing campaigns
   The client typically maintains a fixed budget allocation but makes minor adjustments based on performance. 
   For example, during the holiday season, the total budget is $100K, with $50K for search, $25K for social, and $25K for display. 
   Upon recognizing that search generates the most revenue and display the least, the revised allocation might be $60K for search, $25K for social, and $15K for display.
   This approach is common among clients.
   Another option is the use of Marketing Mix Modeling, an analysis technique that measures the impact of marketing and advertising campaigns.
   MMM helps determine how different elements contribute to desired outcomes, such as driving conversions. It provides insights to refine campaigns based on consumer trends and external influencers, optimizing engagement and sales.
   However, MMM is a complex technique not universally adopted.
   An internal budget forecast tool is also utilized. It involves a linear calculation that considers factors such as historical sales and spend, expected growth, and return on advertising spend.
*/

/* Step 5: Write SQL queries */
---Most Purchased Categories
select category,
    sum(sales) as sales
from user_sales_level
where age_group = '35-39' 
    and region = 'NY' 
    and gender = 'F' 
    and brand = 'A' 
    and (date between '2022-01-01' and '2022-12-31')
group by catogory;

---Details of Top 10 female customers having large purchases
with cte as
    (select customer_id,
        sum(purchase) as total_purchase 
    from user_sales_level
    where Gender ='F' 
	group by customer_id
	)
select distinct c.customer_id, 
    c.age, 
    cte.total_purchase 
from cte inner join campaign_performance c on cte.customer_id, c.customer_id
order by total_purchase desc
limit 10;

---Married and non married users that did minimum purchase
select customer_id, 
    marital_status,
    purchase 
from (select d.customer_id, 
    s.purchase, 
    d.marital_status,
    ROW_NUMBER() over(partition by d.marital_status order by s.purchase) as row_num
    from user_demographics d left join user_sales_level s on d.customer_id = s.customer_id)
where row_num = 1;

---Average Purchase Frequency = 5 times
select count (distinct order_id)/count(distinct customer_id) as frequency
from user_sales_level
where (date between '2022-01-01' and '2022-12-31') 
    and age_group = '35-39' 
    and region = 'NY' 
    and gender = 'F' 
    and brand = 'A' 
    and sales > 0;

---Average Days Since Last Purchase = 43 days
with previous_date as
    (select date, 
        lag(date) over (partition by customer_id order by date) as previous_date
    from user_sales_level
    where brand = 'A' 
        and sales > 0 
        and age_group = '35-39' 
        and (date between '2022-01-01' and '2022-12-31') 
        and region = 'NY' 
        and gender = 'F' 
        and brand = 'A'
    )
select avg(datediff('day', previous_date, date)) as days_since_last_purchase
from previous_date
where previous_date is not null;

/* Step 6: Campaign targeting
   The highest points of sales, website traffic, and keyword searches were observed during the New Year's, Valentine's Day, summer and holiday seasons.
   This suggests that there is potential to optimize marketing strategies to enhance sales.
   Allocate a larger budget to the highly effective search and social campaigns, while also incorporating display advertising to enhance awareness and acquire new users.
   To improve customer retention, we should implement the following remarketing strategies:
   1. Utilize email campaigns that offer incentives to encourage customers to return. By sending targeted emails with personalized incentives, we can entice customers who have not made a purchase within 43 days to engage with our brand again.
   2. Set up behavioral display campaigns specifically targeting customers who haven't made a purchase in the last 43 days. By displaying relevant ads to these customers based on their browsing behavior, we can increase the chances of re-engagement and improve our retention rate.
*/