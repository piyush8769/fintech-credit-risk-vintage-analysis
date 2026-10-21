# Fintech Credit Risk & Loan Portfolio Vintage Analysis

An end-to-end credit risk modeling and portfolio vintage analytics project evaluating 105,000+ consumer loan accounts to identify default risk drivers, categorize delinquency aging buckets (30/60/90+ DPD), track Non-Performing Assets (NPAs), and construct longitudinal vintage loss curves using Python, MySQL, and Power BI.

---

## 1. Executive Summary & Business Context

In consumer fintech, retail banking, and non-banking financial company (NBFC) operations (such as CRED, Bajaj Finserv, Paytm, and Axis Bank), disciplined portfolio risk management is the cornerstone of sustainable net interest margins (NIM). Financial analysts and credit risk modelers must continuously monitor:
- **Default Risk Drivers:** How borrower leverage (Debt-to-Income / DTI), credit scores (FICO), and revolving line utilization influence default probabilities.
- **Delinquency Migration (Roll Rates):** How early-stage overdue balances (1-29 DPD) transition into Special Mention Accounts (30-59 DPD, 60-89 DPD) and regulatory Non-Performing Assets (90+ DPD / NPAs).
- **Longitudinal Portfolio Seasoning:** How cumulative default loss rates mature across successive origination cohorts over Months on Book (MOB 1 to 36).
- **Concentration of Credit Loss:** Which underwriting criteria drive the disproportionate share of portfolio write-offs.

This repository implements a full-lifecycle analytical pipeline evaluating $1.66 Billion in funded loan exposure across 16 quarterly origination vintages (2018-Q1 to 2021-Q4).

---

## 2. Key Findings & Strategic Risk Insights

1. **High-Risk Write-Off Concentration (The 64% Rule):**
   - High-risk borrower criteria (Credit Grades D–G, elevated DTI > 21.3% combined with FICO < 695, and 2+ recent inquiries with revolving utilization > 55%) account for **64.1% of all realized portfolio write-offs**, while comprising only 36.7% of the total borrower base.
   - Tightening underwriting cutoffs on this multi-variable segment would prevent nearly two-thirds of gross losses while preserving 63.3% of prime origination volume.

2. **Non-Linear Leverage & Default Elasticity:**
   - Default rates escalate non-linearly with Debt-to-Income: borrowers in DTI Decile 1 (DTI < 10.5%) demonstrate a 3.8% default rate, whereas borrowers in DTI Decile 10 (DTI > 31.0%) experience a default rate of **24.6%** (a 6.5x risk multiple).

3. **Peak Delinquency Seasoning Horizon (MOB 12 to 24):**
   - Longitudinal vintage curves show that default loss accumulation follows an S-curve profile.
   - Credit losses accelerate sharply between **Months on Book (MOB) 12 and 24**, reaching 78% of their lifetime loss potential by Month 24, before stabilizing between **8.0% and 11.5%** by MOB 36.

4. **Delinquency Migration & Collections Intervention Window:**
   - Accounts entering the 30–59 DPD bucket exhibit a 44.2% cure rate back to current status, whereas accounts entering 60–89 DPD face a **72.8% transition probability into 90+ DPD (terminal NPA / charge-off)**.
   - This identifies the 30–59 DPD window as the highest-ROI interval for automated collections and restructuring interventions.

---

## 3. Technology Stack

- **Data Processing & Analytics:** Python 3.14, Pandas, NumPy
- **Visual Risk Modeling:** Matplotlib, Seaborn
- **Relational Data Warehouse:** MySQL 8.0, SQLAlchemy
- **Credit Risk Querying:** Advanced SQL (CTEs, `CASE` Bucketing, Window Functions: `NTILE`, `PERCENT_RANK`, `DENSE_RANK`, Multi-Table Joins)
- **Business Intelligence & Dashboards:** Microsoft Power BI, Advanced DAX (Time Intelligence, Vintage Rate Modeling, Star Schema Architecture)

---

## 4. Repository Structure

```
.
├── 01_exploratory_data_analysis.ipynb          # Raw schema audit, FICO/DTI distributions, risk correlation heatmap
├── 02_data_cleaning_feature_engineering.ipynb   # Outlier handling, 30/60/90 DPD bucketing, risk tiering, MOB features
├── 03_credit_risk_driver_analysis.ipynb        # Grade default curves, DTI deciles, scatter plots, 64% write-off proof
├── 04_portfolio_vintage_loss_analysis.ipynb    # Quarterly origination cohorts, MOB 1-36 loss curves, triangular heatmap
├── 05_database_export.ipynb                   # MySQL batch ingestion and catalog record count reconciliation
│
├── sql/
│   └── credit_risk_portfolio_analytics.sql     # Executive KPIs, delinquency aging, risk tiers, window functions, SQL vintage matrix
│
├── powerbi/
│   └── dashboard_specification.md             # Star schema ERD, complete DAX measure dictionary, 3-page report layout
│
├── data/
│   ├── loan_portfolio_raw.csv                 # Raw 105,000 borrower transactional dataset (Git ignored)
│   ├── loan_portfolio_clean.csv               # Sanitized fact dataset with derived risk metrics (Git ignored)
│   ├── vintage_loss_matrix.csv                # Longitudinal cumulative loss percentages by vintage & MOB
│   ├── borrower_risk_segments.csv             # Risk tier exposure, borrower counts, and write-off share
│   └── delinquency_aging_summary.csv          # DPD aging bucket counts, exposure, and realized losses
│
├── .gitignore
└── README.md
```

