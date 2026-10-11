# shopkart-ecommerce-analytics
E-commerce funnel, cohort retention, and root cause analysis using MySQL.

# ShopKart — E-commerce Customer Funnel, Retention & RCA Analysis

**Tools:** MySQL, SQL, CTEs, Window Functions, Aggregations, Cohort Analysis

## 1. Project Overview

ShopKart is a fictional e-commerce platform. This project analyses customer behaviour across the shopping journey to understand conversion patterns, customer retention, and potential barriers to successful purchases.

Using SQL and a relational dataset containing users, events, products, orders, and order items, I explored customer journeys, compared signup cohorts, examined retention trends, and investigated differences across devices and acquisition channels.

## 2. Business Problem

ShopKart needs better visibility into how users move from opening the application to purchasing products and whether they continue engaging with the platform over time.

The business needs to understand:
- At which stages users drop off during the shopping journey.
- How conversion varies across devices and acquisition channels.
- How customer retention changes across signup cohorts.
- Whether payment attempts are followed by recorded payment success.
- Which customer segments and journey stages warrant further investigation.

## 3. Project Objectives

- Analyse the customer funnel from app opening to purchase.
- Calculate stage-level conversion and drop-off metrics.
- Compare funnel performance across devices, acquisition channels, product categories, and time periods.
- Measure monthly cohort retention and identify retention declines.
- Investigate potential causes of conversion and retention differences.
- Develop evidence-based recommendations to improve customer engagement and purchase conversion.

## 4. Dataset

The project uses five relational tables:

| Table | Records | Description |
|---|---:|---|
| users | 250 | Signup information, device, city, and acquisition channel |
| events | 3,058 | Customer events and timestamps |
| products | 10 | Product names, categories, and prices |
| orders | 174 | Order details, payment methods, and statuses |
| order_items | 174 | Products and quantities within orders |

The dataset covers January–September 2026 and is intended for analytical practice.

## 5. Analytical Approach

### A. Funnel Analysis
- Counted distinct users at key shopping stages.
- Calculated conversion and drop-off rates.
- Examined sequential customer journeys using event timestamps.
- Compared funnel performance by device, acquisition channel, product category, and date.
- Investigated payment-attempt users without a recorded payment-success event.

### B. Cohort and Retention Analysis
- Assigned users to signup-month cohorts.
- Calculated monthly activity and retention percentages.
- Created a cohort retention matrix.
- Compared retention across signup cohorts and acquisition channels.
- Used `LAG()` and `RANK()` to identify major retention declines.
- Used `AVG()`, `MIN()`, and `MAX()` to examine average retention and variation across cohorts.

### C. Root Cause Analysis
- Compared app-open-to-add-to-cart conversion across devices and acquisition channels.
- Examined users with payment attempts but no recorded success.
- Compared first-month retention across acquisition channels.
- Developed hypotheses for further validation rather than assuming that observed differences proved a cause.

## 6. Key Findings

The analysis produced the following results from the mock dataset:

- **Initial app-open-to-add-to-cart analysis:** 250 unique app-open users and 204 users whose earliest recorded add-to-cart event followed their earliest recorded app-open event, giving a preliminary conversion measure of 81.60%.
- **Device comparison:** Web had the highest observed add-to-cart conversion at 82.80%, while iOS had the lowest at 80.00%.
- **Acquisition-channel comparison:** Referral had the highest observed add-to-cart conversion at 83.87%, while Google had the lowest at 76.92%.
- **Payment tracking:** 20 of 156 payment-attempt users had no recorded payment-success event, representing approximately 12.82%.
- **Retention analysis:** Average retention declined from 65.37% at M1 to 18.13% at M6.
- **Cohort variability:** M2 had the largest observed retention range across signup cohorts at 32.50 percentage points.
- **First-month retention by channel:** Organic had the lowest pooled M1 retention at 50.00%, while Referral had the highest at 61.29%.

These results identify areas for investigation; they do not establish the underlying causes of customer behaviour.

## 7. Business Recommendations

1. **Improve funnel visibility:** Implement session-aware journey analysis to identify the exact stages where users fail to progress.
2. **Investigate acquisition-channel differences:** Examine landing-page relevance, product discovery, and downstream purchase conversion for lower-converting channels.
3. **Audit payment outcomes:** Match payment attempts with individual success/failure records and order statuses before classifying events as payment failures.
4. **Improve early customer engagement:** Investigate first-month retention patterns and test targeted onboarding or follow-up strategies where supported by evidence.
5. **Monitor customer experience by device:** Investigate device-specific usability or tracking issues if further analysis confirms a meaningful performance gap.
6. **Measure impact:** Establish baseline KPIs and evaluate proposed changes through controlled experiments where feasible.

## 8. Limitations

- The dataset is synthetic and does not represent actual ShopKart business performance.
- Event-level comparisons may not fully reconstruct individual shopping sessions.
- A missing payment-success event does not necessarily indicate a failed payment.
- Retention is defined as at least one recorded event in a month; it does not necessarily indicate a purchase.
- Cohort retention uses the M0-active population as its denominator, so M0 retention is 100% by definition.
- Observed differences are exploratory and require additional validation before causal conclusions or business-impact claims can be made.

## 9. Conclusion

This project demonstrates how SQL can be used to investigate customer journeys, measure funnel conversion, analyse cohort retention, compare customer segments, and develop business hypotheses. The resulting findings provide a structured basis for prioritising further investigation and designing measurable improvements to customer engagement and purchase conversion.
