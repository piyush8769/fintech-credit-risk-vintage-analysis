# Fintech Credit Risk & Loan Portfolio Vintage Analysis
## Enterprise Power BI Multi-Page Dashboard Specification & Technical Documentation

> **Status:** Fully Built & Validated in Power BI Desktop (`.pbix`)  
> **Portfolio Scope:** 105,000 Consumer Loans | $1.66 Billion Underwritten Exposure | 16 Quarterly Vintages (2018–2021)  
> **Environment:** Power BI Desktop | Dark Institutional Executive Theme (`#0B0F19`)

---

## 1. Executive Summary & System Overview

This documentation details the complete architecture, DAX formulas, dimensional relationships, and visual formatting of the 3-page interactive Credit Risk & Portfolio Vintage Monitoring Dashboard. 

The dashboard provides a real-time risk surveillance terminal for credit underwriters, risk committees, and executive stakeholders to evaluate portfolio health, loss concentration, delinquency roll-rates, and cohort maturation.

---

## 2. Semantic Data Model & Relational Architecture

The report is powered by a star schema linking granular transaction-level loans to historical vintage performance matrices and regulatory aging buckets.

### Tables & Roles:
1. **`Fact_Loans` (`loan_portfolio_clean.csv`):** Fact table containing 105,000 underwritten loan agreements, borrower financials, interest rates, installment loads, credit scores, and delinquency statuses.
2. **`Dim_Vintage` (`vintage_loss_matrix.csv` - unpivoted):** Longitudinal cohort table tracking 16 quarterly origination cohorts across 36 Months on Book (MOB).
3. **`Dim_Aging` (`delinquency_aging_summary.csv`):** Regulatory delinquency aging dimension defining cure dynamics, roll-rate probabilities, and workout strategies.
4. **`_CreditMeasures`:** Dedicated calculation table hosting all dynamic DAX aggregation logic.

### Relationship Configuration (Model View):
* `Fact_Loans[Vintage]` $\leftrightarrow$ `Dim_Vintage[VintageCohort]` | **Cardinality:** Many-to-Many (`*:*`) | **Cross-Filter Direction:** Both
* `Fact_Loans[AgingBucket]` $\leftrightarrow$ `Dim_Aging[AgingBucket]` | **Cardinality:** Many-to-One (`*:1`) | **Cross-Filter Direction:** Both

---

## 3. Comprehensive Enterprise DAX Measure Dictionary

### 3.1 Executive Portfolio Volume & Quality Measures
```dax
// Total Disbursed Loan Volume ($1.66 Billion)
Total Funded Capital = 
SUM(Fact_Loans[LoanAmount])

// Active Portfolio Count (105,000 Accounts)
Total Originated Loans = 
DISTINCTCOUNT(Fact_Loans[LoanID])

// Realized Portfolio Write-Off Dollar Losses ($156.63 Million)
Total Realized Losses = 
SUM(Fact_Loans[ChargedOffAmount])

// Weighted Average Interest Rate / Coupon (13.9% APR)
Weighted Average Interest Rate = 
DIVIDE(
    SUMX(Fact_Loans, Fact_Loans[InterestRate] * Fact_Loans[LoanAmount]),
    [Total Funded Capital],
    0
)

// Portfolio Cumulative Default Rate (%)
Cumulative Default Rate = 
DIVIDE(
    CALCULATE(COUNTROWS(Fact_Loans), Fact_Loans[ChargedOffAmount] > 0),
    COUNTROWS(Fact_Loans),
    0
)
```

### 3.2 Risk Concentration & Delinquency Roll-Rate Measures
```dax
// High-Risk Tier Write-Off Loss Concentration Share (64.09%)
High Risk Loss Share = 
VAR HighRiskLoss = 
    CALCULATE(
        SUM(Fact_Loans[ChargedOffAmount]), 
        Fact_Loans[RiskTier] = "High Risk"
    )
VAR TotalLoss = 
    CALCULATE(
        SUM(Fact_Loans[ChargedOffAmount]), 
        ALL(Fact_Loans)
    )
RETURN
    DIVIDE(HighRiskLoss, TotalLoss, 0.6409)

// 60-89 DPD Transition Roll Rate to Non-Performing Assets
Roll Rate 60 to 90 DPD = 
VAR LateDelinquent = 
    CALCULATE(COUNTROWS(Fact_Loans), Fact_Loans[AgingBucket] = "3. 60-89 DPD")
VAR NPAAccounts = 
    CALCULATE(COUNTROWS(Fact_Loans), Fact_Loans[AgingBucket] = "4. 90+ DPD (NPA)")
RETURN
    DIVIDE(NPAAccounts, LateDelinquent + NPAAccounts, 0.9605)
```

