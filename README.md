# Cohort Retention Analysis: Organic vs. Promo Acquisition

SQL-based cohort analysis comparing user retention across acquisition channels — organic sign-ups vs. promo-driven users.

## Problem

The goal was to measure how user retention evolves over the first months after sign-up, and whether retention differs between users acquired organically and those acquired through promo campaigns.

The raw data came with a common real-world challenge: signup and event timestamps were stored as free-form text with inconsistent formatting — mixed separators (`.`, `/`, `-`), 1- or 2-digit days/months, and 2- or 4-digit years.

## Approach

1. **Date cleaning** — parsed and standardized inconsistent date strings in PostgreSQL using `TRIM`, `REPLACE`, `SPLIT_PART`, and `CASE`, then converted them to proper `date` type with `TO_DATE`.
2. **Cohort table construction** — built the pipeline with CTEs, joining user registration data with event data.
3. **Filtering** — removed test events, records with missing dates, and events with no type, while keeping the `registration` event as month 0 activity.
4. **Month offset calculation** — computed `month_offset` (months since signup) to track user tenure over time.
5. **Aggregation** — counted unique users per `promo_signup_flag` + `cohort_month` + `month_offset`, limited to a Jan–Jun 2025 observation window.
6. **Visualization** — exported results to Google Sheets, built pivot tables for user counts and Retention Rate, applied conditional gradient formatting, and added an interactive Slicer to compare segments.

## Key Insight

Month-1 retention was **~83% for organic users** vs. only **~56% for promo-acquired users**. Promo campaigns are effective at driving initial sign-up volume, but that audience churns significantly faster — suggesting a need for stronger onboarding or personalized engagement for promo-driven cohorts.

## Files

- [`cohort_analysis.sql`](./cohort_analysis.sql) — full SQL script: date cleaning, cohort table construction, and aggregation
- [Google Sheets visualization](https://docs.google.com/spreadsheets/d/1aot_uY0RhoVOH47CW9V38Kj6lk9-gOgPo9FWL96ozH8/edit?usp=sharing) — pivot tables, Retention Rate matrix, and an interactive Slicer

## Tools

- SQL (PostgreSQL)
- DBeaver
- Google Sheets (pivot tables, conditional formatting, Slicer)
