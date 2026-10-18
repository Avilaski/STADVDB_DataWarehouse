"""Functional checks for the etl script"""
import csv
import tempfile
import unittest

from datetime import date, datetime
from pathlib import Path

from import_source import import_csv
from railway_etl import clean_row, clean_value


def sample_row():
    filename = Path(__file__).parent / "test_data" / "month_sample.csv"

    with open(filename, encoding="utf-8", newline="") as file:
        return next(csv.DictReader(file))


class CleaningTests(unittest.TestCase):
    def test_trim_spaces(self):
        self.assertEqual(clean_value(" Tiel ", "text"), "Tiel")

    def test_empty_values_become_null(self):
        for value in (None, "", "   "):
            with self.subTest(value=value):
                self.assertIsNone(clean_value(value, "number"))

    def test_number_and_negative_delay(self):
        self.assertEqual(clean_value("6728", "number"), 6728)
        self.assertEqual(clean_value("-1", "number"), -1)

    def test_invalid_number(self):
        with self.assertRaises(ValueError):
            clean_value("abc", "number")

    def test_boolean_values(self):
        self.assertIs(clean_value("TRUE", "boolean"), True)
        self.assertIs(clean_value("0", "boolean"), False)

    def test_invalid_boolean(self):
        with self.assertRaises(ValueError):
            clean_value("maybe", "boolean")

    def test_valid_date(self):
        self.assertEqual(clean_value("2024-01-01", "date"), date(2024, 1, 1))

    def test_invalid_date(self):
        with self.assertRaises(ValueError):
            clean_value("2024-02-30", "date")

    def test_winter_and_summer_time_offsets(self):
        winter = clean_value("2024-01-01T09:18:00+01:00", "time")
        summer = clean_value("2024-07-01T09:18:00+02:00", "time")

        self.assertEqual(winter, datetime(2024, 1, 1, 8, 18))
        self.assertEqual(summer, datetime(2024, 7, 1, 7, 18))

    def test_time_without_offset(self):
        with self.assertRaises(ValueError):
            clean_value("2024-01-01T09:18:00", "time")

    def test_service_date_is_preserved_across_midnight(self):
        row = sample_row()
        row["Stop:Departure time"] = "2024-01-02T01:30:00+01:00"

        result = clean_row(row)

        self.assertEqual(result[1], date(2024, 1, 1))
        self.assertEqual(result[14], datetime(2024, 1, 2, 0, 30))

    def test_required_fields(self):
        for name in ("Service:RDT-ID", "Service:Date", "Stop:RDT-ID"):
            row = sample_row()
            row[name] = ""

            with self.subTest(column=name):
                with self.assertRaisesRegex(ValueError, "required"):
                    clean_row(row)

    def test_origin_without_arrival(self):
        result = clean_row(sample_row())

        self.assertEqual(result[11:14], (None, None, None))
        self.assertEqual(result[14], datetime(2024, 1, 1, 8, 18))

    def test_missing_train_number_is_allowed(self):
        row = sample_row()
        row["Service:Train number"] = ""

        self.assertIsNone(clean_row(row)[4])


# Capture imported values instead of sending them to an actual db
class SampleCursor:
    def __init__(self):
        self.rows = []

    def executemany(self, sql, rows):
        self.rows.extend(rows)


class ImportTests(unittest.TestCase):
    def test_import_preserves_raw_values(self):
        filename = Path(__file__).parent / "test_data" / "month_sample.csv"
        cursor = SampleCursor()

        total = import_csv(cursor, str(filename))

        self.assertEqual(total, 4)
        self.assertEqual(len(cursor.rows), 4)
        self.assertEqual(cursor.rows[0][2], " Sprinter ")
        self.assertEqual(cursor.rows[0], cursor.rows[2])

    def test_missing_header(self):
        with tempfile.TemporaryDirectory() as folder:
            filename = Path(folder) / "missing_header.csv"
            filename.write_text("Service:RDT-ID\n900001\n", encoding="utf-8")

            with self.assertRaisesRegex(ValueError, "Missing CSV column"):
                import_csv(SampleCursor(), str(filename))


if __name__ == "__main__":
    unittest.main()
