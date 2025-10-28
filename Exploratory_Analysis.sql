-- Exploratory Data Analysis
-- Description: Point-in-time exploration of totals, rankings, and trends

-- Quick peek at the working (cleaned) table to confirm columns/rows

select *
from layoffs_staging2;


-- Find the single largest layoff event and the max percentage laid off

select max(total_laid_off), max(percentage_laid_off)
from layoffs_staging2;


-- Inspect companies that laid off 100% of staff (percentage_laid_off = 1)
-- Sorted by funds raised to see high-cap firms that completely shut down

select *
from layoffs_staging2
where percentage_laid_off = 1
order by funds_raised_millions desc;


-- Total layoffs by company (overall)
-- Useful for a top-10 chart or long-tail analysis

select company, sum(total_laid_off) as Total_Laid_Off
from layoffs_staging2
group by company
order by 2 desc;


-- Time coverage of the dataset (earliest and latest dates present)

SELECT MIN(`date`) AS min_date,
       MAX(`date`) AS max_date
FROM layoffs_staging2;


-- Total layoffs by industry

SELECT industry,
       SUM(total_laid_off) AS total_laid_off
FROM layoffs_staging2
GROUP BY industry
ORDER BY total_laid_off DESC;


-- Total layoffs by country

SELECT country,
       SUM(total_laid_off) AS total_laid_off
FROM layoffs_staging2
GROUP BY country
ORDER BY total_laid_off DESC;


-- Total layoffs by year (high-level time trend)

SELECT YEAR(`date`) AS `year`,
       SUM(total_laid_off) AS total_laid_off
FROM layoffs_staging2
GROUP BY YEAR(`date`)
ORDER BY `year` DESC;


-- Total layoffs by company stage (e.g., Seed, Series A, Public)

SELECT stage,
       SUM(total_laid_off) AS total_laid_off
FROM layoffs_staging2
GROUP BY stage
ORDER BY total_laid_off DESC;


-- Rolling total of layoffs by month (cumulative)

SELECT SUBSTRING(`date`, 1, 7) AS `month`,
       SUM(total_laid_off)    AS monthly_total
FROM layoffs_staging2
WHERE SUBSTRING(`date`, 1, 7) IS NOT NULL
GROUP BY `month`
ORDER BY `month` ASC;


-- Cumulative rolling total of layoffs across months

WITH rolling_total AS (
    SELECT SUBSTRING(`date`, 1, 7) AS `month`,
           SUM(total_laid_off)     AS monthly_total
    FROM layoffs_staging2
    WHERE SUBSTRING(`date`, 1, 7) IS NOT NULL
    GROUP BY `month`
)
SELECT `month`,
       monthly_total,
       SUM(monthly_total) OVER (ORDER BY `month`) AS rolling_total
FROM rolling_total
ORDER BY `month` ASC;


-- Company Layoffs & Rankings per Year
-- Goal: Identify top companies by total layoffs overall and by year.

-- Overall totals by company

SELECT company,
       SUM(total_laid_off) AS total_laid_off
FROM layoffs_staging2
GROUP BY company
ORDER BY total_laid_off DESC;


-- Yearly totals by company (for per-year ranking)

SELECT company,
       YEAR(`date`)        AS `year`,
       SUM(total_laid_off) AS total_laid_off
FROM layoffs_staging2
GROUP BY company, YEAR(`date`)
ORDER BY total_laid_off DESC;


-- Rank companies within each year by total layoffs (dense_rank)

WITH company_year AS (
    SELECT company,
           YEAR(`date`)        AS `year`,
           SUM(total_laid_off) AS total_laid_off
    FROM layoffs_staging2
    GROUP BY company, YEAR(`date`)
),
company_year_rank AS (
    SELECT *,
           DENSE_RANK() OVER (PARTITION BY `year`
                              ORDER BY total_laid_off DESC) AS ranking
    FROM company_year
    WHERE `year` IS NOT NULL
)

-- Top 5 companies per year by layoff count
SELECT company,
       `year`,
       total_laid_off,
       ranking
FROM company_year_rank
WHERE ranking <= 5
ORDER BY `year` DESC, ranking ASC;