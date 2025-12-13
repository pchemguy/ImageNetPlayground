"""
imagenet_meta_to_sqlite.py
--------------------------

https://chatgpt.com/c/693d8bb7-2dc4-8327-a674-62e1ebbc5da2

Construct a fresh SQLite database containing ImageNet ILSVRC2012 metadata
derived exclusively from the official devkit (meta.mat).

HEADWORD DEFINITION
==================
The column `headword` is defined deterministically as:

  headword :=
      first WordNet lemma from `words`,
      with spaces replaced by underscores

Example:
  words    = "Egyptian cat, Felis catus"
  headword = "Egyptian_cat"

This corresponds to the normalization commonly used by
ImageNet / Caffe / PyTorch label files, but is derived here
WITHOUT any external JSON files or framework dependencies.

PyTorch class mapping (independent source):
  https://s3.amazonaws.com/deep-learning-models/image-models/imagenet_class_index.json
"""

from __future__ import annotations

import sqlite3
import tarfile
from pathlib import Path
from typing import Any, Iterable

import numpy as np
from scipy.io import loadmat


# ---------------------------------------------------------------------
# Configuration
# ---------------------------------------------------------------------

TAR_NAME = "ILSVRC2012_devkit_t12.tar.gz"
MAT_PATH = "ILSVRC2012_devkit_t12/data/meta.mat"
DB_NAME = "meta.db"


# ---------------------------------------------------------------------
# MATLAB -> Python normalization helpers
# ---------------------------------------------------------------------

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


# ---------------------------------------------------------------------
# Headword algorithm (exactly as requested)
# ---------------------------------------------------------------------

def make_headword(words: str | None) -> str | None:
    """
    Algorithm:
      1. Take first lemma from `words`
      2. Trim whitespace
      3. Replace spaces with underscores
    """
    if not words:
        return None

    first_lemma = words.split(",")[0].strip()
    if not first_lemma:
        return None

    return first_lemma.replace(" ", "_")


# ---------------------------------------------------------------------
# Devkit loading
# ---------------------------------------------------------------------

def load_meta_from_tar(tar_path: Path) -> list[dict[str, Any]]:
    with tarfile.open(tar_path, "r:gz") as tf:
        member = tf.getmember(MAT_PATH)
        with tf.extractfile(member) as f:
            if f is None:
                raise FileNotFoundError(MAT_PATH)
            mat = loadmat(f, squeeze_me=True, struct_as_record=False)

    synsets = mat["synsets"]
    records: list[dict[str, Any]] = []

    for s in synsets:
        synset_id = _as_int(s.ILSVRC2012_ID)
        wnid = _as_str(s.WNID)
        words = _as_str(s.words)
        gloss = _as_str(s.gloss)
        num_children = _as_int(s.num_children)
        wordnet_height = _as_int(s.wordnet_height)
        num_train_images = _as_int(s.num_train_images)

        if s.children is None:
            children: list[int] = []
        else:
            children = [int(x) for x in np.atleast_1d(s.children)]

        records.append(
            {
                "synset_id": synset_id,
                "wnid": wnid,
                "headword": make_headword(words),
                "words": words,
                "gloss": gloss,
                "num_children": num_children,
                "children": children,
                "wordnet_height": wordnet_height,
                "num_train_images": num_train_images,
            }
        )

    return records


# ---------------------------------------------------------------------
# Schema creation (FROM SCRATCH)
# ---------------------------------------------------------------------

def create_schema(conn: sqlite3.Connection) -> None:
    conn.executescript(
        """
        PRAGMA foreign_keys = ON;

        CREATE TABLE synsets (
            synset_id           INTEGER PRIMARY KEY,
            wnid                TEXT NOT NULL UNIQUE,
            -- Generated Open Multilingual WordNet ID
            omwid               TEXT GENERATED ALWAYS AS (
                                   'omw-en-' || SUBSTR(wnid, 2) || '-n'
                                 ) VIRTUAL,
            headword            TEXT,
            words               TEXT,
            gloss               TEXT,
            num_children        INTEGER,
            wordnet_height      INTEGER,
            num_train_images    INTEGER
        );

        CREATE TABLE synset_children (
            parent_id INTEGER NOT NULL,
            child_id  INTEGER NOT NULL,
            PRIMARY KEY (parent_id, child_id),
            FOREIGN KEY (parent_id) REFERENCES synsets (synset_id),
            FOREIGN KEY (child_id)  REFERENCES synsets (synset_id)
        );

        CREATE INDEX idx_synset_children_parent
        ON synset_children(parent_id);

        CREATE INDEX idx_synset_children_child
        ON synset_children(child_id);
        """
    )


# ---------------------------------------------------------------------
# Data insertion
# ---------------------------------------------------------------------

def insert_metadata(
    conn: sqlite3.Connection,
    records: Iterable[dict[str, Any]],
) -> None:
    with conn:
        conn.executemany(
            """
            INSERT INTO synsets (
                synset_id,
                wnid,
                headword,
                words,
                gloss,
                num_children,
                wordnet_height,
                num_train_images
            )
            VALUES (?, ?, ?, ?, ?, ?, ?, ?)
            """,
            [
                (
                    r["synset_id"],
                    r["wnid"],
                    r["headword"],
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
            INSERT INTO synset_children (parent_id, child_id)
            VALUES (?, ?)
            """,
            [
                (r["synset_id"], child_id)
                for r in records
                for child_id in r["children"]
            ],
        )


# ---------------------------------------------------------------------
# Main
# ---------------------------------------------------------------------

def main() -> None:
    base_dir = Path(__file__).resolve().parent
    tar_path = base_dir / TAR_NAME

    if not tar_path.exists():
        raise FileNotFoundError(tar_path)

    db_path = base_dir / DB_NAME
    if db_path.exists():
        db_path.unlink()

    records = load_meta_from_tar(tar_path)

    conn = sqlite3.connect(db_path)
    try:
        create_schema(conn)
        insert_metadata(conn, records)
    finally:
        conn.close()

    print(
        f"Constructed {DB_NAME} from scratch "
        f"({len(records)} synsets, headword algorithm applied)."
    )


if __name__ == "__main__":
    main()
