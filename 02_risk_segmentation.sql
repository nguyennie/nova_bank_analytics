-- ============================================================
-- 02. RISK SEGMENTATION MATRIX
-- Question: Which borrower combinations are safest
--           and which are critical?
-- Combines home ownership x prior default history
-- These two variables produce the widest risk spread.
-- Database: SQLite (nova_bank.db)
-- ============================================================

WITH segment_stats AS (
    SELECT
        person_home_ownership,
        cb_person_default_on_file,
        COUNT(*)                                            AS borrower_count,
        ROUND(AVG(CAST(loan_status AS REAL)) * 100, 1)     AS default_rate_pct,
        ROUND(AVG(person_income), 0)                        AS avg_income,
        ROUND(AVG(loan_amnt), 0)                            AS avg_loan_amount,
        ROUND(AVG(loan_to_income_ratio), 3)                 AS avg_lti_ratio,
        ROUND(AVG(debt_to_income_ratio), 3)                 AS avg_dti_ratio
    FROM loans
    GROUP BY person_home_ownership, cb_person_default_on_file
),
totals AS (
    SELECT COUNT(*) AS grand_total FROM loans
),
baseline AS (
    SELECT ROUND(AVG(CAST(loan_status AS REAL)) * 100, 1) AS portfolio_avg
    FROM loans
)
SELECT
    s.person_home_ownership,
    s.cb_person_default_on_file             AS prior_default_on_file,
    s.borrower_count,
    ROUND(s.borrower_count * 100.0 / t.grand_total, 1) AS portfolio_share_pct,
    s.default_rate_pct,
    b.portfolio_avg                         AS portfolio_avg_pct,
    ROUND(s.default_rate_pct - b.portfolio_avg, 1)     AS vs_avg_pp,
    s.avg_income,
    s.avg_loan_amount,
    s.avg_lti_ratio,

    -- Risk tier label for dashboard slicing
    CASE
        WHEN s.default_rate_pct < 10 THEN 'Low Risk'
        WHEN s.default_rate_pct < 25 THEN 'Moderate'
        WHEN s.default_rate_pct < 40 THEN 'High Risk'
        ELSE                              'Critical'
    END AS risk_tier

FROM segment_stats s, totals t, baseline b
ORDER BY s.default_rate_pct DESC;
