DECLARE @d DATE = DATEADD(YEAR, -1, CAST(GETDATE() as DATE))

SELECT type,
  COUNT(*) as total_loans,
  SUM(CASE WHEN returned_date <= due_date THEN 1 END)
    as timely_returns,
  (SUM(CASE WHEN returned_date <= due_date THEN 1 END) * 100.0) / COUNT(*)
    as timely_percentage,
  SUM(CASE WHEN notice_sent = 0 AND returned_date > due_date THEN 1 END)
    as late_returns_before_notice,
  (SUM(CASE WHEN notice_sent = 0 AND returned_date > due_date THEN 1 END) *
      100.0) / COUNT(*)
    as percentage_before_notice,
  SUM(CAST(notice_sent as int))
    as late_returns_after_notice,
  (SUM(CAST(notice_sent as int)) * 100.0) / COUNT(*)
    as percentage_after_notice
FROM (
  SELECT id,
    type,
    dbo.due_date_by_mem_type(start_date, type) as due_date,
    CAST(returned_date as DATE) as returned_date,
    notice_sent
  FROM person    
  INNER JOIN loan ON ssn = member_ssn
WHERE start_date >= @d
  AND returned_date IS NOT NULL) loans
GROUP BY type
OPTION (RECOMPILE);

-- Index
DROP INDEX IDX_loan_start_date_returned_date ON loan

CREATE INDEX [IDX_loan_start_date_returned_date]
ON [gtl_database].dbo.[loan] ([start_date],[returned_date]) include (member_ssn, notice_sent)
WHERE returned_date is not null AND start_date >= '2022-06-04'


-- DELETE loans for non-member persons
DELETE -- SELECT * 
FROM loan
WHERE id in (
  SELECT id
FROM loan
  INNER JOIN person on member_ssn = ssn
WHERE m_flag = 0
)

-- Make 2000 loans for professors overdue within past 300 days
MERGE loan as l1 
USING(
  SELECT TOP 2000
    id,
    start_date,
    returned_date,
    DATEADD(month, 3, returned_date) as updated_date
  FROM loan
    INNER JOIN person on  member_ssn = ssn
  WHERE start_date > DATEADD(DAY, -300, GETDATE())
    AND returned_date IS NOT NULL
    AND type = 'Professor'
  ORDER BY start_date
) AS l2 on l1.id = l2.id 
WHEN MATCHED 
  THEN UPDATE SET l1.returned_date = l2.updated_date;

-- Set notice_sent based on loan priod
MERGE loan as l1 
USING(
  SELECT id, CASE WHEN dbo.get_loan_end_w_grace_by_member_type(start_date, type) < returned_date THEN 1 else 0 END as updated_notice
FROM loan
  INNER JOIN person on member_ssn = ssn
) AS l2 on l1.id = l2.id 
WHEN MATCHED 
  THEN UPDATE SET l1.notice_sent = l2.updated_notice;
