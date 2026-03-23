import os
import zipfile
import pyodbc
import pandas as pd
from sqlalchemy import create_engine
import urllib

# ─── CONFIG ───────────────────────────────────────────────
IPEDS_ROOT = r"C:\Users\timot\OneDrive - University of Nebraska\Data\IPEDS"
EXTRACT_BASE = r"C:\IPEDS_temp"
SERVER = r"OKOLIKO\SQLEXPRESS"
DATABASE = "IPEDS_StudentSuccess"

# Tables we want from each year
TARGET_TABLES = ["GR", "HD", "EF", "DRVGR"]

# ─── SQL SERVER CONNECTION ─────────────────────────────────
params = urllib.parse.quote_plus(
    f"DRIVER={{ODBC Driver 17 for SQL Server}};"
    f"SERVER={SERVER};"
    f"DATABASE={DATABASE};"
    f"Trusted_Connection=yes;"
)
engine = create_engine(f"mssql+pyodbc:///?odbc_connect={params}")

# ─── HELPER: FIND MATCHING TABLE ──────────────────────────
def find_table(cursor, keyword):
    """Find a table name containing the keyword"""
    for row in cursor.tables(tableType='TABLE'):
        if keyword.upper() in row.table_name.upper():
            return row.table_name
    return None

# ─── MAIN ETL LOOP ────────────────────────────────────────
year_folders = [f for f in os.listdir(IPEDS_ROOT) 
                if os.path.isdir(os.path.join(IPEDS_ROOT, f)) 
                and f.startswith("IPEDS")]

print(f"Found {len(year_folders)} year folders\n")

for folder in sorted(year_folders):
    folder_path = os.path.join(IPEDS_ROOT, folder)
    print(f"Processing: {folder}")

    # Find zip file
    zip_files = [f for f in os.listdir(folder_path) if f.endswith(".zip")]
    if not zip_files:
        print(f"  No zip found, skipping")
        continue

    zip_path = os.path.join(folder_path, zip_files[0])
    extract_to = os.path.join(EXTRACT_BASE, folder)
    os.makedirs(extract_to, exist_ok=True)

    # Extract zip
    with zipfile.ZipFile(zip_path, 'r') as z:
        z.extractall(extract_to)

    # Find Access database
    db_path = None
    for root, dirs, files in os.walk(extract_to):
        for file in files:
            if file.endswith(".accdb") or file.endswith(".mdb"):
                db_path = os.path.join(root, file)
                break

    if not db_path:
        print(f"  No Access database found, skipping")
        continue

    # Connect to Access
    access_conn_str = (
        f"Driver={{Microsoft Access Driver (*.mdb, *.accdb)}};"
        f"DBQ={db_path};"
    )
    access_conn = pyodbc.connect(access_conn_str)
    cursor = access_conn.cursor()

    # Extract each target table
    for table_key in TARGET_TABLES:
        table_name = find_table(cursor, table_key)
        if not table_name:
            print(f"  {table_key} - not found, skipping")
            continue

        try:
            df = pd.read_sql(f"SELECT * FROM [{table_name}]", access_conn)

            # Add year column for tracking
            year_label = folder.replace("IPEDS ", "").replace("_", "-")
            df["data_year"] = year_label

            # Clean column names
            df.columns = [c.strip().replace(" ", "_").replace("-", "_") 
                         for c in df.columns]

            # Load to SQL Server
            sql_table = f"{table_key}_IPEDS"
            df.to_sql(
                sql_table,
                engine,
                if_exists="append",
                index=False,
                chunksize=500
            )
            print(f"  {table_key} - loaded {len(df)} rows into {sql_table}")

        except Exception as e:
            print(f"  {table_key} - error: {e}")

    access_conn.close()

print("\nETL complete. All data loaded into IPEDS_StudentSuccess.")