-- DATA CLEANING: layoffs_staging → layoffs_staging2
-- Tasks:
--   1) Remove duplicates
--   2) Standardize data (strings, dates, country formatting)
--   3) Address NULL / missing values
--   4) Remove helper columns/rows


-- =========================
-- 1) IDENTIFY DUPLICATES
--    (Quick check on the source staging table)
-- =========================

SELECT *,
       ROW_NUMBER() OVER (
         PARTITION BY company, industry, total_laid_off, percentage_laid_off, `date`
       ) AS row_num
FROM layoffs_staging;


-- ===========================================================
-- 2) CREATE A DEDUPED WORKING TABLE (layoffs_staging2)
--    We'll copy data + a row_num for duplicate removal.
-- ===========================================================

-- (Note) Some MySQL versions don’t allow DELETE directly from a CTE,
-- so we’ll materialize into a new table and delete by row_num there.

CREATE TABLE `layoffs_staging2` (
  `company` TEXT,
  `location` TEXT,
  `industry` TEXT,
  `total_laid_off` INT DEFAULT NULL,
  `percentage_laid_off` TEXT,
  `date` TEXT,
  `stage` TEXT,
  `country` TEXT,
  `funds_raised_millions` INT DEFAULT NULL,
  `row_num` INT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

-- Confirm the empty schema
SELECT *
FROM layoffs_staging2;

-- Insert source data and compute row_num to mark duplicates
INSERT INTO layoffs_staging2
SELECT *,
       ROW_NUMBER() OVER (
         PARTITION BY company, location, industry, total_laid_off,
                      percentage_laid_off, `date`, stage, country, funds_raised_millions
       ) AS row_num
FROM layoffs_staging;

-- Allow deletes without key-in-WHERE (Workbench safe mode uses this)
SET SQL_SAFE_UPDATES = 0;

-- Remove duplicate rows (keep row_num = 1)
DELETE
FROM layoffs_staging2
WHERE row_num > 1;


-- =======================================
-- 3) STANDARDIZE DATA (strings & formats)
-- =======================================

-- Company names: remove leading/trailing whitespace
SELECT company, TRIM(company) AS company_trimmed
FROM layoffs_staging2;

UPDATE layoffs_staging2
SET company = TRIM(company);

-- Industry: normalize “Crypto” variations (e.g., 'Cryptocurrency', 'Crypto - Exchange', etc.)
SELECT DISTINCT industry
FROM layoffs_staging2;

UPDATE layoffs_staging2
SET industry = 'Crypto'
WHERE industry LIKE 'Crypto%';

-- Location quick scan (helps spot typos/inconsistencies)
SELECT DISTINCT location
FROM layoffs_staging2
ORDER BY 1;

-- Country: remove trailing periods and standardize
SELECT DISTINCT country, TRIM(TRAILING '.' FROM country) AS country_trimmed
FROM layoffs_staging2
ORDER BY 1;

UPDATE layoffs_staging2
SET country = TRIM(TRAILING '.' FROM country)
WHERE country LIKE 'United States%';  -- adjust case as needed for your data

-- Dates: convert text → DATE
-- First, parse to a yyyy-mm-dd DATE, then change column type.
SELECT `date`
FROM layoffs_staging2;

UPDATE layoffs_staging2
SET `date` = STR_TO_DATE(`date`, '%Y-%m-%d');

ALTER TABLE layoffs_staging2
MODIFY COLUMN `date` DATE;


-- ============================================
-- 4) ADDRESS NULL / MISSING VALUES
-- ============================================

-- Rows where both total_laid_off and percentage_laid_off are NULL
-- (often not useful for analysis; we’ll delete later)
SELECT *
FROM layoffs_staging2
WHERE total_laid_off IS NULL
  AND percentage_laid_off IS NULL;

-- Turn empty-string industries into NULL for consistent handling
UPDATE layoffs_staging2
SET industry = NULL
WHERE industry = '';

-- Review remaining empty/NULL industries
SELECT *
FROM layoffs_staging2
WHERE industry IS NULL
   OR industry = '';

-- Spot check a specific company with missing industry
SELECT *
FROM layoffs_staging2
WHERE company LIKE 'Bally%';

-- Backfill missing industry values using other rows from the same company
-- (self-join to copy a known industry when available)
SELECT *
FROM layoffs_staging2 t1
JOIN layoffs_staging2 t2
  ON t1.company = t2.company
WHERE (t1.industry IS NULL OR t1.industry = '')
  AND t2.industry IS NOT NULL;

UPDATE layoffs_staging2 t1
JOIN layoffs_staging2 t2
  ON t1.company = t2.company
SET t1.industry = t2.industry
WHERE t1.industry IS NULL
  AND t2.industry IS NOT NULL;

-- Remove rows that have no layoff metrics at all
DELETE
FROM layoffs_staging2
WHERE total_laid_off IS NULL
  AND percentage_laid_off IS NULL;

-- Quick sanity check
SELECT *
FROM layoffs_staging2;


-- ============================================
-- 5) DROP HELPER COLUMN(S)
--    (row_num was only for duplicate removal)
-- ============================================
ALTER TABLE layoffs_staging2
DROP COLUMN row_num;


-- ======================================================================
-- CLEANING COMPLETE
--   ✓ Removed duplicates
--   ✓ Standardized strings (company, industry, country) and dates
--   ✓ Addressed NULL/missing values (backfilled or removed)
--   ✓ Dropped helper columns
-- ======================================================================