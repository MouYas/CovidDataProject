
/*
Covid 19 Data Exploration 

Skills used: Joins, CTE's, Temp Tables, Windows Functions, Aggregate Functions, Creating Views, Converting Data Types

*/


SELECT *
FROM covidProject..CovidDeaths
WHERE continent IS NOT NULL
ORDER BY 3,4;

SELECT *
FROM covidProject..CovidVaccinations
WHERE continent IS NOT NULL
ORDER BY 3,4;


-- Select Data that we are going to be starting with

SELECT location, date, new_cases, total_cases,  total_deaths, population
FROM covidProject..CovidDeaths
ORDER BY 1,2;


-- Total Cases vs Total Deaths

SELECT location, date, total_cases,  total_deaths, ROUND((total_deaths/total_cases)*100,2) as percentage_deaths
FROM covidProject..CovidDeaths
WHERE total_cases IS NOT NULL
--AND location LIKE '%%' --Add text between percentage signs to check date for specific country
ORDER BY 1,2;


-- Total Cases vs Population

SELECT location, date, total_deaths, total_cases, population , ROUND((total_cases/population)*100,3) as percent_population_infected
FROM covidProject..CovidDeaths
WHERE total_cases IS NOT NULL
ORDER BY 1,2;


--Countries with Highest Infection Rate compared to Population --Tableau 3 4

SELECT location, population ,MAX(total_cases) AS max_cases,  MAX(ROUND((total_cases/population)*100,3)) as percent_population_infected
FROM covidProject..CovidDeaths
WHERE total_cases IS NOT NULL
GROUP BY location,population
ORDER BY percent_population_infected DESC;

SELECT location, population, date,MAX(total_cases) AS max_cases,  MAX(ROUND((total_cases/population)*100,3)) as percent_population_infected
FROM covidProject..CovidDeaths
WHERE total_cases IS NOT NULL
GROUP BY location,population,date
ORDER BY percent_population_infected DESC;


-- Countries with Highest Death Count

SELECT location, max(cast (total_deaths as int)) AS total_death_count
FROM covidProject..CovidDeaths
WHERE continent IS NOT NULL
GROUP BY location
ORDER BY total_death_count desc;


-- Showing Contintents with the Highest Death Count per Population --Tableau 2

SELECT location, max(cast (total_deaths as int)) AS total_death_count
FROM covidProject..CovidDeaths
WHERE continent IS NULL
AND location NOT IN ('World', 'European Union','International')
GROUP BY location
ORDER BY total_death_count desc;


--Showing Vaccination count by Continent --Tableau 8
SELECT d.location,
SUM(cast(v.new_vaccinations as numeric)) AS total_vaccinations
FROM covidProject..CovidDeaths AS d
JOIN covidProject..CovidVaccinations AS v
ON d.location= v.location AND
d.date = v.date
WHERE d.continent IS NULL
AND d.location NOT IN ('World', 'European Union','International')
GROUP BY d.location;


-- GLOBAL NUMBERS  --Tableau 1

Select SUM(new_cases) as total_cases, 
SUM(cast(new_deaths as int)) as total_deaths, 
SUM(cast(new_deaths as int))/SUM(New_Cases)*100 as death_percentage
FROM covidProject..CovidDeaths
WHERE continent IS NOT NULL 
ORDER BY 1,2


-- Global Vaccination Count --Tableau 5
SELECT
SUM(cast(v.new_vaccinations as numeric)) AS total_vaccinations
FROM covidProject..CovidDeaths AS d
JOIN covidProject..CovidVaccinations AS v
ON d.location= v.location AND
d.date = v.date
WHERE d.continent IS NULL
AND d.location NOT IN ('World', 'European Union','International');




--Global Death Rate per Day

SELECT
date, 
SUM(new_cases) AS global_new_cases, 
SUM(cast(new_deaths as int)) AS global_new_deaths,
(SUM(cast (new_deaths as int))/NULLIF(SUM(new_cases),0)) *100 AS global_death_rate
FROM covidProject..CovidDeaths
WHERE continent IS NULL
GROUP BY date
ORDER BY date;


