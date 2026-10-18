
## Running the tests

Run from the root folder:

```
py -m unittest -v test_etl
```

The tests use sample values and a cursor to capture the imported rows from the csv

| ID | Input / condition | Expected result |
|---|---|---|
| A01 | Text with surrounding spaces | Spaces removed, internal text preserved |
| A02 | None, empty text, spaces only | Python None, ready to become SQL NULL |
| A03 | Numeric text and negative delay | Integers, negative delay preserved |
| A04 | abc as a number | ValueError |
| A05 | TRUE and 0 | True and False |
| A06 | maybe as a boolean | ValueError |
| A07 | Valid service date | Correct date object |
| A08 | February 30 | ValueError |
| A09 | Winter +01:00 and summer +02:00 timestamps | Correct UTC values |
| A10 | Timestamp without an offset | ValueError |
| A11 | Stop occurs after midnight on a later date | Service date stays unchanged |
| A12 | Missing service ID, stop ID or service date | ValueError identifying required field |
| A13 | Origin with no arrival | Arrival fields remain NULL, departure retained |
| A14 | Missing train number | Row accepted with train number NULL |
| A15 | Import sample CSV with four raw rows | Four rows imported text and duplicates preserved in source |
| A16 | CSV missing required headers | Import rejected |

## MySQL loading checks

Run these on another test database with the same source and warehouse names
For example on a separate local MySQL server. The ETL replaces warehouse
contents so DONT use on the actual warehouse

Start with empty source and warehouse tables created using source.sql and
warehouse.sql. Import test_data/month_sample.csv using import_source.py, then run
railway_etl.py. The sample contains four raw rows:
three different stop visits
two services
two train numbers for service 900001
and one identical duplicate

Service 900002 has no train number. It has a cancelled arrival and a negative delay.

| ID | Procedure | Expected result |
|---|---|---|
| M01 | Load the unmodified sample | Counts: Services 2, Stops 3, Stop Arrivals 3, Stop Departures 3, Stops and Services 3, Service Train Numbers 2 |
| M02 | Inspect service 900001 | One service row, maximum delay 8, despite input values 8 and 0 |
| M03 | Inspect Service Train Numbers | Exactly (900001, 6728) and (900001, 8828), stored numerically, no pair for 900002 |
| M04 | Inspect stop 910001 | Station name Tiel without outer spaces, NULL arrival details, departure 2024-01-01 08:18:00 UTC |
| M05 | Inspect stop 910002 | Arrival retained, departure details NULL |
| M06 | Inspect service 900002 and stop 910003 | Completely cancelled true, arrival cancelled true, arrival delay -1 retained |
| M07 | Run ETL again without changing source | All six table contents and counts unchanged |
| M08 | Import the same sample again, then run ETL | Source has 8 rows, warehouse contents stay unchanged |
| M09 | In a copy of the sample, blank a required ID/date, or set a delay to abc | ETL reports error, previous warehouse remains unchanged |
| M10 | Add a row assigning stop 910001 to service 900002 | ETL rejects multiple services for one stop, previous warehouse unchanged |
| M11 | Add a copy of stop 910001 with a different station name | Primary-key error during loading, previous warehouse contents restored by rollback |
| M12 | Empty the test source and run ETL | Empty-source error, previous warehouse remains unchanged |
| M13 | Finally load the chosen real monthly dataset | Load completes, six table counts print, manually compare several raw rows to their cleaned warehouse records |

For M09-M11, use a fresh copy of the original sample for each case and replace
only the disposable test source. Keep the successful M01 warehouse as the
baseline. Compare all six tables before and after a failed load, not just counts.
These cases verify rollback of warehouse data. They do not roll back the separate
CSV import, which has already committed to the test source
