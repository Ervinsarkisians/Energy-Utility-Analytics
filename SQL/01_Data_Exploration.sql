/*
============================================================
ENERGY UTILITY ANALYTICS
01_Data_Exploration.sql

Purpose:
    Explore source data, identify data-quality issues,
    understand relationships, and prepare for ETL.

Source schema:
    dbo
============================================================
*/

USE [Portfolio];
GO


/*============================================================
1. ROW COUNTS
============================================================*/

SELECT 'customers' AS TableName, COUNT(*) AS TotalRows
FROM dbo.customers

UNION ALL

SELECT 'accounts', COUNT(*)
FROM dbo.accounts

UNION ALL

SELECT 'account_rate_plans', COUNT(*)
FROM dbo.account_rate_plans

UNION ALL

SELECT 'bills', COUNT(*)
FROM dbo.bills

UNION ALL

SELECT 'energy_usage', COUNT(*)
FROM dbo.energy_usage

UNION ALL

SELECT 'infrastructure_assets', COUNT(*)
FROM dbo.infrastructure_assets

UNION ALL

SELECT 'maintenance_logs', COUNT(*)
FROM dbo.maintenance_logs

UNION ALL

SELECT 'meters', COUNT(*)
FROM dbo.meters

UNION ALL

SELECT 'outages', COUNT(*)
FROM dbo.outages

UNION ALL

SELECT 'payments', COUNT(*)
FROM dbo.payments

UNION ALL

SELECT 'rate_plans', COUNT(*)
FROM dbo.rate_plans;


/*============================================================
2. CUSTOMER DATA
============================================================*/

-- Check for duplicate Customer IDs
SELECT
    customer_id,
    COUNT(*) AS RecordCount
FROM dbo.customers
GROUP BY customer_id
HAVING COUNT(*) > 1;


-- Check for missing customer information
SELECT *
FROM dbo.customers
WHERE customer_id IS NULL
   OR first_name IS NULL
   OR last_name IS NULL
   OR email IS NULL;


-- Examine phone number formatting
SELECT
    phone_number,
    LEN(phone_number) AS PhoneLength
FROM dbo.customers
ORDER BY phone_number;


/*============================================================
3. ACCOUNT DATA
============================================================*/

-- Duplicate accounts
SELECT
    account_id,
    COUNT(*) AS RecordCount
FROM dbo.accounts
GROUP BY account_id
HAVING COUNT(*) > 1;


-- Accounts without a customer
SELECT a.*
FROM dbo.accounts a
LEFT JOIN dbo.customers c
    ON a.customer_id = c.customer_id
WHERE c.customer_id IS NULL;


-- Account status distribution
SELECT
    account_status,
    COUNT(*) AS AccountCount
FROM dbo.accounts
GROUP BY account_status
ORDER BY AccountCount DESC;


/*============================================================
4. ACCOUNT RATE PLAN DATA
============================================================*/

-- Invalid date ranges
SELECT *
FROM dbo.account_rate_plans
WHERE start_date IS NOT NULL
  AND end_date IS NOT NULL
  AND end_date < start_date;


-- Accounts without valid rate plans
SELECT arp.*
FROM dbo.account_rate_plans arp
LEFT JOIN dbo.accounts a
    ON arp.account_id = a.account_id
WHERE a.account_id IS NULL;


/*============================================================
5. BILLING DATA
============================================================*/

-- Invalid billing periods
SELECT *
FROM dbo.bills
WHERE billing_period_start IS NOT NULL
  AND billing_period_end IS NOT NULL
  AND billing_period_end < billing_period_start;


-- Negative billing amounts
SELECT *
FROM dbo.bills
WHERE total_amount < 0;


-- Bills without an account
SELECT b.*
FROM dbo.bills b
LEFT JOIN dbo.accounts a
    ON b.account_id = a.account_id
WHERE a.account_id IS NULL;


/*============================================================
6. PAYMENT DATA
============================================================*/

-- Negative payments
SELECT *
FROM dbo.payments
WHERE payment_amount < 0;


