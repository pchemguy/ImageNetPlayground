PRAGMA temp_store = MEMORY;

DROP TABLE IF EXISTS "temp"."mpaths";

CREATE TEMP TABLE "mpaths" (
    "rid"       INTEGER NOT NULL,
    "sid"       TEXT NOT NULL COLLATE NOCASE,
    "path_rid"  TEXT NOT NULL COLLATE NOCASE PRIMARY KEY,
    "path_sid"  TEXT NOT NULL COLLATE NOCASE UNIQUE,
    "depth"     INTEGER NOT NULL
);

CREATE INDEX "mpaths_rid_index" ON "mpaths" ("rid");
CREATE INDEX "mpaths_sid_index" ON "mpaths" ("sid");
