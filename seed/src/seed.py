import logging

import duckdb

from src.dynamic_inserter import DynamicInserter
from src.zip_manager import ZipManager

DB = "sim"
TABLE = "sim"
CHUNK_SIZE = 50_000

logger = logging.getLogger(__name__)


def setup_logging() -> None:
    logging.basicConfig(
        level=logging.INFO,
        format="%(asctime)s [%(levelname)s] %(name)s: %(message)s",
        datefmt="%Y-%m-%d %H:%M:%S",
    )


def process_year_range(
    conn: duckdb.DuckDBPyConnection,
    start_year: int,
    end_year: int,
    logger: logging.Logger,
) -> None:
    inserter = DynamicInserter(conn, TABLE, CHUNK_SIZE, logger)

    for ano in range(start_year, end_year + 1):
        with ZipManager(ano, logger) as zm:
            inserter.insert(zm)


def main(
    start_year: int,
    end_year: int,
) -> None:
    logger = setup_logging()
    conn = duckdb.connect(f"{DB}.duckdb")
    process_year_range(conn, start_year, end_year, logger)

__all__ = ["main"]

if __name__ == "__main__":
    import sys

    main(int(sys.argv[1]), int(sys.argv[2]))
