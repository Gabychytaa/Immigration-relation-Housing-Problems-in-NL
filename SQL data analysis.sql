USE migration_eda;

-- HOUSING FINAL
TRUNCATE TABLE housing_final;
LOAD DATA INFILE 'C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/housing_final.csv'
INTO TABLE housing_final
CHARACTER SET utf8mb4
FIELDS TERMINATED BY ','  ENCLOSED BY '"'  ESCAPED BY '\\'
LINES  TERMINATED BY '\n'
IGNORE 1 LINES
(id, occupant_group, type_rental, region, period, @year, @month,
 @occ, @hh, @ls)
SET
  year              = NULLIF(@year,'\N'),
  month             = NULLIF(@month,'\N'),
  amount_occupants  = NULLIF(@occ,'\N'),
  amount_households = NULLIF(@hh,'\N'),
  amount_living_spaces = NULLIF(@ls,'\N');

-- HOUSING STOCK
USE migration_eda;

TRUNCATE TABLE housing_stock;

LOAD DATA INFILE 'C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/housing_stock.csv'
INTO TABLE housing_stock
CHARACTER SET utf8mb4
FIELDS TERMINATED BY ','  ENCLOSED BY '"'  ESCAPED BY '\\'
LINES  TERMINATED BY '\n'
IGNORE 1 LINES
(@id, @status, @region, @period, @year, @stock, @assoc, @other)
SET
  status_of_occupancy      = NULLIF(@status,'\\N'),
  region                   = NULLIF(@region,'\\N'),
  year                     = NULLIF(@year,'\\N'),
  stock                    = NULLIF(@stock,'\\N'),
  owned_by_association     = NULLIF(@assoc,'\\N'),
  owned_by_other_landlords = NULLIF(@other,'\\N');
  
 USE migration_eda;

-- FAMILY
-- FAMILY
TRUNCATE TABLE family_final;
LOAD DATA INFILE 'C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/family_final.csv'
INTO TABLE family_final
CHARACTER SET utf8mb4
FIELDS TERMINATED BY ','  ENCLOSED BY '"'  ESCAPED BY '\\'
LINES  TERMINATED BY '\n'
IGNORE 1 LINES
(@id, @gender, @age, @nat, @motive, @status, @stay, @year, @amt)
SET
  id                  = NULLIF(@id,'\\N'),
  gender              = NULLIF(@gender,'\\N'),
  age                 = NULLIF(@age,'\\N'),
  nationality         = NULLIF(@nat,'\\N'),
  motive              = NULLIF(@motive,'\\N'),
  status              = NULLIF(@status,'\\N'),
  stay_duration_years = NULLIF(@stay,'\\N'),
  immigration_year    = NULLIF(@year,'\\N'),
  amount_immigrant    = NULLIF(@amt,'\\N');

-- STUDY
DROP TABLE IF EXISTS study_final;

CREATE TABLE study_final (
  id BIGINT NULL,
  gender VARCHAR(40),
  age VARCHAR(40),
  nationality VARCHAR(120),
  motive VARCHAR(120),
  status VARCHAR(120),
  stay_duration_years INT,
  immigration_year INT,
  amount_immigrant BIGINT NULL
) CHARACTER SET utf8mb4;

LOAD DATA INFILE 'C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/study_final.csv'
INTO TABLE study_final
CHARACTER SET utf8mb4
FIELDS TERMINATED BY ',' OPTIONALLY ENCLOSED BY '"' ESCAPED BY '\\'
LINES TERMINATED BY '\n'
IGNORE 1 LINES
(@id,@gender,@age,@nat,@motive,@status,@stay,@year,@amt)
SET
  id                  = NULLIF(@id,'\\N'),
  gender              = NULLIF(@gender,'\\N'),
  age                 = NULLIF(@age,'\\N'),
  nationality         = NULLIF(@nat,'\\N'),
  motive              = NULLIF(@motive,'\\N'),
  status              = NULLIF(@status,'\\N'),
  stay_duration_years = NULLIF(@stay,'\\N'),
  immigration_year    = NULLIF(@year,'\\N'),
  amount_immigrant    = NULLIF(@amt,'\\N');

