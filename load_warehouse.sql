DELETE FROM railway_warehouse.`Stops and Services`;

DELETE FROM railway_warehouse.`Stop Arrivals`;
DELETE FROM railway_warehouse.`Stop Departures`;

DELETE FROM railway_warehouse.`Stops`;
DELETE FROM railway_warehouse.`Services`;


INSERT INTO railway_warehouse.`Services` (
    `Service:RDT-ID`,
    `Service:Date`,
    `Service:Type`,
    `Service:Company`,
    `Service:Train number`,
    `Service:Completely cancelled`,
    `Service:Partly cancelled`,
    `Service:Maximum delay`
)

SELECT
    `Service:RDT-ID`,
    `Service:Date`,
    `Service:Type`,
    `Service:Company`,
    GROUP_CONCAT(
        DISTINCT `Service:Train number`
        ORDER BY `Service:Train number`
        SEPARATOR ', '
    ),
    `Service:Completely cancelled`,
    `Service:Partly cancelled`,
    MAX(`Service:Maximum delay`)
FROM cleaned
GROUP BY
    `Service:RDT-ID`,
    `Service:Date`,
    `Service:Type`,
    `Service:Company`,
    `Service:Completely cancelled`,
    `Service:Partly cancelled`;


INSERT INTO railway_warehouse.`Stops` (
    `Stop:RDT-ID`,
    `Stop:Station code`,
    `Stop:Station name`
)

SELECT DISTINCT
    `Stop:RDT-ID`,
    `Stop:Station code`,
    `Stop:Station name`
FROM cleaned;


INSERT INTO railway_warehouse.`Stop Arrivals` (
    `Stop:RDT-ID`,
    `Stop:Arrival time`,
    `Stop:Arrival delay`,
    `Stop:Arrival cancelled`
)

SELECT DISTINCT
    `Stop:RDT-ID`,
    `Stop:Arrival time`,
    `Stop:Arrival delay`,
    `Stop:Arrival cancelled`
FROM cleaned;


INSERT INTO railway_warehouse.`Stop Departures` (
    `Stop:RDT-ID`,
    `Stop:Departure time`,
    `Stop:Departure delay`,
    `Stop:Departure cancelled`
)

SELECT DISTINCT
    `Stop:RDT-ID`,
    `Stop:Departure time`,
    `Stop:Departure delay`,
    `Stop:Departure cancelled`
FROM cleaned;


INSERT INTO railway_warehouse.`Stops and Services` (
    `Service:RDT-ID`,
    `Stop:RDT-ID`
)

SELECT DISTINCT
    `Service:RDT-ID`,
    `Stop:RDT-ID`
FROM cleaned;