-- Payments without corresponding bills
SELECT p.*
FROM dbo.payments p
LEFT JOIN dbo.bills b
    ON p.bill_id = b.bill_id
WHERE b.bill_id IS NULL;


-- Payment method distribution
SELECT
    payment_method,
    COUNT(*) AS PaymentCount,
    SUM(payment_amount) AS TotalPayments
FROM dbo.payments
GROUP BY payment_method
ORDER BY TotalPayments DESC;


/*============================================================
7. ENERGY USAGE
============================================================*/

-- Negative usage
SELECT *
FROM dbo.energy_usage
WHERE kwh_used < 0;


-- Missing meter references
SELECT eu.*
FROM dbo.energy_usage eu
LEFT JOIN dbo.meters m
    ON eu.meter_id = m.meter_id
WHERE m.meter_id IS NULL;


-- Peak vs non-peak usage
SELECT
    peak_usage_flag,
    COUNT(*) AS UsageRecords,
    SUM(kwh_used) AS TotalKWh
FROM dbo.energy_usage
GROUP BY peak_usage_flag;


/*============================================================
8. METER DATA
============================================================*/

SELECT
    meter_type,
    COUNT(*) AS MeterCount
FROM dbo.meters
GROUP BY meter_type;


/*============================================================
9. ASSET DATA
============================================================*/

SELECT
    asset_type,
    status,
    COUNT(*) AS AssetCount
FROM dbo.infrastructure_assets
GROUP BY
    asset_type,
    status
ORDER BY
    asset_type,
    AssetCount DESC;


-- Assets with future installation dates
SELECT *
FROM dbo.infrastructure_assets
WHERE install_date > CAST(GETDATE() AS DATE);


/*============================================================
10. MAINTENANCE
============================================================*/

SELECT
    maintenance_type,
    COUNT(*) AS MaintenanceCount
FROM dbo.maintenance_logs
GROUP BY maintenance_type
ORDER BY MaintenanceCount DESC;


-- Maintenance records without valid assets
SELECT ml.*
FROM dbo.maintenance_logs ml
LEFT JOIN dbo.infrastructure_assets ia
    ON ml.asset_id = ia.asset_id
WHERE ia.asset_id IS NULL;


/*============================================================
11. OUTAGES
============================================================*/

-- Invalid outage durations
SELECT *
FROM dbo.outages
WHERE end_time < start_time;


-- Negative affected customers
SELECT *
FROM dbo.outages
WHERE customers_affected < 0;


-- Outages by cause
SELECT
    cause,
    COUNT(*) AS OutageCount,
    SUM(customers_affected) AS CustomersAffected
FROM dbo.outages
GROUP BY cause
ORDER BY OutageCount DESC;


/*============================================================
12. RATE PLAN DATA
============================================================*/

SELECT
    rate_plan_id,
    name,
    rate_per_kwh,
    peak_rate,
    effective_date
FROM dbo.rate_plans
ORDER BY rate_plan_id;


/*
IMPORTANT DATA QUALITY FINDING:

rate_per_kwh and peak_rate are TIME columns.

Example:
    00:14:00 = likely $0.14
    00:58:00 = likely $0.58

This will be handled in the cleaning/transformation stage.
*/


/*============================================================
13. BASIC BUSINESS METRICS
============================================================*/

SELECT
    COUNT(DISTINCT customer_id) AS TotalCustomers
FROM dbo.customers;


SELECT
    COUNT(DISTINCT account_id) AS TotalAccounts
FROM dbo.accounts;


SELECT
    COUNT(*) AS TotalBills,
    SUM(total_amount) AS TotalBilledAmount,
    AVG(total_amount) AS AverageBillAmount
FROM dbo.bills;


SELECT
    COUNT(*) AS TotalUsageRecords,
    SUM(kwh_used) AS TotalKWhUsed,
    AVG(kwh_used) AS AverageKWhPerRecord
FROM dbo.energy_usage;


SELECT
    COUNT(*) AS TotalOutages,
    SUM(customers_affected) AS TotalCustomersAffected
FROM dbo.outages;