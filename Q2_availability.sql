--Indexes
DROP INDEX IDX_loan_barcode ON loan
DROP INDEX IDX_item_copy_i_id ON item_copy

CREATE NONCLUSTERED INDEX IDX_loan_barcode
ON dbo.loan (barcode) --, returned_date, start_date)

CREATE NONCLUSTERED INDEX IDX_item_copy_i_id
ON dbo.item_copy (i_id);


-- 23% and 8% cost compared to below queries respectively
SELECT id, title, date, for_acquisition, type, isbn, area, misc_identifier, total_copies, total_copies - COALESCE(lent, 0) - COALESCE(destroyed, 0) as available, lent, destroyed
FROM item
  LEFT OUTER JOIN (
    SELECT ic.i_id,
      COUNT(CASE WHEN destroyed = 0 THEN 1 END) as lent,
      COUNT(CASE WHEN destroyed = 1 THEN 1 END) as destroyed
    FROM item_copy ic
    WHERE destroyed = 1 
      OR EXISTS (
        SELECT *
        FROM loan l
        WHERE ic.barcode = l.barcode 
          AND l.start_date IS NOT NULL 
          AND l.returned_date IS NULL
      )
    GROUP BY i_id
  ) unavailable_copies on id = unavailable_copies.i_id
  LEFT OUTER JOIN (
    SELECT i_id, COUNT(*) as total_copies
    FROM item_copy
    GROUP BY I_id
  ) total_copies ON id = total_copies.i_id
WHERE id = 10


SELECT id, title, date, for_acquisition, type, isbn, area, misc_identifier, total_copies, total_copies - lent - destroyed as available, lent, destroyed
FROM item
  LEFT OUTER JOIN (
    SELECT ics.i_id,
      COUNT(ics.i_id) total_copies,
      COUNT(CASE WHEN destroyed = 0 AND active_loan = 1 THEN 1 END) as lent,
      COUNT(CASE WHEN destroyed = 1 THEN 1 END) as destroyed
    FROM (
      SELECT i_id,
        destroyed,
        CASE WHEN EXISTS (
          SELECT 1
          FROM loan l
          WHERE ic.barcode = l.barcode 
            AND l.start_date IS NOT NULL 
            AND l.returned_date IS NULL
          ) THEN 1 ELSE 0 END as active_loan
      FROM item_copy ic
    ) ics
    GROUP BY i_id
  ) copies on id = i_id
where i_id = 10


SELECT id, title, date, for_acquisition, type, isbn, area, misc_identifier, total_copies, available, total_copies - available - destroyed as lent, destroyed
FROM item
  LEFT OUTER JOIN (
    SELECT ic.i_id,
      COUNT(ic.i_id) total_copies,
      COUNT(CASE WHEN destroyed = 0 AND l.barcode IS NULL THEN 1 END) as available,
      COUNT(CASE WHEN destroyed = 1 THEN 1 END) as destroyed
    FROM item_copy ic
      LEFT OUTER JOIN (
        SELECT barcode
        FROM loan
        WHERE start_date IS NOT NULL 
          AND returned_date IS NULL
      ) l ON ic.barcode = l.barcode
    GROUP BY i_id
  ) copies on id = i_id
where id = 10;


-- DELETE all active loans except one for each copy
DELETE -- select *
FROM loan
WHERE start_date IS NOT NULL AND returned_date is null
  AND id NOT IN (SELECT MAX(id)
  FROM loan l1
  WHERE start_date IS NOT NULL AND returned_date is null
  GROUP BY l1.barcode)
