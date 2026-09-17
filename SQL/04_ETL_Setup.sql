/* ============================================================
   STEP 4 - ETL / DATA WAREHOUSE LOAD
   Energy Utility Analytics Portfolio
   ============================================================

   PURPOSE:
   - Build reporting/data warehouse tables
   - Load dimensions and facts from ETL tables
   - Correctly maintain relationships
   - Avoid dependency on optional calculated columns
   - Preserve source data-quality issues as flags

   IMPORTANT:
   - Change [YourDatabaseName] below.
   - Run Step 2 and Step 3 before running this script.
   - This script does NOT modify dbo source tables.
   ============================================================ */

USE [Portfolio];
GO


/* ============================================================
   1. CREATE DW SCHEMA
   ============================================================ */

IF NOT EXISTS
(
    SELECT 1
    FROM sys.schemas
    WHERE name = 'dw'
)
BEGIN
    EXEC('CREATE SCHEMA dw');
END;
GO


/* ============================================================
   2. DROP EXISTING DW TABLES
   ============================================================ */

IF OBJECT_ID('dw.FactEnergyUsage', 'U') IS NOT NULL
    DROP TABLE dw.FactEnergyUsage;

IF OBJECT_ID('dw.FactPayments', 'U') IS NOT NULL
    DROP TABLE dw.FactPayments;

IF OBJECT_ID('dw.FactBilling', 'U') IS NOT NULL
    DROP TABLE dw.FactBilling;

IF OBJECT_ID('dw.FactMaintenance', 'U') IS NOT NULL
    DROP TABLE dw.FactMaintenance;

IF OBJECT_ID('dw.FactOutage', 'U') IS NOT NULL
    DROP TABLE dw.FactOutage;

IF OBJECT_ID('dw.BridgeAccountRatePlan', 'U') IS NOT NULL
    DROP TABLE dw.BridgeAccountRatePlan;

IF OBJECT_ID('dw.DimRatePlan', 'U') IS NOT NULL
    DROP TABLE dw.DimRatePlan;

IF OBJECT_ID('dw.DimMeter', 'U') IS NOT NULL
    DROP TABLE dw.DimMeter;

IF OBJECT_ID('dw.DimAsset', 'U') IS NOT NULL
    DROP TABLE dw.DimAsset;

IF OBJECT_ID('dw.DimAccount', 'U') IS NOT NULL
    DROP TABLE dw.DimAccount;

IF OBJECT_ID('dw.DimCustomer', 'U') IS NOT NULL
    DROP TABLE dw.DimCustomer;

GO


/* ============================================================
   3. DIMENSION TABLES
   ============================================================ */


/* -------------------------
   CUSTOMER
   ------------------------- */

CREATE TABLE dw.DimCustomer
(
    customer_id     TINYINT NOT NULL,
    first_name      NVARCHAR(50) NULL,
    last_name       NVARCHAR(50) NULL,
    customer_name   NVARCHAR(101) NULL,
    email           NVARCHAR(50) NULL,
    phone_number    NVARCHAR(50) NULL,
    created_at      DATE NULL,

    CONSTRAINT PK_DimCustomer
        PRIMARY KEY (customer_id)
);

GO


/* -------------------------
   ACCOUNT
   ------------------------- */

CREATE TABLE dw.DimAccount
(
    account_id          TINYINT NOT NULL,
    customer_id         TINYINT NULL,
    service_address     NVARCHAR(100) NULL,
    billing_address     NVARCHAR(100) NULL,
    account_status      NVARCHAR(50) NULL,

    CONSTRAINT PK_DimAccount
        PRIMARY KEY (account_id)
);

GO


/* -------------------------
   METER
   ------------------------- */

CREATE TABLE dw.DimMeter
(
    meter_id        TINYINT NOT NULL,
    account_id      TINYINT NULL,
    meter_type      NVARCHAR(50) NULL,
    install_date    DATE NULL,

    CONSTRAINT PK_DimMeter
        PRIMARY KEY (meter_id)
);