---

## 5. Analytical Workflow & Methodology

### 5.1 Exploratory Data Analysis & Schema Audit (`01_exploratory_data_analysis.ipynb`)
- Ingested 105,000 consumer loan accounts representing $1.66 Billion in funded credit exposure.
- Evaluated borrower distributions across FICO credit scores (580 to 850), Debt-to-Income ratios (2% to 55%), annual income, and loan amounts ($1,000 to $40,000).
- Computed correlation matrices across underwriting variables, identifying strong positive relationships between interest rates, DTI, revolving line utilization, and charge-off losses.

### 5.2 Data Sanitation & Feature Engineering (`02_data_cleaning_feature_engineering.ipynb`)
- Standardized Days Past Due (DPD) into regulatory aging buckets: `Current / Performing`, `1-29 DPD (Grace Period)`, `30-59 DPD (SMA-1)`, `60-89 DPD (SMA-2)`, and `90+ DPD (NPA / Charge-off)`.
- Derived monthly installment burden ratios (`InstallmentToIncome`).
- Engineered composite borrower risk tiers (`Low Risk`, `Moderate Risk`, `High Risk`) based on multi-variable credit scorecard rules.
- Exported standardized analytical facts to `data/loan_portfolio_clean.csv`.

### 5.3 Risk Driver & Write-Off Concentration Analysis (`03_credit_risk_driver_analysis.ipynb`)
- Evaluated default probabilities across credit rating grades: Grade A accounts experienced a 2.4% default rate, whereas Grade G accounts experienced a 44.8% default rate.
- Grouped borrowers into DTI deciles to visualize default elasticity curves.
- Rendered multi-variable scatter plots mapping FICO vs. DTI against charge-off losses.
- Empirically validated the **64.1% write-off concentration** within the High-Risk segment via donut visualizations.

### 5.4 Portfolio Vintage Curves & Seasoning (`04_portfolio_vintage_loss_analysis.ipynb`)
- Segmented the portfolio into 16 quarterly origination vintages (`2018-Q1` through `2021-Q4`).
- Tracked cumulative net loss (CNL) rates across Months on Book (`MOB 1 to 36`).
- Constructed the classic triangular vintage loss rate matrix and generated publication-grade vintage curves and heatmap matrices.

### 5.5 Enterprise Database Export (`05_database_export.ipynb`)
- Initialized relational database schema `fintech_credit_risk` in MySQL 8.0.
- Streamed normalized tables (`loans_fact`, `dim_risk_tiers`, `dim_delinquency_aging`, `vintage_loss_matrix`) into relational storage with 100% record reconciliation.

---

## 6. SQL Analytics Architecture (`sql/credit_risk_portfolio_analytics.sql`)

The repository includes five production SQL modules designed for ad-hoc financial reporting:
- **Module 1 (Executive KPIs):** Total funded capital, weighted average interest rate, average FICO, gross recovery rate, and overall default percentages.
- **Module 2 (Delinquency Aging & NPAs):** CTEs and `CASE` statements bucketing accounts into 30, 60, and 90+ DPD tiers, measuring portfolio exposure at risk.
- **Module 3 (Risk Tier Write-Off Verification):** Validating the 64.1% write-off concentration within the high-risk segment.
- **Module 4 (Deciles & Window Functions):** Leveraging `NTILE(10)` over DTI, `PERCENT_RANK()` across credit scores, and `AVG() OVER (PARTITION BY Grade)` for peer benchmarking.
- **Module 5 (SQL Vintage Performance):** Computing cumulative default rates and write-off losses across origination quarters directly in SQL.

---

## 7. Power BI Semantic Model & Dashboard Specifications

Detailed in `powerbi/dashboard_specification.md`:
- **Data Model:** Star Schema connecting `loans_fact` to `dim_borrower`, `dim_aging_bucket`, `dim_vintage`, and `dim_date`.
- **DAX Measures:** Full formulas for `[Total Funded Capital]`, `[Weighted Average Coupon]`, `[PAR 90 Exposure]`, `[PAR 90 Ratio]`, `[High Risk Loss Share]`, and `[Cumulative Net Loss Rate]`.
- **Report Layout:** Wireframes for a 3-page interactive executive suite (Portfolio Overview, Underwriting Risk Drivers, and Vintage Loss Heatmap).

---

## 8. Setup & Reproducibility Guide

1. **Clone the Repository:**
   ```bash
   git clone https://github.com/piyush8769/fintech-credit-risk-vintage-analysis.git
   cd fintech-credit-risk-vintage-analysis
   ```

2. **Environment Configuration:**
   ```bash
   python -m venv venv
   source venv/bin/activate  # On Windows: .\venv\Scripts\activate
   pip install pandas numpy matplotlib seaborn sqlalchemy mysql-connector-python
   ```

3. **Execute Analytics Pipeline:**
   Run the notebooks sequentially:
   - `01_exploratory_data_analysis.ipynb`
   - `02_data_cleaning_feature_engineering.ipynb`
   - `03_credit_risk_driver_analysis.ipynb`
   - `04_portfolio_vintage_loss_analysis.ipynb`
   - `05_database_export.ipynb`

4. **Deploy Database Queries:**
   Load and run `sql/credit_risk_portfolio_analytics.sql` in MySQL Workbench or DBeaver.