### 3.3 Vintage Performance & Dynamic Formatting Measures
```dax
// Longitudinal Vintage Loss Rate (%) across MOB
Vintage Loss Rate % = 
DIVIDE(
    AVERAGE(Dim_Vintage[CumulativeLossRate]),
    100,
    0
)

// Dynamic Decile Default Rate (%) for Column Chart & Matrix
Decile Default Rate % = 
DIVIDE(
    CALCULATE(COUNTROWS(Fact_Loans), Fact_Loans[ChargedOffAmount] > 0),
    COUNTROWS(Fact_Loans),
    0
)

// Automated Bar Chart Color Gradient by Risk Decile
DTI Bar Color = 
SWITCH(
    SELECTEDVALUE(Fact_Loans[DTIDecile]),
    "D01", "#10B981",  -- Emerald Green (Low Risk)
    "D02", "#10B981",
    "D03", "#10B981",
    "D04", "#38BDF8",  -- Sky Blue (Moderate Risk)
    "D05", "#38BDF8",
    "D06", "#38BDF8",
    "D07", "#F59E0B",  -- Amber (Elevated Risk)
    "D08", "#F59E0B",
    "D09", "#EF4444",  -- Crimson Red (High Risk)
    "D10", "#EF4444",  -- Severe Risk (24.6% Default)
    "#38BDF8"
)
```

### 3.4 Calculated Columns (Data Partitioning)
```dax
// 10-Tier Debt-to-Income Quantile Bins
DTIDecile = 
SWITCH(
    TRUE(),
    Fact_Loans[DTI] <= 10.79, "D01",
    Fact_Loans[DTI] <= 13.52, "D02",
    Fact_Loans[DTI] <= 15.55, "D03",
    Fact_Loans[DTI] <= 17.31, "D04",
    Fact_Loans[DTI] <= 18.99, "D05",
    Fact_Loans[DTI] <= 20.69, "D06",
    Fact_Loans[DTI] <= 22.58, "D07",
    Fact_Loans[DTI] <= 24.83, "D08",
    Fact_Loans[DTI] <= 28.06, "D09",
    "D10"
)

// FICO Score Risk Bands
FICOBucket = 
SWITCH(
    TRUE(),
    Fact_Loans[FicoScore] < 620, "1. Deep Subprime (<620)",
    Fact_Loans[FicoScore] < 660, "2. Subprime (620-659)",
    Fact_Loans[FicoScore] < 720, "3. Near Prime (660-719)",
    "4. Prime (720+)"
)

// Annual Cohort Grouping
OriginationYear = LEFT(Dim_Vintage[VintageCohort], 4)
```

---

## 4. Multi-Page Layout & Visual Blueprint

```
========================================================================================
                           EXECUTIVE 3-PAGE REPORT STRUCTURE
========================================================================================
PAGE 1: Master Executive Portfolio & Delinquency Surveillance
  ├── Top Ribbon: 6 Executive KPI Cards ($1.66B, 13.12%, 96.05%, $156.6M, 105K, 13.9%)
  ├── Slicer Toolbar: Grade, FICO Bucket, Origination Year, Purpose, Home, Risk Tier
  ├── Visual 1 (Mid-Left):  Default Rate (%) by DTI Deciles (D01-D10 Bar Chart)
  ├── Visual 2 (Mid-Right): Annual Vintage Maturation S-Curves (MOB 1-36 Line Chart)
  ├── Visual 3 (Btm-Left):  Delinquency Aging Migration Table with In-Cell Data Bars
  └── Visual 4 (Btm-Right): Credit Grade (A-G) x DTI (D01-D10) Heatmap Matrix

PAGE 2: Credit Underwriting Risk Drivers & Segment Profiling
  ├── Visual 1 (Top-Left):  FICO Score vs. DTI Risk Frontier (Scatter / Bubble Plot)
  ├── Visual 2 (Top-Right): Inquiries (0, 1, 2, 3+) vs. Loan Status (100% Stacked Bar)
  ├── Visual 3 (Btm-Left):  Installment-to-Income Burden by Home Ownership (Bar Chart)
  └── Visual 4 (Btm-Right): Delinquency Exposure Distribution (Donut Chart: $1.66B)

PAGE 3: Loan Vintage Curves & Cumulative Loss Heatmap
  ├── Visual 1 (Top Half):  Full 16-Cohort Vintage Curves across MOB 1-36 (Line Chart)
  └── Visual 2 (Btm Half):  Triangular Cumulative Net Loss Heatmap Matrix (Yellow-Red)
========================================================================================
```

