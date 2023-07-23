USE master;
GO

IF NOT EXISTS (
    SELECT name 
    FROM sys.databases
    WHERE name = N'ProjectDatabase'
    )
  CREATE DATABASE [ProjectDatabase];
GO

IF SERVERPROPERTY('ProductVersion') > '12'
   ALTER DATABASE [ProjectDatabase] SET QUERY_STORE = ON;
GO;

SELECT *
FROM ProjectDatabase..CovidDeath
WHERE continent IS NOT NULL
ORDER BY 3, 4

--SELECT *
--FROM ProjectDatabase..CovidVaccination
--ORDER BY 3, 4
--Select Data that we are going to be using

SELECT location, date, total_cases, new_cases, total_deaths, population
FROM ProjectDatabase..CovidDeath
WHERE continent IS NOT NULL
ORDER BY 1, 2


--Looking at Total Cases vs TOtal Deaths
--Shows likelihood of dying if you contract covid in your country
SELECT location, date, total_cases, total_deaths, (cast(total_deaths AS numeric)/ cast(total_cases AS numeric)) *100 as deathpercentage
FROM ProjectDatabase..CovidDeath
WHERE location like 'China'
AND continent IS NOT NULL
ORDER BY 1, 2

--Looking at Total Cases vs Population
--Shows what percentage of population got Covid
SELECT location, date, population, total_cases, (cast(total_cases AS numeric)/ cast(population AS numeric)) *100 as PercentPopulationInfected
FROM ProjectDatabase..CovidDeath
WHERE continent IS NOT NULL
ORDER BY 1, 2


--Looking at Countries with Highest Infection Rate compared to Population
SELECT location, population, MAX(total_cases) AS HighestInfectionCount, MAX(cast(total_cases AS numeric)/ cast(population AS numeric)) *100 as PercentPopulationInfected
FROM ProjectDatabase..CovidDeath
WHERE continent IS NOT NULL
GROUP BY location, population
ORDER BY PercentPopulationInfected DESC


--Showing Countries with Highest Death Count per Population
SELECT location, MAX(total_deaths) AS TotalDeathCount
FROM ProjectDatabase..CovidDeath
WHERE continent IS NOT NULL
GROUP BY location
ORDER BY TotalDeathCount DESC


--Let's Break things Down By Continent
SELECT location, MAX(total_deaths) AS TotalDeathCount
FROM ProjectDatabase..CovidDeath
WHERE continent IS NULL
GROUP BY location
ORDER BY TotalDeathCount DESC 


--Showing continents with the highest death count per population
SELECT continent, MAX(CAST(total_deaths AS numeric)) AS TotalDeathCount
FROM ProjectDatabase..CovidDeath
WHERE continent IS NOT NULL
GROUP BY continent
ORDER BY TotalDeathCount DESC


--Global Numbers
SELECT date, SUM(CAST(new_cases AS numeric)) AS total_cases, SUM(CAST(new_deaths AS numeric)) AS total_deaths, (SUM(CAST(new_cases AS numeric))/SUM(CAST(new_deaths AS numeric)))*100 AS NewDeathPercentage
FROM ProjectDatabase..CovidDeath
WHERE continent IS NOT NULL
GROUP BY date
ORDER BY 1, 2

--Global Numbers
SELECT SUM(CAST(new_cases AS numeric)) AS total_cases, SUM(CAST(new_deaths AS numeric)) AS total_deaths, (SUM(CAST(new_cases AS numeric))/SUM(CAST(new_deaths AS numeric)))*100 AS NewDeathPercentage
FROM ProjectDatabase..CovidDeath
WHERE continent IS NOT NULL
--GROUP BY date
ORDER BY 1, 2


--Looking at total population vs. Vaccinations
SELECT dea.continent, dea.location, dea.date, dea.population, dea.new_vaccinations, 
       SUM(CAST(dea.new_vaccinations AS numeric)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS RollingPeopleVaccinated
FROM ProjectDatabase..CovidDeath dea
JOIN ProjectDatabase..CovidVaccination vac
    ON dea.location = vac.location
    AND dea.date = vac.date 
WHERE dea.continent IS NOT NULL
ORDER BY 2,3

--USE CTE
WITH PopvsVac(Conitinent, Location, Date, Population, New_Vaccinations, RollingPeopleVaccinated)
AS
(
SELECT dea.continent, dea.location, dea.date, dea.population, dea.new_vaccinations, 
       SUM(CAST(dea.new_vaccinations AS numeric)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS RollingPeopleVaccinated
FROM ProjectDatabase..CovidDeath dea
JOIN ProjectDatabase..CovidVaccination vac
    ON dea.location = vac.location
    AND dea.date = vac.date 
WHERE dea.continent IS NOT NULL
--ORDER BY 2,3
)
SELECT *, (RollingPeopleVaccinated/Population)*100
FROM PopvsVac


--TEMP TABLE

DROP Table if EXISTS #PercentPopulationVaccinated
Create Table #PercentPopulationVaccinated
(
  Continent NVARCHAR(255),
  Location NVARCHAR(255),
  Date DATETIME,
  Population NUMERIC,
  New_Vaccinations NUMERIC,
  RollingPeopleVaccinated NUMERIC
)

INSERT INTO #PercentPopulationVaccinated
SELECT dea.continent, dea.location, dea.date, dea.population, dea.new_vaccinations, 
       SUM(CAST(dea.new_vaccinations AS numeric)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS RollingPeopleVaccinated
FROM ProjectDatabase..CovidDeath dea
JOIN ProjectDatabase..CovidVaccination vac
    ON dea.location = vac.location
    AND dea.date = vac.date 
--WHERE dea.continent IS NOT NULL
--ORDER BY 2,3

SELECT *, (RollingPeopleVaccinated/Population)*100
FROM #PercentPopulationVaccinated



--Creating View to store data for later visualizations

Create View PercentPopulationVaccinated AS
SELECT dea.continent, dea.location, dea.date, dea.population, dea.new_vaccinations, 
       SUM(CAST(dea.new_vaccinations AS numeric)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS RollingPeopleVaccinated
FROM ProjectDatabase..CovidDeath dea
JOIN ProjectDatabase..CovidVaccination vac
    ON dea.location = vac.location
    AND dea.date = vac.date 
WHERE dea.continent IS NOT NULL
--ORDER BY 2,3


SELECT *
FROM PercentPopulationVaccinated
