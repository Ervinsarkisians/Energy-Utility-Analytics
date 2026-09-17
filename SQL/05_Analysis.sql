/* ============================================================
   ENERGY UTILITY ANALYTICS
   STEP 5 - DATA WAREHOUSE ANALYSIS

   Purpose:
       Analyze the curated Data Warehouse created in Step 4.

   Source:
       dw schema

   This script:
       1. Executive KPIs
       2. Customer & Account Analysis
       3. Billing & Revenue Analysis
       4. Payment Analysis
       5. Energy Usage Analysis
       6. Rate Plan Analysis
       7. Infrastructure & Maintenance Analysis
       8. Outage Analysis
       9. Data Quality / Validation

   Important:
       FactBilling and FactPayments are analyzed separately or
       through pre-aggregated payment totals to avoid duplicate
       billing amounts when a bill has multiple payments.

   ============================================================ */


USE Portfolio;
GO


/* ============================================================
   SECTION 1
   EXECUTIVE KPI SUMMARY
   ============================================================ */

PRINT '============================================================';
PRINT 'SECTION 1 - EXECUTIVE KPI SUMMARY';
PRINT '============================================================';


/* ------------------------------------------------------------
   1.1 Customer and Account Overview
   ------------------------------------------------------------ */

SELECT
    COUNT(DISTINCT c.customer_id) AS TotalCustomers,
    COUNT(DISTINCT a.account_id) AS TotalAccounts,
    SUM(
        CASE
            WHEN a.account_status = 'Active' THEN 1
            ELSE 0
        END
    ) AS ActiveAccounts,
    SUM(
        CASE
            WHEN a.account_status <> 'Active'
                 OR a.account_status IS NULL
            THEN 1
            ELSE 0
        END
    ) AS InactiveOrOtherAccounts
FROM dw.DimCustomer AS c
LEFT JOIN dw.DimAccount AS a
    ON c.customer_id = a.customer_id;


/* ------------------------------------------------------------
   1.2 Billing Overview
   ------------------------------------------------------------ */

SELECT
    COUNT(*) AS TotalBills,
    CAST(SUM(total_amount) AS DECIMAL(14,2)) AS TotalBilledAmount,
    CAST(AVG(total_amount) AS DECIMAL(14,2)) AS AverageBillAmount,
    CAST(MIN(total_amount) AS DECIMAL(14,2)) AS MinimumBillAmount,
    CAST(MAX(total_amount) AS DECIMAL(14,2)) AS MaximumBillAmount
FROM dw.FactBilling;


/* ------------------------------------------------------------
   1.3 Payment Overview
   ------------------------------------------------------------ */

SELECT
    COUNT(*) AS TotalPayments,
    CAST(SUM(payment_amount) AS DECIMAL(14,2)) AS TotalPaymentAmount,
    CAST(AVG(payment_amount) AS DECIMAL(14,2)) AS AveragePaymentAmount,
    CAST(MIN(payment_amount) AS DECIMAL(14,2)) AS MinimumPaymentAmount,
    CAST(MAX(payment_amount) AS DECIMAL(14,2)) AS MaximumPaymentAmount
FROM dw.FactPayments;


/* ------------------------------------------------------------
   1.4 Energy Usage Overview
   ------------------------------------------------------------ */

SELECT
    COUNT(*) AS UsageRecords,
    CAST(SUM(kwh_used) AS DECIMAL(14,2)) AS TotalKWhUsed,
    CAST(AVG(kwh_used) AS DECIMAL(14,2)) AS AverageKWhPerRecord,
    CAST(MIN(kwh_used) AS DECIMAL(14,2)) AS MinimumKWh,
    CAST(MAX(kwh_used) AS DECIMAL(14,2)) AS MaximumKWh,
    SUM(
        CASE
            WHEN peak_usage_flag = 1 THEN 1
            ELSE 0
        END
    ) AS PeakUsageRecords
FROM dw.FactEnergyUsage;


/* ------------------------------------------------------------
   1.5 Infrastructure Overview
   ------------------------------------------------------------ */

SELECT
    COUNT(*) AS TotalAssets,
    SUM(
        CASE
            WHEN status = 'Active' THEN 1
            ELSE 0
        END
    ) AS ActiveAssets,
    SUM(
        CASE
            WHEN status <> 'Active'
                 OR status IS NULL
            THEN 1
            ELSE 0
        END
    ) AS InactiveOrOtherAssets
FROM dw.DimAsset;


/* ------------------------------------------------------------
   1.6 Outage Overview
   ------------------------------------------------------------ */

