/*
============================================================
ENERGY UTILITY ANALYTICS
03_Data_Transformation.sql

Purpose:
    Create reporting-ready views from cleaned ETL tables.
============================================================
*/

USE [Portfolio];
GO


/*============================================================
1. CUSTOMER ACCOUNT VIEW
============================================================*/

CREATE OR ALTER VIEW etl.vw_CustomerAccounts
AS

SELECT
    c.customer_id,
    c.first_name,
    c.last_name,

    CONCAT(c.first_name, ' ', c.last_name) AS customer_name,

    c.email,
    c.phone_number,
    c.created_at,

    a.account_id,
    a.service_address,
    a.billing_address,
    a.account_status

FROM etl.Customers c

LEFT JOIN etl.Accounts a
    ON c.customer_id = a.customer_id;
GO


/*============================================================
2. ENERGY USAGE VIEW
============================================================*/

CREATE OR ALTER VIEW etl.vw_EnergyUsage
AS

SELECT
    eu.usage_id,
    eu.usage_date,

    eu.meter_id,
    m.meter_type,

    m.account_id,

    a.customer_id,

    eu.kwh_used,
    eu.usage_period,

    CASE
        WHEN eu.usage_period = 'Peak'
            THEN 1
        ELSE 0
    END AS is_peak_usage

FROM etl.EnergyUsage eu

LEFT JOIN etl.Meters m
    ON eu.meter_id = m.meter_id

LEFT JOIN etl.Accounts a
    ON m.account_id = a.account_id;
GO


/*============================================================
3. BILLING VIEW
============================================================*/

CREATE OR ALTER VIEW etl.vw_Billing
AS

SELECT
    b.bill_id,
    b.account_id,

    a.customer_id,

    b.billing_period_start,
    b.billing_period_end,
    b.total_amount,
    b.due_date,

    CASE
        WHEN b.due_date < CAST(GETDATE() AS DATE)
             AND b.total_amount > 0
            THEN 1
        ELSE 0
    END AS potentially_overdue,

    b.invalid_billing_period

FROM etl.Bills b

LEFT JOIN etl.Accounts a
    ON b.account_id = a.account_id;
GO


/*============================================================
4. BILLING + PAYMENT VIEW
============================================================*/

CREATE OR ALTER VIEW etl.vw_BillingPayments
AS

SELECT
    b.bill_id,
    b.account_id,
    b.customer_id,

    b.billing_period_start,
    b.billing_period_end,
    b.total_amount,
    b.due_date,

    p.payment_id,
    p.payment_date,
    p.payment_amount,
    p.payment_method,

    CASE
        WHEN p.payment_amount IS NULL
            THEN b.total_amount
        ELSE b.total_amount - p.payment_amount
    END AS outstanding_amount

FROM etl.vw_Billing b

LEFT JOIN etl.Payments p
    ON b.bill_id = p.bill_id;
GO


/*============================================================
5. RATE PLAN VIEW
============================================================*/

CREATE OR ALTER VIEW etl.vw_AccountRatePlans
AS

SELECT
    arp.account_id,
    arp.rate_plan_id,

    rp.name AS rate_plan_name,
    rp.rate_per_kwh,
    rp.peak_rate,

    arp.start_date,
    arp.end_date,

    arp.invalid_date_range

FROM etl.AccountRatePlans arp

LEFT JOIN etl.RatePlans rp
    ON arp.rate_plan_id = rp.rate_plan_id;
GO


/*============================================================
6. ASSET + MAINTENANCE VIEW
============================================================*/

CREATE OR ALTER VIEW etl.vw_AssetMaintenance
AS

SELECT
    ia.asset_id,
    ia.asset_type,
    ia.location,
    ia.install_date,
    ia.status,

    ml.log_id,
    ml.maintenance_date,
    ml.maintenance_type,

    CASE
        WHEN ml.log_id IS NOT NULL
            THEN 1
        ELSE 0
    END AS has_maintenance_record

FROM etl.InfrastructureAssets ia

LEFT JOIN etl.MaintenanceLogs ml
    ON ia.asset_id = ml.asset_id;
GO


/*============================================================
7. OUTAGE ANALYTICS VIEW
============================================================*/

CREATE OR ALTER VIEW etl.vw_Outages
AS

SELECT
    outage_id,
    start_time,
    end_time,
    affected_area,
    customers_affected,
    cause,

    CASE
        WHEN end_time >= start_time
            THEN DATEDIFF(MINUTE, start_time, end_time)
        ELSE NULL
    END AS outage_duration_minutes,

    CASE
        WHEN end_time >= start_time
            THEN DATEDIFF(MINUTE, start_time, end_time) / 60.0
        ELSE NULL
    END AS outage_duration_hours,

    invalid_duration

FROM etl.Outages;
GO


/*============================================================
8. BASIC TRANSFORMATION TESTS
============================================================*/

SELECT TOP 20 *
FROM etl.vw_CustomerAccounts;


SELECT TOP 20 *
FROM etl.vw_EnergyUsage;


SELECT TOP 20 *
FROM etl.vw_BillingPayments;


SELECT TOP 20 *
FROM etl.vw_AccountRatePlans;


SELECT TOP 20 *
FROM etl.vw_AssetMaintenance;


SELECT TOP 20 *
FROM etl.vw_Outages;