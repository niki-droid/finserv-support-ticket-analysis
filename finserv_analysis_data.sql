
-- Q1: Average resolution time per product line and region
-- Excluded outliers (resolution_hours > 200) and NULL values
-- Finding: North region consistently shows highest resolution times
-- Insurance-North highest at 59.43 hours
-- Personal Loan-South anomaly at 58.34 hours warrants investigation
select product_line,region,
round(avg(resolution_hours),2) as average_resolution_time
from cleaned_tickets
where resolution_outlier='Normal' and resolution_outlier is not NULL
and product_line is not null
group by region,product_line
order by region,product_line;
-- Q2: Agent performance ranked by average resolution time
-- Best performer: Anita Das (AGT003) - 44.37 hours avg
-- Worst performer: Amit Joshi (AGT010) - 58.82 hours avg
-- Gap of 14.45 hours between best and worst agent
-- Suggests training or process inconsistency worth investigating
SELECT agent_id, agent_name,
    ROUND(AVG(resolution_hours), 2) AS avg_resolution_hr,
    RANK() OVER (ORDER BY AVG(resolution_hours) ASC) AS performance_rank
FROM cleaned_tickets
WHERE resolution_outlier = 'Normal'
AND resolution_hours IS NOT NULL
AND agent_name IS NOT NULL
GROUP BY agent_id, agent_name
ORDER BY performance_rank;
-- Q3: SLA breach analysis
-- SLA threshold: 48 hours resolution time
-- Breached tickets: 262 out of 965 (27.15%)
-- Significantly above industry benchmark of 10-15%
-- Requires urgent investigation by region and product line
select 
breached_tickets,total_tickets, round(breached_tickets*100.0/total_tickets,2) as breached_percentage
from(
 select
sum(case when resolution_hours>48 then 1 else 0 end) as breached_tickets,
count(*) as total_tickets
from cleaned_tickets
)t;
-- Q4: Ticket volume trend month on month by category
-- Billing Issue is dominant category -- highest volume in 6 out of 12 months
-- Peaks at 19 tickets in May suggesting persistent operational gap
-- Payment Failure spikes in July(18) and November(15) -- possible seasonal pattern
-- Account Access doubled in July(15) vs average(8-10) -- investigate system disruption
-- No single category consistently low -- volume spread relatively even across categories
select month(created_at_clean) as month,
category,
count(*) as total_tickets
from cleaned_tickets
where category is not null
group by month(created_at_clean) ,category
order by month(created_at_clean) asc,count(*) desc;
-- Q5: Agent ticket volume ranked within region
-- Severe workload imbalance found in all three regions
-- North: Rahul Verma(96) vs bottom agents(2) -- 48x difference
-- South: Top 3 agents carry majority of load
-- East: Pooja Reddy(85) and Neha Bose(82) dominate
-- Recommendation: Review ticket allocation system
SELECT agent_id, agent_name,region,
   count(*) as ticket_volume,
   Rank() over(partition by region order by count(*) desc) as agent_Rank
FROM cleaned_tickets
where agent_name is not null
group by agent_id,agent_name,region;
-- Q6: First response vs resolution time gap per product line
-- All products show consistent first response: 11-13 hours
-- Personal Loan avg resolution 52.6 hours -- exceeds 48hr SLA on average
-- Credit Card(49.95) and Insurance(48.08) dangerously close to SLA threshold
-- Personal Loan has largest response-to-resolution gap(40.89 hours)
-- Suggests loan resolution process needs streamlining
select product_line,
round(avg(first_response_hours),2) as avg_first_response,
round(avg(resolution_hours),2) as avg_resolution_hr
from cleaned_tickets
where first_response_outlier = 'Normal' and first_response_hours is not null
and resolution_hours is not null and resolution_outlier ='Normal'
and product_line is not null
group by product_line;