-- WORK
TRUNCATE TABLE work_final;

LOAD DATA INFILE 'C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/work_final.csv'
INTO TABLE work_final
CHARACTER SET utf8mb4
FIELDS TERMINATED BY ',' OPTIONALLY ENCLOSED BY '"' ESCAPED BY '\\'
LINES  TERMINATED BY '\n'
IGNORE 1 LINES
(@id, @gender, @age, @nat, @motive, @stay, @year, @amt)
SET
  id                  = NULLIF(@id,'\\N'),
  gender              = NULLIF(@gender,'\\N'),
  age                 = NULLIF(@age,'\\N'),
  nationality         = NULLIF(@nat,'\\N'),
  motive              = NULLIF(@motive,'\\N'),
  stay_duration_years = NULLIF(@stay,'\\N'),
  immigration_year    = NULLIF(@year,'\\N'),
  amount_immigrant    = NULLIF(@amt,'\\N');


-- ASYLUM
TRUNCATE TABLE asylum_final;

LOAD DATA INFILE 'C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/asylum_final.csv'
INTO TABLE asylum_final
CHARACTER SET utf8mb4
FIELDS TERMINATED BY ',' OPTIONALLY ENCLOSED BY '"' ESCAPED BY '\\'
LINES  TERMINATED BY '\n'
IGNORE 1 LINES
(@id, @gender, @age, @nat, @motive, @status, @stay, @year, @amt)
SET
  id                  = NULLIF(@id,'\\N'),
  gender              = NULLIF(@gender,'\\N'),
  age                 = NULLIF(@age,'\\N'),
  nationality         = NULLIF(@nat,'\\N'),
  motive              = NULLIF(@motive,'\\N'),
  status              = NULLIF(@status,'\\N'),
  stay_duration_years = NULLIF(@stay,'\\N'),
  immigration_year    = NULLIF(@year,'\\N'),
  amount_immigrant    = NULLIF(@amt,'\\N');


-- sanity check
SELECT 'family_final'  t, COUNT(*) FROM family_final
UNION ALL SELECT 'study_final',  COUNT(*) FROM study_final
UNION ALL SELECT 'work_final',   COUNT(*) FROM work_final
UNION ALL SELECT 'asylum_final', COUNT(*) FROM asylum_final
UNION ALL SELECT 'housing_final',COUNT(*) FROM housing_final
UNION ALL SELECT 'housing_stock',COUNT(*) FROM housing_stock;

USE migration_eda;

-- Family / Study / Work / Asylum share the same logical shape
ALTER TABLE family_final  ADD INDEX ix_family_nat_year (nationality, immigration_year),
                          ADD INDEX ix_family_gender   (gender),
                          ADD INDEX ix_family_age      (age),
                          ADD INDEX ix_family_stay     (stay_duration_years);

ALTER TABLE study_final   ADD INDEX ix_study_nat_year (nationality, immigration_year),
                          ADD INDEX ix_study_gender   (gender),
                          ADD INDEX ix_study_age      (age),
                          ADD INDEX ix_study_stay     (stay_duration_years);

ALTER TABLE work_final    ADD INDEX ix_work_nat_year (nationality, immigration_year),
                          ADD INDEX ix_work_gender   (gender),
                          ADD INDEX ix_work_age      (age),
                          ADD INDEX ix_work_stay     (stay_duration_years);

ALTER TABLE asylum_final  ADD INDEX ix_asylum_nat_year (nationality, immigration_year),
                          ADD INDEX ix_asylum_gender   (gender),
                          ADD INDEX ix_asylum_age      (age),
                          ADD INDEX ix_asylum_stay     (stay_duration_years);

-- Housing tables (different shape)
ALTER TABLE housing_final ADD INDEX ix_hf_region_year (region, year),
                          ADD INDEX ix_hf_month       (month);

ALTER TABLE housing_stock ADD INDEX ix_hs_region_year (region, year);

-- Canonical order for sorting age buckets
ALTER TABLE family_final
  ADD COLUMN age_ord TINYINT AS (
    CASE age
      WHEN '0–18' THEN 1 WHEN '18–30' THEN 2 WHEN '30–40' THEN 3 WHEN '40+' THEN 4
      ELSE NULL END
  ) STORED,
  ADD INDEX ix_family_ageord (age_ord);

