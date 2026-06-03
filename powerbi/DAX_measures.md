# Power BI — DAX Measures

Create one **Measures** table (Home → Enter Data → name it `_Measures`, delete the
blank column) and add every measure below to it. This keeps measures organised and
separate from the `customers` table.

> Tip: numbers in **₹** use a custom format string. For a measure, set
> Measure tools → Format → `"₹"#,0` (or `"₹"#,0.0,,"M"` to show millions).

---

## 1. Base counts

```DAX
Total Signups = COUNTROWS ( customers )
```

```DAX
Verified = CALCULATE ( [Total Signups], customers[is_verified] = 1 )
```

```DAX
Activated = CALCULATE ( [Total Signups], customers[is_activated] = 1 )
```

```DAX
Churned Customers =
CALCULATE ( [Total Signups], customers[is_churned] = 1 )
```

```DAX
Active Customers =
CALCULATE (
    [Total Signups],
    customers[is_activated] = 1,
    customers[is_churned] = 0
)
```

## 2. Funnel conversion rates

```DAX
Verification Rate = DIVIDE ( [Verified], [Total Signups] )
```

```DAX
Activation Rate = DIVIDE ( [Activated], [Total Signups] )
```

## 3. Churn & retention (headline metrics)

```DAX
Churn Rate =
DIVIDE ( [Churned Customers], [Activated] )
-- format as Percentage. Churn is measured only among activated customers.
```

```DAX
Retention Rate = 1 - [Churn Rate]
```

## 4. Revenue measures

```DAX
Active MRR =                                    -- Monthly Recurring Revenue
CALCULATE (
    SUM ( customers[monthly_charge] ),
    customers[is_activated] = 1,
    customers[is_churned] = 0
)
```

```DAX
Monthly Revenue Lost =
CALCULATE (
    SUM ( customers[monthly_charge] ),
    customers[is_churned] = 1
)
```

```DAX
Avg Revenue per User (ARPU) =
DIVIDE ( [Active MRR], [Active Customers] )
```

```DAX
Lifetime Revenue = SUM ( customers[total_revenue] )
```

## 5. RFM helper measures (Recency / Frequency / Monetary)

```DAX
Avg Recency (days) =
AVERAGEX (
    FILTER ( customers, customers[is_churned] = 0 ),
    DATEDIFF ( customers[last_active_date], DATE ( 2026, 5, 31 ), DAY )
)
```

```DAX
Avg Monthly Logins =
CALCULATE ( AVERAGE ( customers[monthly_logins] ), customers[is_churned] = 0 )
```

## 6. Dynamic title / narrative measures (nice-to-have, shows polish)

```DAX
Churn KPI Title =
"Churn Rate — " & FORMAT ( [Churn Rate], "0.0%" ) &
" across " & FORMAT ( [Activated], "#,0" ) & " activated customers"
```

```DAX
Revenue at Risk =
-- monthly revenue tied to still-active customers on the highest-churn profile
CALCULATE (
    SUM ( customers[monthly_charge] ),
    customers[is_activated] = 1,
    customers[is_churned] = 0,
    customers[contract_type] = "Monthly"
)
```

---

## Calculated columns (create on the `customers` table)

```DAX
Tenure Band =
SWITCH (
    TRUE (),
    customers[tenure_months] <= 3,  "0-3 months",
    customers[tenure_months] <= 6,  "4-6 months",
    customers[tenure_months] <= 12, "7-12 months",
    "12+ months"
)
```

```DAX
Cohort Month = FORMAT ( customers[signup_date], "YYYY-MM" )
```

```DAX
Recency Days =
DATEDIFF ( customers[last_active_date], DATE ( 2026, 5, 31 ), DAY )
```

> For **Tenure Band** sorting: create a hidden numeric `Tenure Band Sort`
> (1–4) column and use *Sort by Column* so the axis orders correctly.