SELECT
    COUNT(*) AS TotalOutages,
    SUM(customers_affected) AS TotalCustomersAffected,
    CAST(AVG(duration_minutes) AS DECIMAL(14,2))
        AS AverageOutageMinutes,
    CAST(MAX(duration_minutes) AS DECIMAL(14,2))
        AS LongestOutageMinutes
FROM dw.FactOutage;


/* ============================================================
   SECTION 2
   CUSTOMER & ACCOUNT ANALYSIS
   ============================================================ */

PRINT '============================================================';
PRINT 'SECTION 2 - CUSTOMER & ACCOUNT ANALYSIS';
PRINT '============================================================';


/* ------------------------------------------------------------
   2.1 Accounts by Status
   ------------------------------------------------------------ */

SELECT
    account_status,
    COUNT(*) AS AccountCount
FROM dw.DimAccount
GROUP BY account_status
ORDER BY AccountCount DESC;


/* ------------------------------------------------------------
   2.2 Accounts by Customer
   ------------------------------------------------------------ */

SELECT
    c.customer_id,
    CONCAT(c.first_name, ' ', c.last_name) AS CustomerName,
    COUNT(a.account_id) AS AccountCount
FROM dw.DimCustomer AS c
LEFT JOIN dw.DimAccount AS a
    ON c.customer_id = a.customer_id
GROUP BY
    c.customer_id,
    c.first_name,
    c.last_name
ORDER BY AccountCount DESC;


/* ------------------------------------------------------------
   2.3 Customers with Multiple Accounts
   ------------------------------------------------------------ */

SELECT
    c.customer_id,
    CONCAT(c.first_name, ' ', c.last_name) AS CustomerName,
    COUNT(a.account_id) AS AccountCount
FROM dw.DimCustomer AS c
INNER JOIN dw.DimAccount AS a
    ON c.customer_id = a.customer_id
GROUP BY
    c.customer_id,
    c.first_name,
    c.last_name
HAVING COUNT(a.account_id) > 1
ORDER BY AccountCount DESC;


/* ------------------------------------------------------------
   2.4 Account Distribution by Customer
   ------------------------------------------------------------ */

SELECT
    AccountCount,
    COUNT(*) AS NumberOfCustomers
FROM
(
    SELECT
        c.customer_id,
        COUNT(a.account_id) AS AccountCount
    FROM dw.DimCustomer AS c
    LEFT JOIN dw.DimAccount AS a
        ON c.customer_id = a.customer_id
    GROUP BY c.customer_id
) AS CustomerAccounts
GROUP BY AccountCount
ORDER BY AccountCount;


/* ============================================================
   SECTION 3
   BILLING & REVENUE ANALYSIS
   ============================================================ */

PRINT '============================================================';
PRINT 'SECTION 3 - BILLING & REVENUE ANALYSIS';
PRINT '============================================================';


/* ------------------------------------------------------------
   3.1 Total Billed vs Total Paid vs Outstanding
   IMPORTANT:
   Payment totals are aggregated by bill before joining.
   This prevents duplicate billing amounts.
   ------------------------------------------------------------ */

WITH PaymentTotals AS
(
    SELECT
        bill_id,
        SUM(payment_amount) AS total_paid
    FROM dw.FactPayments
    GROUP BY bill_id
)
SELECT
    COUNT(b.bill_id) AS TotalBills,

    CAST(
        SUM(b.total_amount)
        AS DECIMAL(14,2)
    ) AS TotalBilled,

    CAST(
        COALESCE(SUM(pt.total_paid), 0)
        AS DECIMAL(14,2)
    ) AS TotalPaid,

    CAST(
        SUM(b.total_amount)
        - COALESCE(SUM(pt.total_paid), 0)
        AS DECIMAL(14,2)
    ) AS OutstandingBalance

FROM dw.FactBilling AS b

LEFT JOIN PaymentTotals AS pt
    ON b.bill_id = pt.bill_id;


/* ------------------------------------------------------------
   3.2 Payment Collection Rate
   ------------------------------------------------------------ */

WITH PaymentTotals AS
(
    SELECT
        bill_id,
        SUM(payment_amount) AS total_paid
    FROM dw.FactPayments
    GROUP BY bill_id
)
SELECT

    CAST(
        SUM(b.total_amount)
        AS DECIMAL(14,2)
    ) AS TotalBilled,

    CAST(
        COALESCE(SUM(pt.total_paid), 0)
        AS DECIMAL(14,2)
    ) AS TotalPaid,

    CAST(
        CASE
            WHEN SUM(b.total_amount) = 0 THEN 0
            ELSE
                (
                    COALESCE(SUM(pt.total_paid), 0)
                    / SUM(b.total_amount)
                ) * 100
        END
        AS DECIMAL(10,2)
    ) AS PaymentCollectionRatePercent

