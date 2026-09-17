# Energy Utility Analytics - DAX Measures

This document contains the DAX measures used in the Power BI
Energy Utility Analytics dashboard.

The measures are organized by business function and support
customer analysis, billing and payments, energy usage,
infrastructure and maintenance, and outage analysis.

---

## Customer & Account KPIs

### Total Customers

```DAX
Total Customers = COUNTROWS(customers)
```

### Total Accounts

```DAX
Total Accounts = COUNTROWS(accounts)
```

## Billing & Payment KPIs

### Total Billed

```DAX
Total Billed = SUM(bills[total_amount])
```

### Average Bill Amount

```DAX
Average Bill Amount = AVERAGE(bills[total_amount])
```

### Outstanding Balance

```DAX
Outstanding Balance = [Total Billed] - [Total Payments]
```

### Overdue Bills

```DAX
Overdue Bills =
COUNTROWS(
    FILTER(
        bills,
        bills[due_date] < TODAY() &&
        NOT bills[bill_id] IN VALUES(payments[bill_id])
    )
)
```

### Total Payments

```DAX
Total Payments = SUM(payments[payment_amount])
```

### Payment Coverage %

```DAX
Payment Coverage % =
DIVIDE([Total Payments], [Total Billed], 0)
```

## Energy Usage KPIs

### Total kWh Used

```DAX
Total kWh Used = SUM(energy_usage[kwh_used])
```

### Average Daily kWh

```DAX
Average Daily kWh = AVERAGE(energy_usage[kwh_used])
```

### Peak Usage Count

```DAX
Peak Usage Count =
COUNTROWS(
    FILTER(
        energy_usage,
        energy_usage[peak_usage_flag] = TRUE()
    )
)
```

### Peak Usage %

```DAX
Peak Usage % =
DIVIDE([Peak Usage Count], COUNTROWS(energy_usage), 0)
```

## Infrastructure & Maintenance KPIs

### Total Meters

```DAX
Total Meters = COUNTROWS(meters)
```

### Total Assets

```DAX
Total Assets = COUNTROWS(infrastructure_assets)
```

### Maintenance Events

```DAX
Maintenance Events = COUNTROWS(maintenance_logs)
```

## Outage KPIs

### Total Outages

```DAX
Total Outages = COUNTROWS(outages)
```

### Total Customers Affected

```DAX
Total Customers Affected = SUM(outages[customers_affected])
```

### Average Outage Duration (Hours)

```DAX
Average Outage Duration (Hours) =
AVERAGEX(
    outages,
    DATEDIFF(outages[start_time], outages[end_time], HOUR)
)
```