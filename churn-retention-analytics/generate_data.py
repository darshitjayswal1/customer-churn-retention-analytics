"""
Synthetic dataset generator for the Customer Churn & Retention Analytics project.

Business context: "StreamNova" - a fictional subscription streaming + connectivity
company in India. Generates a realistic customer base with an acquisition funnel,
tenure, billing, usage and churn behaviour. Relationships are intentionally built in
so the downstream SQL / Power BI analysis surfaces a real, defensible story.

Output: data/customers.csv  (one row per customer)
"""

import numpy as np
import pandas as pd

rng = np.random.default_rng(42)
N = 7043  # mirrors the well-known telco churn dataset size

# -----------------------------------------------------------------------------
# Reference data
# -----------------------------------------------------------------------------
channels = ["Organic Search", "Paid Social", "Paid Search", "Referral", "Affiliate", "Email"]
channel_w = [0.27, 0.22, 0.18, 0.13, 0.12, 0.08]

cities = ["Ahmedabad", "Mumbai", "Delhi", "Bengaluru", "Pune", "Hyderabad", "Chennai", "Kolkata", "Jaipur", "Surat"]
city_w = [0.13, 0.16, 0.15, 0.14, 0.10, 0.09, 0.08, 0.06, 0.05, 0.04]

plans = ["Basic", "Standard", "Premium"]
plan_w = [0.45, 0.35, 0.20]
plan_price = {"Basic": 199, "Standard": 499, "Premium": 799}

contracts = ["Monthly", "Annual", "Two-Year"]
contract_w = [0.55, 0.30, 0.15]

pay_methods = ["UPI", "Credit Card", "Debit Card", "Net Banking", "Wallet"]
pay_w = [0.40, 0.20, 0.18, 0.12, 0.10]

genders = ["Male", "Female"]

# -----------------------------------------------------------------------------
# Core attributes
# -----------------------------------------------------------------------------
customer_id = [f"CUST-{100000 + i}" for i in range(N)]
channel = rng.choice(channels, N, p=channel_w)
city = rng.choice(cities, N, p=city_w)
gender = rng.choice(genders, N, p=[0.54, 0.46])
age = rng.integers(18, 70, N)
senior = (age >= 60).astype(int)
plan = rng.choice(plans, N, p=plan_w)
contract = rng.choice(contracts, N, p=contract_w)
payment = rng.choice(pay_methods, N, p=pay_w)
paperless = rng.choice(["Yes", "No"], N, p=[0.6, 0.4])

# Signup dates spread across ~24 months ending 2026-05-31 (cohort analysis needs history)
start = pd.Timestamp("2024-06-01")
end = pd.Timestamp("2026-05-31")
span_days = (end - start).days
signup_date = pd.Series(start + pd.to_timedelta(rng.integers(0, span_days, N), unit="D"))

# Monthly charge = plan price + small noise + add-on uplift
addons = rng.integers(0, 4, N)  # 0-3 add-ons
monthly_charge = np.array([plan_price[p] for p in plan]) + addons * 60 + rng.normal(0, 15, N)
monthly_charge = np.round(np.clip(monthly_charge, 149, None), 0)

# -----------------------------------------------------------------------------
# Acquisition funnel: Signup -> Verified -> Activated (first conversion)
# Quality varies by channel (referral/organic convert better than paid social)
# -----------------------------------------------------------------------------
verify_rate = {"Organic Search":0.93,"Paid Social":0.78,"Paid Search":0.86,
               "Referral":0.95,"Affiliate":0.82,"Email":0.88}
activate_rate = {"Organic Search":0.82,"Paid Social":0.63,"Paid Search":0.74,
                 "Referral":0.88,"Affiliate":0.70,"Email":0.76}

verified = np.array([rng.random() < verify_rate[c] for c in channel]).astype(int)
# can only activate if verified
activated = np.array([1 if (v == 1 and rng.random() < activate_rate[c]) else 0
                      for v, c in zip(verified, channel)]).astype(int)

# -----------------------------------------------------------------------------
# Tenure (months observed) - capped at months since signup
# -----------------------------------------------------------------------------
months_since_signup = ((end.year - signup_date.dt.year) * 12 +
                       (end.month - signup_date.dt.month)).to_numpy()