FROM dw.FactBilling AS b

LEFT JOIN PaymentTotals AS pt
    ON b.bill_id = pt.bill_id;


/* ------------------------------------------------------------
   3.3 Billing by Account
   ------------------------------------------------------------ */

SELECT
    a.account_id,
    a.customer_id,
    a.account_status,

    COUNT(b.bill_id) AS NumberOfBills,

    CAST(
        SUM(b.total_amount)
        AS DECIMAL(14,2)
    ) AS TotalBilled,

    CAST(
        AVG(b.total_amount)
        AS DECIMAL(14,2)
    ) AS AverageBillAmount

FROM dw.DimAccount AS a

LEFT JOIN dw.FactBilling AS b
    ON a.account_id = b.account_id

GROUP BY
    a.account_id,
    a.customer_id,
    a.account_status

ORDER BY TotalBilled DESC;


/* ------------------------------------------------------------
   3.4 Highest Revenue Accounts
   ------------------------------------------------------------ */

SELECT TOP 10

    a.account_id,
    a.customer_id,

    CAST(
        SUM(b.total_amount)
        AS DECIMAL(14,2)
    ) AS TotalBilled

FROM dw.DimAccount AS a

INNER JOIN dw.FactBilling AS b
    ON a.account_id = b.account_id

GROUP BY
    a.account_id,
    a.customer_id

ORDER BY TotalBilled DESC;


/* ------------------------------------------------------------
   3.5 Billing by Month
   ------------------------------------------------------------ */

SELECT

    YEAR(billing_period_end) AS BillingYear,
    MONTH(billing_period_end) AS BillingMonth,

    COUNT(*) AS NumberOfBills,

    CAST(
        SUM(total_amount)
        AS DECIMAL(14,2)
    ) AS TotalBilled,

    CAST(
        AVG(total_amount)
        AS DECIMAL(14,2)
    ) AS AverageBillAmount

FROM dw.FactBilling

GROUP BY
    YEAR(billing_period_end),
    MONTH(billing_period_end)

ORDER BY
    BillingYear,
    BillingMonth;


/* ------------------------------------------------------------
   3.6 Bills by Due Date
   ------------------------------------------------------------ */

SELECT

    YEAR(due_date) AS DueYear,
    MONTH(due_date) AS DueMonth,

    COUNT(*) AS BillsDue,

    CAST(
        SUM(total_amount)
        AS DECIMAL(14,2)
    ) AS AmountDue

FROM dw.FactBilling

GROUP BY
    YEAR(due_date),
    MONTH(due_date)

ORDER BY
    DueYear,
    DueMonth;


/* ============================================================
   SECTION 4
   PAYMENT ANALYSIS
   ============================================================ */

PRINT '============================================================';
PRINT 'SECTION 4 - PAYMENT ANALYSIS';
PRINT '============================================================';


/* ------------------------------------------------------------
   4.1 Payments by Method
   ------------------------------------------------------------ */

SELECT

    payment_method,

    COUNT(*) AS PaymentCount,

    CAST(
        SUM(payment_amount)
        AS DECIMAL(14,2)
    ) AS TotalPaymentAmount,

    CAST(
        AVG(payment_amount)
        AS DECIMAL(14,2)
    ) AS AveragePaymentAmount

FROM dw.FactPayments

GROUP BY payment_method

ORDER BY TotalPaymentAmount DESC;


/* ------------------------------------------------------------
   4.2 Payments by Month
   ------------------------------------------------------------ */

SELECT

    YEAR(payment_date) AS PaymentYear,
    MONTH(payment_date) AS PaymentMonth,

    COUNT(*) AS PaymentCount,

    CAST(
        SUM(payment_amount)
        AS DECIMAL(14,2)
    ) AS TotalPayments

FROM dw.FactPayments

GROUP BY
    YEAR(payment_date),
    MONTH(payment_date)

ORDER BY
    PaymentYear,
    PaymentMonth;


/* ------------------------------------------------------------
   4.3 Bills with No Payment
   ------------------------------------------------------------ */

SELECT

    b.bill_id,
    b.account_id,
    b.billing_period_start,
    b.billing_period_end,
    b.total_amount,
    b.due_date

FROM dw.FactBilling AS b

LEFT JOIN dw.FactPayments AS p
    ON b.bill_id = p.bill_id

WHERE p.bill_id IS NULL

ORDER BY b.due_date;