ALTER TABLE study_final
  ADD COLUMN age_ord TINYINT AS (
    CASE age
      WHEN '0–18' THEN 1 WHEN '18–30' THEN 2 WHEN '30–40' THEN 3 WHEN '40+' THEN 4
      ELSE NULL END
  ) STORED,
  ADD INDEX ix_study_ageord (age_ord);

ALTER TABLE work_final
  ADD COLUMN age_ord TINYINT AS (
    CASE age
      WHEN '0–18' THEN 1 WHEN '18–30' THEN 2 WHEN '30–40' THEN 3 WHEN '40+' THEN 4
      ELSE NULL END
  ) STORED,
  ADD INDEX ix_work_ageord (age_ord);

ALTER TABLE asylum_final
  ADD COLUMN age_ord TINYINT AS (
    CASE age
      WHEN '0–18' THEN 1 WHEN '18–30' THEN 2 WHEN '30–40' THEN 3 WHEN '40+' THEN 4
      ELSE NULL END
  ) STORED,
  ADD INDEX ix_asylum_ageord (age_ord);

-- Year bins for quick time slicing
ALTER TABLE family_final
  ADD COLUMN year_bin VARCHAR(10) AS (
    CASE
      WHEN immigration_year <= 1999 THEN '≤1999'
      WHEN immigration_year BETWEEN 2000 AND 2007 THEN '2000–2007'
      WHEN immigration_year BETWEEN 2008 AND 2014 THEN '2008–2014'
      WHEN immigration_year BETWEEN 2015 AND 2019 THEN '2015–2019'
      WHEN immigration_year BETWEEN 2020 AND 2024 THEN '2020–2024'
      ELSE NULL END
  ) STORED,
  ADD INDEX ix_family_yearbin (year_bin);

ALTER TABLE study_final
  ADD COLUMN year_bin VARCHAR(10) AS (
    CASE
      WHEN immigration_year <= 1999 THEN '≤1999'
      WHEN immigration_year BETWEEN 2000 AND 2007 THEN '2000–2007'
      WHEN immigration_year BETWEEN 2008 AND 2014 THEN '2008–2014'
      WHEN immigration_year BETWEEN 2015 AND 2019 THEN '2015–2019'
      WHEN immigration_year BETWEEN 2020 AND 2024 THEN '2020–2024'
      ELSE NULL END
  ) STORED,
  ADD INDEX ix_study_yearbin (year_bin);

ALTER TABLE work_final
  ADD COLUMN year_bin VARCHAR(10) AS (
    CASE
      WHEN immigration_year <= 1999 THEN '≤1999'
      WHEN immigration_year BETWEEN 2000 AND 2007 THEN '2000–2007'
      WHEN immigration_year BETWEEN 2008 AND 2014 THEN '2008–2014'
      WHEN immigration_year BETWEEN 2015 AND 2019 THEN '2015–2019'
      WHEN immigration_year BETWEEN 2020 AND 2024 THEN '2020–2024'
      ELSE NULL END
  ) STORED,
  ADD INDEX ix_work_yearbin (year_bin);

ALTER TABLE asylum_final
  ADD COLUMN year_bin VARCHAR(10) AS (
    CASE
      WHEN immigration_year <= 1999 THEN '≤1999'
      WHEN immigration_year BETWEEN 2000 AND 2007 THEN '2000–2007'
      WHEN immigration_year BETWEEN 2008 AND 2014 THEN '2008–2014'
      WHEN immigration_year BETWEEN 2015 AND 2019 THEN '2015–2019'
      WHEN immigration_year BETWEEN 2020 AND 2024 THEN '2020–2024'
      ELSE NULL END
  ) STORED,
  ADD INDEX ix_asylum_yearbin (year_bin);
-- -- -- Single union-all view -- -- --
CREATE OR REPLACE VIEW immigration_all AS
SELECT 'family' AS domain, id, gender, age, age_ord, nationality, motive, status,
       stay_duration_years, immigration_year, year_bin, amount_immigrant
