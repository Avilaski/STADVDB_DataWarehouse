CREATE TEMPORARY TABLE cleaned (
    `Service:RDT-ID` BIGINT,
    `Service:Date` DATE,
    `Service:Type` VARCHAR(255),
    `Service:Company` VARCHAR(255),
    `Service:Train number` BIGINT,
    `Service:Completely cancelled` BOOLEAN,
    `Service:Partly cancelled` BOOLEAN,
    `Service:Maximum delay` BIGINT,
    `Stop:RDT-ID` BIGINT,
    `Stop:Station code` VARCHAR(255),
    `Stop:Station name` VARCHAR(255),
    `Stop:Arrival time` DATETIME(6),
    `Stop:Arrival delay` BIGINT,
    `Stop:Arrival cancelled` BOOLEAN,
    `Stop:Departure time` DATETIME(6),
    `Stop:Departure delay` BIGINT,
    `Stop:Departure cancelled` BOOLEAN
);