/* ------------------------------------------------------------
   4.4 Bills with Multiple Payments
   ------------------------------------------------------------ */

SELECT

    b.bill_id,
    b.account_id,
    b.total_amount,

    COUNT(p.payment_id) AS PaymentCount,

    CAST(
        SUM(p.payment_amount)
        AS DECIMAL(14,2)
    ) AS TotalPaid

FROM dw.FactBilling AS b

INNER JOIN dw.FactPayments AS p
    ON b.bill_id = p.bill_id

GROUP BY
    b.bill_id,
    b.account_id,
    b.total_amount

HAVING COUNT(p.payment_id) > 1

ORDER BY PaymentCount DESC;


/* ------------------------------------------------------------
   4.5 Payment Status by Bill
   ------------------------------------------------------------ */

WITH PaymentTotals AS
(
    SELECT

        bill_id,

        SUM(payment_amount) AS total_paid

    FROM dw.FactPayments

    GROUP BY bill_id
)

SELECT

    CASE

        WHEN pt.total_paid IS NULL
            THEN 'Unpaid'

        WHEN pt.total_paid < b.total_amount
            THEN 'Partially Paid'

        WHEN pt.total_paid >= b.total_amount
            THEN 'Paid'

        ELSE 'Unknown'

    END AS PaymentStatus,

    COUNT(*) AS BillCount,

    CAST(
        SUM(b.total_amount)
        AS DECIMAL(14,2)
    ) AS TotalBilled

FROM dw.FactBilling AS b

LEFT JOIN PaymentTotals AS pt
    ON b.bill_id = pt.bill_id

GROUP BY

    CASE

        WHEN pt.total_paid IS NULL
            THEN 'Unpaid'

        WHEN pt.total_paid < b.total_amount
            THEN 'Partially Paid'

        WHEN pt.total_paid >= b.total_amount
            THEN 'Paid'

        ELSE 'Unknown'

    END

ORDER BY BillCount DESC;


/* ============================================================
   SECTION 5
   ENERGY USAGE ANALYSIS
   ============================================================ */

PRINT '============================================================';
PRINT 'SECTION 5 - ENERGY USAGE ANALYSIS';
PRINT '============================================================';


/* ------------------------------------------------------------
   5.1 Overall Energy Usage
   ------------------------------------------------------------ */

SELECT

    COUNT(*) AS UsageRecords,

    CAST(
        SUM(kwh_used)
        AS DECIMAL(14,2)
    ) AS TotalKWh,

    CAST(
        AVG(kwh_used)
        AS DECIMAL(14,2)
    ) AS AverageKWh,

    CAST(
        MIN(kwh_used)
        AS DECIMAL(14,2)
    ) AS MinimumKWh,

    CAST(
        MAX(kwh_used)
        AS DECIMAL(14,2)
    ) AS MaximumKWh

FROM dw.FactEnergyUsage;


/* ------------------------------------------------------------
   5.2 Peak vs Non-Peak Usage
   ------------------------------------------------------------ */

SELECT

    CASE
        WHEN peak_usage_flag = 1
            THEN 'Peak'
        ELSE 'Non-Peak'
    END AS UsagePeriod,

    COUNT(*) AS UsageRecords,

    CAST(
        SUM(kwh_used)
        AS DECIMAL(14,2)
    ) AS TotalKWh,

    CAST(
        AVG(kwh_used)
        AS DECIMAL(14,2)
    ) AS AverageKWh

FROM dw.FactEnergyUsage

GROUP BY

    CASE
        WHEN peak_usage_flag = 1
            THEN 'Peak'
        ELSE 'Non-Peak'
    END

ORDER BY TotalKWh DESC;


/* ------------------------------------------------------------
   5.3 Energy Usage by Meter
   ------------------------------------------------------------ */

SELECT

    m.meter_id,
    m.account_id,
    m.meter_type,

    COUNT(u.usage_id) AS UsageRecords,

    CAST(
        SUM(u.kwh_used)
        AS DECIMAL(14,2)
    ) AS TotalKWh,

    CAST(
        AVG(u.kwh_used)
        AS DECIMAL(14,2)
    ) AS AverageKWh

FROM dw.DimMeter AS m

LEFT JOIN dw.FactEnergyUsage AS u
    ON m.meter_id = u.meter_id

GROUP BY

    m.meter_id,
    m.account_id,
    m.meter_type

ORDER BY TotalKWh DESC;


/* ------------------------------------------------------------
   5.4 Highest Energy Consuming Accounts
   ------------------------------------------------------------ */

