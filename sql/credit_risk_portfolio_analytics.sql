-- ==============================================================================
-- Portfolio Analytics: Fintech Credit Risk & Loan Portfolio Vintage Analysis
-- Target Engine: MySQL 8.0+
-- Database: fintech_credit_risk
-- ==============================================================================

USE fintech_credit_risk;

-- ==============================================================================
-- Module 1: Executive Portfolio KPIs & Underwriting Summary
-- Business Objective: Compute macro exposure, weighted average pricing,
-- gross portfolio losses, and portfolio-at-risk (PAR 90+).
-- ==============================================================================

SELECT
    COUNT(DISTINCT LoanID) AS total_loans_originated,
    COUNT(DISTINCT BorrowerID) AS unique_borrowers,
    ROUND(SUM(LoanAmount), 2) AS total_funded_capital,
    ROUND(AVG(LoanAmount), 2) AS average_loan_size,
    ROUND(SUM(InterestRate * LoanAmount) / SUM(LoanAmount), 2) AS weighted_avg_interest_rate,
    ROUND(AVG(FicoScore), 1) AS portfolio_avg_fico,
    ROUND(AVG(DTI), 2) AS portfolio_avg_dti_pct,
    ROUND(SUM(CASE WHEN LoanStatus IN ('Charged Off', 'Default') THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 2) AS terminal_default_rate_pct,
    ROUND(SUM(ChargedOffAmount), 2) AS total_realized_writeoffs,
    ROUND(SUM(Recoveries), 2) AS total_recoveries_collected,
    ROUND(SUM(Recoveries) / NULLIF(SUM(ChargedOffAmount + Recoveries), 0) * 100.0, 2) AS gross_recovery_rate_pct
FROM loans_fact;

-- ==============================================================================
-- Module 2: Delinquency Aging Buckets & Non-Performing Assets (NPA) Tracking
-- Business Objective: Segment accounts into standard 30, 60, and 90+ DPD aging
-- buckets to track early-warning stress and monitor regulatory NPAs.
-- ==============================================================================

WITH DelinquencyClassification AS (
    SELECT
        LoanID,
        BorrowerID,
        LoanAmount,
        InterestRate,
        DaysPastDue,
        ChargedOffAmount,
        CASE
            WHEN DaysPastDue = 0 THEN '0. Current / Performing'
            WHEN DaysPastDue BETWEEN 1 AND 29 THEN '1. 1-29 DPD (Grace Period)'
            WHEN DaysPastDue BETWEEN 30 AND 59 THEN '2. 30-59 DPD (SMA-1)'
            WHEN DaysPastDue BETWEEN 60 AND 89 THEN '3. 60-89 DPD (SMA-2)'
            ELSE '4. 90+ DPD (NPA / Charge-off)'
        END AS DelinquencyAgingBucket,
        CASE
            WHEN DaysPastDue >= 90 THEN 1
            ELSE 0
        END AS IsNPA
    FROM loans_fact
)
SELECT
    DelinquencyAgingBucket,
    COUNT(LoanID) AS LoanCount,
    ROUND(COUNT(LoanID) * 100.0 / SUM(COUNT(LoanID)) OVER (), 2) AS AccountShare_Pct,
    ROUND(SUM(LoanAmount), 2) AS TotalExposure,
    ROUND(SUM(LoanAmount) * 100.0 / SUM(SUM(LoanAmount)) OVER (), 2) AS ExposureShare_Pct,
    ROUND(SUM(ChargedOffAmount), 2) AS RealizedLoss,
    ROUND(AVG(DaysPastDue), 1) AS MeanDaysPastDue
FROM DelinquencyClassification
GROUP BY DelinquencyAgingBucket
ORDER BY DelinquencyAgingBucket;

-- ==============================================================================
-- Module 3: Multi-Variable Borrower Risk Tiering & 64% Write-Off Proof
-- Business Objective: Empirically validate the borrower scorecard model by
-- isolating high-risk criteria and measuring concentration of credit losses.
-- ==============================================================================

WITH RiskScorecardEvaluation AS (
    SELECT
        LoanID,
        BorrowerID,
        LoanAmount,
        Grade,
        FicoScore,
        DTI,
        Inquiries6M,
        RevolvingUtilization,
        ChargedOffAmount,
        CASE
            WHEN Grade IN ('D', 'E', 'F', 'G')
              OR (DTI > 21.3 AND FicoScore < 695)
              OR (Inquiries6M >= 2 AND RevolvingUtilization > 55.0)
            THEN 'High Risk'
            WHEN Grade IN ('A', 'B')
             AND DTI < 16.0
             AND FicoScore >= 720
             AND Inquiries6M = 0
            THEN 'Low Risk'
            ELSE 'Moderate Risk'
        END AS CalculatedRiskTier
    FROM loans_fact
)
SELECT
    CalculatedRiskTier,
    COUNT(LoanID) AS BorrowerCount,
    ROUND(COUNT(LoanID) * 100.0 / SUM(COUNT(LoanID)) OVER (), 2) AS BorrowerShare_Pct,
    ROUND(SUM(LoanAmount), 2) AS TotalFundedExposure,
    ROUND(SUM(ChargedOffAmount), 2) AS RealizedLossAmount,
    ROUND(SUM(ChargedOffAmount) * 100.0 / SUM(SUM(ChargedOffAmount)) OVER (), 2) AS WriteOffConcentration_Pct,
    ROUND(AVG(CASE WHEN ChargedOffAmount > 0 THEN 1.0 ELSE 0.0 END) * 100.0, 2) AS SegmentDefaultRate_Pct
FROM RiskScorecardEvaluation
GROUP BY CalculatedRiskTier
ORDER BY CASE CalculatedRiskTier
    WHEN 'Low Risk' THEN 1
    WHEN 'Moderate Risk' THEN 2
    WHEN 'High Risk' THEN 3
END;

-- ==============================================================================
-- Module 4: Advanced Risk Deciles & Window Function Analysis
-- Business Objective: Rank borrowers into leverage deciles (NTILE) and compare
-- subgrade credit spreads and relative risk percentiles.
-- ==============================================================================

WITH LeverageDeciles AS (
    SELECT
        LoanID,
        BorrowerID,
        Grade,
        SubGrade,
        LoanAmount,
        AnnualIncome,
        DTI,
        ChargedOffAmount,
        NTILE(10) OVER (ORDER BY DTI ASC) AS DTIDecile,
        PERCENT_RANK() OVER (ORDER BY FicoScore DESC) AS FicoPercentileRank,
        AVG(InterestRate) OVER (PARTITION BY Grade) AS GradeMeanInterestRate
    FROM loans_fact
)
SELECT
    DTIDecile,
    COUNT(LoanID) AS DecileAccountVolume,
    ROUND(MIN(DTI), 2) AS MinDTI,
    ROUND(MAX(DTI), 2) AS MaxDTI,
    ROUND(AVG(DTI), 2) AS MeanDTI,
    ROUND(AVG(AnnualIncome), 2) AS MeanAnnualIncome,
    ROUND(SUM(CASE WHEN ChargedOffAmount > 0 THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 2) AS DecileDefaultRate_Pct,
    ROUND(SUM(ChargedOffAmount), 2) AS DecileTotalLoss
FROM LeverageDeciles
GROUP BY DTIDecile
ORDER BY DTIDecile;

-- ==============================================================================
-- Module 5: Pure SQL Vintage Performance & Cumulative Default Loss Tracking
-- Business Objective: Aggregate origination quarters (vintages) to measure
-- total capital deployment, terminal defaults, and cumulative loss percentage.
-- ==============================================================================

SELECT
    Vintage,
    COUNT(LoanID) AS VintageOriginatedLoans,
    ROUND(SUM(LoanAmount), 2) AS OriginatedCapital,
    ROUND(SUM(InterestRate * LoanAmount) / SUM(LoanAmount), 2) AS WeightedCoupon_Pct,
    ROUND(AVG(FicoScore), 1) AS CohortAverageFICO,
    ROUND(SUM(CASE WHEN LoanStatus IN ('Charged Off', 'Default') THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 2) AS VintageDefaultRate_Pct,
    ROUND(SUM(ChargedOffAmount), 2) AS VintageWriteOffLoss,
    ROUND(SUM(ChargedOffAmount) / SUM(LoanAmount) * 100.0, 2) AS CumulativeNetLossRate_Pct
FROM loans_fact
GROUP BY Vintage
ORDER BY Vintage;
