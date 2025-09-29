import logging

import duckdb
from dotenv import load_dotenv

from src.dynamic_inserter import DynamicInserter
from src.zip_manager import ZipManager

load_dotenv()

TABLE = "sim"

logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s [%(levelname)s] %(name)s: %(message)s",
    datefmt="%Y-%m-%d %H:%M:%S",
)

logger = logging.getLogger(__name__)

conn = duckdb.connect("sim.duckdb")
dynamic_inserter = DynamicInserter(conn, TABLE, 200_000, logger)

for ano in range(1979, 2025):
    with ZipManager(ano, logger) as zm:
        dynamic_inserter.insert(zm)
