/*
                                                      "Covid 19 Data Exploration" 


Skills used: Joins, CTE's, Temp Tables, Windows Functions, Aggregate Functions, Creating Views, Converting Data Types

*/



--1)to check the data has been loaded into database from excelsheet 



select * from dbo.CovidDeaths

select * from dbo.CovidVaccinations


Select *
From CovidDeaths
Where continent is not null 
order by 3,4


-- 2)Select Data that we are going to be starting with

Select Location, date, total_cases, new_cases, total_deaths, population
From CovidDeaths
Where continent is not null 
order by 1,2


-- 3)Total Cases vs Total Deaths
-- Shows likelihood of dying if you contract covid in your country
SELECT Location, Date, Total_Cases, Total_Deaths, (CAST(Total_Deaths AS FLOAT) / CAST(Total_Cases AS FLOAT)) * 100 AS DeathPercentage
FROM    CovidDeaths
WHERE  Location LIKE '%states%' AND Continent IS NOT NULL ORDER BY    1, 2;


-- 4) Total Cases vs Population
-- Shows what percentage of population infected with Covid

Select Location, date, Population, total_cases,  (total_cases/population)*100 as PercentPopulationInfected
From CovidDeaths
--Where location like '%states%'
order by 1,2


-- 5) Countries with Highest Infection Rate compared to Population

Select Location, Population, MAX(total_cases) as HighestInfectionCount,  Max((total_cases/population))*100 as PercentPopulationInfected
From CovidDeaths
--Where location like '%states%'
Group by Location, Population
order by PercentPopulationInfected desc


-- 6) Countries with Highest Death Count per Population

Select Location, MAX(cast(Total_deaths as int)) as TotalDeathCount
From CovidDeaths
--Where location like '%states%'
Where continent is not null 
Group by Location
order by TotalDeathCount desc



-- 7)BREAKING THINGS DOWN BY CONTINENT

-- Showing contintents with the highest death count per population

Select continent, MAX(cast(Total_deaths as int)) as TotalDeathCount
From CovidDeaths
--Where location like '%states%'
Where continent is not null 
Group by continent
order by TotalDeathCount desc



-- 8) GLOBAL NUMBERS in percentage

Select SUM(new_cases) as total_cases, SUM(cast(new_deaths as int)) as total_deaths, 
SUM(cast(new_deaths as int))/SUM(New_Cases)*100 as DeathPercentage
From CovidDeaths
--Where location like '%states%'
where continent is not null 
--Group By date
order by 1,2



-- 9)Total Population vs Vaccinations
-- Shows Percentage of Population that has recieved at least one Covid Vaccine

SELECT 
    SUM(new_cases) AS total_cases, 
    SUM(CAST(new_deaths AS INT)) AS total_deaths, 
    (SUM(CAST(new_deaths AS INT)) * 100.0) / SUM(new_cases) AS DeathPercentage
FROM 
    CovidDeaths
--Where location like '%states%'
WHERE 
    continent IS NOT NULL 
--Group By date
ORDER BY 
    1, 2;


-- 10)Using CTE to perform Calculation on Partition By in previous query

With PopvsVac (Continent, Location, Date, Population, New_Vaccinations, RollingPeopleVaccinated)
as
(
Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(CONVERT(int,vac.new_vaccinations)) OVER (Partition by dea.Location Order by dea.location, dea.Date) as RollingPeopleVaccinated
--, (RollingPeopleVaccinated/population)*100
From CovidDeaths dea
Join CovidVaccinations vac
	On dea.location = vac.location
	and dea.date = vac.date
where dea.continent is not null 
--order by 2,3
)
Select *, (RollingPeopleVaccinated/Population)*100
From PopvsVac


-- 11)Using Temp Table to perform Calculation on Partition By in previous query

-- Create the temporary table
DROP Table if exists #PercentPopulationVaccinated
CREATE TABLE #PercentPopulationVaccinated (
    Continent NVARCHAR(255),
    Location NVARCHAR(255),
    Date DATETIME,
    Population NUMERIC,
    New_vaccinations NUMERIC,
    RollingPeopleVaccinated BIGINT  -- Change data type to BIGINT to prevent overflow
);

-- Insert data into the temporary table
INSERT INTO #PercentPopulationVaccinated (Continent, Location, Date, Population, New_vaccinations, RollingPeopleVaccinated)
SELECT 
    dea.continent, 
    dea.location, 
    dea.date, 
    dea.population, 
    vac.new_vaccinations,
    SUM(CONVERT(BIGINT, vac.new_vaccinations)) OVER 
	(PARTITION BY dea.Location ORDER BY dea.location, dea.Date) as RollingPeopleVaccinated
FROM 
    CovidDeaths dea
JOIN 
    CovidVaccinations vac ON dea.location = vac.location AND dea.date = vac.date;

-- Select data from the temporary table
SELECT 
    Continent, 
    Location, 
    Date, 
    Population, 
    New_vaccinations, 
    CASE 
        WHEN Population = 0 THEN 0  -- Prevent division by zero
        ELSE (RollingPeopleVaccinated * 100.0) / NULLIF(Population, 0)  -- Calculate percentage
    END AS VaccinationPercentage
FROM 
    #PercentPopulationVaccinated;




-- 12) Creating View to store data for later visualizations

Create View PercentPopulationVaccinated as
Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(CONVERT(int,vac.new_vaccinations)) OVER (Partition by dea.Location Order by dea.location, dea.Date) as RollingPeopleVaccinated
--, (RollingPeopleVaccinated/population)*100
From CovidDeaths dea
Join CovidVaccinations vac
	On dea.location = vac.location
	and dea.date = vac.date
where dea.continent is not null 


