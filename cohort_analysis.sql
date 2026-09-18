
-- ============================================================
-- Cohort Retention Analysis
-- Cleans inconsistent date formats and builds a cohort table
-- showing user counts by promo_signup_flag, cohort_month, month_offset
-- ============================================================


-- ============================================================
-- Step 4: Clean and normalize dates in cohort_users_raw
-- ============================================================
WITH users_clean AS (
    SELECT
        user_id,
        promo_signup_flag,
        -- keep only the date part (before the space), trim extra whitespace
        TRIM(SPLIT_PART(TRIM(signup_datetime), ' ', 1)) AS date_only_raw
    FROM cohort_users_raw
),
users_unified AS (
    SELECT
        user_id,
        promo_signup_flag,
        -- unify separators: . and / -> -
        REPLACE(REPLACE(date_only_raw, '.', '-'), '/', '-') AS date_unified
    FROM users_clean
),
users_parts AS (
    SELECT
        user_id,
        promo_signup_flag,
        SPLIT_PART(date_unified, '-', 1) AS day_part,
        SPLIT_PART(date_unified, '-', 2) AS month_part,
        SPLIT_PART(date_unified, '-', 3) AS year_part
    FROM users_unified
),
users_padded AS (
    SELECT
        user_id,
        promo_signup_flag,
        LPAD(day_part, 2, '0') AS day_padded,
        LPAD(month_part, 2, '0') AS month_padded,
        CASE
            WHEN LENGTH(year_part) = 2 THEN '20' || year_part
            ELSE year_part
        END AS year_padded
    FROM users_parts
),
users_final AS (
    SELECT
        user_id,
        promo_signup_flag,
        to_date(year_padded || '-' || month_padded || '-' || day_padded, 'YYYY-MM-DD') AS signup_date
    FROM users_padded
),

-- ============================================================
-- Step 5: Clean and normalize dates in cohort_events_raw
-- ============================================================
events_clean AS (
    SELECT
        event_id,
        user_id,
        event_type,
        TRIM(SPLIT_PART(TRIM(event_datetime), ' ', 1)) AS date_only_raw
    FROM cohort_events_raw
),
events_unified AS (
    SELECT
        event_id,
        user_id,
        event_type,
        REPLACE(REPLACE(date_only_raw, '.', '-'), '/', '-') AS date_unified
    FROM events_clean
),
events_parts AS (
    SELECT
        event_id,
        user_id,
        event_type,
        SPLIT_PART(date_unified, '-', 1) AS day_part,
        SPLIT_PART(date_unified, '-', 2) AS month_part,
        SPLIT_PART(date_unified, '-', 3) AS year_part
    FROM events_unified
),
events_padded AS (
    SELECT
        event_id,
        user_id,
        event_type,
        LPAD(day_part, 2, '0') AS day_padded,
        LPAD(month_part, 2, '0') AS month_padded,
        CASE
            WHEN LENGTH(year_part) = 2 THEN '20' || year_part
            ELSE year_part
        END AS year_padded
    FROM events_parts
),
events_final AS (
    SELECT
        event_id,
        user_id,
        event_type,
        to_date(year_padded || '-' || month_padded || '-' || day_padded, 'YYYY-MM-DD') AS event_date
    FROM events_padded
),

-- ============================================================
-- Step 6: Join tables, calculate cohort and month offset
-- ============================================================
joined AS (
    SELECT
        u.user_id,
        u.promo_signup_flag,
        DATE_TRUNC('month', u.signup_date)::date AS cohort_month,
        DATE_TRUNC('month', e.event_date)::date AS activity_month,
        (
            (EXTRACT(YEAR FROM e.event_date) - EXTRACT(YEAR FROM u.signup_date)) * 12
            + (EXTRACT(MONTH FROM e.event_date) - EXTRACT(MONTH FROM u.signup_date))
        )::int AS month_offset
    FROM users_final u
    JOIN events_final e ON e.user_id = u.user_id
    WHERE u.signup_date IS NOT NULL          -- drop users with missing signup date
      AND e.event_date IS NOT NULL           -- drop events with missing date
      AND e.event_type IS NOT NULL           -- drop events with no type
      AND e.event_type <> 'test_event'       -- drop test events
)

-- ============================================================
-- Step 7: Final aggregated cohort table
-- ============================================================
SELECT
    promo_signup_flag,
    cohort_month,
    month_offset,
    COUNT(DISTINCT user_id) AS users_total
FROM joined
WHERE activity_month BETWEEN '2025-01-01' AND '2025-06-01'   -- observation window: Jan-Jun 2025
GROUP BY promo_signup_flag, cohort_month, month_offset
ORDER BY promo_signup_flag, cohort_month, month_offset;
