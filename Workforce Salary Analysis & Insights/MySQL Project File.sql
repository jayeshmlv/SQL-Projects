-- Task1 You need to count how many employees are working in different companies, categorized by size (S, M, L).

SELECT
    company_size,
    COUNT(employee_id) AS employee_count
FROM workforce
WHERE work_year = 2021
GROUP BY company_size;

-- Task2 Top 3 job titles with the highest average salary for 
-- part-time positions in 2023 & only include countries with more than 50 employees

SELECT
    job_title,
    AVG(salary_in_usd) AS avg_salary
FROM workforce
WHERE employment_type = 'PT'
  AND work_year = 2023
GROUP BY job_title
HAVING COUNT(*) > 50
ORDER BY avg_salary DESC
LIMIT 3;

-- Task3  Identify countries where the average salary for mid-level 
-- employees (MI) is greater than the overall average for that level in 2023:

SELECT
	company_location,
    ROUND(AVG(salary),2) AS average_salary
FROM workforce
WHERE work_year = "2023" AND experience_level = "MI"
GROUP BY company_location
HAVING AVG(salary) > (SELECT AVG(salary)
						FROM workforce
						WHERE work_year = "2023" AND experience_level = "MI")
ORDER BY average_salary DESC;

-- Task4  Identify which countries pay seniorlevel (SE) employees the highest and lowest average salaries in 2023

WITH cte AS
(
SELECT
	company_location,
    AVG(salary) AS average_salary
FROM workforce
WHERE experience_level = "SE" AND work_year = "2023"
GROUP BY company_location
)

-- Country with highest average salary
SELECT * FROM cte
ORDER BY average_salary DESC
LIMIT 1;

-- Country with lowest average salary
SELECT * FROM cte
ORDER BY average_salary
LIMIT 1;

-- Task5 Calculate the percentage increase in salaries for various job titles between two years (e.g., 2023 and 2024).

WITH cte_2023 AS
(
SELECT
	job_title,
    ROUND(AVG(salary),2) AS avg_salary_2023
FROM workforce
WHERE work_year = 2023
GROUP BY job_title
)
,
cte_2024 AS
(
SELECT
	job_title,
    ROUND(AVG(salary),2) AS avg_salary_2024
FROM workforce
WHERE work_year = 2024
GROUP BY job_title
)

SELECT 
	cte_2023.job_title,
    avg_salary_2023,
    avg_salary_2024,
    ROUND((avg_salary_2024 - avg_salary_2023)*100.0 / avg_salary_2023,2) AS percentage_change
FROM cte_2023 JOIN cte_2024
ON cte_2023.job_title = cte_2024.job_title;

-- Task6 Top three countries with the highest salary growth for entrylevel roles from 2020 to 2023.

WITH cte_2020 AS
(
SELECT
	company_location,
    ROUND(AVG(salary),2) AS avg_salary_2020
FROM workforce
WHERE work_year = 2020 AND experience_level = "EN"
GROUP BY company_location
)
,
cte_2023 AS
(
SELECT
	company_location,
    ROUND(AVG(salary),2) AS avg_salary_2023
FROM workforce
WHERE work_year = 2023 AND experience_level = "EN"
GROUP BY company_location
)

SELECT 
	cte_2020.company_location,
    avg_salary_2020,
    avg_salary_2023,
    ROUND((avg_salary_2023 - avg_salary_2020)*100.0 / avg_salary_2020,2) AS percentage_change
FROM cte_2020 JOIN cte_2023
ON cte_2020.company_location = cte_2023.company_location
ORDER BY percentage_change DESC
LIMIT 3;


-- Task7 Update remote work ratio for employees earning more than $90,000 in the US and AU

UPDATE workforce
SET remote_ratio = "100"
WHERE salary > 90000 AND employee_residence IN ("US", "AU");

-- Task8  Update the salaries for various experience levels (SE, MI, etc.) according to predefined percentage increases

UPDATE workforce
SET salary = salary *
	CASE
		WHEN experience_level = 'SE' THEN 1.22
		WHEN experience_level = 'MI' THEN 1.30
		WHEN experience_level = 'EN' THEN 1.35
		WHEN experience_level = 'EX' THEN 1.20
		ELSE 1
	END
WHERE work_year = 2024;

-- Task9 Identify which year had the highest average salary for each job title.

WITH cte AS (
    SELECT
        job_title,
        work_year,
        AVG(salary_in_usd) AS avg_salary
    FROM workforce
    GROUP BY job_title, work_year
),
cte2 AS (
    SELECT
        job_title,
        work_year,
        avg_salary,
        ROW_NUMBER() OVER(PARTITION BY job_title ORDER BY avg_salary DESC) AS rnk
    FROM cte
)

