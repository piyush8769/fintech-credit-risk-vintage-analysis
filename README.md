# Fintech Credit Risk & Loan Portfolio Vintage Analysis

An end-to-end data analytics project evaluating loan default drivers, delinquency aging buckets, and vintage loss curves across 105,000+ consumer loans ($1.66B funded exposure) using Python, MySQL, and Power BI.

---

## Business Problem

Consumer lending and fintech platforms need to balance loan origination growth with credit risk. If credit losses grow faster than interest income, profitability erodes quickly.

This project analyzes 105,000 loan accounts spanning 16 quarterly cohorts (2018–2021) to address four core risk questions:
1. **Which borrower segments drive the majority of defaults?** How do credit grade, debt-to-income (DTI), and FICO score correlate with write-offs?
2. **How does default risk develop over time (vintage curves)?** At what point in a loan's lifecycle (Months on Book) do credit losses peak and stabilize?
3. **What are the transition rates across delinquency buckets?** How often do early overdue accounts (30–59 DPD) cure versus roll forward into non-performing assets (90+ DPD / NPAs)?
4. **How can underwriting cutoffs be refined to protect margins?** Where can risk thresholds be adjusted to cut losses while protecting prime loan volume?

---

## Key Findings

- **Disproportionate Loss Concentration:** Lower-grade loans (Grades D through G) and borrowers with DTI > 21.3% combined with FICO < 695 account for **64.1% of all portfolio write-offs**, despite making up only 36.7% of accounts.
- **The Impact of Leverage (DTI):** Borrowers with DTI below 10.5% have a low default rate of **3.8%**, while borrowers with DTI above 31.0% default at **24.6%** (over 6 times higher).
- **Peak Loss Window (Months on Book 12–24):** Cohort loss curves show that defaults pick up rapidly between **Month 12 and Month 24**, reaching roughly 78% of their total lifetime losses by Month 24 before leveling off around **8.0%–11.5%** by Month 36.
- **Roll Rate Cliff (60–89 DPD):** While accounts in the 30–59 DPD bracket have a 44.2% chance of curing back to good standing, accounts that reach 60–89 DPD have a **72.8% probability of rolling into 90+ DPD (default/charge-off)**. This makes the 30–59 DPD window the critical intervention point for collections.

---

## Tools Used

- **Python (Pandas, NumPy, Matplotlib, Seaborn):** Data cleaning, feature engineering (aging buckets, installment ratios), correlation analysis, and vintage loss matrices.
- **MySQL:** Relational database staging and writing multi-table queries, window functions (`NTILE`, `PERCENT_RANK`, `DENSE_RANK`), and CTEs for delinquency tracking.
- **Power BI:** Star Schema data modeling, DAX measures for dynamic vintage tracking, and a 3-page interactive risk monitoring report.

---

## Project Structure

```
├── 01_exploratory_data_analysis.ipynb          # Raw data distribution, null checks, correlation heatmap
├── 02_data_cleaning_feature_engineering.ipynb   # DPD aging buckets (30/60/90+ DPD), risk tiering, MOB features
├── 03_credit_risk_driver_analysis.ipynb        # Default rates by credit grade, DTI deciles, risk segments
├── 04_portfolio_vintage_loss_analysis.ipynb    # Quarterly origination cohorts, MOB 1-36 curves, loss heatmap
├── 05_database_export.ipynb                   # Staging clean data into MySQL
├── sql/
│   └── credit_risk_portfolio_analytics.sql     # Executive KPIs, delinquency aging, and SQL vintage queries
├── powerbi/
│   └── dashboard_specification.md             # Star schema model, DAX measures, and visual layouts
├── data/
│   ├── vintage_loss_matrix.csv                # Cumulative loss percentages by cohort & MOB
│   ├── borrower_risk_segments.csv             # Risk tier exposure, counts, and loss share
│   └── delinquency_aging_summary.csv          # DPD aging bucket counts and exposure
├── .gitignore
└── README.md
```

---

## Analytical Steps

### 1. Data Cleaning & Feature Engineering
- Audited 105,000 loan accounts totaling $1.66 Billion in funded volume.
- Grouped Days Past Due (DPD) into standard regulatory aging buckets:
  - `Performing` (Current)
  - `1–29 DPD` (Grace Period)
  - `30–59 DPD` (Early Delinquency)
  - `60–89 DPD` (Late Delinquency)
  - `90+ DPD` (NPA / Charge-off)
- Created composite risk tiers (`Low Risk`, `Moderate Risk`, `High Risk`) combining credit grades, DTI, and FICO scores.

### 2. Risk Driver Analysis
- Analyzed default rates across credit grades: Grade A accounts had a 2.4% default rate, while Grade G accounts reached 44.8%.
- Segmented borrowers into DTI deciles to highlight the sharp increase in default rates past 20% DTI.
- Verified that tightening cutoffs on the high-risk tier could reduce total write-offs by up to 64% while maintaining over 63% of originations.

### 3. Vintage Analysis (Cohort Seasoning)
- Grouped loans into 16 quarterly origination cohorts (`2018-Q1` through `2021-Q4`).
- Tracked cumulative net losses across Months on Book (`MOB 1 to 36`).
- Built the triangular vintage loss rate matrix to compare performance across newer vs. older loan cohorts.

---

## Key SQL Queries

The `sql/credit_risk_portfolio_analytics.sql` script covers:
- Executive portfolio KPIs (Total Funded Capital, Average Interest Rate, Default Rate, Recovery Rate)
- Delinquency aging summaries using `CASE` statements and CTEs
- Risk tier write-off shares and loss concentrations
- DTI deciles and credit score percentiles using `NTILE(10)` and `PERCENT_RANK()`
- Cohort cumulative loss tracking across origination quarters
