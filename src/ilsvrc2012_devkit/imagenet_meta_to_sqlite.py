"""
imagenet_meta_to_sqlite.py
--------------------------

https://chatgpt.com/c/693d8bb7-2dc4-8327-a674-62e1ebbc5da2

Import ImageNet ILSVRC2012 meta.mat into SQLite.

Expected layout:
  ./ILSVRC2012_devkit_t12.tar.gz
      |-- ILSVRC2012_devkit_t12/data/meta.mat

Output:
  ./meta.db
"""

from __future__ import annotations

import sqlite3
import tarfile
from pathlib import Path
from typing import Any

import numpy as np
from scipy.io import loadmat


TAR_NAME = "ILSVRC2012_devkit_t12.tar.gz"
MAT_PATH = "ILSVRC2012_devkit_t12/data/meta.mat"
DB_NAME = "meta.db"


def _as_int(value: Any) -> int | None:
    if value is None:
        return None
    if isinstance(value, np.ndarray):
        if value.size == 0:
            return None
        return int(value.squeeze())
    return int(value)


def _as_str(value: Any) -> str | None:
    if value is None:
        return None
    if isinstance(value, np.ndarray):
        if value.size == 0:
            return None
        value = value.squeeze()
    if isinstance(value, bytes):
        return value.decode("utf-8")
    return str(value)


def load_meta_from_tar(tar_path: Path) -> list[dict[str, Any]]:
    with tarfile.open(tar_path, "r:gz") as tf:
        member = tf.getmember(MAT_PATH)
        with tf.extractfile(member) as f:
            mat = loadmat(f, squeeze_me=True, struct_as_record=False)

    synsets = mat["synsets"]

    records: list[dict[str, Any]] = []

    for s in synsets:
        records.append(
            {
                "synset_id": _as_int(s.ILSVRC2012_ID),
                "wnid": _as_str(s.WNID),
                "words": _as_str(s.words),
                "gloss": _as_str(s.gloss),
                "num_children": _as_int(s.num_children),
                "children": (
                    []
                    if s.children is None
                    else [int(x) for x in np.atleast_1d(s.children)]
                ),
                "wordnet_height": _as_int(s.wordnet_height),
                "num_train_images": _as_int(s.num_train_images),
            }
        )

    return records


def create_schema(conn: sqlite3.Connection) -> None:
    conn.executescript(
        """
        PRAGMA foreign_keys = ON;

        CREATE TABLE IF NOT EXISTS synsets (
                synset_id           INTEGER PRIMARY KEY,
                wnid                TEXT NOT NULL UNIQUE,
                words               TEXT,
                gloss               TEXT,
                num_children        INTEGER,
                wordnet_height      INTEGER,
                num_train_images    INTEGER
        );

        CREATE TABLE IF NOT EXISTS synset_children (
                parent_id INTEGER NOT NULL,
                child_id  INTEGER NOT NULL,
                PRIMARY KEY (parent_id, child_id),
                FOREIGN KEY (parent_id) REFERENCES synsets (synset_id),
                FOREIGN KEY (child_id)  REFERENCES synsets (synset_id)
        );
        """
    )


def insert_metadata(
    conn: sqlite3.Connection, records: list[dict[str, Any]]
) -> None:
    with conn:
        conn.executemany(
            """
            INSERT INTO synsets (
                    synset_id,
                    wnid,
                    words,
                    gloss,
                    num_children,
                    wordnet_height,
                    num_train_images
            )
            VALUES (?, ?, ?, ?, ?, ?, ?)
            """,
            [
                (
                    r["synset_id"],
                    r["wnid"],
                    r["words"],
                    r["gloss"],
                    r["num_children"],
                    r["wordnet_height"],
                    r["num_train_images"],
                )
                for r in records
            ],
        )

        conn.executemany(
            """
            INSERT OR IGNORE INTO synset_children (parent_id, child_id)
            VALUES (?, ?)
            """,
            [
                (r["synset_id"], child_id)
                for r in records
                for child_id in r["children"]
            ],
        )


def main() -> None:
    tar_path = Path(TAR_NAME)
    if not tar_path.exists():
        raise FileNotFoundError(tar_path)

    records = load_meta_from_tar(tar_path)

    conn = sqlite3.connect(DB_NAME)
    try:
        create_schema(conn)
        insert_metadata(conn, records)
    finally:
        conn.close()

    print(f"Imported {len(records)} synsets into {DB_NAME}")


if __name__ == "__main__":
    main()
