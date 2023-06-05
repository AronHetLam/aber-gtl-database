CREATE TABLE [item_type] (
  [type] nvarchar(255) PRIMARY KEY,
  [loanable] bit DEFAULT (1),
  [item_type] nvarchar(255)
)
GO

CREATE TABLE [subject] (
  [subject] nvarchar(255) PRIMARY KEY
)
GO

CREATE TABLE [item_subjects] (
  [subject] nvarchar(255),
  [i_id] int,
  PRIMARY KEY ([subject], [i_id])
)
GO

CREATE TABLE [author] (
  [id] int PRIMARY KEY,
  [first_name] varchar(50),
  [last_name] varchar(50)
)
GO

CREATE TABLE [item_authors] (
  [i_id] int,
  [a_id] int,
  PRIMARY KEY ([i_id], [a_id])
)
GO

CREATE TABLE [item] (
  [id] int PRIMARY KEY,
  [title] nvarchar(255) NOT NULL,
  [date] datetime,
  [for_acquisition] bit DEFAULT (0),
  [description] text,
  [type] nvarchar(255) NOT NULL,
  [isbn] nvarchar(255),
  [area] nvarchar(255),
  [misc_identifier] nvarchar(255)
)
GO

CREATE TABLE [item_copy] (
  [barcode] int PRIMARY KEY,
  [destroyed] bit,
  [i_id] int
)
GO

CREATE TABLE [loan] (
  [Id] int PRIMARY KEY,
  [barcode] int,
  [member_ssn] int,
  [reservation_date] datetime,
  [start_date] datetime,
  [returned_date] datetime,
  [notice_sent] bit DEFAULT (0)
)
GO

CREATE TABLE [person] (
  [ssn] int PRIMARY KEY,
  [first_name] nvarchar(255),
  [last_name] nvarchar(255),
  [birth_date] datetime,
  [sex] char(1),
  [campus] nvarchar(255),
  [phone_no] nvarchar(255),
  [address] nvarchar(255),
  [l_flag] bit DEFAULT (0),
  [role] nvarchar(255),
  [m_flag] bit DEFAULT (0),
  [type] nvarchar(255)
)
GO

CREATE TABLE [member_card] (
  [card_number] int PRIMARY KEY,
  [issued] datetime NOT NULL,
  [member_ssn] int NOT NULL
)
GO

ALTER TABLE [item] ADD FOREIGN KEY ([type]) REFERENCES [item_type] ([type])
GO

ALTER TABLE [item_subjects] ADD FOREIGN KEY ([subject]) REFERENCES [subject] ([subject])
GO

ALTER TABLE [item_subjects] ADD FOREIGN KEY ([i_id]) REFERENCES [item] ([id])
GO

ALTER TABLE [item_authors] ADD FOREIGN KEY ([a_id]) REFERENCES [author] ([id])
GO

ALTER TABLE [item_authors] ADD FOREIGN KEY ([i_id]) REFERENCES [item] ([id])
GO

ALTER TABLE [item_copy] ADD FOREIGN KEY ([i_id]) REFERENCES [item] ([id])
GO

ALTER TABLE [loan] ADD FOREIGN KEY ([barcode]) REFERENCES [item_copy] ([barcode])
GO

ALTER TABLE [loan] ADD FOREIGN KEY ([member_ssn]) REFERENCES [person] ([ssn])
GO

ALTER TABLE [member_card] ADD FOREIGN KEY ([member_ssn]) REFERENCES [person] ([ssn])
GO