--Rolling Vaccination Count By Country

SELECT d.continent, 
d.location, 
d.date, 
d.population, 
v.new_vaccinations, 
SUM(cast(v.new_vaccinations as int)) OVER (PARTITION BY d.location ORDER BY d.location,d.date) AS rolling_people_vaccinated
FROM covidProject..CovidDeaths AS d
JOIN covidProject..CovidVaccinations AS v
ON d.location= v.location AND
d.date = v.date
WHERE d.continent IS NOT NULL AND d.population IS NOT NULL
ORDER BY 2,3;


-- Using CTE to perform Calculation on Partition By in previous query

WITH total_vac AS 
(SELECT d.continent, 
d.location, 
d.date, 
d.population, 
v.new_vaccinations, 
SUM(cast(v.new_vaccinations as int)) OVER (PARTITION BY d.location ORDER BY d.location,d.date) AS rolling_vaccination_count
FROM covidProject..CovidDeaths AS d
JOIN covidProject..CovidVaccinations AS v
ON d.location= v.location AND
d.date = v.date
WHERE d.continent IS NOT NULL AND d.population IS NOT NULL
)



--SELECT location,date, population, rolling_vaccination_count, (rolling_vaccination_count/population)*100 AS percent_vaccinated
--FROM total_vac
--ORDER BY 1,2;

--Countries with Highest Vaccination Count VS Population -- Tableau 6
SELECT location,
MAX(date) AS max_date, 
population, 
MAX(rolling_vaccination_count) AS max_vaccination_count, 
MAX((rolling_vaccination_count/population)*100) AS vaccination_count_vs_population
FROM total_vac
GROUP BY location, population
ORDER BY vaccination_count_vs_population DESC;



--Creating a temp table

DROP TABLE IF EXISTS #PeopleFullyVaccinated
CREATE TABLE #PeopleFullyVaccinated
(continent nvarchar(255),
location nvarchar(255),
date datetime,
population numeric,
people_fully_vaccinated numeric)

INSERT INTO #PeopleFullyVaccinated (continent, location, date, population,people_fully_vaccinated)
SELECT d.continent, 
d.location, 
d.date, 
d.population, 
v.people_fully_vaccinated
FROM covidProject..CovidDeaths AS d
JOIN covidProject..CovidVaccinations AS v
ON d.location= v.location AND
d.date = v.date
WHERE d.continent IS NOT NULL AND d.population IS NOT NULL;

--Percentage fully vaccinated by country and date

SELECT *, (people_fully_vaccinated/population)*100 AS percent_fully_vaccinated
FROM #PeopleFullyVaccinated
order by 2,3;


--Countries with Highest Percentage of Population Fully Vaccinated --Tableau 7


SELECT location,
MAX(date) AS latest_date, 
population,
MAX(people_fully_vaccinated) AS max_people_fully_vaccinated,
MAX((people_fully_vaccinated/population)*100) as percent_fully_vaccinated
FROM #PeopleFullyVaccinated
GROUP BY location, population
ORDER BY 5 desc;


-- Creating View to Store Data for Later Visualizations

 CREATE VIEW PostitiveTestRate AS
 SELECT d.continent,
 d.location,
 d.date,
 d.population,
 v.total_tests,
 v.positive_rate
 FROM covidProject.dbo.CovidDeaths as d
 JOIN covidProject.dbo.CovidVaccinations as v
 ON d.location=v.location AND
 d.date=v.date 
 WHERE d.continent IS NOT NULL AND d.population IS NOT NULL;


  WITH total_tests_by_country AS
  (SELECT  DISTINCT location, 
 max(date) OVER (PARTITION BY location) AS latest_date
 ,max(total_tests) OVER (PARTITION BY location) AS total_tests
 FROM covidProject.dbo.PostitiveTestRate)

 SELECT *
 FROM total_tests_by_country;