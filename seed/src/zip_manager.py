import json
import logging
import os
import tempfile
import zipfile
from collections.abc import Iterator
from pathlib import Path
from typing import Any

import requests


class ZipNotAvailableError(RuntimeError):
    """ZIP não localizado."""


class FilesNotAvailableError(RuntimeError):
    """Pasta temporario não localizada."""


class ZipManager:
    DOWNLOAD_URL = "https://s3.sa-east-1.amazonaws.com/ckan.saude.gov.br/SIM/json/Mortalidade_Geral_{ano}.json.zip"

    def __init__(self, ano: int, logger: logging.Logger) -> None:
        self.ano = ano
        self.logger = logger
        self._zip_path: Path | None = None
        self._tmpdir: tempfile.TemporaryDirectory | None = None

    @property
    def download_url(self) -> str:
        return ZipManager.DOWNLOAD_URL.format(ano=self.ano)

    @property
    def _tmpdir_path(self) -> Path:
        if self._tmpdir is None:
            raise FilesNotAvailableError
        return Path(self._tmpdir.name)

    def _download_file(self) -> None:
        fd, path_str = tempfile.mkstemp(suffix=".zip")
        os.close(fd)
        self._zip_path = Path(path_str)

        request = requests.get(self.download_url, stream=True, timeout=(10, 300))
        request.raise_for_status()

        self.logger.info("Baixando arquivo referente ao ano %s.", self.ano)

        with self._zip_path.open("wb") as f:
            for chunk in request.iter_content(chunk_size=8192):
                f.write(chunk)

    def _extract_files(self) -> None:
        if self._zip_path is None:
            raise ZipNotAvailableError

        self._tmpdir = tempfile.TemporaryDirectory()

        with zipfile.ZipFile(self._zip_path) as z:
            z.extractall(self._tmpdir_path)

    def get_objects(self) -> Iterator[dict[str, Any]]:
        if self._tmpdir is None:
            raise FilesNotAvailableError

        for path in self._tmpdir_path.rglob("*.json"):
            self.logger.info("Lendo arquivo %s.", path.name)
            with path.open("r", encoding="utf-8") as file:
                obj = json.load(file)

                if isinstance(obj, dict):
                    yield obj

                elif isinstance(obj, list):
                    for item in obj:
                        if isinstance(item, dict):
                            yield item

    def __enter__(self) -> "ZipManager":
        self._download_file()
        self._extract_files()
        return self

    def __exit__(self, exc_type, exc_val, exc_tb) -> bool:
        if self._zip_path and self._zip_path.exists():
            self._zip_path.unlink()
            self._zip_path = None

        if self._tmpdir:
            self._tmpdir.cleanup()
            self._tmpdir = None

        self.logger.info("ZipManager do ano %s finalizado.", self.ano)

        return False
