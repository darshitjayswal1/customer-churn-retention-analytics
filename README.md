# Customer Churn & Retention Analytics — Power BI + SQL

**Author:** Darshit Jayswal · [LinkedIn](https://www.linkedin.com/in/darshitjayswal) · darshitjayswal1@gmail.com
**Tools:** Power BI (DAX, Power Query) · SQL (window functions, CTEs) · Python (data prep)

> An end-to-end analysis of customer churn and acquisition for *StreamNova*, a
> (fictional) Indian subscription business with **7,043 customers**. The project
> identifies **₹5.1 lakh / month of revenue lost to churn**, pinpoints exactly
> *who* is leaving and *why*, and recommends where to redirect retention and
> acquisition spend.

---

## 1. Business problem

StreamNova's leadership saw revenue growth flattening despite steady ad spend.
The questions for analytics:

1. Where in the acquisition funnel are we losing people?
2. Which customers churn, and what are the underlying drivers?
3. Which acquisition channels actually produce *loyal* customers — not just sign-ups?
4. Where should a limited retention budget be spent for maximum revenue saved?

## 2. Data

A single customer-level table (`data/customers.csv`, 7,043 rows, 22 fields)
covering demographics, acquisition channel, a 3-stage funnel
(*Signup → Verified → Activated*), contract & billing, usage, tenure and churn.
The dataset is synthetic but modelled on realistic subscription dynamics, and
deliberately includes data-quality issues (missing charges, inconsistent casing,
whitespace, shorthand values) so the cleaning process is part of the story.

> **Why this dataset?** It mirrors the acquisition-funnel and churn work I did in
> production at GJ Tech Solutions — so the analysis reflects real business
> questions, not a textbook exercise.

## 3. Approach

| Step | What I did | File |
|------|------------|------|
| 1. Schema & load | Defined the table and import process | `sql/01_create_schema.sql` |
| 2. Data quality | Audited + fixed nulls, casing, whitespace, shorthand; validated funnel logic | `sql/02_data_cleaning.sql` |
| 3. Analysis | 8 business questions: KPIs, funnel, churn drivers, channel quality, cohort retention, RFM | `sql/03_analysis_queries.sql` |
| 4. Modelling & DAX | KPI measures, churn/retention, ARPU, RFM helpers | `powerbi/DAX_measures.md` |
| 5. Dashboard | 3-page Power BI report (Overview / Churn / Segments) | `powerbi/dashboard_spec.md` |

## 4. Key findings

**The funnel leaks before activation.** Of 7,043 sign-ups, 6,195 verify (88%) but
only **4,658 activate (66%)** — a third of acquired users never become customers.

**Contract type is the #1 churn driver.** Month-to-month customers churn at
**29.5%**, vs 10.8% (Annual) and **5.9% (Two-Year)**. Locking customers into longer
terms is the single highest-leverage retention move.

**Churn is an early-life problem.** **45.8%** of churn happens in the first 3
months; by 12+ months it falls to **4.8%**. The first 90 days are where retention
is won or lost.

**Paid Social is the worst channel on every axis.** It has the lowest activation
(**48%**) *and* the highest churn (**28%**) — it buys expensive, low-quality users.
**Referral** is the opposite: **84% activation, 15% churn** — the best customers,
and likely under-funded.

**Payment method is a quiet churn signal.** Wallet (non-autopay) customers churn at
**31.6%** vs **18.7%** on UPI — missed auto-payments are a leading indicator.

**Money at stake:** churn is removing **₹5.1 lakh of recurring revenue every month**
against an active base of **₹19.0 lakh MRR**.

## 5. Recommendations

1. **Shift acquisition budget from Paid Social → Referral / Organic.** Same spend,
   higher-quality customers; could lift activation and cut downstream churn.
2. **Attack first-90-day churn** with onboarding nudges and an activation milestone —
   this is where 46% of churn occurs.
3. **Incentivise annual / two-year contracts** (discount or perk). Moving even 10%
   of monthly customers to annual measurably reduces blended churn.
4. **Push Wallet users to UPI auto-pay.** Removing payment friction targets the
   highest-churn billing segment.
5. **Protect "Champions" and "Loyal/High-Value" RFM segments** — they carry the
   highest revenue and lowest recency; a light-touch loyalty programme defends MRR.

## 6. How to reproduce

```bash
# 1. (optional) regenerate the data
python generate_data.py

# 2. run the SQL in SQLite / Postgres
#    load 01 -> 02 -> 03 (see comments in each file)

# 3. open Power BI Desktop -> Get Data -> Text/CSV -> data/customers.csv
#    add the measures from powerbi/DAX_measures.md
#    build the 3 pages from powerbi/dashboard_spec.md
```

## 7. Repository structure

```
churn-retention-analytics/
├── README.md                  <- this case study
├── generate_data.py           <- synthetic data generator
├── data/
│   └── customers.csv          <- 7,043-row dataset
├── sql/
│   ├── 01_create_schema.sql
│   ├── 02_data_cleaning.sql
│   └── 03_analysis_queries.sql
├── powerbi/
│   ├── DAX_measures.md
│   └── dashboard_spec.md
└── images/                    <- add dashboard screenshots here
```

---

*Built to demonstrate end-to-end analyst work: framing a business question,
cleaning messy data, defining metrics defensibly, and turning the result into a
clear, money-relevant recommendation.*