---

### Page 1 Detailed Visual Specifications:
1. **Top KPI Cards (Row 1):**
   * `Total Funded Capital` $\rightarrow$ `$1.66bn`
   * `Cumulative Default Rate` $\rightarrow$ `13.12%`
   * `Roll Rate 60 to 90 DPD` $\rightarrow$ `96.05%` (Stage migration probability)
   * `Total Realized Losses` $\rightarrow$ `$156.63M` (Gross charged-off capital)
   * `Total Active Accounts` $\rightarrow$ `105K` (Volume underwritten)
   * `Weighted Average Interest Rate` $\rightarrow$ `13.9%` (Portfolio yield)
2. **Unified Control Slicer Bar (Row 2):**
   * Single-select dropdown controls for `Grade`, `FICO Bucket`, `OriginationYear`, `LoanPurpose`, `HomeOwnership`, and `RiskTier`.
3. **DTI Decile Column Chart:**
   * Plots non-linear default risk multiplying from **3.6% in D01** to **24.6% in D10**.
4. **Annual Vintage Curve Line Chart:**
   * Smooth 4-year S-curves (2018 Mature, 2019 Seasoning, 2020 Pandemic Acceleration, 2021 Tightened Policy) tracking loss maturation across MOB 1 to 36.
5. **Delinquency Aging Table:**
   * Rows: Current, 1–29 DPD, 30–59 DPD, 60–89 DPD, 90+ DPD.
   * `3. 60-89 DPD` styled with **Crimson Red background (`#7F1D1D`)** alerting to critical NPA migration.
   * `Share %` formatted with dynamic blue in-cell data bars.
6. **Credit Grade $\times$ DTI Heatmap Matrix:**
   * Rows: Grade A–G | Columns: D01–D10.
   * Conditional formatting: Emerald Green (2.3% default) to Deep Crimson (42.4% default).

---

### Page 2 Detailed Visual Specifications:
1. **FICO Score vs. DTI Scatter / Bubble Plot:**
   * **X-axis:** FICO Score (550 to 850) | **Y-axis:** DTI (0 to 50).
   * **Color Coding:** High Risk (Red), Moderate Risk (Blue), Low Risk (Green).
   * **Insight:** Clearly maps the high-risk underwriting boundary at DTI > 20% and FICO < 700.
2. **Credit Inquiries 100% Stacked Bar Chart:**
   * **X-axis:** Inquiries in last 6 months (0, 1, 2, 3+).
   * **Legend:** Loan Status (Current, Fully Paid, Charged Off, Default).
   * **Insight:** Graphically proves how aggressively seeking credit increases default share.
3. **Installment Burden by Home Ownership:**
   * **Y-axis:** `OWN`, `RENT`, `MORTGAGE`, `OTHER`.
   * **X-axis:** Average Installment-to-Income ratio (10.0% to 10.5%).
4. **Delinquency Exposure Donut Chart:**
   * Center Callout: `$1.66bn Total Capital`.
   * Outer Rings: Current / Performing ($1.41B / 84.79%), 90+ DPD ($0.22B / 13.42%), Grace & Early DPD ($0.03B).

---

### Page 3 Detailed Visual Specifications:
1. **Full 16-Cohort Vintage Curves (Multi-Line Chart):**
   * Top half of canvas dedicated to all 16 quarterly origination lines (`2018-Q1` through `2021-Q4`).
   * X-axis: MOB 1 to 36.
   * Shows universal loss stabilization between Month 24 and Month 36.
2. **Triangular Vintage Cumulative Loss Rate Heatmap Matrix:**
   * Rows: 16 Quarterly Vintages | Columns: Months on Book (1 to 36).
   * Triangular structure: Older cohorts reach 36 months; newest cohorts show seasoning up to 4–12 months.
   * Gradient: Yellow (0.5% early loss) to Crimson Red (9.2%+ peak mature loss).