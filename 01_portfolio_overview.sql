-- ============================================================
-- 01. PORTFOLIO OVERVIEW
-- Question: What does the overall book look like,
--           and which grade tiers need immediate action?
-- Database: SQLite (nova_bank.db)
-- ============================================================

WITH grade_metrics AS (
    SELECT
        loan_grade,
        COUNT(*)                                        AS total_loans,
        SUM(loan_status)                                AS total_defaults,
        ROUND(AVG(CAST(loan_status AS REAL)) * 100, 1) AS default_rate_pct,
        ROUND(AVG(loan_int_rate), 2)                    AS avg_interest_rate,
        ROUND(AVG(loan_amnt), 0)                        AS avg_loan_amount,
        ROUND(SUM(loan_amnt), 0)                        AS total_exposure_usd
    FROM loans
    GROUP BY loan_grade
),
overall AS (
    SELECT ROUND(AVG(CAST(loan_status AS REAL)) * 100, 1) AS portfolio_default_rate
    FROM loans
)
SELECT
    g.loan_grade,
    g.total_loans,
    g.total_defaults,
    g.default_rate_pct,
    o.portfolio_default_rate                            AS portfolio_avg_pct,
    ROUND(g.default_rate_pct - o.portfolio_default_rate, 1) AS vs_avg_pp,
    g.avg_interest_rate,
    g.avg_loan_amount,
    g.total_exposure_usd,

    -- Business action flag based on default rate
    CASE
        WHEN g.default_rate_pct >= 50 THEN 'SUSPEND - near-certain loss'
        WHEN g.default_rate_pct >= 30 THEN 'REVIEW - reprice or add collateral'
        WHEN g.default_rate_pct >= 20 THEN 'MONITOR - above portfolio average'
        ELSE                               'APPROVE - within acceptable range'
    END AS policy_action

FROM grade_metrics g, overall o
ORDER BY g.loan_grade;
