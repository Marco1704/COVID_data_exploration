select *
from COVID_Data_exploration..['covid_data_exploration_ vaccina$']
where continent is not null
order by 3,4

--select *
--from COVID_Data_exploration..covid_data_exploration_deaths$
--order by 3,4

--Data Selection

select location,date, total_cases, new_cases, total_deaths, population
from COVID_Data_exploration..covid_data_exploration_deaths$
where continent is not null
order by 1, 2


-- Relation between Total number of Cases vs Total number of deaths
-- Shows likelihood of dying if you contract covid in your country

select location,date, total_cases, total_deaths, (total_deaths/total_cases)*100 as death_percentage
from COVID_Data_exploration..covid_data_exploration_deaths$
where location like 'United Kingdom'
order by 1, 2


-- Relation between Total number of Cases vs Total Population
-- Shows what percentage of population got Covid

select location,date, total_cases, population, (total_cases/population)*100 as population_infection_percentage
from COVID_Data_exploration..covid_data_exploration_deaths$
where location like 'United Kingdom'
and location is not null
order by 1, 2

-- Relation between population vs rate of infection

select location, max(total_cases) as infection_count, population, max((total_cases/population))*100 as population_infection_percentage
from COVID_Data_exploration..covid_data_exploration_deaths$
-- where location like 'United Kingdom'
group by population, location
order by population_infection_percentage desc

-- Relation between Total number of deaths vs Total Population
select location, max(cast(total_deaths as int)) as total_death_count
from COVID_Data_exploration..covid_data_exploration_deaths$
-- where location like 'United Kingdom'
where continent is not null
group by location
order by total_death_count desc

-- Analyses by Continent
-- Highest death count by continent
select location, MAX(cast(total_deaths as int)) as total_death_count
from COVID_Data_exploration..covid_data_exploration_deaths$
where continent is null
group by location
order by total_death_count desc


-- Global Numbers
-- daily total cases vs total deaths 
select date, SUM(new_cases) as total_cases,SUM(cast(new_deaths as int)) as total_deaths, (SUM(cast(new_deaths as int))/SUM(new_cases))*100 as death_percentage
from COVID_Data_exploration..covid_data_exploration_deaths$
where continent is not null
group by date
order by 1, 2


--total cases vs total deaths 
select SUM(new_cases) as total_cases,SUM(cast(new_deaths as int)) as total_deaths, (SUM(cast(new_deaths as int))/SUM(new_cases))*100 as death_percentage
from COVID_Data_exploration..covid_data_exploration_deaths$
where continent is not null
--group by date
order by 1, 2


--Joining the two tables in date ana location
Select *
from COVID_Data_exploration..covid_data_exploration_deaths$ dea
join COVID_Data_exploration..['covid_data_exploration_ vaccina$'] vac
	on dea.location = vac.location
	and dea.date = vac.date

-- Relation between Total population vs Vaccinations

Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(cast(vac.new_vaccinations as int)) over (Partition by dea.location order by dea.location,
dea.date) as sum_daily_vac 
from COVID_Data_exploration..covid_data_exploration_deaths$ dea
join COVID_Data_exploration..['covid_data_exploration_ vaccina$'] vac
	on dea.location = vac.location
	and dea.date = vac.date
where dea.continent is not null
order by 2,3


-- Calculate the percentage of people vaccinated by country using CTE

with PopvsVac (Continent, Location, Date, Population, New_vaccinations, sum_daily_vac)
as
(
Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(cast(vac.new_vaccinations as int)) over (Partition by dea.location order by dea.location,
dea.date) as sum_daily_vac 
from COVID_Data_exploration..covid_data_exploration_deaths$ dea
join COVID_Data_exploration..['covid_data_exploration_ vaccina$'] vac
	on dea.location = vac.location
	and dea.date = vac.date
where dea.continent is not null
--order by 2,3
)

select *, (sum_daily_vac/Population)*100 as total_vaccinated
from PopvsVac


-- Using Temp Table to perform Calculation on Partition By in previous query

DROP Table if exists #PercentPopulationVaccinated
Create Table #PercentPopulationVaccinated
(
Continent nvarchar(255),
Location nvarchar(255),
Date datetime,
Population numeric,
New_vaccinations numeric,
sum_daily_vac numeric
)

Insert into #PercentPopulationVaccinated
Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(cast(vac.new_vaccinations as numeric)) over (Partition by dea.location order by dea.location,
dea.date) as sum_daily_vac 
from COVID_Data_exploration..covid_data_exploration_deaths$ dea
join COVID_Data_exploration..['covid_data_exploration_ vaccina$'] vac
	on dea.location = vac.location
	and dea.date = vac.date
where dea.continent is not null
--order by 2,3

Select *, (sum_daily_vac/Population)*100 as percentage_of_vaccinated_population
From #PercentPopulationVaccinated

-- Creating View to store data for later visualizations

Create View
percent_population_vaccinated as
Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(CONVERT(int,vac.new_vaccinations)) OVER (Partition by dea.Location Order by dea.location, dea.Date) as sum_daily_vac
--, (RollingPeopleVaccinated/population)*100
From COVID_Data_exploration..covid_data_exploration_deaths$ dea
Join COVID_Data_exploration..['covid_data_exploration_ vaccina$'] vac
	On dea.location = vac.location
	and dea.date = vac.date
where dea.continent is not null
--order by 2,3
