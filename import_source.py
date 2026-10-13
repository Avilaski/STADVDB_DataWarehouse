"""Import a downloaded railway CSV into the MySQL source database"""
import csv

from getpass import getpass
from railway_etl import columns, connect, run_sql

# Import the CSV into the source (raw values) database
def import_csv(cursor, filename):
    sql = "INSERT INTO railway_source.services_raw VALUES (" + ", ".join(["%s"] * 17) + ")"
    rows = []
    total = 0

    with open(filename, "r", encoding="utf-8-sig", newline="") as file:
        reader = csv.DictReader(file)

        for name, type in columns:
            if name not in (reader.fieldnames or []):
                raise ValueError("Missing CSV column: " + name)

        for row in reader:
            if None in row:
                raise ValueError("CSV row has too many values")

            values = []

            for name, type in columns:
                if row[name] is None:
                    raise ValueError("CSV row has too few values")

                values.append(row[name])

            rows.append(tuple(values))
            total += 1

            if len(rows) == 1000:
                cursor.executemany(sql, rows)
                rows = []

        if rows:
            cursor.executemany(sql, rows)

    return total


def main():
    filename = input("CSV filename: ").strip()

    if filename == "":
        print("Provide a filename.")
        return

    password = getpass("MySQL password: ")
    connection = connect(password)

    try:
        cursor = connection.cursor()
        run_sql(cursor, "source.sql")

        total = import_csv(cursor, filename)

        connection.commit()
        print(f"Imported {total} source rows.")
    except Exception:
        connection.rollback()
        raise
    finally:
        connection.close()


if __name__ == "__main__":
    main()
