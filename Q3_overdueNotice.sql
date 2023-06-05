DROP FUNCTION IF EXISTS due_date_by_mem_type
DROP FUNCTION IF EXISTS due_date_w_grace_by_mem_type
GO

CREATE FUNCTION due_date_by_mem_type(
  @start_date DATETIME,
  @person_type nvarchar(255))
RETURNS DATE
AS
BEGIN
  DECLARE @d DATETIME = DATEADD(DAY, (
    CASE
      WHEN LOWER(@person_type) = 'professor' 
        THEN 90 -- days
      ELSE 21 -- days
      END
    ),
    @start_date)

  RETURN CAST(@d as DATE)
END
GO

CREATE FUNCTION due_date_w_grace_by_mem_type(
  @start_date DATETIME,
  @person_type nvarchar(255))
RETURNS DATE
AS
BEGIN
  DECLARE @d DATETIME = DATEADD(DAY, (
    CASE 
      WHEN LOWER(@person_type) = 'professor' 
        THEN 104 -- 90 + 14 days
      ELSE 28 -- 21 + 7 days
      END
    ),
    @start_date)

  RETURN CAST(@d as DATE)
END
GO

SELECT dbo.due_date_w_grace_by_mem_type(GETDATE(), 'professor')

SELECT *
FROM loan
  INNER JOIN person on member_ssn = ssn
WHERE 
  start_date IS NOT NULL
  AND returned_date IS NULL
  AND notice_sent = 0
  AND dbo.due_date_w_grace_by_mem_type(start_date, type) < CAST(GETDATE() AS DATE)

Select count(*) from loan where returned_date is null

SELECT *
FROM loan
  INNER JOIN person on member_ssn = ssn
WHERE start_date IS NOT NULL
  AND returned_date IS NULL
  AND notice_sent = 0
  AND dbo.due_date_w_grace_by_mem_type(start_date, type) < DATEADD(DAY, -1, CAST(GETDATE() AS DATE))

-- Marker som at notits er sendt for tidligere udløbede udlån, for at simulere at der bliver gjordt dagligt
UPDATE loan SET 
notice_sent = (
SELECT (CASE WHEN start_date IS NOT NULL
  AND l2.returned_date IS NULL
  AND dbo.due_date_w_grace_by_mem_type(l2.start_date, type) < DATEADD(DAY, -1, CAST(GETDATE() AS DATE)) THEN 1 ELSE 0 END) as notice_sent_updated
FROM loan l2
  INNER JOIN person on l2.member_ssn = ssn
WHERE  loan.Id = l2.Id
) 

DROP INDEX [loan_ret_date_noti_sent_idx] on loan
DROP INDEX [loan_ret_date_noti_sent_idx1] on loan
DROP INDEX [loan_ret_date_noti_sent_idx2] on loan
DROP INDEX [loan_ret_date_noti_sent_idx3] on loan
DROP INDEX [loan_ret_date_noti_sent_idx4] on loan

CREATE NONCLUSTERED INDEX [loan_ret_date_noti_sent_idx]
ON [dbo].[loan] ([returned_date],[notice_sent],[start_date])
CREATE NONCLUSTERED INDEX [loan_ret_date_noti_sent_idx1]
ON [dbo].[loan] ([returned_date],[start_date],[notice_sent])
CREATE NONCLUSTERED INDEX [loan_ret_date_noti_sent_idx2]
ON [dbo].[loan] ([start_date],[returned_date],[notice_sent])
CREATE NONCLUSTERED INDEX [loan_ret_date_noti_sent_idx3]
ON [dbo].[loan] ([notice_sent],[start_date],[returned_date])
CREATE NONCLUSTERED INDEX [loan_ret_date_noti_sent_idx4]
ON [dbo].[loan] ([start_date],[notice_sent],[returned_date])

SELECT cast(GETDATE() as DATE), cast(DATEADD(DAY , -28, GETDATE()) as DATE), cast(DATEADD(DAY , -104, GETDATE()) as DATE)