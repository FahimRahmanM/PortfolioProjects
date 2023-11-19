
/*
Covid 19 Data Exploration 

Skills used: Joins, CTE's, Temp Tables, Windows Functions, Aggregate Functions, Creating Views, Converting Data Types

*/


SELECT *
FROM CovidDeaths

--Selecting data I will be using:

SELECT location, date, total_cases, new_cases, total_deaths, population
FROM CovidDeaths
WHERE continent is not null
ORDER BY 1,2


-- Total Cases vs Total Deaths:
-- Showing percentage of death compared to total cases in the United Kingdom

SELECT location, date, total_cases, total_deaths, (total_deaths/total_cases)*100 AS Percentage_deaths
FROM CovidDeaths
WHERE location like '%kingdom%'
and continent is not null
ORDER BY 1,2


-- Total Cases vs Population:
-- Showing percentage of population infected with Covid

SELECT location, date, total_cases, population, (total_cases/population)*100 AS Percentage_cases
FROM CovidDeaths
WHERE location like '%kingdom%'
ORDER BY 1,2



-- What country has the highest infection rate compared to Population?:

SELECT location, population, MAX(total_cases) AS Highest_Infection_Count, MAX((total_cases/population))*100 AS Percentage_infected
FROM CovidDeaths
--WHERE location like '%kingdom%'
GROUP BY location, population
ORDER BY Percentage_infected desc



-- Countries with highest death count per population:

SELECT location, MAX(cast(total_deaths as int)) AS total_death_count
FROM CovidDeaths
--WHERE location like '%kingdom%'
WHERE continent is not null
GROUP BY location
ORDER BY total_death_count desc


--Breaking out by continent:
-- Showing continents with the highest death count per population

SELECT continent, MAX(cast(total_deaths as int)) AS total_death_count
FROM CovidDeaths
--WHERE location like '%kingdom%'
WHERE continent is not null
GROUP BY continent
ORDER BY total_death_count desc


-- GLOBAL NUMBERS:

SELECT SUM(new_cases) as total_cases, SUM(cast(new_deaths as int)) as total_deaths, (SUM(cast(new_deaths as int))/SUM(new_cases))*100 as DeathPercentage
FROM CovidDeaths
WHERE continent is not null
--GROUP BY date
ORDER BY 1,2


--Total Population vs Vaccinations:
--Showing number of people vaccinated as time passes, for each location

SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
SUM(CAST(vac.new_vaccinations as int)) OVER (partition by dea.location ORDER BY dea.location, dea.date) as RollingPeopleVaccinated
--(RollingPeopleVaccinated/population)*100
FROM CovidDeaths dea
JOIN CovidVaccinations vac
	ON dea.location = vac.location
	AND dea.date = vac.date
	WHERE dea.continent is not null
	ORDER BY 2,3


--CTE Creation to perform calculation on Partition By in previous query (see comment above for ref on the calculation):

With PopvsVac (continent, location, date, population, new_vaccinations, RollingPeopleVaccinated)
as
(
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
SUM(CAST(vac.new_vaccinations as int)) OVER (partition by dea.location ORDER BY dea.location, dea.date) as RollingPeopleVaccinated
FROM CovidDeaths dea
JOIN CovidVaccinations vac
	ON dea.location = vac.location
	AND dea.date = vac.date
	WHERE dea.continent is not null
	--ORDER BY 2,3
	)
Select *, (RollingPeopleVaccinated/population)*100 --here is the calculation
FROM PopvsVac



-- Using Temp Table to perform calculation on Partition By instead of CTE.

DROP Table if exists #PerecentPopulationVaccinated
CREATE Table #PerecentPopulationVaccinated
(
Continent varchar(255),
Location varchar(255),
Date datetime,
Population int,
new_vaccinations int,
RollingPeopleVaccinated int
)

Insert into #PerecentPopulationVaccinated
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
SUM(CAST(vac.new_vaccinations as int)) OVER (partition by dea.location ORDER BY dea.location, dea.date) as RollingPeopleVaccinated
--(RollingPeopleVaccinated/population)*100 -- cannot perform, will require CTE or temp table then apply.
FROM CovidDeaths dea
JOIN CovidVaccinations vac
	ON dea.location = vac.location
	AND dea.date = vac.date
	WHERE dea.continent is not null
	--ORDER BY 2,3
	
Select *, (RollingPeopleVaccinated/population)*100 as PerecentagePeopleVaccinated
FROM #PerecentPopulationVaccinated



-- Creating View to store data later for visulisations:

Create View PerecentPopulationVaccinated as
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
SUM(CAST(vac.new_vaccinations as int)) OVER (partition by dea.location ORDER BY dea.location, dea.date) as RollingPeopleVaccinated
--(RollingPeopleVaccinated/population)*100 -- cannot perform, will require CTE or temp table then apply.
FROM CovidDeaths dea
JOIN CovidVaccinations vac
	ON dea.location = vac.location
	AND dea.date = vac.date
	WHERE dea.continent is not null
	--ORDER BY 2,3

Select *
From PerecentPopulationVaccinated