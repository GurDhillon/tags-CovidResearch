SET search_path TO phase2;
--This view gives each country, the date, their gdppercapita, and number cases for each variant for comparison,
--can use where clause to search above and below impoverished line for gdp.
DROP VIEW IF EXISTS gdpvariantcases CASCADE;
CREATE VIEW gdpvariantcases AS
SELECT cases.countrycode, cases.date, countries.gdppercapita, variants.variant, cases.cases*variants.share / 100 AS cases
FROM (cases INNER JOIN variants 
ON cases.countrycode = variants.countrycode AND cases.date = variants.date)
INNER JOIN countries ON cases.countrycode = countries.countrycode
ORDER BY countries.gdppercapita, cases.date DESC;

--Helper view which gives total number of doses per country
DROP VIEW IF EXISTS totaldoses CASCADE;
CREATE VIEW totaldoses AS
SELECT doses.countrycode, doses.date, SUM(doses.doses)
FROM doses
GROUP BY doses.countrycode, doses.date
ORDER BY doses.countrycode, doses.date DESC;

--View gives number of variants present vs number of doses for given date and country
--can use where clause to filter out variants with minimal presence to reduce noise if desired
DROP VIEW IF EXISTS dosesvariant CASCADE;
CREATE VIEW dosesvariant AS
SELECT cases.countrycode, cases.date, COUNT(variants.variant), totaldoses.sum as doses
FROM ((cases 
	   INNER JOIN variants ON cases.countrycode = variants.countrycode AND cases.date = variants.date)
	   INNER JOIN countries ON cases.countrycode = countries.countrycode)
	   INNER JOIN totaldoses ON cases.countrycode = totaldoses.countrycode AND cases.date = totaldoses.date
WHERE variants.share <> 0
GROUP BY cases.countrycode, cases.date, countries.gdppercapita, totaldoses.sum
ORDER BY countries.gdppercapita, cases.date DESC;

