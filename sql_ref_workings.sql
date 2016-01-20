----------------------------------------------------------------------------------
-- SQL code for Data Analysis Case Study
-- 01/20/2016
-- Review of Data from the Refugee Processing Center
-- Refugees resettled into the US during 2015
--
-- Read more on my website at:
-- http://www.benlcollins.com/sql/us-refugee-case-study/
----------------------------------------------------------------------------------

----------------------------------------------------------------------------------
-- Create the two data tables
----------------------------------------------------------------------------------
DROP TABLE IF EXISTS ref_destination_data;

CREATE TABLE ref_destination_data (
	id 					SERIAL NOT NULL,
	Textbox87				text,
	Textbox82				text,
	nat_definition4				text,
	region_name_3				text,
	textbox37				text,
	Category3				text,
	textbox39				text,
	Assur_DestinationCity1			text,
	Cases3					text,
	Cases4					text
);

DROP TABLE IF EXISTS ref_religion_data;

CREATE TABLE ref_religion_data (
	id 					SERIAL NOT NULL,
	Textbox126				text,
	Textbox127				text,
	nat_definition3				text,
	region_name_2				text,
	textbox36				text,
	relig_definition1			text,
	Cases					text,
	Cases2					text
);

----------------------------------------------------------------------------------
-- import data from CSV
----------------------------------------------------------------------------------
COPY ref_destination_data(Textbox87,Textbox82,nat_definition4,region_name_3,textbox37,Category3,textbox39,Assur_DestinationCity1,Cases3,Cases4)
FROM '/Users/benlcollins/Documents/mx_arrivals_destination_nationality.csv' CSV HEADER DELIMITER ',';

COPY ref_religion_data(Textbox126,Textbox127,nat_definition3,region_name_2,textbox36,relig_definition1,Cases,Cases2)
FROM '/Users/benlcollins/Documents/mx_arrivals_nationality_religion.csv' CSV HEADER DELIMITER ',';

----------------------------------------------------------------------------------
-- check data
----------------------------------------------------------------------------------
SELECT * FROM ref_destination_data;
SELECT * FROM ref_religion_data;

----------------------------------------------------------------------------------
-- delete the duplicate data
----------------------------------------------------------------------------------
DELETE FROM ref_destination_data
WHERE ref_dest_id > 2844;

DELETE FROM ref_religion_data
WHERE ref_rel_id > 334;

----------------------------------------------------------------------------------
-- change datatype for numerical columns in destination data
----------------------------------------------------------------------------------
ALTER TABLE ref_destination_data ALTER COLUMN textbox37 SET DATA TYPE integer USING (replace(textbox37, ',','')::integer);
ALTER TABLE ref_destination_data ALTER COLUMN textbox39 SET DATA TYPE integer USING (replace(textbox39, ',','')::integer);
ALTER TABLE ref_destination_data ALTER COLUMN cases3 SET DATA TYPE integer USING (replace(cases3, ',','')::integer);
ALTER TABLE ref_destination_data ALTER COLUMN cases4 SET DATA TYPE integer USING (replace(cases4, ',','')::integer);

----------------------------------------------------------------------------------
-- change datatype for numerical columns in religion data
----------------------------------------------------------------------------------
ALTER TABLE ref_religion_data ALTER COLUMN textbox36 SET DATA TYPE integer USING (replace(textbox36, ',','')::integer);
ALTER TABLE ref_religion_data ALTER COLUMN cases SET DATA TYPE integer USING (replace(cases, ',','')::integer);
ALTER TABLE ref_religion_data ALTER COLUMN cases2 SET DATA TYPE integer USING (replace(cases2, ',','')::integer);

----------------------------------------------------------------------------------
-- change the column headings for destination data table
----------------------------------------------------------------------------------
ALTER TABLE ref_destination_data RENAME textbox87 TO start_date;
ALTER TABLE ref_destination_data RENAME textbox82 TO end_date;
ALTER TABLE ref_destination_data RENAME nat_definition4 TO state;
ALTER TABLE ref_destination_data RENAME region_name_3 TO period;
ALTER TABLE ref_destination_data RENAME textbox37 TO num_state;
ALTER TABLE ref_destination_data RENAME category3 TO origin;
ALTER TABLE ref_destination_data RENAME textbox39 TO num_state_dest;
ALTER TABLE ref_destination_data RENAME assur_destinationcity1 TO destination_city;
ALTER TABLE ref_destination_data RENAME cases3 TO num_unique;
ALTER TABLE ref_destination_data RENAME cases4 TO total;

----------------------------------------------------------------------------------
-- change the column headings for religion data table
----------------------------------------------------------------------------------
ALTER TABLE ref_religion_data RENAME textbox126 TO start_date;
ALTER TABLE ref_religion_data RENAME textbox127 TO end_date;
ALTER TABLE ref_religion_data RENAME nat_definition3 TO origin;
ALTER TABLE ref_religion_data RENAME region_name_2 TO period;
ALTER TABLE ref_religion_data RENAME textbox36 TO num_origin;
ALTER TABLE ref_religion_data RENAME relig_definition1 TO religion;
ALTER TABLE ref_religion_data RENAME cases TO num_unique;
ALTER TABLE ref_religion_data RENAME cases2 TO total;

----------------------------------------------------------------------------------
/* ANALYSIS OF REFUGEE DATA */
----------------------------------------------------------------------------------

----------------------------------------------------------------------------------
-- summarize by origin, from highest to lowest
----------------------------------------------------------------------------------
SELECT 	origin
	, sum(num_unique) AS number_refugees
	, total
	, round((sum(num_unique)*1.0/total)*100,1) AS refugee_ratio
