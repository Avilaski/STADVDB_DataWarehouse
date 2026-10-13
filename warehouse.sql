CREATE DATABASE IF NOT EXISTS `railway_warehouse`;


CREATE TABLE IF NOT EXISTS `railway_warehouse`.`Services` (
    `Service:RDT-ID` BIGINT NOT NULL,
    `Service:Date` DATE NOT NULL,
    `Service:Type` VARCHAR(255),
    `Service:Company` VARCHAR(255),
    `Service:Train number` TEXT,
    `Service:Completely cancelled` BOOLEAN,
    `Service:Partly cancelled` BOOLEAN,
    `Service:Maximum delay` BIGINT,

    PRIMARY KEY (`Service:RDT-ID`)
);


CREATE TABLE IF NOT EXISTS `railway_warehouse`.`Stops` (
    `Stop:RDT-ID` BIGINT NOT NULL,
    `Stop:Station code` VARCHAR(255),
    `Stop:Station name` VARCHAR(255),

    PRIMARY KEY (`Stop:RDT-ID`)
);


CREATE TABLE IF NOT EXISTS `railway_warehouse`.`Stop Arrivals` (
    `Stop:RDT-ID` BIGINT NOT NULL,
    `Stop:Arrival time` DATETIME(6),
    `Stop:Arrival delay` BIGINT,
    `Stop:Arrival cancelled` BOOLEAN,

    PRIMARY KEY (`Stop:RDT-ID`),

    FOREIGN KEY (`Stop:RDT-ID`)
        REFERENCES `railway_warehouse`.`Stops` (`Stop:RDT-ID`)
);


CREATE TABLE IF NOT EXISTS `railway_warehouse`.`Stop Departures` (
    `Stop:RDT-ID` BIGINT NOT NULL,
    `Stop:Departure time` DATETIME(6),
    `Stop:Departure delay` BIGINT,
    `Stop:Departure cancelled` BOOLEAN,

    PRIMARY KEY (`Stop:RDT-ID`),

    FOREIGN KEY (`Stop:RDT-ID`)
        REFERENCES `railway_warehouse`.`Stops` (`Stop:RDT-ID`)
);


CREATE TABLE IF NOT EXISTS `railway_warehouse`.`Stops and Services` (
    `Service:RDT-ID` BIGINT NOT NULL,
    `Stop:RDT-ID` BIGINT NOT NULL,

    PRIMARY KEY (`Service:RDT-ID`, `Stop:RDT-ID`),

    FOREIGN KEY (`Stop:RDT-ID`)
        REFERENCES `railway_warehouse`.`Stops` (`Stop:RDT-ID`),

    FOREIGN KEY (`Service:RDT-ID`)
        REFERENCES `railway_warehouse`.`Services` (`Service:RDT-ID`)
);
