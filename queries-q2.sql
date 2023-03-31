SET SEARCH_PATH TO phase2;

-- For each country, the msot recent date for which vaccination data is available.
CREATE VIEW RecentDates AS
SELECT countryCode, max(date) as date
FROM Vaccinations
GROUP BY countryCode;

-- The most recent vaccination data for each country.
CREATE VIEW RecentVaccination AS
SELECT *
FROM RecentDates NATURAL JOIN Vaccinations;

-- For each country, the proportion of the population that has been vaccinated/fully vaccinated.
CREATE VIEW ProportionVaccinated AS
SELECT countryCode, gdppercapita, vaccinated / (population * 1.0) as vaccinated, fullyvaccinated / (population * 1.0) as fullyvaccinated
FROM RecentVaccination NATURAL JOIN Countries;

-- The data required to answer our second investigative question, the relationship between gdp per capita and
-- the proportion of fully vaccinated individuals.
CREATE VIEW q2 AS
SELECT countryCode, gdppercapita, fullyvaccinated
FROM ProportionVaccinated;

--- Further exploration of the data ---

-- The countries for which vaccination data is available.
CREATE VIEW VaccinationCountries AS
SELECT countryCode, gdppercapita
FROM (SELECT distinct countryCode FROM Vaccinations) v NATURAL JOIN Countries;

-- A series of dates from 2020-01-01 to 2021-11-16.
CREATE VIEW RefDates AS
SELECT generate_series('2020-01-01'::timestamp, '2021-11-16'::timestamp, '1 day'::interval) AS ref_date;

-- The wealthy countries for which vaccination data is available.
CREATE VIEW WealthyCountries AS
SELECT countryCode
FROM VaccinationCountries
WHERE gdppercapita > 15500;

-- The vaccination data for wealthy countries only.
CREATE VIEW WealthyVaccinations AS
SELECT *
FROM WealthyCountries NATURAL JOIN Vaccinations;

-- The cartesian product of the series of dates and vaccination data for wealthy countries,
-- but filtered such that the date for each data point is less than ref_date.
CREATE VIEW WealthyEarlier AS
SELECT countryCode, ref_date, date, vaccinated, fullyvaccinated
FROM RefDates, WealthyVaccinations
WHERE date <= ref_date;

-- For each wealthy country and each ref_date, the most recent date for which vaccination data is available.
CREATE VIEW WealthyMaxDate AS
SELECT countryCode, ref_date, max(date) as date
FROM WealthyEarlier
GROUP BY countryCode, ref_date;

-- For each wealthy country and each ref_date, the most recent vaccination data that is available.
CREATE VIEW WealthyRecent AS
SELECT countryCode, ref_date, vaccinated, fullyvaccinated
FROM WealthyEarlier NATURAL JOIN WealthyMaxDate;

-- For each ref_date, the number of vaccinated/fully vaccinated individuals in total in wealthy countries.
CREATE VIEW WealthyTotal AS
SELECT ref_date, sum(vaccinated) AS vaccinated, sum(fullyvaccinated) AS fullyvaccinated
FROM WealthyRecent
GROUP BY ref_date;

-- The total population of wealthy countries.
CREATE VIEW WealthyPopulation AS
SELECT sum(population) as totalPop
FROM WealthyCountries NATURAL JOIN Countries;

-- For each ref_date, the proportion of vaccinated/fully vaccinated individuals in wealthy countries.
CREATE VIEW WealthyProportion AS
SELECT ref_date, vaccinated / (totalPop * 1.0) AS vaccinated, fullyvaccinated / (totalPop * 1.0) AS fullyvaccinated
FROM WealthyTotal, WealthyPopulation;

-- The impoverished countries for which vaccination data is available.
CREATE VIEW PoorCountries AS
SELECT countryCode
FROM VaccinationCountries
WHERE gdppercapita < 15500;

-- The vaccination data for impoverished countries only.
CREATE VIEW PoorVaccinations AS
SELECT *
FROM PoorCountries NATURAL JOIN Vaccinations;

-- The cartesian product of the series of dates and vaccination data for impoverished countries,
-- but filtered such that the date for each data point is less than ref_date.
CREATE VIEW PoorEarlier AS
SELECT countryCode, ref_date, date, vaccinated, fullyvaccinated
FROM RefDates, PoorVaccinations
WHERE date <= ref_date;

-- For each impoverished country and each ref_date, the most recent date for which vaccination data is available.
CREATE VIEW PoorMaxDate AS
SELECT countryCode, ref_date, max(date) as date
FROM PoorEarlier
GROUP BY countryCode, ref_date;

-- For each impoverished country and each ref_date, the most recent vaccination data that is available.
CREATE VIEW PoorRecent AS
SELECT countryCode, ref_date, vaccinated, fullyvaccinated
FROM PoorEarlier NATURAL JOIN PoorMaxDate;

-- For each ref_date, the number of vaccinated/fully vaccinated individuals in total in impoverished countries.
CREATE VIEW PoorTotal AS
SELECT ref_date, sum(vaccinated) AS vaccinated, sum(fullyvaccinated) AS fullyvaccinated
FROM PoorRecent
GROUP BY ref_date;

-- The total population of impoverished countries.
CREATE VIEW PoorPopulation AS
SELECT sum(population) as totalPop
FROM PoorCountries NATURAL JOIN Countries;

-- For each ref_date, the proportion of vaccinated/fully vaccinated individuals in impoverished countries.
CREATE VIEW PoorProportion AS
SELECT ref_date, vaccinated / (totalPop * 1.0) AS vaccinated, fullyvaccinated / (totalPop * 1.0) AS fullyvaccinated
FROM PoorTotal, PoorPopulation;

-- All countries that are EU members.
CREATE TABLE EUNations (
	countryCode TEXT PRIMARY KEY,
	FOREIGN KEY (countryCode) REFERENCES Countries(countryCode)
);

INSERT INTO EUNations VALUES
('BGR'),
('ROU'),
('HRV'),
('POL'),
('HUN'),
('LVA'),
('SVK'),
('LTU'),
('PRT'),
('CZE'),
('EST'),
('SVN'),
('CYP'),
('ESP'),
('MLT'),
('ITA'),
('EUU'),
('FRA'),
('BEL'),
('DEU'),
('AUT'),
('FIN'),
('SWE'),
('NLD'),
('DNK'),
('IRL'),
('LUX'),
('GRC');

-- For each ref_date, the number of vaccinated/fully vaccinated individuals in total in impoverished EU member states.
CREATE VIEW EUPoorTotal AS
SELECT ref_date, sum(vaccinated) AS vaccinated, sum(fullyvaccinated) AS fullyvaccinated
FROM PoorRecent
WHERE countryCode IN (SELECT * FROM EUNations)
GROUP BY ref_date;

-- The total population of impoverished EU member states.
CREATE VIEW EUPoorPopulation AS
SELECT sum(population) as totalPop
FROM PoorCountries NATURAL JOIN Countries
WHERE countryCode IN (SELECT * FROM EUNations);

-- For each ref_date, the proportion of vaccinated/fully vaccinated individuals in impoverished EU member states.
CREATE VIEW EUPoorProportion AS
SELECT ref_date, vaccinated / (totalPop * 1.0) AS vaccinated, fullyvaccinated / (totalPop * 1.0) AS fullyvaccinated
FROM EUPoorTotal, EUPoorPopulation;

