WITH RECURSIVE
    relation_sources AS (
        SELECT DISTINCT e.source_rowid AS rid, e.source_synid AS sid
        FROM temp.edges AS e
        ORDER BY e.source_synid
    ),
    relation_targets AS (
        SELECT DISTINCT e.target_rowid AS rid, e.target_synid AS sid
        FROM temp.edges AS e
        ORDER BY e.target_synid
    ),
    root_nodes AS (
        SELECT rt.*
        FROM relation_targets AS rt
        LEFT JOIN relation_sources AS rs
        ON rt.rid = rs.rid
        WHERE rs.rid IS NULL
        ORDER BY rt.sid
    ),
    leaf_nodes AS (
        SELECT rs.*
        FROM relation_sources AS rs
        LEFT JOIN relation_targets AS rt
        ON rt.rid = rs.rid
        WHERE rt.rid IS NULL
        ORDER BY rs.sid
    ),

    paths_LOOP AS (
        -- seed: every synset that participates in the hierarchy defined by edges.
        SELECT DISTINCT
            rn.rid AS root_rid,
            rn.sid AS root_sid,
            rn.rid AS curr_rid,

            json_array(rn.sid) AS path_sid,
            json_array(rn.rid) AS path_rid,

            1 AS depth
        FROM root_nodes AS rn

        UNION ALL

        -- recursive step: append child
        SELECT
            p.root_rid,
            p.root_sid,
            e.source_rowid AS curr_rid,

            json_insert(p.path_sid, '$[#]', e.source_synid) AS path_sid,
            json_insert(p.path_rid, '$[#]', e.source_rowid) AS path_rid,

            p.depth + 1
        FROM paths_LOOP AS p
        JOIN temp.edges AS e
          ON e.target_rowid = p.curr_rid

        -- cycle safety
        WHERE NOT EXISTS (
            SELECT 1 FROM json_each(p.path_rid) WHERE value = e.source_rowid
        )

        -- optional hard stop (safety valve)
        AND p.depth < 64
    ),

    -- Discard all intermediate paths, having non-leaf last node.
    preflitered_paths AS (
        SELECT
            p.root_rid,
            p.root_sid,
            p.path_rid ->> -1 AS leaf_rid,
            p.path_sid ->> -1 AS leaf_sid,
            p.path_sid,
            p.path_rid,
            p.depth
        FROM paths_LOOP AS p
        WHERE p.depth > 1
          AND leaf_rid IN (SELECT rid FROM leaf_nodes)
    ),

    -- Identify paths set for dom/sub testing: find all paths subsets
    -- with identical root/leaf nodes with at least two different depths
    multipath_index AS (
        SELECT root_rid, leaf_rid
        FROM (
            SELECT root_rid, leaf_rid
            FROM preflitered_paths
            GROUP BY root_rid, leaf_rid, depth
        )
        GROUP BY root_rid, leaf_rid
        HAVING count(*) > 1
    ),

    -- SELECT identified paths for subset testing.
    multipaths AS (
        SELECT
            (row_number() OVER (
                    ORDER BY pp.root_sid, pp.leaf_sid, depth DESC, path_sid
                )) AS path_id,
            pp.*
        FROM preflitered_paths AS pp, multipath_index AS mi
        WHERE (pp.root_rid, pp.leaf_rid) = (mi.root_rid, mi.leaf_rid)
    ),
    -- TODO:
    --   Every path of length 2 should be flagged for pruning without further testing -
    --       strip these paths from the FULL path set and rerun multipath analysis.
    dominance_matrix AS (
        SELECT d.*, s.path_id AS short_id, s.path_rid AS shortcut_path_rid
        FROM multipaths AS d, multipaths AS s
        WHERE (d.root_rid, d.leaf_rid) = (s.root_rid, s.leaf_rid)
          AND d.depth > s.depth
    ),
    -- TODO:
    ---  Strip root/leaf nodes from both paths before preparing for the dom/sub subset test.
    masked_paths AS (
        SELECT
            dm.*,
            -- Returns 0 if all items match (TRUE subset)
            -- Returns 1 if any item is missing (FALSE subset)
            MAX(dom.value IS NULL) AS keep_sub
        FROM dominance_matrix AS dm,
            json_each(dm.shortcut_path_rid) AS sub       -- 1. Unpack shortcut array
        LEFT JOIN
            json_each(dm.path_rid) AS dom       -- 2. Try to find match in path array
            ON sub.value = dom.value
        GROUP BY dm.path_id, dm.short_id
    ),
    filtered_paths AS (
        SELECT pp.*
        FROM preflitered_paths AS pp
        WHERE NOT pp.path_rid IN (
            SELECT shortcut_path_rid FROM masked_paths WHERE keep_sub = 0
        )
    )

SELECT * FROM filtered_paths;
