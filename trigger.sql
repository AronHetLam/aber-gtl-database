CREATE TRIGGER reject_loan_or_reservation_for_reserved_item_copy
ON loan
FOR INSERT
AS
DECLARE @member_type nvarchar(255)
DECLARE @start_date DATE
DECLARE @due_date DATE
DECLARE @reservations TABLE (
  id INT,
  barcode INT,
  reservation_date DATETIME,
  reservation_due_date DATE
)
BEGIN
  -- Only allow one row at a time
  IF (SELECT COUNT(*) FROM inserted) > 1
    BEGIN
     RAISERROR ('Only one loan/reservation can be inserted at a time', 0, 0)
     ROLLBACK
    END
  
  -- Get inserted row start_date and member type
  (SELECT @start_date = COALESCE(start_date, reservation_date), @member_type = type
  FROM inserted i
    LEFT OUTER JOIN person on member_ssn = ssn)

  -- Get inserted row due date
  SET @due_date = dbo.due_date_by_mem_type(@start_date, @member_type)

  PRINT 'Calculated due date: ' + CAST(@due_date AS varchar(20))
  
  -- Find overlapping reservations
  INSERT INTO @reservations
    (id, barcode, reservation_date, reservation_due_date)
  SELECT reservations.id, reservations.barcode, reservations.reservation_date, reservation_due_date
  FROM inserted i
    LEFT OUTER JOIN (
      SELECT id, barcode, reservation_date, dbo.due_date_by_mem_type(reservation_date, type) as reservation_due_date, member_ssn
      FROM loan l
        INNER JOIN person p on l.member_ssn = ssn
      WHERE reservation_date IS NOT NULL
        AND start_date IS NULL
        AND reservation_date >= CAST(DATEADD(DAY, -7, GETDATE()) AS DATE) -- let reservations expire after 7 days
    ) reservations on i.barcode = reservations.barcode
  WHERE reservations.reservation_date <= @due_date AND reservation_due_date >= @start_date

  -- ROLLBACK on overlapping reservations
  IF EXISTS (SELECT * FROM @reservations)
  BEGIN
    RAISERROR ('Cannot create loan/reservation due to overlap with existing reservatin(s)', 0, 1)
    SELECT * FROM @reservations
    ROLLBACK
  END
END
GO

insert into loan
  (Id, barcode, member_ssn, start_date)
values
  ((select max(id) + 1 from loan), 1001896, 100000011, GETDATE()),
  ((select max(id) + 2 from loan), 1001896, 100000011, GETDATE())

select *
from person p
  join loan l on p.ssn = l.member_ssn
where ssn  in (100000010, 100000011, 100000012, 100000013)
order by ssn

DELETE FROM loan WHERE id >= 100001

select *
from person p
  join loan l on p.ssn = l.member_ssn
where ssn in (100000010, 100000011) and barcode = 1008167
order by ssn