-- M02
SELECT `Service:RDT-ID`, `Service:Maximum delay`
FROM railway_warehouse.`Services`
WHERE `Service:RDT-ID` = 900001;

-- M03
SELECT *
FROM railway_warehouse.`Service Train Numbers`
ORDER BY `Service:RDT-ID`, `Service:Train number`;

-- M04
SELECT
    s.`Stop:Station name`,
    a.`Stop:Arrival time`,
    a.`Stop:Arrival delay`,
    a.`Stop:Arrival cancelled`,
    d.`Stop:Departure time`
FROM railway_warehouse.`Stops` AS s
JOIN railway_warehouse.`Stop Arrivals` AS a
    ON a.`Stop:RDT-ID` = s.`Stop:RDT-ID`
JOIN railway_warehouse.`Stop Departures` AS d
    ON d.`Stop:RDT-ID` = s.`Stop:RDT-ID`
WHERE s.`Stop:RDT-ID` = 910001;

-- M05
SELECT
    a.`Stop:Arrival time`,
    a.`Stop:Arrival delay`,
    a.`Stop:Arrival cancelled`,
    d.`Stop:Departure time`,
    d.`Stop:Departure delay`,
    d.`Stop:Departure cancelled`
FROM railway_warehouse.`Stop Arrivals` AS a
JOIN railway_warehouse.`Stop Departures` AS d
    ON d.`Stop:RDT-ID` = a.`Stop:RDT-ID`
WHERE a.`Stop:RDT-ID` = 910002;

-- M06-1
SELECT `Service:Completely cancelled`
FROM railway_warehouse.`Services`
WHERE `Service:RDT-ID` = 900002;

-- M06-2
SELECT `Stop:Arrival cancelled`, `Stop:Arrival delay`
FROM railway_warehouse.`Stop Arrivals`
WHERE `Stop:RDT-ID` = 910003;

-- Check this and save before running M07 for comparison
SELECT * FROM railway_warehouse.`Services`
ORDER BY `Service:RDT-ID`;

SELECT * FROM railway_warehouse.`Stops`
ORDER BY `Stop:RDT-ID`;

SELECT * FROM railway_warehouse.`Stop Arrivals`
ORDER BY `Stop:RDT-ID`;

SELECT * FROM railway_warehouse.`Stop Departures`
ORDER BY `Stop:RDT-ID`;

SELECT * FROM railway_warehouse.`Stops and Services`
ORDER BY `Service:RDT-ID`, `Stop:RDT-ID`;

SELECT * FROM railway_warehouse.`Service Train Numbers`
ORDER BY `Service:RDT-ID`, `Service:Train number`;

-- M07 Just check if its the same count

-- M08
SELECT COUNT(*) AS source_rows
FROM railway_source.services_raw;

-- M09
TRUNCATE TABLE railway_source.services_raw;

-- Then
SET SQL_SAFE_UPDATES = 0;

UPDATE railway_source.services_raw
SET `Stop:Departure delay` = 'abc'
WHERE `Stop:RDT-ID` = '910001';

COMMIT;

SET SQL_SAFE_UPDATES = 1;

-- ,10
TRUNCATE TABLE railway_source.services_raw;

-- then reimport, before railway_etl, run
SET SQL_SAFE_UPDATES = 0;

UPDATE railway_source.services_raw
SET `Service:RDT-ID` = '900002'
WHERE `Stop:RDT-ID` = '910001'
LIMIT 1;

COMMIT;

SET SQL_SAFE_UPDATES = 1;

-- M11
TRUNCATE TABLE railway_source.services_raw;

-- then reimport, before railway_etl, run
SET SQL_SAFE_UPDATES = 0;

UPDATE railway_source.services_raw
SET `Stop:Station name` = 'Different Station'
WHERE `Stop:RDT-ID` = '910001'
LIMIT 1;

COMMIT;

SET SQL_SAFE_UPDATES = 1;

-- Check if the name is still Tiel
SELECT `Stop:Station name`
FROM railway_warehouse.`Stops`
WHERE `Stop:RDT-ID` = 910001;

-- M12
TRUNCATE TABLE railway_source.services_raw;

SELECT COUNT(*)
FROM railway_source.services_raw;

-- Once empty, run railway_etl, should be an error

-- M13
-- With an empty source still, reimport 