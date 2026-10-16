# Starting the Railway ETL

## 1. Prepare MySQL and Python

Install Python and MySQL 8.0 or newer, then start MySQL Server

The scripts connect to localhost using the MySQL user root

## 2. Install the Python dependency

Open cmd or powershell and run this IN trhe root folder

```
py -m pip install -r requirements.txt
```

## 3. Create the warehouse tables

Open warehouse.sql in MySQL Workbench and execute the entire file.
Do this for the initial setup

The connection should be:
hostname: localhost
Port: 3306
Username: root

## 4. Prepare the dataset

Download a file from [Dutch Railway Datasets](https://duckdb.org/docs/lts/guides/snippets/dutch_railway_datasets)

Extract the downloaded .csv.gz file to get its csv file
Place the extracted file in the /data folder. The data foldewr should NOT have .gz in it (maybe in the future we can extract it via script)
Create the data folder if it does not exist

## 5. Import the CSV

From the root folder run:

```
py import_source.py
```

Enter your extracted CSV filename, for example:

```
data/services-2025-03.csv
```

It MUST have the "data/" and ".csv"

Enter your MySQL password. The script creates the source table using
source.sql and imports the CSV records.

## 6. Run the ETL

```
py railway_etl.py
```

Enter your MySQL password again. The script reads the source database
cleans the records, and loads the six warehouse tables. It prints the table
counts and a completion message when finished

The pipeline is basically:
```
CSV > Source database > Cleaned data > Warehouse tables
```

The steps are:
```
1. Execute warehouse.sql (Create empty warehouse)
2. Put CSV in data folder (Extracted CSV file) 
3. import_source.py (Imports the CSV into source.sql, a raw data table)
4. railway_etl.py cleans data in source.sql, then puts them into temp table cleaned.sql
5. load_warehouse.sql loads the cleaned data into the actual warehouse database

```
Each CSV import adds records to the source database
Basically importing a CSV adds its data to the source database of raw values.
Then running the railway_etl script cleans the entire source database again, then rebuilds the warehouse.
May be able to refine in the future.

Import each file ONLY once.

For another dataset file just repeat steps 5 and 6



## FOLLOWING RECENT SCHEMA CHANGE: numbers

Services now has one row per service and no train-number column.
Service Train Numbers stores one row per distinct service ID and train number
The other four tables are unchanged.
Source imports and temporary cleaned rows are unchanged.

For an existing warehouse, execute reset_warehouse.sql in Workbench, then
warehouse.sql. The reset permanently deletes the six warehouse tables and their
contents, though not touching railway_source 

If you want to clear out the source database too, run:

```sql
TRUNCATE TABLE railway_source.services_raw;
```

Then run import_source.py for each CSV and railway_etl.py to load the warehouse
If you keep the existing source instead, you can just rerun the ETL without needing to reimport