SELECT TOP 10

    a.account_id,
    a.customer_id,

    COUNT(u.usage_id) AS UsageRecords,

    CAST(
        SUM(u.kwh_used)
        AS DECIMAL(14,2)
    ) AS TotalKWh

FROM dw.DimAccount AS a

INNER JOIN dw.FactEnergyUsage AS u
    ON a.account_id = u.account_id

GROUP BY

    a.account_id,
    a.customer_id

ORDER BY TotalKWh DESC;


/* ------------------------------------------------------------
   5.5 Energy Usage by Date
   ------------------------------------------------------------ */

SELECT

    usage_date,

    COUNT(*) AS UsageRecords,

    CAST(
        SUM(kwh_used)
        AS DECIMAL(14,2)
    ) AS TotalKWh,

    CAST(
        AVG(kwh_used)
        AS DECIMAL(14,2)
    ) AS AverageKWh

FROM dw.FactEnergyUsage

GROUP BY usage_date

ORDER BY usage_date;


/* ------------------------------------------------------------
   5.6 Monthly Energy Usage
   ------------------------------------------------------------ */

SELECT

    YEAR(usage_date) AS UsageYear,
    MONTH(usage_date) AS UsageMonth,

    COUNT(*) AS UsageRecords,

    CAST(
        SUM(kwh_used)
        AS DECIMAL(14,2)
    ) AS TotalKWh,

    CAST(
        AVG(kwh_used)
        AS DECIMAL(14,2)
    ) AS AverageKWh

FROM dw.FactEnergyUsage

GROUP BY

    YEAR(usage_date),
    MONTH(usage_date)

ORDER BY

    UsageYear,
    UsageMonth;


/* ============================================================
   SECTION 6
   RATE PLAN ANALYSIS
   ============================================================ */

PRINT '============================================================';
PRINT 'SECTION 6 - RATE PLAN ANALYSIS';
PRINT '============================================================';


/* ------------------------------------------------------------
   6.1 Rate Plan Overview
   ------------------------------------------------------------ */

SELECT

    rate_plan_id,
    name,
    rate_per_kwh,
    peak_rate,
    effective_date

FROM dw.DimRatePlan

ORDER BY rate_plan_id;


/* ------------------------------------------------------------
   6.2 Accounts by Rate Plan
   ------------------------------------------------------------ */

SELECT

    rp.rate_plan_id,
    rp.name AS RatePlanName,

    COUNT(DISTINCT br.account_id) AS AccountCount

FROM dw.DimRatePlan AS rp

LEFT JOIN dw.BridgeAccountRatePlan AS br
    ON rp.rate_plan_id = br.rate_plan_id

GROUP BY

    rp.rate_plan_id,
    rp.name

ORDER BY AccountCount DESC;


/* ------------------------------------------------------------
   6.3 Rate Plan Customer Distribution
   ------------------------------------------------------------ */

SELECT

    rp.rate_plan_id,
    rp.name AS RatePlanName,

    COUNT(DISTINCT a.customer_id) AS CustomerCount

FROM dw.DimRatePlan AS rp

INNER JOIN dw.BridgeAccountRatePlan AS br
    ON rp.rate_plan_id = br.rate_plan_id

INNER JOIN dw.DimAccount AS a
    ON br.account_id = a.account_id

GROUP BY

    rp.rate_plan_id,
    rp.name

ORDER BY CustomerCount DESC;


/* ============================================================
   SECTION 7
   INFRASTRUCTURE & MAINTENANCE ANALYSIS
   ============================================================ */

PRINT '============================================================';
PRINT 'SECTION 7 - INFRASTRUCTURE & MAINTENANCE ANALYSIS';
PRINT '============================================================';


/* ------------------------------------------------------------
   7.1 Assets by Type
   ------------------------------------------------------------ */

SELECT

    asset_type,

    COUNT(*) AS AssetCount

FROM dw.DimAsset

GROUP BY asset_type

ORDER BY AssetCount DESC;


/* ------------------------------------------------------------
   7.2 Assets by Status
   ------------------------------------------------------------ */

SELECT

    status,

    COUNT(*) AS AssetCount

FROM dw.DimAsset

GROUP BY status

ORDER BY AssetCount DESC;


/* ------------------------------------------------------------
   7.3 Asset Type and Status
   ------------------------------------------------------------ */

SELECT

    asset_type,
    status,

    COUNT(*) AS AssetCount

FROM dw.DimAsset

GROUP BY

    asset_type,
    status

ORDER BY

    asset_type,
    AssetCount DESC;


/* ------------------------------------------------------------
   7.4 Maintenance by Type
   ------------------------------------------------------------ */

SELECT

    maintenance_type,

    COUNT(*) AS MaintenanceCount

