SELECT * 
FROM PortfolioProject..CovidDeaths$
WHERE continent IS NOT NULL
ORDER BY 3,4

SELECT * 
FROM PortfolioProject..CovidVaccinations$
ORDER BY 3,4

-- Data Selection
SELECT location, date, total_cases, new_cases, total_deaths, population
FROM PortfolioProject..CovidDeaths$
ORDER BY 1,2


-- Total Cases vs Total Deaths 
-- Chance of Death from Contracting COVID-19 in the U.S.
SELECT location, date, total_deaths, total_cases,
(CONVERT (float, total_deaths)/ NULLIF(CONVERT(float, total_cases), 0)) *100 AS DeathPercentage
FROM PortfolioProject..CovidDeaths$
WHERE location = 'United States'
ORDER BY 1,2

-- Percentage of Population to Contract COVID-19 in the U.S.
SELECT location, date,total_cases, population,
(total_cases/population)*100 AS PercentPopulationInfected
FROM PortfolioProject..CovidDeaths$
WHERE location = 'United States'
ORDER BY 1,2

-- Countries with Highest Infection Rate Per Population
SELECT location, MAX(total_cases) AS HighestInfectionCount, population, MAX((total_cases/population))*100 AS PercentPopulationInfected
FROM PortfolioProject..CovidDeaths$
WHERE continent IS NOT NULL AND continent <> 'World'
GROUP BY location, population
ORDER BY PercentPopulationInfected DESC

-- Countries with Highest Death Count per Population
SELECT location, MAX(cast(total_deaths AS INT)) AS TotalDeathCount
FROM PortfolioProject..CovidDeaths$
WHERE continent IS NOT NULL AND location <> 'World'
GROUP BY location 
ORDER BY TotalDeathCount DESC

-- Continents with Highest Death Count Per Population
SELECT continent, MAX(cast(total_deaths AS INT)) AS TotalDeathCount
FROM PortfolioProject..CovidDeaths$
WHERE continent IS NOT NULL 
GROUP BY continent 
ORDER BY TotalDeathCount DESC

-- GLOBAL NUMBERS
SELECT SUM(new_cases) AS total_cases, SUM(cast(new_deaths AS INT)) AS total_deaths, SUM(cast(new_deaths AS INT))/SUM(new_cases)*100 AS DeathPercentage
FROM PortfolioProject..CovidDeaths$
WHERE continent IS NOT NULL
-- GROUP BY date
ORDER BY 1,2

-- DAILY GLOBAL NUMBERS
SELECT date, SUM(new_cases) AS total_cases, SUM(cast(new_deaths AS INT)) AS total_deaths, SUM(cast(new_deaths AS INT))/SUM(new_cases)*100 AS DeathPercentage
FROM PortfolioProject..CovidDeaths$
WHERE continent IS NOT NULL
GROUP BY date
ORDER BY 1,2

-- Total Population vs Vaccinations
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
SUM(CAST (vac.new_vaccinations AS BIGINT)) OVER (PARTITION BY dea.location ORDER BY dea.location,dea.date) AS RollingPeopleVaccinatedlocation,dea.date)/population) * 100 AS 
FROM PortfolioProject..CovidDeaths$ AS dea
JOIN PortfolioProject..CovidVaccinations$ AS vac
	ON dea.location = vac.location
	AND dea.date = vac.date
WHERE dea.continent IS NOT NULL
ORDER BY 2,3

-- USE CTE 
WITH PopvsVac (continent, location, date, population, new_vaccinations, RollingPeopleVaccinated)
AS
(SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
SUM(CAST (vac.new_vaccinations AS BIGINT)) OVER (PARTITION BY dea.location ORDER BY dea.location,dea.date) AS RollingPeopleVaccinated
FROM PortfolioProject..CovidDeaths$ AS dea
JOIN PortfolioProject..CovidVaccinations$ AS vac
	ON dea.location = vac.location
	AND dea.date = vac.date
WHERE dea.continent IS NOT NULL)

SELECT *, (RollingPeopleVaccinated/Population) * 100
FROM PopvsVac

-- TEMP TABLE
DROP TABLE IF EXISTS #PercentPopulationVaccinated

CREATE TABLE #PercentPopulationVaccinated
(continent nvarchar(255), location nvarchar(255), date datetime, population numeric, new_vaccinations numeric, RollingPeopleVaccinated numeric)
INSERT INTO #PercentPopulationVaccinated
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
SUM(CAST (vac.new_vaccinations AS BIGINT)) OVER (PARTITION BY dea.location ORDER BY dea.location,dea.date) AS RollingPeopleVaccinated
FROM PortfolioProject..CovidDeaths$ AS dea
JOIN PortfolioProject..CovidVaccinations$ AS vac
	ON dea.location = vac.location
	AND dea.date = vac.date
WHERE dea.continent IS NOT NULL

SELECT *, (RollingPeopleVaccinated/population) *100
FROM #PercentPopulationVaccinated

-- Create View for Visualizations
CREATE VIEW PercentPopulationVaccinated AS
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
SUM(CAST(vac.new_vaccinations AS BIGINT)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS RollingPeopleVaccinated
FROM PortfolioProject..CovidDeaths$ AS dea
JOIN PortfolioProject..CovidVaccinations$ AS vac
ON dea.location = vac.location
	AND dea.date = vac.date
WHERE dea.continent IS NOT NULL

SELECT *
FROM PercentPopulationVaccinated