FROM ref_destination_data
GROUP BY origin, total
ORDER BY 2 DESC;

----------------------------------------------------------------------------------
-- summarize by origin, from highest to lowest with cumulative total
----------------------------------------------------------------------------------
WITH ref_stats AS (
	SELECT 	origin
		, sum(num_unique) AS number_refugees
		, total
		, round((sum(num_unique)*1.0/total)*100,1) AS refugee_ratio
	FROM ref_destination_data
	GROUP BY origin, total
	ORDER BY 2 DESC
)
SELECT a.origin, a.number_refugees, a.total, a.refugee_ratio,SUM(b.refugee_ratio)
FROM ref_stats a, ref_stats b
WHERE b.number_refugees >= a.number_refugees
GROUP BY a.origin, a.number_refugees, a.total, a.refugee_ratio
ORDER BY 2 DESC
LIMIT 20;

----------------------------------------------------------------------------------
-- summarize data by state
----------------------------------------------------------------------------------
SELECT 	state
	, num_state AS state_refs
	, sum(num_unique) AS calculation_state_refs	-- this is a check that sum of uniques agrees
	, total AS total_refugees
	, round((num_state*1.0/total)*100,2) AS refugee_ratio
FROM ref_destination_data
GROUP BY state, num_state, total
ORDER BY 1,2 ASC;

----------------------------------------------------------------------------------
-- sort by state, highest to lowest numbers
----------------------------------------------------------------------------------
SELECT 	state
	, num_state AS state_refs
	, total AS total_refugees
	, round((num_state*1.0/total)*100,2) AS refugee_ratio
FROM ref_destination_data
GROUP BY state, num_state, total
ORDER BY 2 DESC;

----------------------------------------------------------------------------------
-- summary statistics by Country of Origin
----------------------------------------------------------------------------------
SELECT 	sum(number_refugees) AS total_refs
	, round(avg(number_refugees)) AS average_per_country
	, round(stddev(number_refugees)) AS std_deviation
FROM (
	SELECT	origin, sum(num_unique) AS number_refugees
	FROM ref_destination_data
	GROUP BY origin
) t2;
-- Average refugees from each country of Origin: 899
-- Standard deviation: 2717

----------------------------------------------------------------------------------
-- summary statistics by State
----------------------------------------------------------------------------------
SELECT 	round(avg(number_refugees)) as average_by_state
	, round(stddev(number_refugees)) as std_deviation_by_state
FROM (
	SELECT	state, sum(num_unique) AS number_refugees
	FROM ref_destination_data
	GROUP BY state
) t1;
-- Average refugees into each State: 1357
-- Standard deviation: 1439

----------------------------------------------------------------------------------
-- summary by religion, high to low
----------------------------------------------------------------------------------
SELECT 	religion
	, sum(num_unique) as num_religion
	, total
	, round((sum(num_unique)*1.0/total)*100,1) AS refugee_ratio
FROM ref_religion_data
GROUP BY religion, total
ORDER BY 2 DESC;


----------------------------------------------------------------------------------
-- categorize religions into groups for statistics
----------------------------------------------------------------------------------
SELECT 	religious_group
	, SUM(num_religion)
	, total
	, round((sum(num_religion)*1.0/total)*100,1) AS group_ratio
FROM
(
	SELECT religion, 
		CASE religion
		WHEN 'Ahmadiyya'  THEN 'Islam'
		WHEN 'Animist'  THEN 'Other'
		WHEN 'Atheist'  THEN 'Other'
		WHEN 'Bahai'  THEN 'Other'
		WHEN 'Baptist'  THEN 'Christian'
		WHEN 'Buddhist'  THEN 'Other'
		WHEN 'Catholic'  THEN 'Christian'
		WHEN 'Chaldean'  THEN 'Christian'
		WHEN 'Christian'  THEN 'Christian'
		WHEN 'Coptic'  THEN 'Christian'
		WHEN 'Evangelical Christian'  THEN 'Christian'
		WHEN 'Greek Orthodox'  THEN 'Christian'
		WHEN 'Hindu'  THEN 'Other'
		WHEN 'Jehovah Witness'  THEN 'Christian'
		WHEN 'Jewish'  THEN 'Other'
		WHEN 'Kaaka''i'  THEN 'Other'
		WHEN 'Kirat'  THEN 'Other'
		WHEN 'Lutheran'  THEN 'Christian'
		WHEN 'Methodist'  THEN 'Christian'
		WHEN 'Moslem'  THEN 'Islam'
		WHEN 'Moslem Ismaici'  THEN 'Islam'
		WHEN 'Moslem Shiite'  THEN 'Islam'
		WHEN 'Moslem Suni'  THEN 'Islam'
		WHEN 'No Religion'  THEN 'Other'
		WHEN 'Orthodox'  THEN 'Christian'
		WHEN 'Other Religion'  THEN 'Other'
		WHEN 'Pentecostalist'  THEN 'Christian'
		WHEN 'Protestant'  THEN 'Christian'
		WHEN 'Sabeans-Mandean'  THEN 'Other'
		WHEN 'Seventh Day Adventist'  THEN 'Christian'
		WHEN 'Ukr Orthodox'  THEN 'Christian'
		WHEN 'Uniate'  THEN 'Christian'
		WHEN 'Unknown'  THEN 'Other'
		WHEN 'Yazidi'  THEN 'Other'
		WHEN 'Zoroastrian'  THEN 'Other'
		ELSE 'Other'
		END AS religious_group
		, sum(num_unique) as num_religion
		, total
	FROM ref_religion_data
	GROUP BY religion, total
) t
GROUP BY religious_group, total
ORDER BY 2 DESC;


----------------------------------------------------------------------------------
-- END
----------------------------------------------------------------------------------
