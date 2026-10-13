CREATE DATABASE IF NOT EXISTS railway_source;

CREATE TABLE IF NOT EXISTS railway_source.services_raw (
    `Service:RDT-ID` LONGTEXT,
    `Service:Date` LONGTEXT,
    `Service:Type` LONGTEXT,
    `Service:Company` LONGTEXT,
    `Service:Train number` LONGTEXT,
    `Service:Completely cancelled` LONGTEXT,
    `Service:Partly cancelled` LONGTEXT,
    `Service:Maximum delay` LONGTEXT,

    `Stop:RDT-ID` LONGTEXT,
    `Stop:Station code` LONGTEXT,
    `Stop:Station name` LONGTEXT,

    `Stop:Arrival time` LONGTEXT,
    `Stop:Arrival delay` LONGTEXT,
    `Stop:Arrival cancelled` LONGTEXT,

    `Stop:Departure time` LONGTEXT,
    `Stop:Departure delay` LONGTEXT,
    `Stop:Departure cancelled` LONGTEXT
);