GO


/* -------------------------
   RATE PLAN
   ------------------------- */

CREATE TABLE dw.DimRatePlan
(
    rate_plan_id        TINYINT NOT NULL,
    name                NVARCHAR(50) NULL,
    rate_per_kwh        DECIMAL(10,4) NULL,
    peak_rate           DECIMAL(10,4) NULL,
    effective_date      DATE NULL,

    CONSTRAINT PK_DimRatePlan
        PRIMARY KEY (rate_plan_id)
);

GO


/* -------------------------
   ASSET
   ------------------------- */

CREATE TABLE dw.DimAsset
(
    asset_id        TINYINT NOT NULL,
    asset_type      NVARCHAR(50) NULL,
    location        NVARCHAR(50) NULL,
    install_date    DATE NULL,
    status          NVARCHAR(50) NULL,

    CONSTRAINT PK_DimAsset
        PRIMARY KEY (asset_id)
);

GO


/* ============================================================
   4. FACT TABLES
   ============================================================ */


/* -------------------------
   BILLING
   ------------------------- */

CREATE TABLE dw.FactBilling
(
    bill_id                 SMALLINT NOT NULL,
    account_id              TINYINT NULL,
    customer_id             TINYINT NULL,
    billing_period_start    DATE NULL,
    billing_period_end      DATE NULL,
    total_amount            DECIMAL(12,2) NULL,
    due_date                DATE NULL,
    invalid_billing_period  BIT NULL,

    CONSTRAINT PK_FactBilling
        PRIMARY KEY (bill_id)
);

GO


/* -------------------------
   PAYMENTS
   ------------------------- */

CREATE TABLE dw.FactPayments
(
    payment_id          SMALLINT NOT NULL,
    bill_id             SMALLINT NULL,
    account_id          TINYINT NULL,
    customer_id         TINYINT NULL,
    payment_date        DATE NULL,
    payment_amount      DECIMAL(12,2) NULL,
    payment_method      NVARCHAR(50) NULL,

    CONSTRAINT PK_FactPayments
        PRIMARY KEY (payment_id)
);

GO


/* -------------------------
   ENERGY USAGE
   ------------------------- */

CREATE TABLE dw.FactEnergyUsage
(
    usage_id            SMALLINT NOT NULL,
    meter_id            TINYINT NULL,
    account_id          TINYINT NULL,
    customer_id         TINYINT NULL,
    usage_date          DATE NULL,
    kwh_used            DECIMAL(12,2) NULL,
    peak_usage_flag     BIT NULL,
    usage_period        NVARCHAR(20) NULL,

    CONSTRAINT PK_FactEnergyUsage
        PRIMARY KEY (usage_id)
);

GO


/* -------------------------
   MAINTENANCE
   ------------------------- */

CREATE TABLE dw.FactMaintenance
(
    log_id              TINYINT NOT NULL,
    asset_id            TINYINT NULL,
    maintenance_date    DATE NULL,
    maintenance_type    NVARCHAR(50) NULL,

    CONSTRAINT PK_FactMaintenance
        PRIMARY KEY (log_id)
);

GO


/* -------------------------
   OUTAGES
   ------------------------- */

CREATE TABLE dw.FactOutage
(
    outage_id           TINYINT NOT NULL,
    start_time          DATETIME2 NULL,
    end_time            DATETIME2 NULL,
    affected_area       NVARCHAR(50) NULL,
    customers_affected  SMALLINT NULL,
    cause               NVARCHAR(50) NULL,
    duration_minutes    DECIMAL(12,2) NULL,
    duration_hours      DECIMAL(12,2) NULL,
    invalid_duration    BIT NULL,

    CONSTRAINT PK_FactOutage
        PRIMARY KEY (outage_id)
);

GO


