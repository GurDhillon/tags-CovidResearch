-- Changes: Added a foreign key constraint in the Variants table because it was missing before.

DROP SCHEMA IF EXISTS phase2 CASCADE;
CREATE SCHEMA phase2;
SET search_path to phase2;

-- The variants of COVID-19.
CREATE DOMAIN Variant AS VARCHAR(7)
	CHECK (VALUE IN ('Beta', 'Epsilon', 'Gamma', 'Kappa', 'Iota', 'Eta', 'Delta', 'Alpha', 'Lambda', 'Mu', 'Other'));

-- The manufacturers of COVID-19 vaccines.
-- manufacturer is the manufacturer's name, and efficacy is the
-- tested efficacy rating of the vaccine.
CREATE TABLE Manufacturers (
	manufacturer TEXT PRIMARY KEY,
	efficacy FLOAT NOT NULL
);

-- A country or region.
-- countryCode is a unique identifier code for the country or region,
-- countryName is the name of the country or region, population is
-- the population of the country or region, and GDPPerCapita is
-- the GDP per capita of the country or region.
CREATE TABLE Countries (
	countryCode TEXT primary key,
	countryName TEXT NOT NULL,
	population BIGINT NOT NULL,
	GDPPerCapita FLOAT NOT NULL
);

-- The number of doses of a vaccine given.
-- countryCode is the code of the country or region where the doses
-- were administered, date is the date on which the doses were
-- administered, manufacturer is the manufacturer name of the vaccine,
-- and doses is the number of doses that were administered.
CREATE TABLE Doses (
	countryCode TEXT,
	date TIMESTAMP,
	manufacturer TEXT,
	doses INT NOT NULL,
	PRIMARY KEY (countryCode, date, manufacturer),
	FOREIGN KEY (countryCode) REFERENCES Countries(countryCode),
	FOREIGN KEY (manufacturer) REFERENCES Manufacturers(manufacturer)
);

-- The number of vaccinated and fully vaccinated people.
-- countryCode is the code of the country or region, date is a date,
-- vaccinated is the number of people that have received at least
-- one dose of a vaccine by the given date, and fully vaccinated
-- is the number of fully vaccinated people by the given date.
CREATE TABLE Vaccinations (
	countryCode TEXT,
	date TIMESTAMP,
	vaccinated BIGINT NOT NULL,
	fullyVaccinated BIGINT NOT NULL,
	PRIMARY KEY (countryCode, date),
	FOREIGN KEY (countryCode) REFERENCES Countries(countryCode)
);


-- The number of biweekly cases per 1 million people.
-- countryCode is the code of the country or region, date is a date,
-- and cases is the number of cases per 1 million people that have arisen
-- in the last two weeks from the given date.
CREATE TABLE Cases (
	countryCode TEXT,
	date TIMESTAMP,
	cases FLOAT NOT NULL,
	PRIMARY KEY (countryCode, date),
	FOREIGN KEY (countryCode) REFERENCES Countries(countryCode)
);

-- The share of analyzed sequences that correspond to each COVID-19 variant.
-- countryCode is the code of the country or region, date is a date,
-- variant is the name of a COVID-19 variant, and share is the share of
-- analyzed sequences in the last two weeks from the given date that
-- correspond to the COVID-19 variant.
CREATE TABLE Variants (
	countryCode TEXT,
	date TIMESTAMP,
	variant VARIANT,
	share FLOAT NOT NULL,
	PRIMARY KEY (countryCode, date, variant),
	FOREIGN KEY (countryCode) REFERENCES Countries(countryCode)
);
	
