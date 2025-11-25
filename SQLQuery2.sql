select *
from covidProject..CovidDeaths
WHERE continent IS NOT NULL
order by 3,4;

select *
from covidProject..CovidVaccinations
order by 3,4;

select location, date, new_cases, total_cases,  total_deaths, population
from covidProject..CovidDeaths
order by 1,2;

-- total cases vs deaths

select location, date, total_cases,  total_deaths, ROUND((total_deaths/total_cases)*100,2) as percentage_deaths
from covidProject..CovidDeaths
WHERE total_cases is not null
and location like '%land%'
order by 1,2;


-- total cases vs population
select location, date, total_deaths, total_cases, population , ROUND((total_cases/population)*100,3) as percentage_of_pop
from covidProject..CovidDeaths
WHERE total_cases is not null
order by 1,2;


--countries with highest infection rate
select location, population ,MAX(total_cases) AS max_cases,  MAX(ROUND((total_cases/population)*100,3)) as percentage_of_pop
from covidProject..CovidDeaths
WHERE total_cases is not null
GROUP BY location,population
order by percentage_of_pop DESC;

--countries with highest deaths
select location, max(cast (total_deaths as int)) AS max_death_rate
from covidProject..CovidDeaths
WHERE continent is not null
GROUP BY location
ORDER BY max_death_rate desc;

--continent deaths
select location, max(cast (total_deaths as int)) AS max_death_rate
from covidProject..CovidDeaths
WHERE continent is null
GROUP BY location
ORDER BY max_death_rate desc;

--Global 
SELECT
date, 
SUM(new_cases) AS global_new_cases, 
SUM(cast(new_deaths as int)) AS global_new_deaths,
(SUM(cast (new_deaths as int))/NULLIF(SUM(new_cases),0)) *100 AS global_death_rate
from covidProject..CovidDeaths
WHERE continent is null
GROUP BY date
ORDER BY date;


SELECT d.continent, 
d.location, 
d.date, 
d.population, 
v.new_vaccinations, 
SUM(cast(v.new_vaccinations as int)) OVER (PARTITION BY d.location ORDER BY d.location,d.date) AS total_vac_per_cou
FROM covidProject..CovidDeaths AS d
JOIN covidProject..CovidVaccinations AS v
ON d.location= v.location AND
d.date = v.date
WHERE d.continent IS NOT NULL AND d.population IS NOT NULL
ORDER BY 2,3;


WITH total_vac AS 
(SELECT d.continent, 
d.location, 
d.date, 
d.population, 
v.new_vaccinations, 
SUM(cast(v.new_vaccinations as int)) OVER (PARTITION BY d.location ORDER BY d.location,d.date) AS total_vac_per_cou
FROM covidProject..CovidDeaths AS d
JOIN covidProject..CovidVaccinations AS v
ON d.location= v.location AND
d.date = v.date
WHERE d.continent IS NOT NULL AND d.population IS NOT NULL
--ORDER BY 2,3)
)



--SELECT location,date, population, total_vac_per_cou, (total_vac_per_cou/population)*100 AS percent_vaccinated
--FROM total_vac
--ORDER BY 1,2;


SELECT location,MAX(date), population, MAX(total_vac_per_cou), MAX((total_vac_per_cou/population)*100) AS vaccinations_vs_population
FROM total_vac
GROUP BY location, population
ORDER BY vaccinations_vs_population DESC;



--Creating a temp table

DROP TABLE IF EXISTS #PeopleFullyVaccinated
CREATE TABLE #PeopleFullyVaccinated
(continent nvarchar(255),
location nvarchar(255),
date datetime,
population numeric,
people_fully_vaccinated numeric)


INSERT INTO #PeopleFullyVaccinated
SELECT d.continent, 
d.location, 
d.date, 
d.population, 
v.people_fully_vaccinated
FROM covidProject..CovidDeaths AS d
JOIN covidProject..CovidVaccinations AS v
ON d.location= v.location AND
d.date = v.date
WHERE d.continent IS NOT NULL AND d.population IS NOT NULL
--ORDER BY 2,3)

SELECT location,
MAX(date), 
population,
MAX(people_fully_vaccinated) AS max_people_fully_vaccinated,
MAX((people_fully_vaccinated/population)*100) as percent_fully_vaccinated
FROM #PeopleFullyVaccinated
GROUP BY location, population
ORDER BY 5 desc;


--CREATING A VIEW
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