/* ============================================================
   5. ACCOUNT / RATE PLAN BRIDGE
   ============================================================ */

CREATE TABLE dw.BridgeAccountRatePlan
(
    account_id          TINYINT NOT NULL,
    rate_plan_id        TINYINT NOT NULL,
    start_date          DATE NULL,
    end_date            DATE NULL,
    invalid_date_range  BIT NULL
);

GO


/* ============================================================
   6. LOAD DIM CUSTOMER
   ============================================================ */

INSERT INTO dw.DimCustomer
(
    customer_id,
    first_name,
    last_name,
    customer_name,
    email,
    phone_number,
    created_at
)
SELECT
    customer_id,
    first_name,
    last_name,
    CONCAT(first_name, ' ', last_name),
    email,
    phone_number,
    created_at
FROM etl.Customers;

GO


/* ============================================================
   7. LOAD DIM ACCOUNT
   ============================================================ */

INSERT INTO dw.DimAccount
(
    account_id,
    customer_id,
    service_address,
    billing_address,
    account_status
)
SELECT
    account_id,
    customer_id,
    service_address,
    billing_address,
    account_status
FROM etl.Accounts;

GO


/* ============================================================
   8. LOAD DIM METER
   ============================================================ */

INSERT INTO dw.DimMeter
(
    meter_id,
    account_id,
    meter_type,
    install_date
)
SELECT
    meter_id,
    account_id,
    meter_type,
    install_date
FROM etl.Meters;

GO


/* ============================================================
   9. LOAD DIM RATE PLAN
   ============================================================ */

INSERT INTO dw.DimRatePlan
(
    rate_plan_id,
    name,
    rate_per_kwh,
    peak_rate,
    effective_date
)
SELECT
    rate_plan_id,
    name,
    rate_per_kwh,
    peak_rate,
    effective_date
FROM etl.RatePlans;

GO


/* ============================================================
   10. LOAD DIM ASSET
   ============================================================ */

INSERT INTO dw.DimAsset
(
    asset_id,
    asset_type,
    location,
    install_date,
    status
)
SELECT
    asset_id,
    asset_type,
    location,
    install_date,
    status
FROM etl.InfrastructureAssets;

GO


/* ============================================================
   11. LOAD FACT BILLING
   ============================================================ */

INSERT INTO dw.FactBilling
(
    bill_id,
    account_id,
    customer_id,
    billing_period_start,
    billing_period_end,
    total_amount,
    due_date,
    invalid_billing_period
)
SELECT
    b.bill_id,
    b.account_id,
    a.customer_id,
    b.billing_period_start,
    b.billing_period_end,
    b.total_amount,
    b.due_date,

    CASE
        WHEN b.billing_period_end < b.billing_period_start
            THEN 1
        ELSE 0
    END

FROM etl.Bills b

LEFT JOIN etl.Accounts a
    ON b.account_id = a.account_id;

GO


/* ============================================================
   12. LOAD FACT PAYMENTS
   ============================================================ */

INSERT INTO dw.FactPayments
(
    payment_id,
    bill_id,
    account_id,
    customer_id,
    payment_date,
    payment_amount,
    payment_method
)
SELECT
    p.payment_id,
    p.bill_id,
    b.account_id,
    a.customer_id,
    p.payment_date,
    p.payment_amount,
    p.payment_method

FROM etl.Payments p

LEFT JOIN etl.Bills b
    ON p.bill_id = b.bill_id

LEFT JOIN etl.Accounts a
    ON b.account_id = a.account_id;

GO


/* ============================================================
   13. LOAD FACT ENERGY USAGE
   IMPORTANT:
   We calculate peak/off-peak directly from the source
   peak_usage_flag rather than relying on an ETL-derived
   column name.
   ============================================================ */

