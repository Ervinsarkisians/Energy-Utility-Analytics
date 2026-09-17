USE Portfolio;
GO

CREATE OR ALTER PROCEDURE dw.usp_LoadEnergyUtilityDW
AS
BEGIN
    SET NOCOUNT ON;

    BEGIN TRY

        PRINT '=============================================';
        PRINT 'STARTING ENERGY UTILITY DATA WAREHOUSE LOAD';
        PRINT '=============================================';

        BEGIN TRANSACTION;

        ---------------------------------------------------------
        -- STEP 1: CLEAR EXISTING DATA
        -- Full Refresh ETL
        ---------------------------------------------------------

        PRINT 'Clearing existing DW data...';

        DELETE FROM dw.FactPayments;
        DELETE FROM dw.FactBilling;
        DELETE FROM dw.FactEnergyUsage;
        DELETE FROM dw.FactMaintenance;
        DELETE FROM dw.FactOutage;
        DELETE FROM dw.BridgeAccountRatePlan;

        DELETE FROM dw.DimCustomer;
        DELETE FROM dw.DimAccount;
        DELETE FROM dw.DimMeter;
        DELETE FROM dw.DimRatePlan;
        DELETE FROM dw.DimAsset;

        ---------------------------------------------------------
        -- STEP 2: LOAD DIM CUSTOMER
        ---------------------------------------------------------

        PRINT 'Loading DimCustomer...';

        INSERT INTO dw.DimCustomer
        (
            customer_id,
            first_name,
            last_name,
            email,
            phone_number,
            created_at
        )
        SELECT
            customer_id,
            first_name,
            last_name,
            email,
            phone_number,
            created_at
        FROM etl.Customers;

        ---------------------------------------------------------
        -- STEP 3: LOAD DIM ACCOUNT
        ---------------------------------------------------------

        PRINT 'Loading DimAccount...';

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

        ---------------------------------------------------------
        -- STEP 4: LOAD DIM METER
        ---------------------------------------------------------

        PRINT 'Loading DimMeter...';

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

        ---------------------------------------------------------
        -- STEP 5: LOAD DIM RATE PLAN
        ---------------------------------------------------------

        PRINT 'Loading DimRatePlan...';

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

        ---------------------------------------------------------
        -- STEP 6: LOAD DIM ASSET
        ---------------------------------------------------------

        PRINT 'Loading DimAsset...';

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

        ---------------------------------------------------------
        -- STEP 7: LOAD FACT BILLING
        ---------------------------------------------------------

        PRINT 'Loading FactBilling...';

        INSERT INTO dw.FactBilling
        (
            bill_id,
            account_id,
            billing_period_start,
            billing_period_end,
            total_amount,
            due_date
        )
        SELECT
            bill_id,
            account_id,
            billing_period_start,
            billing_period_end,
            total_amount,
            due_date
        FROM etl.Bills;

        ---------------------------------------------------------
        -- STEP 8: LOAD FACT PAYMENTS
        ---------------------------------------------------------

        PRINT 'Loading FactPayments...';

        INSERT INTO dw.FactPayments
        (
            payment_id,
            bill_id,
            payment_date,
            payment_amount,
            payment_method
        )
        SELECT
            payment_id,
            bill_id,
            payment_date,
            payment_amount,
            payment_method
        FROM etl.Payments;

        ---------------------------------------------------------
        -- STEP 9: LOAD FACT ENERGY USAGE
        --
        -- IMPORTANT:
        -- peak_usage_flag is pulled directly from
        -- dbo.energy_usage because etl.EnergyUsage
        -- does not contain this column.
        ---------------------------------------------------------

        PRINT 'Loading FactEnergyUsage...';

        INSERT INTO dw.FactEnergyUsage
        (
            usage_id,
            meter_id,
            account_id,
            usage_date,
            kwh_used,
            peak_usage_flag
        )
        SELECT
            u.usage_id,
            u.meter_id,
            m.account_id,
            u.usage_date,
            CAST(u.kwh_used AS DECIMAL(12,2)),
            u.peak_usage_flag
        FROM dbo.energy_usage AS u
        INNER JOIN dbo.meters AS m
            ON u.meter_id = m.meter_id;

        ---------------------------------------------------------
        -- STEP 10: LOAD FACT MAINTENANCE
        ---------------------------------------------------------

        PRINT 'Loading FactMaintenance...';

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

        ---------------------------------------------------------
        -- STEP 11: LOAD FACT OUTAGE
        --
        -- IMPORTANT:
        -- duration_minutes and duration_hours are calculated
        -- directly from dbo.outages.
        ---------------------------------------------------------

        PRINT 'Loading FactOutage...';

        INSERT INTO dw.FactOutage
        (
            outage_id,
            start_time,
            end_time,
            affected_area,
            customers_affected,
            cause,
            duration_minutes,
            duration_hours
        )
        SELECT
            o.outage_id,
            o.start_time,
            o.end_time,
            o.affected_area,
            o.customers_affected,
            o.cause,

            CASE
                WHEN o.end_time >= o.start_time
                THEN DATEDIFF(MINUTE, o.start_time, o.end_time)
                ELSE NULL
            END AS duration_minutes,

            CASE
                WHEN o.end_time >= o.start_time
                THEN CAST(
                    DATEDIFF(MINUTE, o.start_time, o.end_time)
                    / 60.0
                    AS DECIMAL(10,2)
                )
                ELSE NULL
            END AS duration_hours

        FROM dbo.outages AS o;

        ---------------------------------------------------------
        -- STEP 12: LOAD BRIDGE ACCOUNT RATE PLAN
        ---------------------------------------------------------

        PRINT 'Loading BridgeAccountRatePlan...';

        INSERT INTO dw.BridgeAccountRatePlan
        (
            account_id,
            rate_plan_id,
            start_date,
            end_date
        )
        SELECT
            account_id,
            rate_plan_id,
            start_date,
            end_date
        FROM etl.AccountRatePlans;

        ---------------------------------------------------------
        -- STEP 13: VALIDATION
        ---------------------------------------------------------

        PRINT '=============================================';
        PRINT 'VALIDATING DATA WAREHOUSE ROW COUNTS';
        PRINT '=============================================';

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

        ---------------------------------------------------------
        -- STEP 14: COMMIT
        ---------------------------------------------------------

        COMMIT TRANSACTION;

        PRINT '=============================================';
        PRINT 'ETL / DATA WAREHOUSE LOAD COMPLETED SUCCESSFULLY.';
        PRINT '=============================================';

    END TRY

    BEGIN CATCH

        ---------------------------------------------------------
        -- ROLLBACK IF ANY ERROR OCCURS
        ---------------------------------------------------------

        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;

        PRINT '=============================================';
        PRINT 'ETL / DATA WAREHOUSE LOAD FAILED.';
        PRINT '=============================================';

        PRINT 'Error Number: ' + CAST(ERROR_NUMBER() AS VARCHAR(10));
        PRINT 'Error Message: ' + ERROR_MESSAGE();
        PRINT 'Error Line: ' + CAST(ERROR_LINE() AS VARCHAR(10));

        THROW;

    END CATCH;

END;
GO