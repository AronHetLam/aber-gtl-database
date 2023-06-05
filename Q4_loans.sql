-- GOD TIL INDEX
SELECT first_name, last_name, title, item_copy.barcode, reservation_date, start_date, returned_date, notice_sent
FROM person p 
  INNER JOIN loan on ssn = member_ssn
  INNER JOIN item_copy on loan.barcode = item_copy.barcode
  INNER JOIN item on item.id = i_id
WHERE p.ssn = 100000003

DROP INDEX [IDX_loan_member_ssn] on loan

CREATE NONCLUSTERED INDEX [IDX_loan_member_ssn]
ON [dbo].[loan] ([member_ssn])