INSERT INTO dw.FactEnergyUsage
(
    usage_id,
    meter_id,
    account_id,
    customer_id,
    usage_date,
    kwh_used,
    peak_usage_flag,
    usage_period
)
SELECT
    u.usage_id,
    u.meter_id,
    m.account_id,
    a.customer_id,
    u.usage_date,
    u.kwh_used,

    /* Peak flag */
    CASE
        WHEN u.peak_usage_flag = 1
            THEN 1
        ELSE 0
    END,

    /* Usage period */
    CASE
        WHEN u.peak_usage_flag = 1
            THEN 'Peak'
        ELSE 'Off-Peak'
    END

FROM dbo.energy_usage u

LEFT JOIN dbo.meters m
    ON u.meter_id = m.meter_id

LEFT JOIN dbo.accounts a
    ON m.account_id = a.account_id;

GO


/* ============================================================
   14. LOAD FACT MAINTENANCE
   ============================================================ */

INSERT INTO dw.FactMaintenance
(
    log_id,
    asset_id,
    maintenance_date,
    maintenance_type
)
SELECT
    log_id,
    asset_id,
    maintenance_date,
    maintenance_type
FROM etl.MaintenanceLogs;

GO


/* ============================================================
   15. LOAD FACT OUTAGE
   Calculate duration directly from start/end times.
   ============================================================ */

INSERT INTO dw.FactOutage
(
    outage_id,
    start_time,
    end_time,
    affected_area,
    customers_affected,
    cause,
    duration_minutes,
    duration_hours,
    invalid_duration
)
SELECT
    outage_id,
    start_time,
    end_time,
    affected_area,
    customers_affected,
    cause,

    CASE
        WHEN end_time >= start_time
            THEN CAST(
                DATEDIFF(SECOND, start_time, end_time) / 60.0
                AS DECIMAL(12,2)
            )
        ELSE NULL
    END AS duration_minutes,

    CASE
        WHEN end_time >= start_time
            THEN CAST(
                DATEDIFF(SECOND, start_time, end_time) / 3600.0
                AS DECIMAL(12,2)
            )
        ELSE NULL
    END AS duration_hours,

    CASE
        WHEN end_time < start_time
            THEN 1
        ELSE 0
    END AS invalid_duration

FROM dbo.outages;

GO


/* ============================================================
   16. LOAD ACCOUNT / RATE PLAN BRIDGE
   ============================================================ */

INSERT INTO dw.BridgeAccountRatePlan
(
    account_id,
    rate_plan_id,
    start_date,
    end_date,
    invalid_date_range
)
SELECT
    account_id,
    rate_plan_id,
    start_date,
    end_date,

    CASE
        WHEN end_date < start_date
            THEN 1
        ELSE 0
    END

FROM etl.AccountRatePlans;

GO


/* ============================================================
   17. CREATE INDEXES
   ============================================================ */


/* Account */

CREATE INDEX IX_DimAccount_CustomerID
ON dw.DimAccount(customer_id);


/* Meter */

CREATE INDEX IX_DimMeter_AccountID
ON dw.DimMeter(account_id);


/* Billing */

CREATE INDEX IX_FactBilling_AccountID
ON dw.FactBilling(account_id);

CREATE INDEX IX_FactBilling_CustomerID
ON dw.FactBilling(customer_id);

CREATE INDEX IX_FactBilling_DueDate
ON dw.FactBilling(due_date);


/* Payments */

CREATE INDEX IX_FactPayments_BillID
ON dw.FactPayments(bill_id);

CREATE INDEX IX_FactPayments_AccountID
ON dw.FactPayments(account_id);

CREATE INDEX IX_FactPayments_CustomerID
ON dw.FactPayments(customer_id);

CREATE INDEX IX_FactPayments_PaymentDate
ON dw.FactPayments(payment_date);


/* Energy Usage */

CREATE INDEX IX_FactEnergyUsage_MeterID
ON dw.FactEnergyUsage(meter_id);

CREATE INDEX IX_FactEnergyUsage_AccountID
ON dw.FactEnergyUsage(account_id);

