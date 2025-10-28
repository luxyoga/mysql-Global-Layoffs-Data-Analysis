# MySQL – Global Layoffs Data Analysis (Data Cleaning + Exploratory Data Analysis)

## Overview
This project was built in **MySQL Workbench** to demonstrate real-world data cleaning, transformation, and analytical skills using SQL.  
It explores a dataset of **global layoffs (2020–2023)** to identify trends, affected industries, and company-level insights.

The project consists of two key phases:
1. **Data Cleaning** – preparing the raw dataset for accurate analysis  
2. **Exploratory Data Analysis (EDA)** – uncovering insights and trends from the cleaned data  

---

## Dataset

| File | Description |
|------|--------------|
| layoffs_raw.csv | Original dataset containing global layoff information |
| layoffs_cleaned.csv | Final cleaned dataset after transformation and formatting |
| Source | Publicly available layoffs data (2020–2023) |

Each record includes:
- Company  
- Industry  
- Country  
- Stage  
- Funds Raised (Millions)  
- Date  
- Total Laid Off  
- Percentage Laid Off  

---

## Part 1 – Data Cleaning (SQL)

### Objective
Transform the messy raw data into a clean, structured, and analysis-ready table by:
- Removing duplicates  
- Standardizing text fields and date formats  
- Handling NULL and missing values  
- Cleaning up helper columns  

### Cleaning Steps

| Step | Description | SQL Techniques |
|------|--------------|----------------|
| 1 | Remove duplicates using ROW_NUMBER() and PARTITION BY to identify duplicates, then delete rows where row_num > 1 | CTE, ROW_NUMBER(), DELETE |
| 2 | Standardize text fields such as company and industry names, and correct country names | TRIM(), LIKE, UPDATE |
| 3 | Convert text dates into proper DATE format | STR_TO_DATE(), ALTER TABLE |
| 4 | Backfill missing industries and remove null rows | JOIN, UPDATE, DELETE |
| 5 | Drop helper columns used during cleaning | ALTER TABLE DROP COLUMN |

### Example Queries
```sql
-- Remove duplicate rows
DELETE
FROM layoffs_staging2
WHERE row_num > 1;

-- Standardize company names
UPDATE layoffs_staging2
SET company = TRIM(company);

-- Normalize industry names
UPDATE layoffs_staging2
SET industry = 'Crypto'
WHERE industry LIKE 'Crypto%';

-- Fix country format
UPDATE layoffs_staging2
SET country = TRIM(TRAILING '.' FROM country)
WHERE country LIKE 'United States%';

-- Convert text dates to DATE type
UPDATE layoffs_staging2
SET date = STR_TO_DATE(date, '%Y-%m-%d');
ALTER TABLE layoffs_staging2
MODIFY COLUMN date DATE;
```

### Outcome

- Clean, deduplicated dataset stored as layoffs_staging2
- All columns standardized and formatted
- Exported final dataset as layoffs_cleaned.csv

---

## Part 2 – Exploratory Data Analysis (EDA)

### Objective
Analyze global layoff data to uncover high-level trends, key affected industries, and year-over-year changes.

### Analytical Focus

| Category | Question Answered |
|------|--------------|
| Company | Which companies experienced the largest layoffs? |
| Industry | Which sectors were most impacted? |
| Country | Which regions were affected most? |
| Year | How did layoffs evolve annually? |
| Stage | Were startups or public companies hit harder? |
| Rolling Trends | How did layoffs accumulate month-to-month? |
| Ranking | Which were the top 5 companies by layoffs each year? |

### Example Queries
```sql
-- Total layoffs by industry
SELECT industry, SUM(total_laid_off) AS total_laid_off
FROM layoffs_staging2
GROUP BY industry
ORDER BY total_laid_off DESC;

-- Rolling total of layoffs by month
WITH rolling_total AS (
  SELECT SUBSTRING(date, 1, 7) AS month,
         SUM(total_laid_off) AS monthly_total
  FROM layoffs_staging2
  WHERE SUBSTRING(date, 1, 7) IS NOT NULL
  GROUP BY month
)
SELECT month,
       monthly_total,
       SUM(monthly_total) OVER (ORDER BY month) AS rolling_total
FROM rolling_total;

-- Top 5 companies per year by layoffs
WITH company_year AS (
  SELECT company,
         YEAR(date) AS year,
         SUM(total_laid_off) AS total_laid_off
  FROM layoffs_staging2
  GROUP BY company, YEAR(date)
),
company_year_rank AS (
  SELECT *,
         DENSE_RANK() OVER (PARTITION BY year ORDER BY total_laid_off DESC) AS ranking
  FROM company_year
)
SELECT company, year, total_laid_off, ranking
FROM company_year_rank
WHERE ranking <= 5
ORDER BY year DESC, ranking;
```

### Key Insights

- 2022–2023 experienced the highest volume of global layoffs
- Tech, Crypto, and Retail were the hardest-hit industries
- United States accounted for the largest share of total layoffs
- Late-stage and public companies led in absolute layoffs, while startups had higher relative percentages
- Rolling monthly totals show a sharp increase starting mid-2022, peaking in early 2023

### Tools and Techniques

- MySQL Workbench – database creation, cleaning, and analysis
- SQL Concepts: CTEs, Window Functions, Joins, Aggregations, Ranking
- Data Cleaning: String operations, date conversion, NULL handling
- Analysis: Grouped aggregations, rolling totals, ranking queries
- Next Steps: Tableau or Power BI for visualization

### Project Learnings

- Built a complete SQL data-cleaning pipeline from raw CSV to clean dataset
- Strengthened use of CTEs, window functions, and aggregate logic for EDA
- Improved ability to identify and resolve real-world data quality issues





