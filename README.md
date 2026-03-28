# Market Basket Analysis and Product Recommendation System

## About the Project

This project looks at retail transaction data to understand basket behavior and product relationships. The main idea was to find which products are often bought together and turn those patterns into recommendation-oriented insights.

I built this project using:
- **Python** for data cleaning, basket transformation, Apriori, and association rules
- **SQL Server** for data import, validation, and basket-level business analysis
- **Power BI** for the final dashboard and presentation layer

---

## Problem Statement

Retail businesses often want to know:
- which products are commonly purchased together
- which products can be recommended alongside another product
- how basket behavior looks across invoices
- how these patterns can support cross-selling or bundling

This project was built to answer those questions using transaction-level retail data.

---

## What I Did

### In Python
- cleaned the raw transaction data
- removed cancelled and invalid records
- created a basket-format invoice-product matrix
- applied the **Apriori algorithm**
- generated **association rules**
- built a cleaner recommendation table using support, confidence, and lift

### In SQL Server
- created a raw staging table and a final typed transaction table
- validated the imported data using conversion checks
- analyzed:
  - invoice counts
  - product counts
  - customer counts
  - basket size and basket value
  - product presence across invoices
  - top co-purchased product pairs
  - monthly invoice and revenue trends

### In Power BI
I created a 3-page dashboard:

#### 1. Retail & Basket Overview
- total revenue
- total invoices
- total products
- total customers
- average basket size
- average basket value
- monthly invoice and revenue trend
- top products by invoice presence

#### 2. Product Association Insights
- top co-purchased product pairs
- recommendation rules by confidence and lift
- recommendation rules table

#### 3. Recommendation Explorer
- product selector
- filtered recommendation table

---

## Key Insights

- The dataset contains rich invoice baskets, which makes it suitable for market basket analysis.
- Several products repeatedly appear together across many invoices.
- Association rules revealed strong relationships between related product variants and themed items.
- The SQL co-purchase analysis supported the same basket patterns observed in Python.
- Monthly trend analysis showed that late 2011, especially November, was a high-activity period in both invoice count and revenue.

---

## Tools Used

- Python
- pandas
- numpy
- mlxtend
- SQL Server / SSMS
- Power BI

---

## Project Files

- `Market Basket Analysis and Product Recommendation System using Online Retail Data.ipynb`  
  Main Python notebook

- `Online Retail.sql`  
  SQL Server script used for import, validation, and business analysis

- `recommendation_rules.csv`  
  Recommendation rules exported from Python

- `kpi_summary_sql.csv`  
- `monthly_trend_sql.csv`  
- `product_presence_sql.csv`  
- `product_pairs_sql.csv`  
  SQL-based summary tables used in Power BI

- Power BI dashboard screenshots / `.pbix` file

---

## Why I Built This

I wanted this project to be more than a basic sales dashboard. My goal was to create something that combined:
- transaction-level analysis
- recommendation logic
- SQL-based business querying
- dashboard storytelling

This project helped me practice how Python, SQL Server, and Power BI can work together in a realistic analytics workflow.

---

## Author

**Nikhitha Mamidi**