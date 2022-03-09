
-- PART I  DATA CLEANING
-- SKILLS USED: UPDATE, ALTER, SUBSTRING_INDEX, CONCAT, WHERE, LIKE, REGEXP_REPLACE, CASE  & WHEN
 
-- SELECT THE DATA We will be working on

SELECT * FROM coffee;

	-- 1. Change Feature Names Where has '.'
ALTER TABLE `coffee_qual`.`coffee` 
	CHANGE COLUMN `Country.of.Origin` `Country_of_Origin` TEXT NULL DEFAULT NULL ,
	CHANGE COLUMN `Farm.Name` `Farm_Name` TEXT NULL DEFAULT NULL ,
	CHANGE COLUMN `Lot.Number` `Lot_Number` TEXT NULL DEFAULT NULL ,
	CHANGE COLUMN `ICO.Number` `ICO_Number` TEXT NULL DEFAULT NULL ,
	CHANGE COLUMN `Number.of.Bags` `Number_of_Bags` INT(11) NULL DEFAULT NULL ,
	CHANGE COLUMN `Bag.Weight` `Bag_Weight` TEXT NULL DEFAULT NULL ,
	CHANGE COLUMN `In.Country.Partner` `In_Country_Partner` TEXT NULL DEFAULT NULL ,
	CHANGE COLUMN `Harvest.Year` `Harvest_Year` TEXT NULL DEFAULT NULL ,
	CHANGE COLUMN `Grading.Date` `Grading_Date` TEXT NULL DEFAULT NULL ,
	CHANGE COLUMN `Owner.1` `Owner_1` TEXT NULL DEFAULT NULL ,
	CHANGE COLUMN `Processing.Method` `Processing_Method` TEXT NULL DEFAULT NULL ,
	CHANGE COLUMN `Clean.Cup` `Clean_Cup` INT(11) NULL DEFAULT NULL ,
	CHANGE COLUMN `Cupper.Points` `Cupper_Points` DOUBLE NULL DEFAULT NULL ,
	CHANGE COLUMN `Total.Cup.Points` `Total_Cup_Points` DOUBLE NULL DEFAULT NULL ,
	CHANGE COLUMN `Category.One.Defects` `Category_One_Defects` INT(11) NULL DEFAULT NULL ,
	CHANGE COLUMN `Category.Two.Defects` `Category_Two_Defects` INT(11) NULL DEFAULT NULL ,
	CHANGE COLUMN `Certification.Body` `Certification_Body` TEXT NULL DEFAULT NULL ;
    
		-- Change to DATE TIME
ALTER TABLE `coffee_qual`.`coffee`
	CHANGE COLUMN `Grading_Date` `Grading_Date` DATETIME NULL DEFAULT NULL ,
	CHANGE COLUMN `Expiration` `Expiration` DATETIME NULL DEFAULT NULL ;
	
    -- 2. change country names that has United States (something) and return names in brackets
UPDATE coffee
SET 
	Country_of_Origin = substring_index(substring_index(Country_of_Origin, '(',-1), ')', 1)
	WHERE Country_of_Origin LIKE 'United States (%';
	-- 3. Change 'unknown' to Null in ICO_number
UPDATE coffee
SET
	ICO_Number = Null 
    WHERE ICO_Number = 'unknown';

	-- 5. Investigate and update Bag_weight
    
SELECT bag_weight FROM coffee;    
	    -- 5a. Some bag_weights are about 10k kgs. I think these are kg * number_of_bags
        -- 5a. Rows have 'KG' and 'LBS'; convert them into kg and row numbers
        -- 5a. If the weight is equal to 0, convert to NULL
UPDATE coffee
SET bag_weight = 
	CASE 
    WHEN bag_weight LIKE '%lbs%' AND bag_weight NOT LIKE '%kg%' THEN  (bag_weight + 0) * 0.45
    WHEN bag_weight LIKE '%kg%' THEN (bag_weight + 0)
    WHEN bag_weight = 0 THEN NULL
    WHEN bag_weight > 1000 THEN bag_weight / number_of_bags
    WHEN LENGTH(bag_Weight) <= 2 THEN bag_Weight
    END
    ;
    
SELECT bag_weight from coffee;

    
	-- 6. Remove months from harvest year
		-- Since the column info is too complex, I will hard code
    
SELECT REGEXP_Replace(harvest_year,"[^0-9]+", '') FROM coffee;    
		-- Column has 45 distinct values
		-- First remove full letters without no numbers

ALTER TABLE coffee
ADD COLUMN harvest INT AFTER harvest_year;

UPDATE coffee
SET harvest_year = null WHERE REGEXP_Replace(harvest_year,"[^0-9]+", '')  = '';
		
        -- Now, hard code each harvest_year