FROM family_final
UNION ALL
SELECT 'study',  id, gender, age, age_ord, nationality, motive, status,
       stay_duration_years, immigration_year, year_bin, amount_immigrant
FROM study_final
UNION ALL
SELECT 'work',   id, gender, age, age_ord, nationality, motive, status,
       stay_duration_years, immigration_year, year_bin, amount_immigrant
FROM work_final
UNION ALL
SELECT 'asylum', id, gender, age, age_ord, nationality, motive, status,
       stay_duration_years, immigration_year, year_bin, amount_immigrant
FROM asylum_final;

-- -- Analytics views --- 
-- -- total by year & domain -- -- 
CREATE OR REPLACE VIEW v_totals_by_year_domain AS
SELECT domain,
       immigration_year,
       SUM(amount_immigrant) AS total_people
FROM immigration_all
GROUP BY domain, immigration_year;

-- -- Nationality - gender -totals ---- 
CREATE OR REPLACE VIEW v_nat_gender_totals AS
SELECT domain, nationality, gender, SUM(amount_immigrant) AS total_people
FROM immigration_all
WHERE nationality IS NOT NULL AND gender IS NOT NULL
GROUP BY domain, nationality, gender;

CREATE OR REPLACE VIEW v_nat_gender_wide AS
SELECT domain, nationality,
       SUM(CASE WHEN gender='female' THEN total_people ELSE 0 END) AS female,
       SUM(CASE WHEN gender='male'   THEN total_people ELSE 0 END) AS male,
       SUM(total_people) AS total
FROM v_nat_gender_totals
GROUP BY domain, nationality;

-- -- Predominant age by nationality ---- 
CREATE OR REPLACE VIEW v_predominant_age_by_nat AS
WITH age_totals AS (
  SELECT domain, nationality, age, SUM(amount_immigrant) AS cnt
  FROM immigration_all
  WHERE nationality IS NOT NULL AND age IS NOT NULL
  GROUP BY domain, nationality, age
),
ranked AS (
  SELECT t.*,
         ROW_NUMBER() OVER(PARTITION BY domain, nationality ORDER BY cnt DESC) AS rn,
         SUM(cnt) OVER(PARTITION BY domain, nationality) AS nat_total
  FROM age_totals t
)
SELECT domain, nationality, age AS predominant_age, cnt AS age_count,
       nat_total, cnt / NULLIF(nat_total,0) AS share
FROM ranked
WHERE rn = 1;

-- -- Top-10 nationalities per domain (overall & per year_bin) ---- 
CREATE OR REPLACE VIEW v_top10_nat_overall AS
WITH nat_tot AS (
  SELECT domain, nationality, SUM(amount_immigrant) AS total_people
  FROM immigration_all
  WHERE nationality IS NOT NULL
  GROUP BY domain, nationality
),
ranked AS (
  SELECT nt.*,
         ROW_NUMBER() OVER (PARTITION BY domain ORDER BY total_people DESC) AS rn
  FROM nat_tot nt
)
SELECT domain, nationality, total_people
FROM ranked
WHERE rn <= 10;

CREATE OR REPLACE VIEW v_top10_nat_by_yearbin AS
WITH nat_tot AS (
  SELECT domain, year_bin, nationality, SUM(amount_immigrant) AS total_people
  FROM immigration_all
  WHERE nationality IS NOT NULL AND year_bin IS NOT NULL
  GROUP BY domain, year_bin, nationality
),
ranked AS (
  SELECT nt.*,
         ROW_NUMBER() OVER (PARTITION BY domain, year_bin ORDER BY total_people DESC) AS rn
  FROM nat_tot nt
)
SELECT domain, year_bin, nationality, total_people
FROM ranked
WHERE rn <= 10;

-- -- stay-duration distribution per nationality / domain ---- 
CREATE OR REPLACE VIEW v_stay_by_nat AS
SELECT domain, nationality, stay_duration_years, SUM(amount_immigrant) AS total_people
FROM immigration_all
WHERE nationality IS NOT NULL AND stay_duration_years IS NOT NULL
GROUP BY domain, nationality, stay_duration_years;

