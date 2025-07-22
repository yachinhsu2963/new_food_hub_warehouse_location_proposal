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

-- 20 miles warehouse location 
DROP TABLE IF EXISTS city_centers;
CREATE TABLE city_centers (
  Name VARCHAR(100),
  Latitude DOUBLE,
  Longitude DOUBLE
);
LOAD DATA INFILE 'C:/ProgramData/MySQL/MySQL Server 8.4/Uploads/circle_coordinates.csv'
INTO TABLE city_centers
FIELDS TERMINATED BY ',' 
ENCLOSED BY '"'
LINES TERMINATED BY '\r\n'
IGNORE 1 ROWS;

-- find business opportunities for TGA using government data
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
-- farm count in each city
SELECT County, SUM(Value) AS farm_count
FROM live_case_data
WHERE (County IN ("KANDIYOHI", "ST. LOUIS", "STEELE", "OLMSTED", "OTTER TAIL")) AND (Commodity = "FARM OPERATIONS") AND (Data_Item = "FARM OPERATIONS - NUMBER OF OPERATIONS") & (Domain_Category LIKE "AREA OPERATED%")
GROUP BY County;

-- see which place will exist in 20 miles in each city
SELECT 
  T.Name,
  T.Category,
  T.Latitude,
  T.Longitude,
  c.Name AS City,
  (3959 * ACOS(
     COS(RADIANS(T.Latitude)) * COS(RADIANS(c.Latitude)) *
     COS(RADIANS(c.Longitude) - RADIANS(T.Longitude)) +
     SIN(RADIANS(T.Latitude)) * SIN(RADIANS(c.Latitude))
   )) AS distance_miles
FROM TGA AS T
JOIN city_centers c ON 1=1
WHERE T.Category IN ('Suppliers', 'Inspected Meat Processors')
HAVING distance_miles <= 20;
-- proportion of client's farm in all business opportunities
WITH all_business AS
(
  SELECT County, SUM(Value) AS farm_count
  FROM live_case_data
  WHERE County IN ("KANDIYOHI", "ST. LOUIS", "STEELE", "OLMSTED", "OTTER TAIL")
    AND Commodity = "FARM OPERATIONS"
    AND Data_Item = "FARM OPERATIONS - NUMBER OF OPERATIONS"
    AND Domain_Category LIKE "AREA OPERATED%"
  GROUP BY County
),
client_business AS
(
  SELECT 
    T.Name,
    T.Category,
    T.Latitude,
    T.Longitude,
    c.Name AS City,
    (3959 * ACOS(
       COS(RADIANS(T.Latitude)) * COS(RADIANS(c.Latitude)) *
       COS(RADIANS(c.Longitude) - RADIANS(T.Longitude)) +
       SIN(RADIANS(T.Latitude)) * SIN(RADIANS(c.Latitude))
     )) AS distance_miles
  FROM TGA AS T
  JOIN city_centers c ON 1=1
  WHERE T.Category IN ('Suppliers', 'Inspected Meat Processors')
  HAVING distance_miles <= 20
),
client_summary AS
(
  SELECT City, COUNT(*) AS count_City
  FROM client_business
  GROUP BY City
)
SELECT * FROM all_business
;