CREATE INDEX IX_FactEnergyUsage_CustomerID
ON dw.FactEnergyUsage(customer_id);

CREATE INDEX IX_FactEnergyUsage_UsageDate
ON dw.FactEnergyUsage(usage_date);


/* Maintenance */

CREATE INDEX IX_FactMaintenance_AssetID
ON dw.FactMaintenance(asset_id);

CREATE INDEX IX_FactMaintenance_Date
ON dw.FactMaintenance(maintenance_date);


/* Outages */

CREATE INDEX IX_FactOutage_StartTime
ON dw.FactOutage(start_time);

CREATE INDEX IX_FactOutage_Area
ON dw.FactOutage(affected_area);


/* Rate Plans */

CREATE INDEX IX_BridgeAccountRatePlan_AccountID
ON dw.BridgeAccountRatePlan(account_id);

CREATE INDEX IX_BridgeAccountRatePlan_RatePlanID
ON dw.BridgeAccountRatePlan(rate_plan_id);

GO


/* ============================================================
   18. VALIDATE ROW COUNTS
   ============================================================ */

SELECT
    'DimCustomer' AS TableName,
    COUNT(*) AS TotalRows
FROM dw.DimCustomer

UNION ALL

SELECT
    'DimAccount',
    COUNT(*)
FROM dw.DimAccount

UNION ALL

SELECT
    'DimMeter',
    COUNT(*)
FROM dw.DimMeter

UNION ALL

SELECT
    'DimRatePlan',
    COUNT(*)
FROM dw.DimRatePlan

UNION ALL

SELECT
    'DimAsset',
    COUNT(*)
FROM dw.DimAsset

UNION ALL

SELECT
    'FactBilling',
    COUNT(*)
FROM dw.FactBilling

UNION ALL

SELECT
    'FactPayments',
    COUNT(*)
FROM dw.FactPayments

UNION ALL

SELECT
    'FactEnergyUsage',
    COUNT(*)
FROM dw.FactEnergyUsage

UNION ALL

SELECT
    'FactMaintenance',
    COUNT(*)
FROM dw.FactMaintenance

UNION ALL

SELECT
    'FactOutage',
    COUNT(*)
FROM dw.FactOutage

UNION ALL

SELECT
    'BridgeAccountRatePlan',
    COUNT(*)
FROM dw.BridgeAccountRatePlan;

GO


/* ============================================================
   19. ORPHAN RECORD CHECKS
   ============================================================ */


/* Energy Usage → Meter */

SELECT
    'Orphaned Energy Usage' AS CheckName,
    COUNT(*) AS IssueCount
FROM dw.FactEnergyUsage u

LEFT JOIN dw.DimMeter m
    ON u.meter_id = m.meter_id

WHERE m.meter_id IS NULL;


/* Billing → Account */

SELECT
    'Orphaned Billing' AS CheckName,
    COUNT(*) AS IssueCount
FROM dw.FactBilling b

LEFT JOIN dw.DimAccount a
    ON b.account_id = a.account_id

WHERE a.account_id IS NULL;


/* Payments → Bill */

SELECT
    'Orphaned Payments' AS CheckName,
    COUNT(*) AS IssueCount
FROM dw.FactPayments p

LEFT JOIN dw.FactBilling b
    ON p.bill_id = b.bill_id

WHERE b.bill_id IS NULL;


/* Maintenance → Asset */

SELECT
    'Orphaned Maintenance' AS CheckName,
    COUNT(*) AS IssueCount
FROM dw.FactMaintenance m

LEFT JOIN dw.DimAsset a
    ON m.asset_id = a.asset_id

WHERE a.asset_id IS NULL;


/* Account Rate Plan → Account */

SELECT
    'Orphaned Account Rate Plans' AS CheckName,
    COUNT(*) AS IssueCount
FROM dw.BridgeAccountRatePlan arp

