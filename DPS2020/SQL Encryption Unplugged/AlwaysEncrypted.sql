--drop database demodb
CREATE DATABASE DEMODB
GO
USE DEMODB;
GO
/****** Object:  Table [dbo].[TestTable]    Script Date: 11/22/2020 1:52:47 PM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE TABLE [dbo].[TestTable](
	[id] [int] NOT NULL,
	[ssn] [varchar](15)  NOT NULL,
	[name] [varchar](30) NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO

-- Query the table
SELECT [id]
      ,[ssn]
      ,[name]
  FROM [dbo].[TestTable]

insert into dbo.TestTable (id, ssn, name)
values (1, '111-22-3333', 'Bob Musali')

DECLARE @SSN char(11) = '111-22-3333';

insert into dbo.TestTable (id, ssn, name)
values (1, @SSN, 'Bob Musali')


DECLARE @SSN char(11) = '111-22-3333';

insert into dbo.TestTable (id, ssn, name)
values (2, @SSN, 'Ben Miller')