SELECT *
FROM cte2
WHERE rnk = 1;

-- Task10 Calculate the percentage of full-time and part-time employees for each job title.

SELECT
	job_title,
    ROUND(SUM(CASE WHEN employment_type = "FT" THEN 1 ELSE 0 END)*100 / COUNT(*),2) AS ft_percentage,
    ROUND(SUM(CASE WHEN employment_type = "PT" THEN 1 ELSE 0 END)*100 / COUNT(*),2) AS pt_percentage
FROM workforce
GROUP BY job_title;

-- Task12 Top 5 countries with the most large companies

SELECT
	company_location,
    COUNT(*) AS L_companies_count
FROM workforce
WHERE company_size = 'L'
GROUP BY company_location
ORDER BY L_companies_count DESC
LIMIT 5;

-- Task13 Calculate the percentage of fully remote employees earning more than $100,000

SELECT
	ROUND(SUM(CASE WHEN remote_ratio = 100 AND salary > 100000 THEN 1 ELSE 0 END)*100 / COUNT(employee_id),2) AS remote_emp_percentage
FROM workforce;

-- Task14 Identify locations where entrylevel salaries surpass the market average.

SELECT
	company_location,
    ROUND(AVG(salary_in_usd),2) AS avg_en_salary
FROM workforce
WHERE experience_level = "EN"
GROUP BY company_location
HAVING avg_en_salary > (SELECT AVG(salary_in_usd) FROM workforce WHERE experience_level = "EN");

-- Task15  For each job title, identify which country pays the highest average salary.

WITH avg_cte AS
(
SELECT
	job_title,
    company_location,
    ROUND(AVG(salary_in_usd),2) AS avg_salary
FROM workforce
GROUP BY job_title, company_location
)
,
rnk_cte AS
(
SELECT
	*,
    ROW_NUMBER() OVER(PARTITION BY job_title ORDER BY avg_salary DESC) AS rnk
FROM avg_cte
)

SELECT * FROM rnk_cte WHERE rnk = 1;

-- Task16 Identify countries with consistent salary growth over the past three years.

WITH avg_cte AS
(
SELECT
	company_location,
	work_year,
    ROUND(AVG(salary_in_usd),2) AS avg_salary
FROM workforce
GROUP BY company_location, work_year
),

lag_cte AS
(
SELECT
	company_location,
	work_year,
    avg_salary,
    LAG(avg_salary) OVER(PARTITION BY company_location ORDER BY work_year) AS previous_salary
FROM avg_cte
)

SELECT 
	company_location
FROM lag_cte
WHERE previous_salary IS NOT NULL
		AND avg_salary > previous_salary
GROUP BY company_location
HAVING COUNT(*) >=2;

-- Task17 COMPARE THE ADOPTION OF FULLY REMOTE WORK ACROSS EXPERIENCE LEVELS BETWEEN 2021 AND 2024.

WITH cte_2021 AS (
    SELECT
        experience_level,
        100.0 * SUM(CASE WHEN remote_ratio = 100 THEN 1 ELSE 0 END) / COUNT(*) AS remote_2021
    FROM workforce
    WHERE work_year = 2021
    GROUP BY experience_level
),
cte_2024 AS (
    SELECT
        experience_level,
        100.0 * SUM(CASE WHEN remote_ratio = 100 THEN 1 ELSE 0 END) / COUNT(*) AS remote_2024
    FROM workforce
    WHERE work_year = 2024
    GROUP BY experience_level
)

SELECT
    c1.experience_level,
    ROUND(c1.remote_2021, 2) AS remote_2021,
    ROUND(c2.remote_2024, 2) AS remote_2024
FROM cte_2021 c1
LEFT JOIN cte_2024 c2
ON c1.experience_level = c2.experience_level;

-- Task18 Average salary increase percentage by experience level and job title (2023 to 2024):

WITH cte_2023 AS
(
SELECT
	experience_level,
    job_title,
    ROUND(AVG(salary_in_usd),2) AS avg_salary_2023
FROM workforce
WHERE work_year = 2023
GROUP BY experience_level, job_title
)
,
cte_2024 AS
(
SELECT
	experience_level,
    job_title,
    ROUND(AVG(salary_in_usd),2) AS avg_salary_2024
FROM workforce
WHERE work_year = 2024
GROUP BY experience_level, job_title
)

SELECT
	cte_2023.experience_level,
    cte_2023.job_title,
    avg_salary_2023,
    avg_salary_2024,
    (avg_salary_2024 - avg_salary_2023)*100.0 / avg_salary_2023 AS percentage_change
FROM cte_2023 JOIN cte_2024
ON cte_2023.experience_level = cte_2024.experience_level 
	AND cte_2023.job_title = cte_2024.job_title;