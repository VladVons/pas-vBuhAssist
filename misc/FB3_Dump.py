 # VladVons@gmail.com, 2026.01.30
# Native FireBird dump doesnt export to text SQL


import fdb
import os

# Directory where table dumps will be stored
export_dir = 'Medoc_2SRV'
#export_dir = 'Medoc'
os.makedirs(export_dir, exist_ok=True)

tables_incl = []
#tables_incl = ['ORG', 'CARD', 'FORM']
tables_excl = []
tables_excl = ['CERTIF', 'CERTIF1', 'CERTIFBLOB', 'CERTIFBLOBGOV', 'CERTIFCASTE', 'CERTIFCASTE2', 'CERTIFGOV', 'CERTTYPEACSK']

# Connection settings
host = 'localhost'
database = rf'C:\ProgramData\Medoc\{export_dir}\db\ZVIT.FDB'
user = 'SYSDBA'
password = 'masterkey'
charset = 'UTF8'

# Connect to Firebird database
con = fdb.connect(
    host=host,
    database=database,
    user=user,
    password=password,
    charset=charset
)
cur = con.cursor()

# Get list of user tables
if (not tables_incl):
  cur.execute("""
    SELECT RDB$RELATION_NAME
    FROM RDB$RELATIONS
    WHERE RDB$SYSTEM_FLAG = 0
  """)
  tables_incl = [row[0].strip() for row in cur.fetchall()]
tables_incl.sort()

# -----------------------------
# Export each non-empty table
# -----------------------------
TableCnt = 0
FieldCnt = 0
for table in tables_incl:
    if (table in tables_excl):
        continue
    
    # Check if table contains at least one row
    cur.execute(f"SELECT FIRST 1 1 FROM {table}")
    if cur.fetchone() is None:
        # Skip empty tables
        continue

    TableCnt += 1
    print(f'Exporting table: {table}. {TableCnt} / {len(tables_incl)}')

    # Get column names in correct order
    cur.execute(f"""
        SELECT RDB$FIELD_NAME
        FROM RDB$RELATION_FIELDS
        WHERE RDB$RELATION_NAME = '{table}'
        ORDER BY RDB$FIELD_POSITION
    """)
    columns = [row[0].strip() for row in cur.fetchall()]
    column_list = ', '.join(columns)

    # Prepare output file for this table
    table_file = os.path.join(export_dir, f'{table}.sql')

    with open(table_file, 'w', encoding='utf-8') as f:
        # Fetch all rows from table
        cur.execute(f"SELECT * FROM {table}")
        rows = cur.fetchall()

        FieldCnt += len(cur.description)
        f.write(f'table: {table}, fields: {len(cur.description)}, rows: {len(rows)}\n')

        for row in rows:
            values = []
            for value in row:
                if value is None:
                    values.append('NULL')
                elif isinstance(value, str):
                    # Escape single quotes for SQL
                    values.append("'" + value.replace("'", "''") + "'")
                else:
                    values.append(str(value))

                #values_list = ', '.join(values)
                #Res = f'({column_list}) VALUES ({values_list})

            Res = ", ".join(f"{k} = {v}" for k, v in zip(columns, values))
            f.write(Res + '\n' )

con.close()

print(f'Export dir: {export_dir}')
print(f'Tables: {TableCnt} / {len(tables_incl)}')
print(f'Fields: {FieldCnt}')
