# Adicionei logs básicos em pontos críticos
import os, zipfile, json, tempfile
from pathlib import Path
import psycopg2
from psycopg2 import sql
from psycopg2.extras import execute_values
from dotenv import load_dotenv

load_dotenv()

TABLE_NAME = "mortalidade"


def connect():
    print("Conectando ao banco...")
    return psycopg2.connect(
        host=os.getenv("POSTGRES_HOST"),
        port=int(os.getenv("POSTGRES_PORT")),
        user=os.getenv("POSTGRES_USER"),
        password=os.getenv("POSTGRES_PASSWORD"),
        dbname=os.getenv("POSTGRES_DB"),
    )


def ensure_table(cur):
    print("Garantindo tabela...")
    cur.execute(
        sql.SQL(
            """
            CREATE TABLE IF NOT EXISTS {tbl} (
                id BIGSERIAL PRIMARY KEY
            );
            """
        ).format(tbl=sql.Identifier(TABLE_NAME))
    )


def get_existing_columns(cur):
    cur.execute(
        """
        SELECT column_name
        FROM information_schema.columns
        WHERE table_name = %s AND table_schema = current_schema()
        """,
        (TABLE_NAME,),
    )
    cols = {r[0] for r in cur.fetchall()}
    print(f"Colunas existentes: {len(cols)}")
    return cols


def add_missing_columns(cur, missing_cols):
    if not missing_cols:
        return
    print(f"Adicionando colunas: {missing_cols}")
    for col in sorted(missing_cols):
        cur.execute(
            sql.SQL("ALTER TABLE {tbl} ADD COLUMN IF NOT EXISTS {col} TEXT").format(
                tbl=sql.Identifier(TABLE_NAME), col=sql.Identifier(col)
            )
        )


def coerce_value(v):
    if v is None:
        return None
    if isinstance(v, (str, int, float, bool)):
        return str(v)
    return json.dumps(v, ensure_ascii=False)


def insert_batch(cur, rows):
    if not rows:
        return
    print(f"Inserindo lote com {len(rows)} registros...")
    keys = list(rows[0].keys())
    cols = [sql.Identifier(k) for k in keys]

    values = [tuple(coerce_value(r[k]) for k in keys) for r in rows]

    query = sql.SQL("INSERT INTO {tbl} ({fields}) VALUES %s").format(
        tbl=sql.Identifier(TABLE_NAME),
        fields=sql.SQL(", ").join(cols),
    )
    execute_values(cur, query, values)


def iter_json_files_from_zip(zip_path: Path):
    print(f"Lendo arquivo: {zip_path}")
    with zipfile.ZipFile(zip_path) as z:
        with tempfile.TemporaryDirectory() as tmpdir:
            z.extractall(tmpdir)
            for p in Path(tmpdir).rglob("*.json"):
                try:
                    with open(p, "r", encoding="utf-8") as f:
                        obj = json.load(f)
                        if isinstance(obj, dict):
                            yield obj
                        elif isinstance(obj, list):
                            for item in obj:
                                if isinstance(item, dict):
                                    yield item
                except Exception:
                    continue


def main():
    with connect() as conn:
        conn.autocommit = False
        with conn.cursor() as cur:
            ensure_table(cur)
            existing = get_existing_columns(cur)

            for ano in range(1979, 2025):
                print(f"Processando ano {ano}...")
                z = Path(f'sim/Mortalidade_Geral_{ano}.json.zip')
                batch = []
                BATCH_SIZE = 5_000

                for rec in iter_json_files_from_zip(z):
                    keys = set(rec.keys()) - {"id"}
                    missing = keys - existing
                    if missing:
                        add_missing_columns(cur, missing)
                        existing |= missing

                    flat = {k: rec.get(k) for k in keys}
                    batch.append(flat)

                    if len(batch) >= BATCH_SIZE:
                        insert_batch(cur, batch)
                        batch.clear()

                insert_batch(cur, batch)
                conn.commit()
                print(f"Ano {ano} concluído.")

    print(f"Concluído. Tabela: {TABLE_NAME}")


if __name__ == "__main__":
    main()
