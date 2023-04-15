/*
Covid 19 Data Exploration 
Skills used: Joins, CTE's, Temp Tables, Aggregate Functions, Creating Views, Converting Data Types
*/

SELECT * 
FROM [Portfolio Project]..CovidDeaths
Where continent is not NULL
ORDER BY 3, 4

SELECT * 
FROM [Portfolio Project]..CovidVacctionations
ORDER BY 3, 4

-- Select Data that will be analyzed

SELECT location, date, total_cases, new_cases, total_deaths, population 
FROM [Portfolio Project]..CovidDeaths
ORDER BY 1, 2

-- Looking at the Total Cases vs Total Deaths
-- Shows the likelihood of dying if you contract covid in your country

SELECT location, date, total_cases, total_deaths, (total_deaths/total_cases)*100 AS DeathPercentage
FROM [Portfolio Project]..CovidDeaths
WHERE location like '%states%'
ORDER BY 1, 2

-- Looking at the Total Cases vs Population
-- Shows the percentage of the population that contracted covid

SELECT location, date, population, total_cases, total_deaths, (total_cases/population)*100 AS ContractedPercentage
FROM [Portfolio Project]..CovidDeaths
WHERE location like '%states%'
ORDER BY 1, 2

--Looking at countries with the highest infection rate compared to the population

SELECT location, population, MAX(total_cases) as HighestInfectionCount, MAX((total_cases/population))*100 AS PopulationInfectedPercentage
FROM [Portfolio Project]..CovidDeaths
GROUP BY location, population 
ORDER BY PopulationInfectedPercentage desc

-- Showing the Countries with the Highest Death Count Per Population

SELECT location, MAX(cast(total_deaths as int)) as TotalDeathCount
FROM [Portfolio Project]..CovidDeaths
Where continent is not NULL
GROUP BY location
ORDER BY TotalDeathCount desc

-- Breaking down death count by continent
-- Showing the continents with the highest death count 

SELECT continent, MAX(cast(total_deaths as int)) as TotalDeathCount
FROM [Portfolio Project]..CovidDeaths
Where continent is not NULL
GROUP BY continent
ORDER BY TotalDeathCount desc

-- Global Numbers

SELECT SUM(new_cases) as total_cases, SUM(cast(new_deaths as int)) as total_deaths, 
	SUM(cast(new_deaths as int))/SUM(new_cases)*100 as DeathPercentage
FROM [Portfolio Project]..CovidDeaths
Where continent is not null
ORDER BY 1, 2

--Join CovidDeaths and CovidVaccinations table

Select *
FROM [Portfolio Project]..CovidDeaths dea
Join [Portfolio Project]..CovidVacctionations vax
	On dea.location = vax.location
	and dea.date = vax.date

--Looking at the Total Population vs Vaccinations

Select dea.continent, dea.location, dea.date, dea.population, vax.new_vaccinations
FROM [Portfolio Project]..CovidDeaths dea
Join [Portfolio Project]..CovidVacctionations vax
	On dea.location = vax.location
	and dea.date = vax.date
Where dea.continent is not null
ORDER BY 2, 3

--Show new vaccionations per day 

Select dea.continent, dea.location, dea.date, dea.population, vax.new_vaccinations,
	SUM(CONVERT(int,vax.new_vaccinations)) OVER (Partition by dea.location Order by dea.location, 
	dea.date) as NewVaccionationsTotal,
FROM [Portfolio Project]..CovidDeaths dea
Join [Portfolio Project]..CovidVacctionations vax
	On dea.location = vax.location
	and dea.date = vax.date
Where dea.continent is not null
ORDER BY 2, 3

--Using a CTE to perform calculations on Partition By 

WITH PopvsVax (continent, location, date, population, new_vaccinations, NewVaccionationsTotal)
as
(
Select dea.continent, dea.location, dea.date, dea.population, vax.new_vaccinations,
	SUM(CONVERT(int,vax.new_vaccinations)) OVER (Partition by dea.location Order by dea.location, 
	dea.date) as NewVaccionationsTotal
FROM [Portfolio Project]..CovidDeaths dea
Join [Portfolio Project]..CovidVacctionations vax
	On dea.location = vax.location
	and dea.date = vax.date
Where dea.continent is not null
)
Select *, (NewVaccionationsTotal/population)*100
FROM PopvsVax

--Temp Table to perform calculation on Partition By

DROP Table if exists #PercentPopulationVaccinated
Create Table #PercentPopulationVaccinated
(
continent nvarchar(255),
location nvarchar(255),
date datetime,
population numeric,
new_vaccinations numeric,
NewVaccionationsTotal numeric
)

INSERT INTO #PercentPopulationVaccinated
Select dea.continent, dea.location, dea.date, dea.population, vax.new_vaccinations,
	SUM(CONVERT(int,vax.new_vaccinations)) OVER (Partition by dea.location Order by dea.location, 
	dea.date) as NewVaccionationsTotal
FROM [Portfolio Project]..CovidDeaths dea
Join [Portfolio Project]..CovidVacctionations vax
	On dea.location = vax.location
	and dea.date = vax.date
Where dea.continent is not null

Select *, (NewVaccionationsTotal/population)*100
FROM #PercentPopulationVaccinated


-- Creating View to store data for later visualizations

Create View PercentPopulationVaccinated as
Select dea.continent, dea.location, dea.date, dea.population, vax.new_vaccinations,
	SUM(CONVERT(int,vax.new_vaccinations)) OVER (Partition by dea.location Order by dea.location, 
	dea.date) as NewVaccionationsTotal
FROM [Portfolio Project]..CovidDeaths dea
Join [Portfolio Project]..CovidVacctionations vax
	On dea.location = vax.location
	and dea.date = vax.date
Where dea.continent is not null

Select *
FROM PercentPopulationVaccinated