FROM dw.FactMaintenance

GROUP BY maintenance_type

ORDER BY MaintenanceCount DESC;


/* ------------------------------------------------------------
   7.5 Maintenance by Asset
   ------------------------------------------------------------ */

SELECT

    a.asset_id,
    a.asset_type,
    a.location,
    a.status,

    COUNT(m.log_id) AS MaintenanceEvents

FROM dw.DimAsset AS a

LEFT JOIN dw.FactMaintenance AS m
    ON a.asset_id = m.asset_id

GROUP BY

    a.asset_id,
    a.asset_type,
    a.location,
    a.status

ORDER BY MaintenanceEvents DESC;


/* ------------------------------------------------------------
   7.6 Assets with Frequent Maintenance
   ------------------------------------------------------------ */

SELECT

    a.asset_id,
    a.asset_type,
    a.location,
    a.status,

    COUNT(m.log_id) AS MaintenanceEvents

FROM dw.DimAsset AS a

INNER JOIN dw.FactMaintenance AS m
    ON a.asset_id = m.asset_id

GROUP BY

    a.asset_id,
    a.asset_type,
    a.location,
    a.status

HAVING COUNT(m.log_id) >= 2

ORDER BY MaintenanceEvents DESC;


/* ------------------------------------------------------------
   7.7 Maintenance by Month
   ------------------------------------------------------------ */

SELECT

    YEAR(maintenance_date) AS MaintenanceYear,
    MONTH(maintenance_date) AS MaintenanceMonth,

    COUNT(*) AS MaintenanceEvents

FROM dw.FactMaintenance

GROUP BY

    YEAR(maintenance_date),
    MONTH(maintenance_date)

ORDER BY

    MaintenanceYear,
    MaintenanceMonth;


/* ============================================================
   SECTION 8
   OUTAGE ANALYSIS
   ============================================================ */

PRINT '============================================================';
PRINT 'SECTION 8 - OUTAGE ANALYSIS';
PRINT '============================================================';


/* ------------------------------------------------------------
   8.1 Outage Summary
   ------------------------------------------------------------ */

SELECT

    COUNT(*) AS TotalOutages,

    SUM(customers_affected) AS TotalCustomersAffected,

    CAST(
        AVG(duration_minutes)
        AS DECIMAL(14,2)
    ) AS AverageDurationMinutes,

    CAST(
        AVG(duration_hours)
        AS DECIMAL(14,2)
    ) AS AverageDurationHours,

    CAST(
        MAX(duration_minutes)
        AS DECIMAL(14,2)
    ) AS LongestOutageMinutes

FROM dw.FactOutage;


/* ------------------------------------------------------------
   8.2 Outages by Cause
   ------------------------------------------------------------ */

SELECT

    cause,

    COUNT(*) AS OutageCount,

    SUM(customers_affected) AS CustomersAffected,

    CAST(
        AVG(duration_minutes)
        AS DECIMAL(14,2)
    ) AS AverageDurationMinutes

FROM dw.FactOutage

GROUP BY cause

ORDER BY OutageCount DESC;


/* ------------------------------------------------------------
   8.3 Outages by Affected Area
   ------------------------------------------------------------ */

SELECT

    affected_area,

    COUNT(*) AS OutageCount,

    SUM(customers_affected) AS CustomersAffected,

    CAST(
        AVG(duration_minutes)
        AS DECIMAL(14,2)
    ) AS AverageDurationMinutes

FROM dw.FactOutage

GROUP BY affected_area

ORDER BY CustomersAffected DESC;


/* ------------------------------------------------------------
   8.4 Longest Outages
   ------------------------------------------------------------ */

SELECT TOP 10

    outage_id,
    start_time,
    end_time,
    affected_area,
    customers_affected,
    cause,
    duration_minutes,
    duration_hours

FROM dw.FactOutage

ORDER BY duration_minutes DESC;


/* ------------------------------------------------------------
   8.5 Outages Affecting the Most Customers
   ------------------------------------------------------------ */

SELECT TOP 10

    outage_id,
    start_time,
    end_time,
    affected_area,
    customers_affected,
    cause,
    duration_minutes,
    duration_hours

FROM dw.FactOutage

ORDER BY customers_affected DESC;


/* ------------------------------------------------------------
   8.6 Monthly Outage Trend
   ------------------------------------------------------------ */

SELECT

    YEAR(start_time) AS OutageYear,
    MONTH(start_time) AS OutageMonth,

    COUNT(*) AS OutageCount,

    SUM(customers_affected) AS CustomersAffected,

    CAST(
        AVG(duration_minutes)
        AS DECIMAL(14,2)
    ) AS AverageDurationMinutes

