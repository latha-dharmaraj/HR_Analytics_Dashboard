CREATE DATABASE hr_analytics_db;
USE hr_analytics_db;
SELECT * FROM hr_tbl;
RENAME TABLE ht_tbl TO hr_tbl;

ALTER TABLE hr_tbl
RENAME COLUMN ï»¿id TO emp_id;

DESCRIBE hr_tbl;

-- to change date format
SET SQL_SAFE_UPDATES = 0;
UPDATE hr_tbl
SET birthdate = 
CASE 
	WHEN birthdate LIKE '%/%' THEN DATE_FORMAT(STR_TO_DATE(birthdate,'%m/%d/%Y'),'%Y-%m-%d')
    WHEN birthdate LIKE '%-%' THEN DATE_FORMAT(STR_TO_DATE(birthdate,'%m-%d-%Y'),'%Y-%m-%d')
    ELSE NULL
END;

-- to change datatype of birthdate column
ALTER TABLE hr_tbl
MODIFY COLUMN birthdate DATE;

-- change the date format and datatype of hire_date

UPDATE hr_tbl
SET hire_date =
CASE 
	WHEN hire_date LIKE '%/%' THEN DATE_FORMAT(STR_TO_DATE(hire_date,'%m/%d/%Y'),'%Y-%m-%d')
    WHEN hire_date LIKE '%-%' THEN DATE_FORMAT(STR_TO_DATE(hire_date,'%m-%d-%Y'),'%Y-%m-%d')
    ELSE NULL
END;

ALTER TABLE hr_tbl
MODIFY COLUMN hire_date DATE;

UPDATE hr_tbl
SET termdate = DATE(STR_TO_DATE(termdate,'%Y-%m-%d %H:%i:%s UTC'))
WHERE termdate IS NOT NULL AND termdate !='';

UPDATE hr_tbl 
SET termdate = NULL
WHERE termdate ='';

-- create age column
ALTER TABLE hr_tbl
ADD COLUMN age INT;

UPDATE hr_tbl
SET age = timestampdiff(YEAR,birthdate,curdate());

SELECT MAX(age) AS maximum_age, MIN(age) AS minimum_age FROM hr_tbl;

-- 1. What is the gender breakdown of employees in the company
SELECT gender, COUNT(*) AS count FROM hr_tbl
GROUP BY gender;

-- 2. What is the race breakdown of employees in the company
SELECT race, COUNT(*) AS count FROM hr_tbl
WHERE termdate IS NULL 
GROUP BY race;

-- 3. What is the age distribution of employees in the company
SELECT 
	CASE
		WHEN age>=18 AND age<=24 THEN '18-24'
        WHEN age>=25 AND age<=34 THEN '25-34'
        WHEN age>=35 AND age<=44 THEN '35-44'
        WHEN age>=45 AND age<=54 THEN '45-54'
        WHEN age>=55 AND age<=64 THEN '55-64'
        ELSE '65+'
	END AS age_group,
COUNT(*) AS count FROM hr_tbl
WHERE termdate IS NULL 
GROUP BY age_group
ORDER BY age_group;
    
-- 4. How many employees work at HQ vs remote
SELECT location, COUNT(*) AS count
FROM hr_tbl
WHERE termdate IS NULL
GROUP BY location;

-- 5. What is the average length of employement who have been terminated
SELECT ROUND(AVG(year(termdate) - year(hire_date)),0) AS length_of_emp
FROM hr_tbl
WHERE termdate IS NOT NULL AND termdate <=curdate();

-- 6. How does the gender distribution vary across department and jobtitle
SELECT department, jobtitle, gender, COUNT(*) AS count FROM hr_tbl
WHERE termdate IS NOT NULL
GROUP BY department, jobtitle, gender
ORDER BY department, jobtitle, gender;

-- 7. What is the distribution of jobtitles across the company
SELECT jobtitle, COUNT(*) AS count
FROM hr_tbl
WHERE termdate IS NOT NULL 
GROUP BY jobtitle;

-- 8. Which dept has the higher turnover/termination rate
SELECT * FROM hr_tbl;

SELECT department, COUNT(*) AS total_count, 
	COUNT(CASE
				WHEN termdate IS NOT NULL AND termdate <= curdate() THEN 1
		 END) AS terminated_count,
	ROUND((COUNT(CASE
				WHEN termdate IS NOT NULL AND termdate <= curdate() THEN 1
		 END)/ COUNT(*))*100,2) AS termination_rate
	FROM hr_tbl
    GROUP BY department
    ORDER BY termination_rate DESC;
    
-- 9. What is the distribution of employees across location_state
SELECT location_state, COUNT(*) AS count FROM hr_tbl
WHERE termdate IS NULL
GROUP BY location_state;

-- 10. How has the company's employee count changed over time based on hire and termination date
SELECT year, 
	   hires, 
	   terminations, 
	   hires-terminations AS net_change, 
	   (terminations/hires)*100 AS change_percent
   FROM(
		SELECT YEAR(hire_date) AS year, 
        COUNT(*) AS hires, 
        SUM(CASE
				WHEN termdate IS NOT NULL AND termdate <= curdate() THEN 1
            END) AS terminations
		FROM hr_tbl
        GROUP BY YEAR(hire_date)) AS subquery
GROUP BY year
ORDER BY year;

-- 11. What is the tenure distribution for each dept 
SELECT department, ROUND(AVG(datediff(termdate, hire_date)/365),0) AS avg_tenure
FROM hr_tbl
WHERE termdate IS NOT NULL AND termdate <= curdate()
GROUP BY department;

-- 12. termination and hire breakdown gender wise
SELECT gender, 
	total_hires, 
	total_terminations, 
	ROUND((total_terminations/total_hires)*100,2) AS termination_rate
FROM(
		SELECT gender, 
        COUNT(*) AS total_hires,
        COUNT(CASE 
				WHEN termdate IS NOT NULL AND termdate <= curdate() THEN 1
                END) AS total_terminations
		FROM hr_tbl 
		GROUP BY gender) AS subquery
GROUP BY gender;

-- 13. age 
SELECT
	age,
    total_hires,
    total_terminations,
	ROUND((total_terminations/total_hires)*100,2) AS termination_rate
FROM(
		SELECT age, 
        COUNT(*) AS total_hires,
        COUNT(CASE 
				WHEN termdate IS NOT NULL AND termdate <= curdate() THEN 1
                END) AS total_terminations
		FROM hr_tbl 
		GROUP BY age) AS subquery
GROUP BY age
ORDER BY age;

-- 14. race wise termination
SELECT
	race,
    total_hires,
    total_terminations,
	ROUND((total_terminations/total_hires)*100,2) AS termination_rate
FROM(
		SELECT race, 
        COUNT(*) AS total_hires,
        COUNT(CASE 
				WHEN termdate IS NOT NULL AND termdate <= curdate() THEN 1
                END) AS total_terminations
		FROM hr_tbl 
		GROUP BY race) AS subquery
GROUP BY race
ORDER BY race;

-- total employees count
SELECT COUNT(*) AS Total_Employees FROM hr_tbl;

-- active employees count
SELECT COUNT(*) AS Active_Employees FROM hr_tbl
WHERE termdate IS NULL;
      
-- terminated employees count
SELECT COUNT(*) AS Terminated_Employees FROM hr_tbl
WHERE termdate IS NOT NULL;       