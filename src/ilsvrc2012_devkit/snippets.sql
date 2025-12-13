-- SELECT gloss

SELECT synsets.rowid, synsets.id, synsets.pos, definitions.definition AS gloss, synsets.metadata
FROM synsets, definitions
WHERE synsets.rowid = definitions.synset_rowid;


-- SELECT words

WITH
    synsets_forms AS (
        SELECT
            senses.entry_rowid, 
            senses.synset_rowid,
            senses.synset_rank,
            forms.rowid AS form_rowid,
            forms.form,
            synsets.id AS omwid,
            synsets.metadata AS synset_metadata
        FROM senses, forms, synsets
        WHERE senses.entry_rowid = forms.entry_rowid
          AND senses.synset_rowid = synsets.rowid
    ),
    synsets_ex AS (
        SELECT
            synset_rowid,
            omwid,
            json_group_array(form ORDER BY synset_rank) AS words,
            synset_metadata
        FROM synsets_forms    
        GROUP BY synset_rowid
    )
SELECT * FROM synsets_ex
WHERE synset_metadata like '%imagenet%';
