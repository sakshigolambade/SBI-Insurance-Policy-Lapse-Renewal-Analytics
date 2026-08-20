# 🛡️ SBI General Insurance — Policy Lapse & Renewal Analytics

## An end-to-end data analytics and database management solution designed to identify policy lapse risk, evaluate renewal behavior, and support retention strategy through predictive risk scoring.
---
## 📌 Project Overview
Insurance providers lose significant revenue when policyholders let their policies lapse instead of renewing. This project analyzes a synthetic book of 60,000 policies across a full 4-phase pipeline — **Excel → Python → SQL Server → Power BI** — to identify lapse drivers, flag high-risk policyholders, and surface renewal trends for retention planning.

### Key Objectives:
- **Data Cleaning:** Standardize inconsistent categorical values, correct invalid numeric entries, and structure raw policy data in Excel.
- **Exploratory Data Analysis (EDA):** Parse mixed-format dates, engineer risk features, and identify lapse/claims patterns using Python.
- **Relational Schema Design:** Build a normalized SQL Server database with keys, indexes, and data validation.
- **Business Intelligence Queries:** Run CTEs, window functions, and a parameterized stored procedure to surface at-risk policyholders.
- **Performance Dashboards:** Visualize lapse risk, claims behavior, and renewal trends across a 4-page interactive Power BI report.

---
## 🛠️ Tech Stack & Tools
- **Spreadsheet Cleaning:** Excel
- **Programming:** Python (`pandas`, `numpy`, `matplotlib`, `seaborn`)
- **Database:** SQL Server 
- **Environment:** Jupyter Notebook, SQL Server Management Studio (SSMS)
- **Version Control:** Git & GitHub
- **Visualization:** Power BI (custom theme, DAX, synced slicers)

---
## 🗄️ Database Architecture
The relational schema consists of 3 primary entities linked via primary and foreign key constraints, plus a summary view for BI consumption.

### Table Summary:

| Table Name  | Row Count | Primary Key   | Description                                         |
| ----------- | --------- | ------------- | ---------------------------------------------------- |
| `Customers` | 60,000    | `CustomerID`  | Customer demographics — age, gender, city, occupation |
| `Policies`  | 60,000    | `PolicyID`    | Policy details — type, tenure, premium, status, risk flag |
| `Claims`    | 60,000    | `PolicyID`    | Claims history — count, total amount, claim frequency |

A denormalized view, `vw_LapseRiskSummary`, joins all three tables and serves as the single data source for the Power BI report.

---
## 📊 Key Analytics & Insights

### 1. Lapse Drivers

- **Payment Frequency:** Monthly payers lapse at ~33%, compared to ~23-24% for quarterly, half-yearly, and annual payers — the single strongest lapse driver in the dataset.
- **Policy Type:** Lapse rate is fairly consistent across policy types (~25-27%), making it a weak standalone driver on its own.

### 2. Predictive Risk Scoring

- **8.6% of the portfolio (5,146 policies)** is flagged high-risk — defined by first-year tenure, monthly payment frequency, and zero claims filed.
- Risk is **structurally concentrated in year one** — by design of the flagging rule, risk drops to near-zero beyond the first year of tenure.
- **No meaningful link to age or policy type** — confirming this is a payment-behavior pattern rather than a demographic one.

### 3. Renewal Trends

- Overall renewal rate holds steady at **29.8%** with minimal year-over-year variation.
- Monthly payers renew **~4 points lower** than other payment frequencies, mirroring the same behavioral pattern seen in the risk scoring analysis.
- Sales channel has only a mild effect (~1 point spread) — not a priority lever compared to payment frequency.

### 4. Claims Analysis

- **High-value claims (>₹30,000)** make up roughly 12% of all claims filed.
- Claims are broadly consistent across policy types, with no single category dominating claims volume.

---

## 📈 Dashboard Preview

[![Dashboard 1](https://github.com/sakshigolambade/SBI-Insurance-Policy-Lapse-Renewal-Analytics/raw/main/dashboards/dashboard1.png)](dashboards/dashboard1.png)
[![Dashboard 2](https://github.com/sakshigolambade/SBI-Insurance-Policy-Lapse-Renewal-Analytics/raw/main/dashboards/dashboard2.png)](dashboards/dashboard2.png)
[![Dashboard 3](https://github.com/sakshigolambade/SBI-Insurance-Policy-Lapse-Renewal-Analytics/raw/main/dashboards/dashboard3.png)](dashboards/dashboard3.png)
[![Dashboard 4](https://github.com/sakshigolambade/SBI-Insurance-Policy-Lapse-Renewal-Analytics/raw/main/dashboards/dashboard4.png)](dashboards/dashboard4.png)

**Report pages:** Overview · Claims Analysis · Predictive Risk Scoring · Renewal Trends
**Features:** custom brand-color theme, synced cross-page slicers, icon-based navigation sidebar, conditional formatting, and written analytical insights on every page.

---

## 🗂️ Repository Structure
