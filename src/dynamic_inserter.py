import logging

import duckdb
import pandas as pd

from src.zip_manager import ZipManager


class DynamicInserter:
    def __init__(
        self,
        conn: duckdb.DuckDBPyConnection,
        table: str,
        batch_size: int,
        logger: logging.Logger,
    ) -> None:
        self.conn = conn
        self.table = table
        self.batch_size = batch_size
        self.logger = logger

        self._cols: set[str] = set()

        self._ensure_table()

    def _ensure_table(self) -> None:
        self.conn.execute("CREATE SEQUENCE IF NOT EXISTS id_seq START 1;")
        self.conn.execute(f"""
                        CREATE TABLE IF NOT EXISTS {self.table} (
                            id BIGINT PRIMARY KEY DEFAULT nextval('id_seq')
                        );
                        """)
        self._cols.add("id")
        self.logger.info("Tabela %s criada.", self.table)

    def _add_col(self, new_col: str) -> None:
        if new_col in self._cols:
            self.logger.warning(
                "Coluna %s já existe, nenhuma alteração foi realizada.",
                new_col,
            )
            return

        self.conn.execute(
            f"""ALTER TABLE {self.table} ADD COLUMN "{new_col}" TEXT""",
        )
        self._cols.add(new_col)
        self.logger.info("Coluna %s adicionada.", new_col)

    def _insert_df(self, df: pd.DataFrame) -> None:
        cols = set(df.columns)
        new_cols = cols - self._cols

        for new_col in new_cols:
            self._add_col(new_col)

        self.conn.register("temp_df", df)

        df_cols_str = ", ".join([f'"{cols}"' for cols in df.columns])

        self.conn.execute(
            f"INSERT INTO {self.table} ({df_cols_str}) SELECT {df_cols_str} FROM temp_df"
        )

        self.conn.unregister("temp_df")

        self.logger.info("DataFrame de %s linhas inserido com sucesso.", len(df))

    def insert(self, zip_manager: ZipManager) -> None:
        batch = []

        for obj in zip_manager.get_objects():
            batch.append(obj)
            if len(batch) >= self.batch_size:
                batch_df = pd.DataFrame(batch)
                self._insert_df(batch_df)
                batch.clear()

        if len(batch) > 0:
            batch_df = pd.DataFrame(batch)
            self._insert_df(batch_df)
            batch.clear()
