-- FinServ Solutions Data Cleaning Script
-- Prepared by: Nikita Baro
-- Date: 12-07-2026

-- Setup
CREATE DATABASE finserv_db;
USE finserv_db;

-- Created raw_tickets table and imported CSV (1000 rows)

-- Created cleaned_tickets as working copy
CREATE TABLE cleaned_tickets AS
SELECT * FROM raw_tickets
limit 10;

-- Step 1: Remove duplicate ticket_ids
-- 32 ticket_ids were duplicated occupying 67 rows
-- Added row_num as temporary primary key to identify rows safely
ALTER TABLE cleaned_tickets ADD COLUMN row_num INT AUTO_INCREMENT PRIMARY KEY;

-- Kept earliest row per ticket_id, deleted 35 extra rows
-- Result: 965 clean rows remaining
DELETE FROM cleaned_tickets
WHERE row_num NOT IN (
    SELECT min_row FROM (
        SELECT MIN(row_num) AS min_row
        FROM cleaned_tickets
        GROUP BY ticket_id
    ) AS keepers
);

-- Verify: should return 965
SELECT COUNT(*) FROM cleaned_tickets;

-- Step 2: Standardise created_at date format
-- Three formats detected: YYYY-MM-DD, DD/MM/YYYY, MM-DD-YYYY
-- Added new column created_at_clean as DATETIME
-- All formats converted to YYYY-MM-DD HH:MM:SS
-- Original created_at column kept for reference until full cleaning complete

ALTER TABLE cleaned_tickets ADD COLUMN created_at_clean DATETIME;

UPDATE cleaned_tickets
SET created_at_clean = CASE
    WHEN created_at LIKE '____-__-__%' THEN str_to_date(created_at, '%Y-%m-%d %H:%i:%s')
    WHEN created_at LIKE '%/%' THEN str_to_date(created_at, '%d/%m/%Y %H:%i')
    WHEN created_at LIKE '__-__-____%' THEN str_to_date(created_at,  '%m-%d-%Y %H:%i')
END;
SET SQL_SAFE_UPDATES = 0;
-- Step 3: Standardise resolved_at date format
-- Same three formats as created_at
-- 28 NULL values retained intentionally
-- These correspond to Open/Escalated tickets with no resolution date
-- Result: 937 rows with valid resolved_at_clean, 28 NULL (expected)

ALTER TABLE cleaned_tickets ADD COLUMN resolved_at_clean DATETIME;

UPDATE cleaned_tickets
SET resolved_at_clean = CASE
    WHEN resolved_at LIKE '____-__-__%' THEN str_to_date(resolved_at, '%Y-%m-%d %H:%i:%s')
    WHEN resolved_at LIKE '%/%' THEN str_to_date(resolved_at, '%d/%m/%Y %H:%i')
    WHEN resolved_at LIKE '__-__-____%' THEN str_to_date(resolved_at,  '%m-%d-%Y %H:%i')
END;
SET SQL_SAFE_UPDATES = 0;
-- Step 4: Standardise region column
-- Fixed typos: south or Sth→South, EAST or east or Est→East,NORTH or Nrth→North
update cleaned_tickets
set region= case
when region= 'Sth' or region='south' then 'South'
when region='Est' or region='east' or region='EAST' then 'East'
when region='Nrth' OR region='NORTH' then 'North'
else region
end;

-- Step 5: Standardise product_line column
-- Fixed: CreditCard→Credit Card, credit card→Credit Card
-- Fixed: PersonalLoan→Personal Loan, personal loan→Personal Loan
-- 21 blank values converted to NULL
SET product_line = CASE
    WHEN product_line = 'PersonalLoan' THEN 'Personal Loan'
    WHEN product_line = 'personal loan' THEN 'Personal Loan'
    WHEN product_line = 'CreditCard' THEN 'Credit Card'
    WHEN product_line = 'credit card' THEN 'Credit Card'
    WHEN product_line = 'Insurance' THEN 'Insurance'
    WHEN product_line = '' OR product_line IS NULL THEN NULL
    ELSE product_line
END;
-- Step 6: Standardise category column
-- Fixed: BILLING ISSUE→Billing Issue, Account access→Account Access
-- 50 blank values converted to NULL
-- All 8 categories confirmed and standardised explicitly
update cleaned_tickets 
set category=case
when category='BILLING ISSUE' then 'Billing Issue'
when category='Policy Renewal' then 'Policy Renewal'
when category='Account access' then 'Account Access'
when category='Payment Failure' then 'Payment Failure'
when category='Claim Request' then 'Claim Request'
when category='KYC Update' then 'KYC Update'
when category='EMI Query' then 'EMI Query'
when category='Fraud Alert' then 'Fraud Alert'
WHEN category = '' OR category IS NULL THEN NULL
else category
end;
-- Step 7: Standardise status column
-- Fixed: CLOSED→Closed, open→Open, RESOLVED→Resolved
-- Fixed typo: Resolveddd→Resolved
-- Result: 4 clean values - Resolved(265), Closed(254), Escalated(230), Open(216)
update cleaned_tickets
set status = case
when status='CLOSED' THEN 'Closed'
when status='Escalated' then 'Escalated'
when status='open' then 'Open'
when status='RESOLVED' OR status='Resolveddd' then 'Resolved'
else status
end;
-- Step 8: Standardise priority column
-- No case issues or typos found
-- 39 blank values converted to NULL
-- Result: Medium(317), Low(308), High(301), NULL(39)
Update cleaned_tickets
set priority =case
when priority= '' or priority is null then null
else priority end;
-- Step 9: Flag outliers in resolution_hours
-- 27 tickets have resolution_hours > 200 (threshold = ~5x median of 36.79 hours)
-- Flagging instead of deleting -- business should review these cases

SELECT COUNT(*) as outlier_count
FROM cleaned_tickets
WHERE resolution_hours > 200;
ALTER TABLE cleaned_tickets ADD COLUMN resolution_outlier VARCHAR(10);

UPDATE cleaned_tickets
SET resolution_outlier = CASE
    WHEN resolution_hours > 200 THEN 'Outlier'
    ELSE 'Normal'
END;
-- Step 10: Flag outliers in first_response_hours
-- Threshold set at 48 hours (~3.5x median of 13.45 hours)
-- 39 tickets flagged as outlier for first response
-- Result: Normal(939), Outlier(39) -- excluding resolution outlier overlap
UPDATE cleaned_tickets
SET first_response_outlier = CASE
    WHEN first_response_hours > 48 THEN 'Outlier'
    ELSE 'Normal'
END;
-- Step 11: Handle missing agent_name values
-- Phase 1 profiling found 65 missing values
-- After deduplication 61 missing values remain
-- 4 missing rows were part of duplicate records removed in Step 1
-- Blank values converted to NULL for consistency
UPDATE cleaned_tickets
SET agent_name = NULL
WHERE agent_name = '';
-- Step 12: Handle missing csat_score values
-- Phase 1 profiling found 146 missing values
-- After deduplication 140 missing values remain
-- Blank values converted to NULL for consistency
UPDATE cleaned_tickets
SET csat_score = NULL
WHERE csat_score = '';
