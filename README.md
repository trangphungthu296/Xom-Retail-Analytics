# Xom-Retail-Analytics
Stakeholder-oriented BI project translating 62K+ retail transactions into actionable insights on merchandising, store operations, fulfillment, and customer CLV using SQL & Power BI.

# Overview

Xóm Retail is a global multi-channel retailer operating 100s of physical stores across 20+ countries with an online channel. This project turns a retail transaction dataset into a stakeholder-oriented SQL + Python + Power BI analytics solution covering executive performance, merchandising, store operations, and customer retention.

## Business Problems

* **Delivery delay:** Which countries have the slowest online fulfillment?
* **Customer churn:** Do customers return after their first purchase?
* **Store cannibalization:** Does opening a new store reduce revenue at existing stores?

## Stakeholders

Head of Merchandising · VP Store Operations · Head of CRM · Head of Finance · COO

## Dataset

| Table | Rows | Key content |
| :--- | :--- | :--- |
| **customers** | ~15.3K | Customer demographics & geography |
| **products** | ~2.5K | Product, brand, category, cost & price |
| **sales** | ~62.9K | Order-line transactions & delivery dates |
| **stores** | 67 | Country, area & opening date |
| **Total** | **80,734** | **33 columns** |

## Power BI Dashboard

* **Overview** — Revenue, customers, orders, gross margin, AOV, geographic footprint and top products.
* **Products** — Active/zombie SKUs, gross margin, best sellers and cross-selling.
* **Stores** — Revenue per sqm, delivery performance and store cannibalization.
* **Customers** — CLV, repeat purchase rate, cohort retention and VIP customers.

## Key Findings

* **$55.76M** total revenue with **58.58%** gross margin.
* **25 zombie SKUs** have no recorded sales → review assortment.
* **Italy** has the longest average delivery time at **4.68 days** among the countries shown.
* **Highest observed store cannibalization impact:** 66.1% revenue decline in a German store pair.
* **2018 cohort:** 3.64% observed retention at cohort age 3.
* **US** leads store footprint (24 stores) and active customers (5.2K).

## Recommendations

* Review inactive SKUs and rationalize assortment where appropriate.
* Investigate fulfillment bottlenecks in the slowest markets.
* Flag high-impact store pairs for deeper pre/post expansion analysis.
* Strengthen loyalty programs for VIP/high-value customers and re-engage customers with declining purchase activity.

## Analytical Approach

Business context $\rightarrow$ Data validation $\rightarrow$ SQL analysis $\rightarrow$ Power BI modeling & visualization $\rightarrow$ Insight $\rightarrow$ Business action

## Data Limitations

* 2021 data is available only through February, so later cohort periods are incomplete.
* Delivery analysis is limited to records with delivery dates / eligible fulfillment transactions.
* Store cannibalization is observational and should not be interpreted as causal without additional controls.
* VIP and CLV definitions should be formally documented in a production environment.

## Tech Stack

* **SQL** — Business analysis & KPI extraction
* **Power BI** — Interactive dashboard & visualization

## Outcome

A compact BI solution that connects descriptive KPIs with business interpretation and actionable recommendations for Merchandising, Operations, CRM, Finance and executive stakeholders.
