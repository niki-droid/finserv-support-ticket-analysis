# FinServ Solutions: Customer Support Ticket Analysis

An end-to-end analysis of a messy customer support ticket dataset for a fictional financial services company. The project covers data profiling, SQL cleaning in MySQL, six business analysis queries, and a Power BI dashboard.

**Core question:** Where is support performance breaking down: by product line, region, agent, or ticket category, and what should the business investigate first?

## Headline Findings

- **27.15% of tickets breached the 48-hour SLA** (262 of 965).
- **Personal Loan is the weakest product line.** Its average resolution time is 52.6 hours, above the SLA, and it has the largest gap between first response and resolution (40.89 hours).
- **Credit Card (49.95 hrs) and Insurance (48.08 hrs) are also at or above the SLA threshold on average.**
- **The North region is the slowest.** Insurance-North has the highest regional average at 59.43 hours. Personal Loan-South (58.34 hours) is an anomaly worth investigating.
- **Ticket workload is badly unbalanced.** In North, the busiest agent handled 96 tickets while the lowest handled 2 (a 48x difference). East and South show the same pattern, with a few agents carrying most of the load.
- **Agent resolution times vary widely.** The best agent averages 44.37 hours and the slowest 58.82, a gap of 14.45 hours.

## Dataset

- 1,000 rows of support ticket data in CSV format, with deliberate quality problems (duplicates, inconsistent date formats, outliers, missing values).
- After cleaning, 965 tickets were used for the SLA analysis.
- Key fields: ticket ID, product line, region, category, agent, creation date, first response hours, resolution hours.

## Tools

- **MySQL**: cleaning and analysis (CTEs, window functions, `RANK()`, conditional aggregation)
- **Power BI**: dashboard, with a DAX measure for SLA breach rate
- **Excel/CSV**: initial profiling

## Process

### Phase 1: Data profiling
Profiled the raw CSV to find duplicates, inconsistent date formats, null values, and extreme values.

### Phase 2: SQL cleaning
Built a `cleaned_tickets` table in MySQL:
- Removed duplicate tickets
- Standardized date formats
- Flagged outliers in resolution time and first response time (`resolution_outlier`, `first_response_outlier`) rather than deleting them, so the analysis can include or exclude them explicitly

### Phase 3: Business analysis (6 queries)

| # | Question | Technique | Key result |
|---|----------|-----------|------------|
| Q1 | Average resolution time by product line and region | `GROUP BY`, outlier filter | North is slowest; Insurance-North at 59.43 hrs |
| Q2 | Which agents resolve fastest and slowest? | `RANK() OVER` | 14.45 hr gap between best and worst agent |
| Q3 | How many tickets breach the 48-hour SLA? | Subquery, `CASE WHEN` | 262 of 965 (27.15%) |
| Q4 | How does ticket volume trend month by month per category? | Date functions, `GROUP BY` | Billing Issue leads in 6 of 12 months; Payment Failure spikes in July and November; Account Access doubles in July |
| Q5 | How is workload spread across agents within each region? | `RANK() OVER (PARTITION BY)` | Severe imbalance in all three regions |
| Q6 | How big is the gap between first response and resolution? | Multi-column aggregation | Personal Loan gap is largest at 40.89 hrs |

### Phase 4: Power BI dashboard
Visualized SLA breach rate, resolution time by product line and region, agent performance, and monthly category trends. The SLA breach rate is calculated with a DAX measure.


<img width="1163" height="654" alt="Dashboard" src="https://github.com/user-attachments/assets/9f85ffe5-08f8-4b3a-880c-7b1e8035e9d5" />


## Recommendations

1. **Investigate Personal Loan resolution.** First response is fast (11-13 hrs across all products), so the delay is in the resolution process, not in acknowledgment.
2. **Review ticket allocation.** The extreme volume imbalance between agents suggests the assignment logic is not distributing work evenly.
3. **Look into the July spike in Account Access tickets**, which may point to a system disruption.
4. **Break the SLA breach rate down by region and product line** to find where the 27% is concentrated.

## Repository Structure

```
├── data/
│   ├── finserv_raw_tickets.csv      # Original messy dataset (1,000 rows)
│   └── cleaned_tickets.csv          # Output of the cleaning step
├── sql/
│   ├── finserv_cleaning.sql         # Data cleaning steps
│   └── finserv_analysis_data.sql    # Six analysis queries with findings in comments
├── dashboard/
│   └── cleaned_tickets.pbix         # Power BI dashboard
├── images/
│   └── ![Dashboard overview](images/dashboard.png)                # Dashboard screenshot
└── README.md
```

## How to Reproduce

1. Load `data/finserv_raw_tickets.csv` into MySQL.
2. Run `sql/finserv_cleaning.sql` to create the `cleaned_tickets` table.
3. Run `sql/finserv_analysis_data.sql` to reproduce the six analyses.
4. Open `dashboard/cleaned_tickets.pbix` in Power BI Desktop to explore the dashboard (it uses `data/cleaned_tickets.csv`).

## Author

Nikita: [GitHub](https://github.com/niki-droid)
