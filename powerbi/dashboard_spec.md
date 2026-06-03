# Power BI Dashboard — Build Specification

A **3-page** report. Keep it clean: one clear question per page, KPI cards on top,
a slicer panel on the left. Colour palette: a neutral grey/navy base with a single
accent (e.g. teal `#2BB6A6`) and red `#E5534B` reserved **only** for churn/at-risk.

Recommended canvas: 16:9, 1280×720.

---

## Global elements (on every page)

- **Slicer panel (left, ~200px):** `acquisition_channel`, `contract_type`, `plan`, `city`.
- **Title bar (top):** report title + a date card (`"Data as of 31 May 2026"`).
- **Page navigator** (buttons or the built-in navigator) for Overview / Churn / Customers.

---

## Page 1 — Executive Overview  *(question: how healthy is the business?)*

**KPI cards (row across top):**

| Card | Measure |
|------|---------|
| Total Signups | `[Total Signups]` → 7,043 |
| Activation Rate | `[Activation Rate]` → 66.1% |
| Churn Rate | `[Churn Rate]` → 20.4% (red) |
| Active MRR | `[Active MRR]` → ₹19.1L |
| Monthly Revenue Lost | `[Monthly Revenue Lost]` → ₹5.1L (red) |

**Visuals:**

1. **Acquisition funnel** (Funnel visual) — Signup → Verified → Activated. *Source: Q2.*
2. **Activation & churn by channel** (clustered bar, dual) — ranks channel *quality*. *Source: Q4.*
3. **Active MRR trend** (line by `Cohort Month`) — revenue momentum.
4. **Narrative card** using `[Churn KPI Title]` for a dynamic headline.

---

## Page 2 — Churn Deep-Dive  *(question: who churns and why?)*

**Visuals:**

1. **Churn rate by contract type** (bar, sorted desc) — Monthly 29.5% vs Two-Year 5.9%.
   *This is the headline insight — make it the biggest visual.* *Source: Q3.*
2. **Churn rate by tenure band** (column) — 0–3 mo: 45.8% → 12+ mo: 4.8%. *Source: Q8.*
3. **Churn by payment method** (bar) — Wallet/non-autopay highest.
4. **Churn by plan & add-on count** (matrix with conditional-format heat) —
   shows add-ons reduce churn.
5. **Decomposition tree** (AI visual) on `is_churned` — let recruiters watch you
   "drill" into the drivers live. Explain by contract → channel → payment.

---

## Page 3 — Customer Segments (RFM)  *(question: where do we focus retention spend?)*

**Visuals:**

1. **RFM segment table** — segment, customers, avg recency, avg logins, avg revenue.
   *Source: Q6.* Conditional-format the revenue column.
2. **RFM scatter** — X = `Recency Days`, Y = `Avg Monthly Logins`, size = `Lifetime Revenue`,
   colour = segment. Champions vs At-Risk should visually separate.
3. **Revenue at risk callout** — `[Revenue at Risk]` card + a short text box with the
   recommendation (see README "Recommendations").
4. **Cohort retention heatmap** — `Cohort Month` (rows) × tenure (cols), colour = retention %.
   Use a Matrix with background colour scale. *Source: Q5.*

---

## Interaction & polish checklist (the stuff that signals "senior")

- [ ] Edit interactions so the channel slicer cross-filters every visual.
- [ ] Add tooltips that show ₹ revenue, not just counts.
- [ ] Add a **"Reset filters"** bookmark button.
- [ ] One **drill-through** page: right-click a contract type → see those customers.
- [ ] Consistent number formatting (₹ lakhs, 1 decimal on %).
- [ ] A short **insight text box** on each page — recruiters read these first.
- [ ] Publish to Power BI Service and grab the **"Publish to web"** embed link for the portfolio.

---

## Suggested data model

Single flat `customers` table is fine for this size. To show modelling skill,
optionally split into a star schema:

- **Fact:** `customers` (one row per customer, the measures live here)
- **Dim:** `DimDate` (mark as date table, built from `signup_date`)
- **Dim:** `DimChannel`, `DimPlan` (optional) — relate on the text keys.

Mention in your README that you *chose* a flat model because the grain is one row
per customer and a star schema would add joins without analytical benefit at this
scale — that reasoning is exactly what interviewers probe for.
