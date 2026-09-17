/*
============================================================
ENERGY UTILITY ANALYTICS
02_Data_Cleaning.sql

Purpose:
    Create cleaned versions of source tables.

Important:
    Original dbo tables are NOT modified.
============================================================
*/

USE [Portfolio];
GO


/*============================================================
1. CREATE ETL SCHEMA
============================================================*/

IF NOT EXISTS (
    SELECT 1
    FROM sys.schemas
    WHERE name = 'etl'
)
BEGIN
    EXEC('CREATE SCHEMA etl');
END;
GO


/*============================================================
2. CUSTOMERS
============================================================*/

DROP TABLE IF EXISTS etl.Customers;
GO

SELECT
    customer_id,
    NULLIF(LTRIM(RTRIM(first_name)), '') AS first_name,
    NULLIF(LTRIM(RTRIM(last_name)), '') AS last_name,
    LOWER(NULLIF(LTRIM(RTRIM(email)), '')) AS email,

    -- Keep digits only for standardized phone number
    CASE
        WHEN phone_number IS NULL THEN NULL
        ELSE
            REPLACE(
                REPLACE(
                    REPLACE(
                        REPLACE(
                            REPLACE(phone_number, '-', ''),
                        '(', ''),
                    ')', ''),
                '.', ''),
            ' ', '')
    END AS phone_number,

    created_at

INTO etl.Customers
FROM dbo.customers;
GO


/*============================================================
3. ACCOUNTS
============================================================*/

DROP TABLE IF EXISTS etl.Accounts;
GO

SELECT
    account_id,
    customer_id,
    NULLIF(LTRIM(RTRIM(service_address)), '') AS service_address,
    NULLIF(LTRIM(RTRIM(billing_address)), '') AS billing_address,

    CASE
        WHEN account_status IN ('Active', 'Closed')
            THEN account_status
        ELSE 'Unknown'
    END AS account_status

INTO etl.Accounts
FROM dbo.accounts;
GO


/*============================================================
4. ACCOUNT RATE PLANS
============================================================*/

DROP TABLE IF EXISTS etl.AccountRatePlans;
GO

SELECT
    account_id,
    rate_plan_id,
    start_date,
    end_date,

    CASE
        WHEN start_date IS NOT NULL
         AND end_date IS NOT NULL
         AND end_date < start_date
            THEN 1
        ELSE 0
    END AS invalid_date_range

INTO etl.AccountRatePlans
FROM dbo.account_rate_plans;
GO


/*============================================================
5. BILLS
============================================================*/

DROP TABLE IF EXISTS etl.Bills;
GO

SELECT
    bill_id,
    account_id,
    billing_period_start,
    billing_period_end,

    CAST(
        CASE
            WHEN total_amount >= 0 THEN total_amount
            ELSE NULL
        END
        AS DECIMAL(12,2)
    ) AS total_amount,

    due_date,

    CASE
        WHEN billing_period_end < billing_period_start
            THEN 1
        ELSE 0
    END AS invalid_billing_period

INTO etl.Bills
FROM dbo.bills;
GO


/*============================================================
6. ENERGY USAGE
============================================================*/

DROP TABLE IF EXISTS etl.EnergyUsage;
GO

SELECT
    usage_id,
    meter_id,
    usage_date,

    CAST(
        CASE
            WHEN kwh_used >= 0 THEN kwh_used
            ELSE NULL
        END
        AS DECIMAL(12,2)
    ) AS kwh_used,

    CASE
        WHEN peak_usage_flag = 1 THEN 'Peak'
        ELSE 'Off-Peak'
    END AS usage_period

INTO etl.EnergyUsage
FROM dbo.energy_usage;
GO


/*============================================================
7. INFRASTRUCTURE ASSETS
============================================================*/

DROP TABLE IF EXISTS etl.InfrastructureAssets;
GO

SELECT
    asset_id,
    NULLIF(LTRIM(RTRIM(asset_type)), '') AS asset_type,
    NULLIF(LTRIM(RTRIM(location)), '') AS location,

    install_date,

    CASE
        WHEN status IN ('Operational', 'Maintenance', 'Decommissioned')
            THEN status
        ELSE 'Unknown'
    END AS status

INTO etl.InfrastructureAssets
FROM dbo.infrastructure_assets;
GO


/*============================================================
8. MAINTENANCE
============================================================*/

DROP TABLE IF EXISTS etl.MaintenanceLogs;
GO

SELECT
    log_id,
    asset_id,
    maintenance_date,
    NULLIF(LTRIM(RTRIM(maintenance_type)), '') AS maintenance_type

INTO etl.MaintenanceLogs
FROM dbo.maintenance_logs;
GO


/*============================================================
9. METERS
============================================================*/

DROP TABLE IF EXISTS etl.Meters;
GO

SELECT
    meter_id,
    account_id,
    NULLIF(LTRIM(RTRIM(meter_type)), '') AS meter_type,
    install_date

INTO etl.Meters
FROM dbo.meters;
GO


/*============================================================
10. OUTAGES
============================================================*/

DROP TABLE IF EXISTS etl.Outages;
GO

SELECT
    outage_id,
    start_time,
    end_time,

    NULLIF(LTRIM(RTRIM(affected_area)), '') AS affected_area,

    CASE
        WHEN customers_affected >= 0
            THEN customers_affected
        ELSE NULL
    END AS customers_affected,

    NULLIF(LTRIM(RTRIM(cause)), '') AS cause,

    CASE
        WHEN end_time < start_time
            THEN 1
        ELSE 0
    END AS invalid_duration

INTO etl.Outages
FROM dbo.outages;
GO


/*============================================================
11. PAYMENTS
============================================================*/

DROP TABLE IF EXISTS etl.Payments;
GO

SELECT
    payment_id,
    bill_id,
    payment_date,

    CAST(
        CASE
            WHEN payment_amount >= 0 THEN payment_amount
            ELSE NULL
        END
        AS DECIMAL(12,2)
    ) AS payment_amount,

    NULLIF(LTRIM(RTRIM(payment_method)), '') AS payment_method

INTO etl.Payments
FROM dbo.payments;
GO


/*============================================================
12. RATE PLANS
============================================================*/

DROP TABLE IF EXISTS etl.RatePlans;
GO

SELECT
    rate_plan_id,
    NULLIF(LTRIM(RTRIM(name)), '') AS name,

    /*
        Original datatype is TIME.

        Example:
            00:14:00 = $0.14
            00:58:00 = $0.58

        Convert minutes into decimal dollars.
    */

    CAST(
        DATEPART(HOUR, rate_per_kwh) * 60
        + DATEPART(MINUTE, rate_per_kwh)
        + DATEPART(SECOND, rate_per_kwh) / 60.0
        AS DECIMAL(10,4)
    ) / 100 AS rate_per_kwh,

    CAST(
        DATEPART(HOUR, peak_rate) * 60
        + DATEPART(MINUTE, peak_rate)
        + DATEPART(SECOND, peak_rate) / 60.0
        AS DECIMAL(10,4)
    ) / 100 AS peak_rate,

    effective_date

INTO etl.RatePlans
FROM dbo.rate_plans;
GO


/*============================================================
13. CLEANING VALIDATION
============================================================*/

SELECT *
FROM etl.AccountRatePlans
WHERE invalid_date_range = 1;


SELECT *
FROM etl.Bills
WHERE invalid_billing_period = 1;


SELECT *
FROM etl.Outages
WHERE invalid_duration = 1;


SELECT *
FROM etl.RatePlans;