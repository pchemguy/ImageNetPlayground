WITH RECURSIVE
    synsets_ex AS (
        SELECT
            rowid AS rid,
            id    AS omwid,
            metadata ->> '$.identifier' AS sid
        FROM synsets
        WHERE pos = 'n'
    ),

    domain_edges AS (
        -- leaf -> parent edges
        SELECT
            sr.source_rowid AS child_rid,
            sr.target_rowid AS parent_rid
        FROM synset_relations AS sr,
             relation_types AS rt
        WHERE rt.rowid = sr.type_rowid
          AND rt.type = 'domain_topic'
    ),

    paths_LOOP AS (
        -- seed: every synset that participates in domain_topic
        SELECT DISTINCT
            se.rid AS start_rid,
            se.sid AS start_sid,
            se.rid AS curr_rid,

            json_array(se.sid) AS path_sid,
            json_array(se.rid) AS path_rid,

            1 AS depth
        FROM synsets_ex AS se, domain_edges AS de
        WHERE de.child_rid = se.rid

        UNION ALL

        -- recursive step: append parent
        SELECT
            p.start_rid,
            p.start_sid,
            de.parent_rid AS curr_rid,

            json_insert(p.path_sid, '$[#]', pe.sid) AS path_sid,
            json_insert(p.path_rid, '$[#]', pe.rid) AS path_rid,

            p.depth + 1
        FROM paths_LOOP AS p
        JOIN domain_edges AS de
          ON de.child_rid = p.curr_rid
        JOIN synsets_ex AS pe
          ON pe.rid = de.parent_rid

        -- cycle safety
        WHERE NOT EXISTS (
            SELECT 1
            FROM json_each(p.path_rid)
            WHERE value = de.parent_rid
        )

        -- optional hard stop (safety valve)
        AND p.depth < 64
    ),

    maximal_paths AS (
        -- keep only paths that cannot be extended further
        SELECT
            (row_number() OVER (
                    ORDER BY path_sid ->> 0, path_sid ->> -1, depth DESC, path_sid
                )) AS rowid,
            *
        FROM paths_LOOP AS p
        WHERE NOT EXISTS (
            SELECT 1
            FROM domain_edges de
            WHERE de.child_rid = p.curr_rid
        )
    ),

    multi_path_mask AS (
        SELECT start_sid, count(*) > 1 AS mask
        FROM maximal_paths
        GROUP BY start_sid
    ),

    multi_paths AS (
        SELECT
            mp.*,
            json_array(path_rid ->> 0, path_rid ->> -1) AS ends
        FROM maximal_paths AS mp, multi_path_mask AS mpm
        WHERE mp.start_sid = mpm.start_sid AND mpm.mask = 1
    ),

    dominant_candidate AS (
        SELECT a.*
        FROM multi_paths AS a, multi_paths AS b
        WHERE a.rowid <> b.rowid
          AND a.depth > b.depth
          AND a.ends = b.ends
        ORDER BY a.rowid
    ),

    shortcut_candidate AS (
        SELECT a.*
        FROM multi_paths AS a, multi_paths AS b
        WHERE a.rowid <> b.rowid
          AND a.depth < b.depth
          AND a.ends = b.ends
        ORDER BY a.rowid
    ),

    dominant_nodes AS (
        SELECT d.*, jn.value AS node
        FROM dominant_candidate AS d, json_each(d.path_rid) AS jn
        ORDER BY d.rowid, d.path_sid, jn.key
    ),

    shortcut_nodes AS (
        SELECT s.*, jn.value AS node
        FROM shortcut_candidate AS s, json_each(s.path_rid) AS jn
        ORDER BY s.rowid, s.path_sid, jn.key
    ),

    shortcut_mask AS (
        SELECT sn.rowid, max(dn.rowid IS NULL) AS mask
        FROM shortcut_nodes AS sn
        LEFT JOIN dominant_nodes AS dn
        ON  sn.ends = dn.ends
        AND sn.node = dn.node
        GROUP BY sn.rowid
    ),

    paths_no_shortcuts AS (
        SELECT mp.*
        FROM maximal_paths AS mp
        LEFT JOIN shortcut_mask AS sm
        ON mp.rowid = sm.rowid
        WHERE sm.mask IS NULL
           OR sm.mask > 0
    ),

    root_items AS (
        SELECT DISTINCT
            path_rid ->> -1 AS start_rid,
            path_sid ->> -1 AS start_sid,
            json_array(json_array(path_sid ->> -1)) AS all_path_sid,
            json_array(json_array(path_rid ->> -1)) AS all_path_rid,
            1 AS num_paths,
            1 AS max_depth
        FROM paths_no_shortcuts
    ),

    filtered_paths AS (
        SELECT
            start_rid,
            start_sid,
            json_group_array(json(path_sid)) AS all_paths_sid,
            json_group_array(json(path_rid)) AS all_paths_rid,
            count(*) AS num_paths,
            max(depth) AS max_depth
        FROM paths_no_shortcuts
        GROUP BY start_rid, start_sid
        ORDER BY num_paths DESC, start_sid
    ),

    forest AS (
        SELECT * FROM filtered_paths
        UNION ALL
        SELECT * FROM root_items
    )

SELECT *
FROM forest
ORDER BY start_sid;