---- -- housing helper per views---- 
-- Occupants by region/year
CREATE OR REPLACE VIEW v_housing_occupants_region_year AS
SELECT region, year, SUM(amount_occupants) AS occupants
FROM housing_final
WHERE region IS NOT NULL AND year IS NOT NULL
GROUP BY region, year;

-- Stock by region/year
CREATE OR REPLACE VIEW v_housing_stock_region_year AS
SELECT region, year,
       SUM(stock) AS total_stock,
       SUM(owned_by_association)     AS assoc_owned,
       SUM(owned_by_other_landlords) AS other_owned
FROM housing_stock
WHERE region IS NOT NULL AND year IS NOT NULL
GROUP BY region, year;

-- Example combined view (left join; only years/regions present in both will match)
CREATE OR REPLACE VIEW v_housing_region_year AS
SELECT s.region, s.year,
       s.total_stock, s.assoc_owned, s.other_owned,
       o.occupants
FROM v_housing_stock_region_year s
LEFT JOIN v_housing_occupants_region_year o
  ON o.region = s.region AND o.year = s.year;

-- Row counts by table (should match what you saw on load)
SELECT 'family_final' t, COUNT(*) FROM family_final
UNION ALL SELECT 'study_final', COUNT(*) FROM study_final
UNION ALL SELECT 'work_final', COUNT(*) FROM work_final
UNION ALL SELECT 'asylum_final', COUNT(*) FROM asylum_final
UNION ALL SELECT 'housing_final', COUNT(*) FROM housing_final
UNION ALL SELECT 'housing_stock', COUNT(*) FROM housing_stock;

-- Sanity check: top-10 nationalities per domain
SELECT * FROM v_top10_nat_overall ORDER BY domain, total_people DESC;

-- Example: nationality x gender (wide)
SELECT * FROM v_nat_gender_wide ORDER BY domain, total DESC;

-- Predominant age per nationality (per domain)
SELECT * FROM v_predominant_age_by_nat ORDER BY domain, nationality;

USE migration_eda;

DROP VIEW IF EXISTS immigration_all;

CREATE VIEW immigration_all AS
    -- FAMILY (has status)
    SELECT
        'family' AS domain,
        id, gender, age, nationality, motive, status,
        stay_duration_years, immigration_year, amount_immigrant,
        /* ordinal age bucket (safe even if you added a column for it) */
        CASE
            WHEN age = '0-18' THEN 1
            WHEN age = '18-30' THEN 2
            WHEN age = '30-40' THEN 3
            WHEN age = '40+'  THEN 4
        END AS age_ord,
        /* year bin (safe even if you added a column for it) */
        CASE
            WHEN immigration_year < 1999 THEN 'pre-1999'
            WHEN immigration_year BETWEEN 1999 AND 2010 THEN '1999-2010'
            WHEN immigration_year BETWEEN 2011 AND 2019 THEN '2011-2019'
            ELSE '2020s'
        END AS year_bin
    FROM family_final

UNION ALL
    -- STUDY (no status column)
    SELECT
        'study' AS domain,
        id, gender, age, nationality, motive,
        NULL AS status,                                    -- <-- key fix
        stay_duration_years, immigration_year, amount_immigrant,
        CASE
            WHEN age = '0-18' THEN 1
            WHEN age = '18-30' THEN 2
            WHEN age = '30-40' THEN 3
            WHEN age = '40+'  THEN 4
        END AS age_ord,
        CASE
            WHEN immigration_year < 1999 THEN 'pre-1999'
            WHEN immigration_year BETWEEN 1999 AND 2010 THEN '1999-2010'
            WHEN immigration_year BETWEEN 2011 AND 2019 THEN '2011-2019'
            ELSE '2020s'
        END AS year_bin
    FROM study_final

UNION ALL
    -- WORK (no status column)
    SELECT
        'work' AS domain,
        id, gender, age, nationality, motive,
        NULL AS status,                                    -- <-- key fix
        stay_duration_years, immigration_year, amount_immigrant,
        CASE
            WHEN age = '0-18' THEN 1
            WHEN age = '18-30' THEN 2
            WHEN age = '30-40' THEN 3
            WHEN age = '40+'  THEN 4
        END AS age_ord,
        CASE
            WHEN immigration_year < 1999 THEN 'pre-1999'
            WHEN immigration_year BETWEEN 1999 AND 2010 THEN '1999-2010'
            WHEN immigration_year BETWEEN 2011 AND 2019 THEN '2011-2019'
            ELSE '2020s'
        END AS year_bin
    FROM work_final