FROM dw.FactOutage

GROUP BY

    YEAR(start_time),
    MONTH(start_time)

ORDER BY

    OutageYear,
    OutageMonth;


/* ============================================================
   SECTION 9
   CUSTOMER + BILLING ANALYSIS
   ============================================================ */

PRINT '============================================================';
PRINT 'SECTION 9 - CUSTOMER BILLING ANALYSIS';
PRINT '============================================================';


/* ------------------------------------------------------------
   9.1 Customer Billing Summary
   ------------------------------------------------------------ */

SELECT

    c.customer_id,

    CONCAT(
        c.first_name,
        ' ',
        c.last_name
    ) AS CustomerName,

    COUNT(DISTINCT a.account_id) AS AccountCount,

    COUNT(b.bill_id) AS BillCount,

    CAST(
        COALESCE(SUM(b.total_amount), 0)
        AS DECIMAL(14,2)
    ) AS TotalBilled

FROM dw.DimCustomer AS c

LEFT JOIN dw.DimAccount AS a
    ON c.customer_id = a.customer_id

LEFT JOIN dw.FactBilling AS b
    ON a.account_id = b.account_id

GROUP BY

    c.customer_id,
    c.first_name,
    c.last_name

ORDER BY TotalBilled DESC;


/* ------------------------------------------------------------
   9.2 Customer Billing + Payment Summary
   IMPORTANT:
   Billing and payment totals are calculated separately
   to avoid many-to-many duplication.
   ------------------------------------------------------------ */

WITH CustomerBilling AS
(
    SELECT

        a.customer_id,

        SUM(b.total_amount) AS total_billed

    FROM dw.DimAccount AS a

    INNER JOIN dw.FactBilling AS b
        ON a.account_id = b.account_id

    GROUP BY a.customer_id
),

CustomerPayments AS
(
    SELECT

        a.customer_id,

        SUM(p.payment_amount) AS total_paid

    FROM dw.DimAccount AS a

    INNER JOIN dw.FactBilling AS b
        ON a.account_id = b.account_id

    INNER JOIN dw.FactPayments AS p
        ON b.bill_id = p.bill_id

    GROUP BY a.customer_id
)

SELECT

    c.customer_id,

    CONCAT(
        c.first_name,
        ' ',
        c.last_name
    ) AS CustomerName,

    CAST(
        COALESCE(cb.total_billed, 0)
        AS DECIMAL(14,2)
    ) AS TotalBilled,

    CAST(
        COALESCE(cp.total_paid, 0)
        AS DECIMAL(14,2)
    ) AS TotalPaid,

    CAST(
        COALESCE(cb.total_billed, 0)
        - COALESCE(cp.total_paid, 0)
        AS DECIMAL(14,2)
    ) AS OutstandingBalance

FROM dw.DimCustomer AS c

LEFT JOIN CustomerBilling AS cb
    ON c.customer_id = cb.customer_id

LEFT JOIN CustomerPayments AS cp
    ON c.customer_id = cp.customer_id

ORDER BY OutstandingBalance DESC;


/* ============================================================
   SECTION 10
   ACCOUNT ENERGY + BILLING ANALYSIS
   ============================================================ */

PRINT '============================================================';
PRINT 'SECTION 10 - ACCOUNT ENERGY & BILLING ANALYSIS';
PRINT '============================================================';


/* ------------------------------------------------------------
   10.1 Account Usage + Billing
   ------------------------------------------------------------ */

WITH UsageTotals AS
(
    SELECT

        account_id,

        SUM(kwh_used) AS total_kwh

    FROM dw.FactEnergyUsage

    GROUP BY account_id
),

BillingTotals AS
(
    SELECT

        account_id,

        SUM(total_amount) AS total_billed

    FROM dw.FactBilling

    GROUP BY account_id
)

SELECT

    a.account_id,
    a.customer_id,
    a.account_status,

    CAST(
        COALESCE(u.total_kwh, 0)
        AS DECIMAL(14,2)
    ) AS TotalKWh,

    CAST(
        COALESCE(b.total_billed, 0)
        AS DECIMAL(14,2)
    ) AS TotalBilled

FROM dw.DimAccount AS a

LEFT JOIN UsageTotals AS u
    ON a.account_id = u.account_id

LEFT JOIN BillingTotals AS b
    ON a.account_id = b.account_id

ORDER BY TotalKWh DESC;


/* ------------------------------------------------------------
   10.2 Highest Usage Accounts with Billing
   ------------------------------------------------------------ */

