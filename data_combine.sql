USE test_db;

-- Government record overall business opportunities
DROP TABLE IF EXISTS live_case_data;
CREATE TABLE live_case_data (
    Year INT,
    Ag_District VARCHAR(50),
    Ag_District_Code VARCHAR(10),
    County VARCHAR(50),
    County_ANSI VARCHAR(10),
    Commodity VARCHAR(50),
    Data_Item TEXT,
    Domain VARCHAR(50),
    Domain_Category TEXT,
    Value VARCHAR(20),
    Type VARCHAR(50)
);

SHOW VARIABLES LIKE 'secure_file_priv';

LOAD DATA INFILE 'C:/ProgramData/MySQL/MySQL Server 8.4/Uploads/live_case_data_raw.csv'
INTO TABLE live_case_data
FIELDS TERMINATED BY ',' 
ENCLOSED BY '"'
LINES TERMINATED BY '\r\n'
IGNORE 1 ROWS;

-- clients' warehouse location 
DROP TABLE IF EXISTS TGA;
CREATE TABLE TGA (
    Category VARCHAR(50),
    Name TEXT,
    Latitude INT,
    Longitude INT
);
LOAD DATA INFILE 'C:/ProgramData/MySQL/MySQL Server 8.4/Uploads/MN_Food_Hub_Locations.csv'
INTO TABLE TGA
FIELDS TERMINATED BY ',' 
ENCLOSED BY '"'
LINES TERMINATED BY '\r\n';

-- find business opportunities for TGA using government data
-- farm count in each city
SELECT County, SUM(Value) AS farm_count
FROM live_case_data
WHERE (County IN ("KANDIYOHI", "ST. LOUIS", "STEELE", "OLMSTED", "OTTER TAIL")) AND (Commodity = "FARM OPERATIONS") AND (Data_Item = "FARM OPERATIONS - NUMBER OF OPERATIONS") & (Domain_Category LIKE "AREA OPERATED%")
GROUP BY County;
-- small farm count in each city
SELECT County, SUM(Value) AS small_farm_count
FROM live_case_data
WHERE (County IN ("KANDIYOHI", "ST. LOUIS", "STEELE", "OLMSTED", "OTTER TAIL")) AND (Commodity = "FARM OPERATIONS") AND (Data_Item = "FARM OPERATIONS - NUMBER OF OPERATIONS") AND (Domain_Category IN ("AREA OPERATED: (1.0 TO 9.9 ACRES)", "AREA OPERATED: (10.0 TO 49.9 ACRES)"))
GROUP BY County;
-- egg or vegetable farm count in each city
SELECT County, SUM(Value) AS egg_vegetable_sales
FROM live_case_data
WHERE (County IN ("KANDIYOHI", "ST. LOUIS", "STEELE", "OLMSTED", "OTTER TAIL")) AND (Commodity IN ("VEGETABLE TOTALS", "CHICKENS")) AND (Domain = "SALES")
GROUP BY County;
-- percentage of female farmers
WITH male_female AS
(
SELECT County, SUM(CASE WHEN Domain_Category LIKE "%FEMALE PRODUCERS%" THEN Value ELSE 0 END) AS female_count,
               SUM(CASE WHEN Domain_Category LIKE "%MALE PRODUCERS%" THEN Value ELSE 0 END) AS male_count
FROM live_case_data
WHERE (County IN ("KANDIYOHI", "ST. LOUIS", "STEELE", "OLMSTED", "OTTER TAIL"))
GROUP BY County
), 
all_make_female AS
(
SELECT *, female_count + male_count AS all_count
FROM male_female
)
SELECT County, ROUND((female_count*100 / all_count),2) AS female_percentage
FROM all_make_female;