months_since_signup = np.clip(months_since_signup, 0, None)

# -----------------------------------------------------------------------------
# Churn propensity model (logistic-style scoring -> probability)
# Drivers: month-to-month contract, low tenure, high price, paid-social channel,
# wallet/no-autopay, not activated, more add-ons slightly sticky.
# -----------------------------------------------------------------------------
z = (
    -1.75
    + 1.35 * (contract == "Monthly")
    - 0.55 * (contract == "Two-Year")
    + 0.018 * (monthly_charge - monthly_charge.mean()) / 50
    + 0.70 * (channel == "Paid Social")
    + 0.30 * (channel == "Affiliate")
    - 0.45 * (channel == "Referral")
    + 0.60 * (payment == "Wallet")
    - 0.30 * (paperless == "Yes")
    - 0.04 * np.clip(months_since_signup, 0, 18)
    + 0.90 * (activated == 0)
    - 0.12 * addons
    + 0.25 * senior
    + rng.normal(0, 0.45, N)
)
prob_churn = 1 / (1 + np.exp(-z))
churned = (rng.random(N) < prob_churn).astype(int)
# Churn is only defined for customers who actually started service (activated).
# Non-activated sign-ups are tracked separately as funnel drop-off (is_activated=0).
churned = churned * activated

# Tenure for churned customers is shorter (they leave earlier)
tenure_months = np.where(
    churned == 1,
    np.minimum(months_since_signup, rng.integers(0, np.maximum(months_since_signup, 1) + 1)),
    months_since_signup,
)
tenure_months = np.clip(tenure_months, 0, None).astype(int)

churn_date = pd.Series([pd.NaT] * N)
mask = churned == 1
churn_date[mask] = signup_date[mask] + pd.to_timedelta(tenure_months[mask] * 30, unit="D")

total_revenue = np.round(monthly_charge * np.maximum(tenure_months, 1), 0)

# Last activity date (for RFM recency) - churned: at churn; active: recent
last_active = pd.Series(pd.NaT, index=range(N))
last_active[mask] = churn_date[mask]
last_active[~mask] = end - pd.to_timedelta(rng.integers(0, 30, (~mask).sum()), unit="D")

# Monthly logins (frequency proxy) - lower for churn-risk customers
logins = np.clip(rng.normal(18, 7, N) - 8 * prob_churn + 2 * addons, 0, None).round(0)

df = pd.DataFrame({
    "customer_id": customer_id,
    "signup_date": signup_date.dt.strftime("%Y-%m-%d"),
    "acquisition_channel": channel,
    "city": city,
    "gender": gender,
    "age": age,
    "senior_citizen": senior,
    "plan": plan,
    "contract_type": contract,
    "payment_method": payment,
    "paperless_billing": paperless,
    "addon_count": addons,
    "monthly_charge": monthly_charge,
    "is_verified": verified,
    "is_activated": activated,
    "tenure_months": tenure_months,
    "monthly_logins": logins,
    "last_active_date": pd.to_datetime(last_active).dt.strftime("%Y-%m-%d"),
    "total_revenue": total_revenue,
    "churn_date": churn_date.dt.strftime("%Y-%m-%d"),
    "is_churned": churned,
})

# Inject a few realistic data-quality issues for the "cleaning" narrative
# (the SQL/Power Query cleaning step will fix these)
dirty = rng.choice(N, 60, replace=False)
df.loc[dirty[:20], "city"] = df.loc[dirty[:20], "city"].str.upper()       # case inconsistency
df.loc[dirty[20:35], "payment_method"] = " UPI "                          # whitespace
df.loc[dirty[35:50], "monthly_charge"] = np.nan                           # missing values
df.loc[dirty[50:], "gender"] = df.loc[dirty[50:], "gender"].str[0]        # M / F shorthand

df.to_csv("data/customers.csv", index=False)
print("Rows:", len(df))
print("Overall churn rate: {:.1%}".format(df["is_churned"].mean()))
print("Activated rate: {:.1%}".format(df["is_activated"].mean()))