WITH UsageTotals AS
(
    SELECT

        account_id,

        SUM(kwh_used) AS total_kwh

    FROM dw.FactEnergyUsage

    GROUP BY account_id
),

BillingTotals AS
(
    SELECT

        account_id,

        SUM(total_amount) AS total_billed

    FROM dw.FactBilling

    GROUP BY account_id
)

SELECT TOP 10

    a.account_id,
    a.customer_id,

    CAST(
        COALESCE(u.total_kwh, 0)
        AS DECIMAL(14,2)
    ) AS TotalKWh,

    CAST(
        COALESCE(b.total_billed, 0)
        AS DECIMAL(14,2)
    ) AS TotalBilled

FROM dw.DimAccount AS a

LEFT JOIN UsageTotals AS u
    ON a.account_id = u.account_id

LEFT JOIN BillingTotals AS b
    ON a.account_id = b.account_id

ORDER BY TotalKWh DESC;


/* ============================================================
   SECTION 11
   DATA QUALITY & WAREHOUSE VALIDATION
   ============================================================ */

PRINT '============================================================';
PRINT 'SECTION 11 - DATA QUALITY & VALIDATION';
PRINT '============================================================';


/* ------------------------------------------------------------
   11.1 Duplicate Customer IDs
   ------------------------------------------------------------ */

SELECT

    customer_id,

    COUNT(*) AS DuplicateCount

FROM dw.DimCustomer

GROUP BY customer_id

HAVING COUNT(*) > 1;


/* ------------------------------------------------------------
   11.2 Duplicate Account IDs
   ------------------------------------------------------------ */

SELECT

    account_id,

    COUNT(*) AS DuplicateCount

FROM dw.DimAccount

GROUP BY account_id

HAVING COUNT(*) > 1;


/* ------------------------------------------------------------
   11.3 Invalid Billing Periods
   ------------------------------------------------------------ */

SELECT

    bill_id,
    account_id,
    billing_period_start,
    billing_period_end

FROM dw.FactBilling

WHERE billing_period_end < billing_period_start;


/* ------------------------------------------------------------
   11.4 Negative Billing Amounts
   ------------------------------------------------------------ */

SELECT

    bill_id,
    account_id,
    total_amount

FROM dw.FactBilling

WHERE total_amount < 0;


/* ------------------------------------------------------------
   11.5 Negative Payments
   ------------------------------------------------------------ */

SELECT

    payment_id,
    bill_id,
    payment_amount

FROM dw.FactPayments

WHERE payment_amount < 0;


/* ------------------------------------------------------------
   11.6 Invalid Outage Durations
   ------------------------------------------------------------ */

SELECT

    outage_id,
    start_time,
    end_time,
    duration_minutes,
    duration_hours

FROM dw.FactOutage

WHERE end_time < start_time;


/* ------------------------------------------------------------
   11.7 Negative Energy Usage
   ------------------------------------------------------------ */

SELECT

    usage_id,
    meter_id,
    account_id,
    usage_date,
    kwh_used

FROM dw.FactEnergyUsage

WHERE kwh_used < 0;


/* ------------------------------------------------------------
   11.8 Orphan Payments
   ------------------------------------------------------------ */

SELECT

    p.payment_id,
    p.bill_id,
    p.payment_amount

FROM dw.FactPayments AS p

LEFT JOIN dw.FactBilling AS b
    ON p.bill_id = b.bill_id

WHERE b.bill_id IS NULL;


/* ------------------------------------------------------------
   11.9 Orphan Energy Usage Records
   ------------------------------------------------------------ */

SELECT

    u.usage_id,
    u.meter_id,
    u.account_id

FROM dw.FactEnergyUsage AS u

LEFT JOIN dw.DimMeter AS m
    ON u.meter_id = m.meter_id

WHERE m.meter_id IS NULL;


/* ------------------------------------------------------------
   11.10 Orphan Maintenance Records
   ------------------------------------------------------------ */

SELECT

    m.log_id,
    m.asset_id

FROM dw.FactMaintenance AS m

LEFT JOIN dw.DimAsset AS a
    ON m.asset_id = a.asset_id

WHERE a.asset_id IS NULL;


/* ============================================================
   SECTION 12
   FINAL DATA WAREHOUSE ROW COUNT VALIDATION
   ============================================================ */

PRINT '============================================================';
PRINT 'SECTION 12 - FINAL ROW COUNT VALIDATION';
PRINT '============================================================';


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


/* ============================================================
   END OF STEP 5
   ============================================================ */

PRINT '============================================================';
PRINT 'STEP 5 ANALYSIS COMPLETED.';
PRINT '============================================================';