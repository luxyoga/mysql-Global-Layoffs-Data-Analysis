# 💼 MySQL Portfolio Project – Global Layoffs Data (Data Cleaning + Exploratory Data Analysis)

### 👋 Overview
This project was built in **MySQL Workbench** to demonstrate real-world data cleaning, transformation, and analytical skills using SQL.  
It explores a dataset of **global layoffs (2020–2023)** to identify trends, affected industries, and company-level insights.

The project consists of two key phases:
1. **Data Cleaning** – preparing the raw dataset for accurate analysis  
2. **Exploratory Data Analysis (EDA)** – uncovering insights and trends from the cleaned data  

---

## 🧱 Dataset

| File | Description |
|------|--------------|
| `layoffs_raw.csv` | Original dataset containing global layoff information |
| `layoffs_cleaned.csv` | Final cleaned dataset after transformation and formatting |
| Source | *Publicly available layoffs data (2020–2023)* |

Each record includes:
- **Company**, **Industry**, **Country**, **Stage**, **Funds Raised (Millions)**  
- **Date**, **Total Laid Off**, and **Percentage Laid Off**

---

## 🧹 Part 1 – Data Cleaning (SQL)

### 🎯 Objective
Transform the messy raw data into a clean, structured, and analysis-ready table through:
- Removing duplicates  
- Standardizing text fields and date formats  
- Handling NULL and missing values  
- Cleaning up helper columns  

### 🧾 Cleaning Steps

| Step | Description | SQL Techniques |
|------|--------------|----------------|
| **1. Remove Duplicates** | Used `ROW_NUMBER()` and `PARTITION BY` to identify duplicates, removed rows where `row_num > 1`. | `CTE`, `ROW_NUMBER()`, `DELETE` |
| **2. Standardize Text** | Trimmed whitespace, normalized company/industry names, corrected country names. | `TRIM()`, `LIKE`, `UPDATE` |
| **3. Fix Dates** | Converted string dates to proper SQL `DATE` type. | `STR_TO_DATE()`, `ALTER TABLE` |
| **4. Handle Missing Values** | Backfilled missing industry names via self-joins and removed null rows. | `JOIN`, `UPDATE`, `DELETE` |
| **5. Cleanup** | Dropped helper columns like `row_num`. | `ALTER TABLE DROP COLUMN` |

### ⚙️ Example Queries
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

-- Fix country format and trailing characters
UPDATE layoffs_staging2
SET country = TRIM(TRAILING '.' FROM country)
WHERE country LIKE 'United States%';

-- Convert text dates to DATE type
UPDATE layoffs_staging2
SET `date` = STR_TO_DATE(`date`, '%Y-%m-%d');
ALTER TABLE layoffs_staging2
MODIFY COLUMN `date` DATE;
