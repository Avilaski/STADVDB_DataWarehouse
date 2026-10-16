-- Only run this when you intend to discard the existing warehouse
-- This does not delete the raw source database
-- Afterwards, execute warehouse.sql to create the new tables
DROP TABLE IF EXISTS railway_warehouse.`Service Train Numbers`;
DROP TABLE IF EXISTS railway_warehouse.`Stops and Services`;
DROP TABLE IF EXISTS railway_warehouse.`Stop Arrivals`;
DROP TABLE IF EXISTS railway_warehouse.`Stop Departures`;
DROP TABLE IF EXISTS railway_warehouse.`Stops`;
DROP TABLE IF EXISTS railway_warehouse.`Services`;
