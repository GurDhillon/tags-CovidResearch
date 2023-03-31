SET SEARCH_PATH TO phase2;

-- For each country and vaccine manufacturer, the most recent date
-- for which doses data is available.
CREATE VIEW RecentDates AS
SELECT countryCode, manufacturer, max(date) as date
FROM Doses
GROUP BY countryCode, manufacturer;

-- The most recent doses data for each country and vaccine manufacturer.
CREATE VIEW RecentDoses AS
SELECT countryCode, manufacturer, doses
FROM RecentDates NATURAL JOIN Doses;

-- The number of total vaccine doses given in each country.
CREATE VIEW TotalDoses AS
SELECT countryCode, sum(doses) as totalDoses
FROM RecentDoses
GROUP BY countryCode;

-- For each country and vaccine manufacturer, the fraction of total doses
-- that are from this manufacturer in this country.
CREATE VIEW PercentDoses AS
SELECT countryCode, manufacturer, doses / (totalDoses * 1.0) as percentDoses
FROM RecentDoses NATURAL JOIN TotalDoses;

-- For each country and vaccine manufacturer, the fraction of total doses
-- that are from this manufacturer multiplied by the efficacy of the vaccine.
CREATE VIEW PartScore AS
SELECT countryCode, manufacturer, percentDoses * (efficacy / 100.0) as partScore
FROM PercentDoses NATURAL JOIN Manufacturers;

-- The v-score for each country.
CREATE VIEW Score AS
SELECT countryCode, sum(partScore) as score
FROM PartScore
GROUP BY countryCode;

-- The v-score of each country and their GDP per capita, to make comparisons.
CREATE VIEW ScoreGDP AS
SELECT countryCode, gdppercapita, score
FROM Countries NATURAL JOIN Score;

-- The data to answer our first investigative question, the same as ScoreGDP.
CREATE VIEW q1 AS
SELECT *
FROM ScoreGDP;

-- The average score of impoverished countries.
CREATE VIEW PoorAvg AS
SELECT avg(score)
FROM q1
WHERE gdppercapita < 15500;

-- The average score of wealthy countries.
CREATE VIEW WealthyAvg AS
SELECT avg(score)
FROM q1
WHERE gdppercapita > 15500;

---- Further exploration of the data  ----

-- Wealthy countries ordered by their v-score.
CREATE VIEW WealthyScores AS
SELECT *
FROM q1
WHERE gdppercapita > 15500
ORDER BY score;

-- All nations in the q1 table that are members of the European Union.
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
('LUX');

-- Table q1 but with only EU member states.
CREATE VIEW EUScores AS
SELECT *
FROM q1
WHERE countryCode IN (SELECT * FROM EUNations);

-- Table q1 but with only countries that are not EU members.
CREATE VIEW NonEUScores AS
SELECT *
FROM q1
WHERE countryCode NOT IN (SELECT * FROM EUNations);

-- The average v-score of impoverished EU member states.
CREATE VIEW EUPoorAvg AS
SELECT avg(score)
FROM EUScores
WHERE gdppercapita < 15500;

-- The average v-score of impoverished non-EU countries.
CREATE VIEW NonEUPoorAvg AS
SELECT avg(score)
FROM NonEUScores
WHERE gdppercapita < 15500;

-- The average v-score of wealthy EU member states.
CREATE VIEW EUWealthyAvg AS
SELECT avg(score)
FROM EUScores
WHERE gdppercapita > 15500;

-- The average v-score of wealthy non-EU countries.
CREATE VIEW NonEUWealthyAvg AS
SELECT avg(score)
FROM NonEUScores
WHERE gdppercapita > 15500;