UNION ALL
    -- ASYLUM (has status)
    SELECT
        'asylum' AS domain,
        id, gender, age, nationality, motive, status,
        stay_duration_years, immigration_year, amount_immigrant,
        CASE
            WHEN age = '0-18' THEN 1
            WHEN age = '18-30' THEN 2
            WHEN age = '30-40' THEN 3
            WHEN age = '40+'  THEN 4
        END AS age_ord,
        CASE
            WHEN immigration_year < 1999 THEN 'pre-1999'
            WHEN immigration_year BETWEEN 1999 AND 2010 THEN '1999-2010'
            WHEN immigration_year BETWEEN 2011 AND 2019 THEN '2011-2019'
            ELSE '2020s'
        END AS year_bin
    FROM asylum_final;

-- -- -- -- -- --

DROP VIEW IF EXISTS v_predominant_age_by_nat;

CREATE VIEW v_predominant_age_by_nat AS
WITH age_totals AS (
    SELECT
        domain, nationality, age,
        SUM(amount_immigrant) AS cnt
    FROM immigration_all
    WHERE nationality IS NOT NULL AND age IS NOT NULL
    GROUP BY domain, nationality, age
),
ranked AS (
    SELECT
        t.*,
        ROW_NUMBER() OVER (
            PARTITION BY domain, nationality
            ORDER BY cnt DESC, age  -- tie-break on age label
        ) AS rnk
    FROM age_totals t
)
SELECT
    domain,
    nationality,
    age AS predominant_age,
    cnt  AS amount_immigrant
FROM ranked
WHERE rnk = 1;

--
-- Helper to create an index only if it doesn't exist
-- Usage: CALL ensure_index('family_final','ix_family_nat_year','(nationality, immigration_year)');

DROP PROCEDURE IF EXISTS ensure_index;
DELIMITER $$
CREATE PROCEDURE ensure_index(
    IN p_table  VARCHAR(64),
    IN p_index  VARCHAR(64),
    IN p_cols   VARCHAR(255)  -- e.g. '(col1, col2)'
)
BEGIN
  DECLARE n INT DEFAULT 0;
  SELECT COUNT(*)
    INTO n
    FROM INFORMATION_SCHEMA.STATISTICS
   WHERE TABLE_SCHEMA = DATABASE()
     AND TABLE_NAME   = p_table
     AND INDEX_NAME   = p_index;

  IF n = 0 THEN
    SET @sql = CONCAT('CREATE INDEX ', p_index, ' ON ', p_table, ' ', p_cols);
    PREPARE s FROM @sql; EXECUTE s; DEALLOCATE PREPARE s;
  END IF;
END$$
DELIMITER ;

-- Family
CALL ensure_index('family_final','ix_family_nat_year','(nationality, immigration_year)');
CALL ensure_index('family_final','ix_family_gender','(gender)');
CALL ensure_index('family_final','ix_family_age','(age)');
CALL ensure_index('family_final','ix_family_stay','(stay_duration_years)');

-- Study
CALL ensure_index('study_final','ix_study_nat_year','(nationality, immigration_year)');
CALL ensure_index('study_final','ix_study_gender','(gender)');
CALL ensure_index('study_final','ix_study_age','(age)');

-- Work
CALL ensure_index('work_final','ix_work_nat_year','(nationality, immigration_year)');
CALL ensure_index('work_final','ix_work_gender','(gender)');
CALL ensure_index('work_final','ix_work_age','(age)');

-- Asylum
CALL ensure_index('asylum_final','ix_asylum_nat_year','(nationality, immigration_year)');
CALL ensure_index('asylum_final','ix_asylum_gender','(gender)');
CALL ensure_index('asylum_final','ix_asylum_age','(age)');

-- Housing (if you want quicker joins/grouping)
CALL ensure_index('housing_stock','ix_hs_region_year','(region, year)');
CALL ensure_index('housing_final','ix_hf_month','(month)');


