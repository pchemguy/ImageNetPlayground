-- SELECT gloss

SELECT synsets.rowid, synsets.id, synsets.pos, definitions.definition AS gloss, synsets.metadata
FROM synsets, definitions
WHERE synsets.rowid = definitions.synset_rowid;


-- SELECT synsets

WITH
    synsets_ex AS (
        SELECT
			rowid,
            id AS omwid,
			metadata ->> '$.identifier' AS sid,
            metadata ->> '$.imagenet' AS imagenet_id
        FROM synsets
		WHERE pos = 'n'
    )
SELECT * FROM synsets_ex


-- SELECT words and headword (sense synset_rank=0)

WITH
    synsets_forms AS (
        SELECT
            senses.entry_rowid, 
            senses.synset_rowid,
            senses.synset_rank,
            forms.rowid AS form_rowid,
            forms.form,
            synsets.id AS omwid,
            substr(synsets.metadata ->> '$.identifier', 1, length(synsets.metadata ->> '$.identifier') - 5) AS headword,
            synsets.metadata AS synset_metadata
        FROM senses, forms, synsets
        WHERE senses.entry_rowid = forms.entry_rowid
          AND senses.synset_rowid = synsets.rowid
    ),
    synsets_ex AS (
        SELECT
            synset_rowid,
            omwid,
            headword,
            json_group_array(form ORDER BY synset_rank) AS words,
            synset_metadata
        FROM synsets_forms    
        GROUP BY synset_rowid
    )
SELECT * FROM synsets_ex
WHERE synset_metadata like '%imagenet%';


-- Synset Types

SELECT rt.rowid AS relation_id, rt.type, sr.type_rowid AS synset_type_rowid, count(*) AS freq
FROM relation_types AS rt
LEFT JOIN synset_relations AS sr
ON rt.rowid = sr.type_rowid
GROUP BY rt.rowid;


-- Sense Types

SELECT rt.rowid AS relation_id, rt.type, sr.type_rowid AS sense_type_rowid
FROM relation_types AS rt
LEFT JOIN sense_relations AS sr
ON rt.rowid = sr.type_rowid
GROUP BY rt.rowid;


-- Region related

WITH
    synsets_ex AS (
        SELECT
			rowid AS rid,
            id AS omwid,
			metadata ->> '$.identifier' AS sid,
            metadata ->> '$.imagenet' AS imagenet_id
        FROM synsets
		WHERE pos = 'n'
    ),
	related AS (
		SELECT src.rid, src.omwid, src.sid, dst.sid AS rel_sid
		FROM synsets_ex AS src, synsets_ex AS dst, synset_relations AS sr, relation_types AS rt
		WHERE rt.type = 'has_domain_region'
		  AND rt.rowid = sr.type_rowid
		  AND sr.source_rowid = src.rid
		  AND sr.target_rowid = dst.rid		  
	)
SELECT * FROM related;


-- Topic related

WITH
    synsets_ex AS (
        SELECT
			rowid AS rid,
            id AS omwid,
			metadata ->> '$.identifier' AS sid,
            metadata ->> '$.imagenet' AS imagenet_id
        FROM synsets
		WHERE pos = 'n'
    ),
	related AS (
		SELECT src.rid AS src_rid, src.omwid, src.sid, dst.rid AS rel_rid, dst.sid AS rel_sid
		FROM synsets_ex AS src, synsets_ex AS dst, synset_relations AS sr, relation_types AS rt
		WHERE rt.type = 'has_domain_topic'
		  AND rt.rowid = sr.type_rowid
		  AND sr.source_rowid = src.rid
		  AND sr.target_rowid = dst.rid		  
	)
SELECT * FROM related
