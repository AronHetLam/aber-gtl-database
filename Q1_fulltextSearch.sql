DROP FULLTEXT INDEX ON item
DROP FULLTEXT INDEX ON author
DROP FULLTEXT INDEX ON subject

DROP FULLTEXT CATALOG itemCatalog

CREATE FULLTEXT CATALOG itemCatalog AS DEFAULT

CREATE FULLTEXT INDEX ON item ([title], [description], [area]) KEY INDEX PK__item__3213E83FBEE3EFDC ON itemCatalog
CREATE FULLTEXT INDEX ON author ([first_name], [last_name]) KEY INDEX PK__author__3213E83FA4FC7477 ON itemCatalog
CREATE FULLTEXT INDEX ON subject ([subject]) KEY INDEX PK__subject__CED03967DE5351C0 ON itemCatalog

DECLARE @search_string nvarchar(255) = 'data science, sandra'

SELECT id, title, type, isbn, area, misc_identifier, rank
-- ,
--     (SELECT
--         STRING_AGG(first_name + ' '+ last_name, '; ')
--     from item_authors ia
--         INNER JOIN author a on ia.a_id = a.id
--     where i_id = i.id) as authors,
--     (SELECT STRING_AGG(s.[subject], '; ')
--     from item_subjects i_s
--         INNER JOIN [subject] s on i_s.[subject] = s.subject
--     where i_id = i.id) as subjects
FROM item i
    INNER JOIN (
        SELECT i_id, SUM(res.RANK) as RANK
    from (
            SELECT [KEY] as i_id, RANK as RANK
            from FREETEXTTABLE(item, (title, [description], area), @search_string)
        UNION ALL
            SELECT i_id, RANK
            from FREETEXTTABLE(author, (first_name, last_name), @search_string)
                INNER JOIN item_authors ia on [KEY] = a_id
        UNION ALL
            SELECT i_id, RANK
            from FREETEXTTABLE(subject, (subject), @search_string)
                INNER JOIN item_subjects on [KEY] = subject
        ) as res
    GROUP BY i_id) as IDS_RANKED on id = i_id
order by RANK desc
OFFSET 0 ROWS
FETCH NEXT 20 ROWS ONLY



-- INDEXING
DROP INDEX IDX_item_authors_a_id on item_authors

CREATE NONCLUSTERED INDEX [IDX_item_authors_a_id]
ON [dbo].[item_authors] ([a_id])



SELECT TOP (20)
    *
FROM item
where FREETEXT(title, 'art sandra')

SELECT TOP (20)
    *
FROM FREETEXTTABLE(author, (first_name, last_name), 'art sandra')