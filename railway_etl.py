"""Load the Dutch railway data into the MySQL warehouse."""

# getpass is used to hide the password in the terminal
from getpass import getpass
from datetime import date, datetime, timezone

# Column names from the dataset and their data type
columns = [
    ('Service:RDT-ID', 'number'),
    ('Service:Date', 'date'),
    ('Service:Type', 'text'),
    ('Service:Company', 'text'),
    ('Service:Train number', 'number'),
    ('Service:Completely cancelled', 'boolean'),
    ('Service:Partly cancelled', 'boolean'),
    ('Service:Maximum delay', 'number'),
    ('Stop:RDT-ID', 'number'),
    ('Stop:Station code', 'text'),
    ('Stop:Station name', 'text'),
    ('Stop:Arrival time', 'time'),
    ('Stop:Arrival delay', 'number'),
    ('Stop:Arrival cancelled', 'boolean'),
    ('Stop:Departure time', 'time'),
    ('Stop:Departure delay', 'number'),
    ('Stop:Departure cancelled', 'boolean'),
]

# Used to check how many distinct rows each warehouse table should contain
tables = {
    'Services': [
        'Service:RDT-ID',
        'Service:Date',
        'Service:Type',
        'Service:Company',
        'Service:Train number',
        'Service:Completely cancelled',
        'Service:Partly cancelled',
        'Service:Maximum delay',
    ],
    'Stops': [
        'Stop:RDT-ID',
        'Stop:Station code',
        'Stop:Station name',
    ],
    'Stop Arrivals': [
        'Stop:RDT-ID',
        'Stop:Arrival time',
        'Stop:Arrival delay',
        'Stop:Arrival cancelled',
    ],
    'Stop Departures': [
        'Stop:RDT-ID',
        'Stop:Departure time',
        'Stop:Departure delay',
        'Stop:Departure cancelled',
    ],
    'Stops and Services': [
        'Service:RDT-ID',
        'Stop:RDT-ID',
    ],
}


def connect(password):
    import mysql.connector

    return mysql.connector.connect(
        host="localhost",
        user="root",
        password=password,
    )


def run_sql(cursor, filename):
    with open(filename, encoding="utf-8") as file:
        sql = file.read()

    # Split the SQL script into individual statements and execute them one by one
    for statement in sql.split(";"):
        if statement.strip() != "":
            cursor.execute(statement)

def clean_value(value, type):
    if value is None:
        return None

    value = value.strip()

    if value == "":
        return None

    if type == "text":
        return value

    if type == "number":
        return int(value)

    # Convert into a python date object
    if type == "date":
        return date.fromisoformat(value)

    if type == "boolean":
        if value.lower() in ("true", "1"):
            return True

        if value.lower() in ("false", "0"):
            return False

        raise ValueError("Expected true or false")

    # Convert into a python datetime object in UTC, without timezone info
    if type == "time":
        time = datetime.fromisoformat(value.replace("Z", "+00:00"))

        if time.tzinfo is None:
            raise ValueError("Time must include its timezone offset")

        # The dataset has timezone offsets. Store all times in UTC consistently.
        time = time.astimezone(timezone.utc)

        return time.replace(tzinfo=None)

    raise ValueError("Unknown column type: " + type)

def clean_row(row):
    values = []

    # Validate and clean each value in the row according to its expected type
    for name, type in columns:
        try:
            value = clean_value(row[name], type)
        except ValueError as error:
            raise ValueError(f"{name}: {error}") from error

        # Primary keys must not be null
        if name in ("Service:RDT-ID", "Service:Date", "Stop:RDT-ID"):
            if value is None:
                raise ValueError(name + " is required")

        values.append(value)

    return tuple(values)

# Load the cleaned data from the source database into the warehouse database
# First read rows from the `services_raw` table, then clean those rows, then insert them into the `cleaned` table in the warehouse
def load_data(reader, writer):

    writer.execute("USE railway_warehouse")
    run_sql(writer, "cleaned.sql")
    reader.execute("SELECT * FROM railway_source.services_raw")

    sql = "INSERT INTO cleaned VALUES (" + ", ".join(["%s"] * 17) + ")"
    total = 0

    while True:
        # So that we dont load all rows into memory at once we only fetch 1000 rows at a time
        rows = reader.fetchmany(1000)

        if not rows:
            break

        cleaned_rows = []

        for row in rows:
            total += 1

            try:
                cleaned_rows.append(clean_row(row))
            except ValueError as error:
                raise ValueError(f"Source row {total}: {error}") from error

        writer.executemany(sql, cleaned_rows)

    if total == 0:
        raise ValueError("Source is empty. Warehouse was not changed.")

    # One stop ID should belong to only one service
    writer.execute("""
        SELECT `Stop:RDT-ID`
        FROM cleaned
        GROUP BY `Stop:RDT-ID`
        HAVING COUNT(DISTINCT `Service:RDT-ID`) > 1
        LIMIT 1
    """)

    if writer.fetchone() is not None:
        raise ValueError("A stop ID belongs to more than one service")
    
    # Allow enough space when combining the train numbers of each service.
    writer.execute("SET SESSION group_concat_max_len = 65535")
    run_sql(writer, "load_warehouse.sql")

    # Check that the number of distinct rows in each warehouse table matches the expected number of distinct rows in the cleaned table
    for table, names in tables.items():
        selected = []

        for name in names:
            # These two columns are combined into one value per service.
            if table == "Services":
                if name in ("Service:Maximum delay", "Service:Train number"):
                    continue

            selected.append("`" + name + "`")

        selected = ", ".join(selected)

        writer.execute(f"""
            SELECT COUNT(*)
            FROM (SELECT DISTINCT {selected} FROM cleaned) AS records
        """)
        expected = writer.fetchone()[0]

        writer.execute(f"SELECT COUNT(*) FROM railway_warehouse.`{table}`")
        actual = writer.fetchone()[0]

        if expected != actual:
            raise ValueError("Wrong number of rows in " + table)

        print(f"{table}: {actual} rows checked")

    return total


def main():
    password = getpass("MySQL password: ")
    connection = connect(password)
    source = None

    try:
        source = connect(password)
        reader = source.cursor(dictionary=True)
        writer = connection.cursor()

        total = load_data(reader, writer)

        connection.commit()
        print(f"Finished loading {total} source rows into the warehouse.")
    except Exception:
        connection.rollback()
        raise
    finally:
        connection.close()

        if source is not None:
            source.close()


if __name__ == "__main__":
    main()
