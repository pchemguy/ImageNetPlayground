PRAGMA temp_store = MEMORY;

DROP TABLE IF EXISTS "temp"."edges";

CREATE TEMP TABLE "edges" (
    "rowid"         INTEGER PRIMARY KEY,
    "source_rowid"  INTEGER NOT NULL,
    "source_synid"  TEXT NOT NULL COLLATE NOCASE,
    "target_rowid"  INTEGER NOT NULL,
    "target_synid"  TEXT NOT NULL COLLATE NOCASE,
    UNIQUE("source_rowid", "target_rowid"),
    UNIQUE("target_rowid", "source_rowid")
);

INSERT INTO "edges"("rowid", "source_rowid", "source_synid", "target_rowid", "target_synid")
SELECT
    sr.rowid,
    sr.source_rowid,
    ss.sid AS source_synid,
    sr.target_rowid,
    st.sid AS target_synid
FROM
    synset_relations AS sr,
    synsets AS ss,
    synsets AS st,
    relation_types AS rt
WHERE rt.type = 'domain_topic'
  AND sr.type_rowid = rt.rowid
  AND sr.source_rowid = ss.rowid AND ss.pos = 'n'
  AND sr.target_rowid = st.rowid AND st.pos = 'n';