UPDATE coffee
SET
	harvest = 
    ( CASE 
		WHEN harvest_year = 'Mar-10' THEN 2010
        WHEN harvest_year = 'Sept 2009 - April 2010' THEN 2009
        WHEN harvest_year = 'Fall 2009' THEN 2009
        WHEN harvest_year = 'December 2009-March 2010' THEN 2009
        WHEN harvest_year = 'Sept 2009 - April 2010' THEN 2009
		WHEN harvest_year = 'Fall 2009' THEN 2009
        WHEN harvest_year = 'Jan-11' THEN 2011
        WHEN harvest_year = '23-Jul-10' THEN 2010
        WHEN harvest_year = 'Abril - Julio /2011' THEN 2011
        WHEN harvest_year = 'Spring 2011 in Colombia.' THEN 2011
        WHEN harvest_year = '08/09 crop' THEN 2008
        WHEN LENGTH(harvest_year) = 7 AND harvest_year LIKE '%/%' THEN RIGHT(harvest_year, 4)
        WHEN LENGTH(harvest_year) = 6 AND harvest_year LIKE '%-%' THEN CONCAT(20,RIGHT(harvest_year, 2))
        WHEN LENGTH(harvest_year) >= 9 AND harvest_year LIKE '%/%' THEN LEFT(harvest_year, 4)
        WHEN LENGTH(harvest_year) >= 9 AND harvest_year LIKE '%-%' THEN LEFT(harvest_year, 4)
        WHEN LENGTH(harvest_year) = 7 THEN RIGHT(harvest_year, 4)
        WHEN LENGTH(harvest_year) = 5 AND harvest_year LIKE '%/%' THEN CONCAT(20,RIGHT(harvest_year, 2))
        WHEN LENGTH(harvest_year) = 4 THEN harvest_year
        
        
	END);


	-- 7. Correct grading date and expiration AND save as DATETIME object

UPDATE coffee
SET
grading_date =  STR_TO_DATE(CONCAT(SUBSTRING_INDEX(grading_date,' ', 1), '-', (SUBSTRING_INDEX(SUBSTRING_INDEX(grading_date, ',', 1), ' ', -1) + 0), 
	'-', SUBSTRING_INDEX(grading_date,' ', -1)), '%M-%d-%Y'),
expiration = STR_TO_DATE(CONCAT(SUBSTRING_INDEX(expiration,' ', 1), '-', (SUBSTRING_INDEX(SUBSTRING_INDEX(expiration, ',', 1), ' ', -1) + 0), 
	'-', SUBSTRING_INDEX(expiration,' ', -1)), '%M-%d-%Y') ;

    
	-- 8. Change foot to meter
UPDATE coffee
SET altitude_low_meters = altitude_low_meters * 0.3048,
	altitude_high_meters = altitude_high_meters * 0.3048
	WHERE unit_of_measurement = 'ft';

UPDATE coffee
SET altitude_low_meters = (altitude + 0) * 0.3048,
	altitude_high_meters = LEFT(SUBSTRING_INDEX(altitude, '-', -1),4) * 0.3048
	WHERE altitude LIKE '%ft%';
    -- 9. Change None to NULL and Bluish-Green to Blue-Green
UPDATE coffee
SET color =
	( CASE 
		WHEN color = 'None' THEN NULL
        WHEN color = 'Bluish-Green' THEN 'Blue-Green'
		END);
    
-- SELECT THE DATA FOR AGAIN
SELECT * FROM coffee;

-- PART II - DATA EXPLORATION

	-- 1. How many coffee species are there?
SELECT DISTINCT(COUNT(species)), species FROM coffee
	GROUP BY species;

	-- 2. WHICH OWNERS HAVE MORE COFFEE
SELECT DISTINCT(COUNT(species)) as species_count, species, owner FROM coffee
	GROUP BY owner, species
    ORDER BY species_count DESC;
    
    -- 3. WHERE ARE THE COFFEE COMING FROM BY SPECIES?
SELECT DISTINCT(COUNT(species)) AS species_count, species, country_of_origin FROM coffee
	GROUP BY country_of_origin, species
    ORDER BY species_count DESC;
    
    -- 4. WHAT IS THE TOTAL WEIGHT OF COFFEE BAGS
SELECT number_of_bags * bag_weight AS total_coffee_weight  FROM coffee;

	-- 5. WHICH PRODUCER PRODUCES THE MOST COFFEE
SELECT sum(number_of_bags * bag_weight) AS total_coffee_weight, producer FROM coffee
	GROUP BY producer ORDER BY total_coffee_weight DESC;    

	-- 6. WHICH MILL HAD THE HIGHEST AMOUNT OF COFFEE BY YEARS
SELECT sum(number_of_bags * bag_weight) AS total_coffee_weight, mill, harvest FROM coffee
	GROUP BY mill, harvest ORDER BY total_coffee_weight DESC;

    -- WHICH COUNTRY AND REGION PRODUCED THE MOST COFFEE
SELECT sum(number_of_bags * bag_weight) as total_coffee, country_of_origin, region FROM coffee
	GROUP BY country_of_origin, region ORDER BY total_coffee DESC;
    -- WHAT IS THE MEAN TIME OF GRADING AFTER HARVESTING
SELECT AVG(YEAR(Grading_Date) - (harvest)) AS grading_time FROM coffee
		WHERE Grading_Date IS NOT NULL and Harvest IS NOT NULL;
    -- HOW WERE THE COFFEE PROCESSED
SELECT DISTINCT(COUNT(Processing_Method)) as method_count, Processing_Method from coffee
	WHERE Processing_Method IS NOT NULL GROUP BY Processing_Method ;
    -- BEST COFFEE AMONG ALL - BY ALL FEATURES
SELECT species, Owner, Company, total_cup_points, aroma, flavor, aftertaste, acidity, body, balance, uniformity,
clean_cup, sweetness, cupper_points FROM coffee ORDER BY total_cup_points DESC LIMIT 20;
    -- IN WHAT HIGHT COFFEE GROWN?
SELECT AVG(altitude_low_meters), AVG(altitude_high_meters), species FROM coffee
	GROUP BY species;
    -- WHAT IS THE RELATIONSHIP BETWEEN ALTITUDE AND COFFEE QUALITY?
SELECT species, Owner, Company, total_cup_points, aroma, flavor, aftertaste, acidity, body, balance, uniformity,
	clean_cup, sweetness, cupper_points, altitude_low_meters, altitude_high_meters, Altitude FROM coffee 
	ORDER BY total_cup_points DESC LIMIT 20;









