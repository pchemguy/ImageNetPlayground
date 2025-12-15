-- domain_topic

WITH 
WITH 
    relation_sources AS (
        SELECT DISTINCT synset_relations.source_rowid
        FROM synset_relations, relation_types
        WHERE relation_types.type = 'domain_topic'
          AND relation_types.rowid = synset_relations.type_rowid
        ORDER BY synset_relations.source_rowid
    ),
    relation_targets AS (
        SELECT DISTINCT synset_relations.target_rowid
        FROM synset_relations, relation_types
        WHERE relation_types.type = 'domain_topic'
          AND relation_types.rowid = synset_relations.type_rowid
        ORDER BY synset_relations.target_rowid
    ),
    root_nodes AS (
        SELECT rt.target_rowid AS rid, s.sid
        FROM relation_targets AS rt, synsets AS s
        ON  rt.target_rowid = s.rowid AND s.pos = 'n'
        LEFT JOIN relation_sources AS rs
        ON rt.target_rowid = rs.source_rowid
        WHERE rs.source_rowid IS NULL
    )
SELECT * FROM root_nodes;


-- domain_region

WITH 
    relation_sources AS (
        SELECT DISTINCT synset_relations.source_rowid
        FROM synset_relations, relation_types
        WHERE relation_types.type = 'domain_region'
          AND relation_types.rowid = synset_relations.type_rowid
        ORDER BY synset_relations.source_rowid
    ),
    relation_targets AS (
        SELECT DISTINCT synset_relations.target_rowid
        FROM synset_relations, relation_types
        WHERE relation_types.type = 'domain_region'
          AND relation_types.rowid = synset_relations.type_rowid
        ORDER BY synset_relations.target_rowid
    ),
    root_nodes AS (
        SELECT rt.target_rowid AS rid, s.sid
        FROM relation_targets AS rt, synsets AS s
        ON  rt.target_rowid = s.rowid AND s.pos = 'n'
        LEFT JOIN relation_sources AS rs
        ON rt.target_rowid = rs.source_rowid
        WHERE rs.source_rowid IS NULL
    )
SELECT * FROM root_nodes;


-- hypernym

WITH 
    relation_sources AS (
        SELECT DISTINCT synset_relations.source_rowid
        FROM synset_relations, relation_types
        WHERE relation_types.type = 'hypernym'
          AND relation_types.rowid = synset_relations.type_rowid
        ORDER BY synset_relations.source_rowid
    ),
    relation_targets AS (
        SELECT DISTINCT synset_relations.target_rowid
        FROM synset_relations, relation_types
        WHERE relation_types.type = 'hypernym'
          AND relation_types.rowid = synset_relations.type_rowid
        ORDER BY synset_relations.target_rowid
    ),
    root_nodes AS (
        SELECT rt.target_rowid AS rid, s.sid
        FROM relation_targets AS rt, synsets AS s
        ON  rt.target_rowid = s.rowid AND s.pos = 'n'
        LEFT JOIN relation_sources AS rs
        ON rt.target_rowid = rs.source_rowid
        WHERE rs.source_rowid IS NULL
    )
SELECT * FROM root_nodes;


-- holo_member

WITH 
    relation_sources AS (
        SELECT DISTINCT synset_relations.source_rowid
        FROM synset_relations, relation_types
        WHERE relation_types.type = 'holo_member'
          AND relation_types.rowid = synset_relations.type_rowid
        ORDER BY synset_relations.source_rowid
    ),
    relation_targets AS (
        SELECT DISTINCT synset_relations.target_rowid
        FROM synset_relations, relation_types
        WHERE relation_types.type = 'holo_member'
          AND relation_types.rowid = synset_relations.type_rowid
        ORDER BY synset_relations.target_rowid
    ),
    root_nodes AS (
        SELECT rt.target_rowid AS rid, s.sid
        FROM relation_targets AS rt, synsets AS s
        ON  rt.target_rowid = s.rowid AND s.pos = 'n'
        LEFT JOIN relation_sources AS rs
        ON rt.target_rowid = rs.source_rowid
        WHERE rs.source_rowid IS NULL
    )
SELECT * FROM root_nodes;


-- holo_substance

WITH 
    relation_sources AS (
        SELECT DISTINCT synset_relations.source_rowid
        FROM synset_relations, relation_types
        WHERE relation_types.type = 'holo_substance'
          AND relation_types.rowid = synset_relations.type_rowid
        ORDER BY synset_relations.source_rowid
    ),
    relation_targets AS (
        SELECT DISTINCT synset_relations.target_rowid
        FROM synset_relations, relation_types
        WHERE relation_types.type = 'holo_substance'
          AND relation_types.rowid = synset_relations.type_rowid
        ORDER BY synset_relations.target_rowid
    ),
    root_nodes AS (
        SELECT rt.target_rowid AS rid, s.sid
        FROM relation_targets AS rt, synsets AS s
        ON  rt.target_rowid = s.rowid AND s.pos = 'n'
        LEFT JOIN relation_sources AS rs
        ON rt.target_rowid = rs.source_rowid
        WHERE rs.source_rowid IS NULL
    )
SELECT * FROM root_nodes;


-- holo_part

WITH 
    relation_sources AS (
        SELECT DISTINCT synset_relations.source_rowid
        FROM synset_relations, relation_types
        WHERE relation_types.type = 'holo_part'
          AND relation_types.rowid = synset_relations.type_rowid
        ORDER BY synset_relations.source_rowid
    ),
    relation_targets AS (
        SELECT DISTINCT synset_relations.target_rowid
        FROM synset_relations, relation_types
        WHERE relation_types.type = 'holo_part'
          AND relation_types.rowid = synset_relations.type_rowid
        ORDER BY synset_relations.target_rowid
    ),
    root_nodes AS (
        SELECT rt.target_rowid AS rid, s.sid
        FROM relation_targets AS rt, synsets AS s
        ON  rt.target_rowid = s.rowid AND s.pos = 'n'
        LEFT JOIN relation_sources AS rs
        ON rt.target_rowid = rs.source_rowid
        WHERE rs.source_rowid IS NULL
    )
SELECT * FROM root_nodes;
