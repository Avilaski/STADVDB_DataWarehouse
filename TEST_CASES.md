
## Running the tests

Run from the root folder:

```
py -m unittest -v test_etl
```

The tests use sample values and a cursor to capture the imported rows from the csv

| ID | Input / condition | Expected result | Purpose |
|---|---|---|---|
| A01 | Text with surrounding spaces | Spaces removed, internal text preserved | Checks that outer whitespace is removed without changing the text itself|
| A02 | None, empty text, spaces only | Python None, ready to become SQL NULL | Checks that missing values stay unknown instead of becoming zero or false |
| A03 | Numeric text and negative delay | Integers, negative delay preserved | Checks numeric conversion and preservation of early arrivals or departures represented by negative delays|
| A04 | abc as a number | ValueError | Checks that invalid numeric input is rejected |
| A05 | TRUE and 0 | True and False | Checks that accepted boolean representations are converted correctly |
| A06 | maybe as a boolean | ValueError | Checks that ambiguous boolean input is rejected |
| A07 | Valid service date | Correct date object | Checks conversion of the scheduled service date |
| A08 | February 30 | ValueError | Checks that impossible calendar dates are rejected |
| A09 | Winter +01:00 and summer +02:00 timestamps | Correct UTC values | Checks UTC conversion for both winter and summer offsets |
| A10 | Timestamp without an offset | ValueError | Checks that the program does not guess a timezone for a timestamp |
| A11 | Stop occurs after midnight on a later date | Service date stays unchanged | Checks that a stop timestamp does not overwrite the scheduled service date|
| A12 | Missing service ID, stop ID or service date | ValueError identifying required field | Checks that records cannot be loaded without their required identifiers and date |
| A13 | Origin with no arrival | Arrival fields remain NULL, departure retained | Checks that a valid origin stop is accepted even without an arrival |
| A14 | Missing train number | Row accepted with train number NULL | Checks that an unknown train number does not cause a valid source row to be rejected |
| A15 | Import sample CSV with four raw rows | Four rows imported text and duplicates preserved in source | Checks that importing preserves raw values and duplicates for later ETL processing |
| A16 | CSV missing required headers | Import rejected | Checks that a CSV with an incomplete column structure is rejected |

## MySQL loading checks

Run these on another test database with the same source and warehouse names
For example on a separate local MySQL server. The ETL replaces warehouse
contents so DONT use on the actual warehouse. 

If your database already has existing data, export it, then 
```
TRUNCATE TABLE railway_source.services_raw;
```

Then with empty source and warehouse tables created using source.sql and
warehouse.sql. Import test_data/month_sample.csv using import_source.py, then run
railway_etl.py. The sample contains four raw rows:
three different stop visits
two services
two train numbers for service 900001
and one identical duplicate

Service 900002 has no train number. It has a cancelled arrival and a negative delay.

Manual testing on the test data:

| ID | Procedure | Expected result | Purpose |
|---|---|---|---|
| M01 | Load the unmodified sample | Counts: Services 2, Stops 3, Stop Arrivals 3, Stop Departures 3, Stops and Services 3, Service Train Numbers 2 | Checks that the complete ETL populates all six tables with the expected distinct records |
| M02 | Inspect service 900001 | One service row, maximum delay 8, despite input values 8 and 0 | Checks maximum-delay aggregation and one warehouse record per service |
| M03 | Inspect Service Train Numbers | 900001, 6728 and 900001, 8828 | Checks that multiple train numbers are preserved as separate numeric associations |
| M04 | Inspect stop 910001 | Station name Tiel without outer spaces, NULL arrival details, departure 2024-01-01 08:18:00 UTC | Checks that whitespace cleaning, missing arrivals and UTC conversion survive database loading |
| M05 | Inspect stop 910002 | Arrival retained, departure details NULL | Checks that a valid terminal stop keeps its arrival and does not invent a departure |
| M06 | Inspect service 900002 and stop 910003 | Completely cancelled true, arrival cancelled true, arrival delay -1 retained | Checks that cancellation flags and negative delays are preserved in the warehouse. |
| M07 | Run ETL again without changing source | All six table contents and counts unchanged | Checks that rerunning unchanged input does not change warehouse contents or create duplicates. |
| M08 | Import the same sample again, then run ETL | Source has 8 rows, warehouse contents stay unchanged | Checks that duplicate source imports do not duplicate warehouse records. |
| M09 | In a copy of the sample, blank a required ID/date, or set a delay to abc | ETL reports error, previous warehouse remains unchanged | Checks rejection of missing required values or invalid numbers and preservation of the existing warehouse. |
| M10 | Add a row assigning stop 910001 to service 900002 | ETL rejects multiple services for one stop, previous warehouse unchanged | Checks that one stop ID cannot be associated with two services. |
| M11 | Add a copy of stop 910001 with a different station name | Primary-key error during loading, previous warehouse contents restored by rollback | Checks primary-key conflict handling and rollback after warehouse loading has already started. |
| M12 | Empty the test source and run ETL | Empty-source error, previous warehouse remains unchanged | Checks that an empty source cannot erase the existing warehouse |

For M09-M11, use a fresh copy of the original sample for each case and replace
only the disposable test source. Keep the successful M01 warehouse as the
baseline. Compare all six tables before and after a failed load, not just counts.
These cases verify rollback of warehouse data. They do not roll back the separate
CSV import, which has already committed to the test source
