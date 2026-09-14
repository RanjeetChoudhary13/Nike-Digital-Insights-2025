from pathlib import Path
from getpass import getpass

import pandas as pd
from sqlalchemy import create_engine, text, types
from sqlalchemy.engine import URL

# MySQL connection settings
MYSQL_HOST = "localhost"
MYSQL_PORT = 3306
MYSQL_USER = "root"

DATABASE = "nike_insights_2025"
TABLE = "nike_videos"

# CSV and Python file must be in the same folder
csv_path = (
    Path(__file__).resolve().parent
    / "youtube_shorts_tiktok_trends_2025.csv"
)

if not csv_path.is_file():
    raise FileNotFoundError(
        f"CSV not found: {csv_path}\n"
        "Check the filename and keep both files in the same folder."
    )

print("Reading CSV...")

df = pd.read_csv(
    csv_path,
    encoding="utf-8-sig",
    keep_default_na=False
)

print(f"Rows: {len(df):,}")
print(f"Columns: {len(df.columns)}")

# Convert publication date to a proper date
df["publish_date_approx"] = pd.to_datetime(
    df["publish_date_approx"],
    format="%Y-%m-%d",
    errors="raise"
).dt.date

# Set SQL column types
sql_types = {}

for column in df.columns:
    if column == "publish_date_approx":
        sql_types[column] = types.Date()
    elif pd.api.types.is_integer_dtype(df[column]):
        sql_types[column] = types.BigInteger()
    elif pd.api.types.is_float_dtype(df[column]):
        sql_types[column] = types.Double()
    else:
        sql_types[column] = types.Text()

password = getpass("Enter MySQL password: ")

connection_url = URL.create(
    drivername="mysql+pymysql",
    username=MYSQL_USER,
    password=password,
    host=MYSQL_HOST,
    port=MYSQL_PORT,
    database=DATABASE,
    query={"charset": "utf8mb4"}
)

engine = create_engine(connection_url)

try:
    with engine.begin() as connection:
        print("Connected to MySQL.")
        print("Importing data... Please wait.")

        df.to_sql(
            name=TABLE,
            con=connection,
            if_exists="fail",
            index=False,
            chunksize=1000,
            dtype=sql_types
        )

        imported_rows = connection.execute(
            text("SELECT COUNT(*) FROM nike_videos")
        ).scalar_one()

        if imported_rows != len(df):
            raise RuntimeError("CSV and SQL row counts do not match.")

    print("\nIMPORT SUCCESSFUL")
    print(f"Database: {DATABASE}")
    print(f"Table: {TABLE}")
    print(f"Imported rows: {imported_rows:,}")

finally:
    engine.dispose()