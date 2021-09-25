
Select * 
From CovidVaccinations


Select * 
From CovidDeaths


--Selecting columns that we will be using
Select location, date, total_cases,new_cases, total_deaths, population
from CovidProject.dbo.CovidDeaths
order by 1,2

--looking at Total Cases vs Total Deaths
--Shows likelihood of dying if you contract covid in your country
Select location, date,total_cases,total_deaths,(total_deaths/total_cases)*100 as Percentage
From CovidProject.dbo.CovidDeaths
where location = 'India'
order by 1,2

--Total Cases vs Population
--Shows percentage of population got Covid
Select location, date, total_cases, population,(total_cases/population)*100 as totalcases_Percentage
From CovidProject.dbo.CovidDeaths
where location = 'India'
order by 1,2



--Countries with highest infection rates compared to Population
Select location, population, MAX(total_cases) as HighestInfectionCount,
	MAX(total_cases/population)*100 as PercentPopulationInfected
From CovidProject.dbo.CovidDeaths
Group by Location, population
Order by PercentPopulationInfected desc



-- Countries with Highest Death Count per Population

Select Location, MAX(cast(Total_deaths as int)) as TotalDeathCount
From CovidProject.dbo.CovidDeaths
--Where location like '%states%'
Where continent is not null 
Group by Location
order by TotalDeathCount desc




--Highest death count per population BY continent

Select continent, MAX(cast(total_deaths as int)) as TotalDeathCount
From CovidProject.dbo.CovidDeaths
Where continent is not null
Group by continent
Order by TotalDeathCount desc
 

--Global Numbers
Select date, sum(new_cases) as TotalNewCasesPerDay, sum(cast(new_deaths as int)) as TotalNewDeathsPerDay,
	sum(cast(new_deaths as int))/Sum(new_cases)*100 as DeathPercentage
From CovidProject.dbo.CovidDeaths
where continent is not null
group by date
order by DeathPercentage desc

--Total numbers
Select sum(new_cases) as TotalNewCasesPerDay, sum(cast(new_deaths as int)) as TotalNewDeathsPerDay,
	sum(cast(new_deaths as int))/Sum(new_cases)*100 as DeathPercentage
From CovidProject.dbo.CovidDeaths
where continent is not null
order by DeathPercentage desc


--COVID_Vaccinations table
Select * 
From CovidVaccinations


--Joining tables
--Total Population vs Total Vaccinations
Select dea.continent, dea.location, dea.date, vac.new_vaccinations,
	SUM(convert(int, vac.new_vaccinations)) OVER (Partition by dea.location Order by dea.location,dea.date) 
		as RollingPeopleVaccinated
From CovidProject.dbo.CovidDeaths as dea 
Join CovidProject.dbo.CovidVaccinations as vac
On dea.location = vac.location
	AND dea.date = vac.date
where dea.continent is not null
order by 2,3 desc



--Using CTE
With PopVSVac (Continent, Location, Date, Population, RollingPeopleVaccinated)
as
	(Select dea.continent, dea.location, dea.date, vac.new_vaccinations,
		SUM(convert(int, vac.new_vaccinations)) OVER (Partition by dea.location Order by dea.location,dea.date) 
			as RollingPeopleVaccinated
	From CovidProject.dbo.CovidDeaths as dea 
	Join CovidProject.dbo.CovidVaccinations as vac
	On dea.location = vac.location
		AND dea.date = vac.date
	where dea.continent is not null
	)

Select *,(RollingPeopleVaccinated/NULLIF(population,0))*100
From PopVSVac




--TEMP TABLE
Drop Table if exists #PercentPopulationVaccinated
Create Table #PercentPopulationVaccinated
(
	Continent nvarchar(255),
	Location nvarchar(255),
	Date datetime,
	Population numeric,
	NewVaccinations numeric,
	RollingPeopleVaccinated numeric
)

Insert into #PercentPopulationVaccinated
	Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
			SUM(convert(bigint, vac.new_vaccinations)) OVER (Partition by dea.location Order by dea.location,dea.date) 
			as RollingPeopleVaccinated
	From CovidProject.dbo.CovidDeaths as dea 
	Join CovidProject.dbo.CovidVaccinations as vac
	On dea.location = vac.location
		AND dea.date = vac.date


Select *,(RollingPeopleVaccinated/NULLIF(population,0))*100 as RollingVaccinatedPercentage
From #PercentPopulationVaccinated



--Create a new View to store data for later visualizations
Drop view if exists PercentPopulationVaccinated
Create View PercentPopulationVaccinated as
Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
		SUM(convert(bigint, vac.new_vaccinations)) OVER (Partition by dea.location Order by dea.location,dea.date) 
		as RollingPeopleVaccinated
From CovidProject.dbo.CovidDeaths as dea 
Join CovidProject.dbo.CovidVaccinations as vac
On dea.location = vac.location
	AND dea.date = vac.date
where dea.continent is not null