LEFT JOIN dw.DimAccount a
    ON arp.account_id = a.account_id

WHERE a.account_id IS NULL;


/* Account Rate Plan → Rate Plan */

SELECT
    'Orphaned Rate Plans' AS CheckName,
    COUNT(*) AS IssueCount
FROM dw.BridgeAccountRatePlan arp

LEFT JOIN dw.DimRatePlan rp
    ON arp.rate_plan_id = rp.rate_plan_id

WHERE rp.rate_plan_id IS NULL;

GO


/* ============================================================
   20. DATA QUALITY SUMMARY
   ============================================================ */

SELECT
    'Invalid Billing Periods' AS DataQualityIssue,
    COUNT(*) AS IssueCount
FROM dw.FactBilling
WHERE invalid_billing_period = 1

UNION ALL

SELECT
    'Invalid Outage Durations',
    COUNT(*)
FROM dw.FactOutage
WHERE invalid_duration = 1

UNION ALL

SELECT
    'Invalid Account Rate Plan Dates',
    COUNT(*)
FROM dw.BridgeAccountRatePlan
WHERE invalid_date_range = 1;

GO


/* ============================================================
   21. BUSINESS DATA SUMMARY
   ============================================================ */

SELECT
    'Customers' AS Metric,
    COUNT(*) AS MetricValue
FROM dw.DimCustomer

UNION ALL

SELECT
    'Accounts',
    COUNT(*)
FROM dw.DimAccount

UNION ALL

SELECT
    'Meters',
    COUNT(*)
FROM dw.DimMeter

UNION ALL

SELECT
    'Rate Plans',
    COUNT(*)
FROM dw.DimRatePlan

UNION ALL

SELECT
    'Assets',
    COUNT(*)
FROM dw.DimAsset

UNION ALL

SELECT
    'Bills',
    COUNT(*)
FROM dw.FactBilling

UNION ALL

SELECT
    'Payments',
    COUNT(*)
FROM dw.FactPayments

UNION ALL

SELECT
    'Energy Usage Records',
    COUNT(*)
FROM dw.FactEnergyUsage

UNION ALL

SELECT
    'Maintenance Records',
    COUNT(*)
FROM dw.FactMaintenance

UNION ALL

SELECT
    'Outages',
    COUNT(*)
FROM dw.FactOutage

UNION ALL

SELECT
    'Account Rate Plan Records',
    COUNT(*)
FROM dw.BridgeAccountRatePlan;

GO


/* ============================================================
   22. FINAL SUCCESS CHECK
   ============================================================ */

IF
    NOT EXISTS
    (
        SELECT 1
        FROM dw.DimCustomer
        WHERE customer_id IS NULL
    )
    AND NOT EXISTS
    (
        SELECT 1
        FROM dw.DimAccount
        WHERE account_id IS NULL
    )
    AND NOT EXISTS
    (
        SELECT 1
        FROM dw.DimMeter
        WHERE meter_id IS NULL
    )
    AND NOT EXISTS
    (
        SELECT 1
        FROM dw.FactBilling
        WHERE bill_id IS NULL
    )
    AND NOT EXISTS
    (
        SELECT 1
        FROM dw.FactPayments
        WHERE payment_id IS NULL
    )
    AND NOT EXISTS
    (
        SELECT 1
        FROM dw.FactEnergyUsage
        WHERE usage_id IS NULL
    )
    AND NOT EXISTS
    (
        SELECT 1
        FROM dw.FactMaintenance
        WHERE log_id IS NULL
    )
    AND NOT EXISTS
    (
        SELECT 1
        FROM dw.FactOutage
        WHERE outage_id IS NULL
    )
BEGIN
    PRINT 'STEP 4 COMPLETED SUCCESSFULLY - DATA WAREHOUSE LOADED.';
END
ELSE
BEGIN
    PRINT 'STEP 4 COMPLETED WITH DATA VALIDATION ISSUES.';
END;

GO