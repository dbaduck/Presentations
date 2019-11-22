CREATE DATABASE DemoTemporal;

USE DemoTemporal;

/*
Clean up
ALTER TABLE dbo.Department SET (SYSTEM_VERSIONING = OFF)
DECLARE @object_id BIGINT 
SELECT @object_id = OBJECT_ID('dbo.Department',N'U')

DECLARE @sql NVARCHAR(512) = N'DROP TABLE IF EXISTS dbo.MSSQL_TemporalHistoryFor_' + CONVERT(NVARCHAR(16), @object_id)
EXEC sp_executesql @sql
DROP TABLE IF EXISTS dbo.Department

ALTER TABLE dbo.Department SET (SYSTEM_VERSIONING = OFF)
DROP TABLE IF EXISTS dbo.DepartmentHistory
DROP TABLE IF EXISTS dbo.Department

ADD TRUNCATE TABLE
*/

/*
Information About Temporal Tables
In-memory OLTP cannot be used.
Temporal and history table cannot be FILETABLE.
INSTEAD OF triggers are not allowed. AFTER triggers are only allowed on the current table.
The history table cannot have any constraints.
Data in the history table cannot be modified.
*/

/*
Anonymous tables
*/
CREATE TABLE dbo.Department   
(    
     DeptID int NOT NULL PRIMARY KEY CLUSTERED  
   , DeptName varchar(50) NOT NULL  
   , ManagerID INT  NULL  
   , ParentDeptID int NULL  
   , SysStartTime datetime2 GENERATED ALWAYS AS ROW START NOT NULL  
   , SysEndTime datetime2 GENERATED ALWAYS AS ROW END NOT NULL  
   , PERIOD FOR SYSTEM_TIME (SysStartTime,SysEndTime)     
)    
WITH (SYSTEM_VERSIONING = ON)   
;
select *
from dbo.Department

/*
Get the OBJECT_ID of the table to find the history table
*/
SELECT OBJECT_ID('dbo.Department', N'U')

/* 
Find the History Tables 
FORMAT: MSSQL_TemporalHistoryFor_OBJECTID 
*/
SELECT *
FROM sys.tables
WHERE name LIKE 'MSSQL%'


INSERT INTO dbo.Department (DeptID, DeptName, ManagerID, ParentDeptID)
VALUES	(1, 'Executives', 100, NULL),
		(2, 'Global IT', 200, 1),
		(3, 'IT Department', 400, 2),
		(4, 'Engineering', 500, 2)

/* 
Get the datetime before update (remember it is UTC in temporal tables)
*/
SELECT SYSUTCDATETIME()
-- 2018-12-06 18:35:49.7276465

UPDATE dbo.Department
SET ManagerID = 300
WHERE DeptID = 3;

/* 
Get the datetime after update (remember it is UTC in temporal tables)
*/
SELECT SYSUTCDATETIME()
-- 2018-12-06 18:36:21.6434489

SELECT *
FROM dbo.Department;

SELECT *
FROM dbo.MSSQL_TemporalHistoryFor_901578250;

/* 
Options for querying Temporal Tables
-- AS OF <datetime2>
-- FROM <datetime2> TO <datetime2>
-- BETWEEN <datetime2> AND <datetime2>
-- CONTAINED IN (<datetime2>, <datetime2>)
-- ALL - Return All values
*/
SELECT *
FROM dbo.Department
FOR SYSTEM_TIME AS OF '2018-12-06 18:35:49.7276465'
ORDER BY DeptID;

SELECT *
FROM dbo.Department
FOR SYSTEM_TIME AS OF '2018-12-06 18:36:21.6434489'
ORDER BY DeptID;

SELECT *
FROM dbo.Department
FOR SYSTEM_TIME ALL
ORDER BY DeptID;

/* 
* You cannot drop the table without turning off
* SYSTEM_VERSIONING. You get an error.
*/
DROP TABLE dbo.Department;

/*
* Turn off the SYSTEM_VERSIONING and then 
* drop the table (Using the new DIE syntax)
*/
ALTER TABLE dbo.Department SET (SYSTEM_VERSIONING=OFF);
DROP TABLE IF EXISTS dbo.Department;

/*
Default Table
*/
/*
* Let's create a History schema so that we can keep
* the history tables together
*/
CREATE SCHEMA History AUTHORIZATION dbo;

/*
* Now let's create the table with 
* specifying the history table
*/
CREATE TABLE dbo.Department   
(    
     DeptID int NOT NULL PRIMARY KEY CLUSTERED  
   , DeptName varchar(50) NOT NULL  
   , ManagerID INT  NULL  
   , ParentDeptID int NULL  
   , SysStartTime datetime2 GENERATED ALWAYS AS ROW START NOT NULL  
   , SysEndTime datetime2 GENERATED ALWAYS AS ROW END NOT NULL  
   , PERIOD FOR SYSTEM_TIME (SysStartTime, SysEndTime)     
)   
WITH    
   ( 
         SYSTEM_VERSIONING = ON (HISTORY_TABLE = History.Department)   
   )   
;  
SELECT 
	SCHEMA_NAME(schema_id) as [schema_name],
	*
FROM sys.tables
WHERE [name] like 'Department%';


ALTER TABLE dbo.Department SET (SYSTEM_VERSIONING=OFF);
DROP TABLE IF EXISTS dbo.Department;
DROP TABLE IF EXISTS History.Department;

DROP SCHEMA IF EXISTS History;

/*
Create the User-Defined Department History Table
Notice the definition matches with extra columns.
In Custom History tables you do not have to specify 
the GENERATED ALWAYS AS ROW START/END it is implied.
*/
CREATE TABLE dbo.DepartmentHistory   
(    
     DeptID int NOT NULL  
   , DeptName varchar(50) NOT NULL  
   , ManagerID INT  NULL  
   , ParentDeptID int NULL  
   , SysStartTime datetime2 NOT NULL   
   , SysEndTime datetime2 NOT NULL  
);   

/* Different if you have Finite Retention in 2017 */  
CREATE CLUSTERED COLUMNSTORE INDEX IX_DepartmentHistory   
   ON DepartmentHistory;   
CREATE NONCLUSTERED INDEX IX_DepartmentHistory_ID_PERIOD_COLUMNS   
   ON DepartmentHistory (SysEndTime, SysStartTime, DeptID);   
  
CREATE TABLE dbo.Department   
(    
    DeptID int NOT NULL PRIMARY KEY CLUSTERED  
   , DeptName varchar(50) NOT NULL  
   , ManagerID INT  NULL  
   , ParentDeptID int NULL  
   , SysStartTime datetime2 GENERATED ALWAYS AS ROW START NOT NULL  
   , SysEndTime datetime2 GENERATED ALWAYS AS ROW END NOT NULL 
   , PERIOD FOR SYSTEM_TIME (SysStartTime,SysEndTime)      
)    
WITH (SYSTEM_VERSIONING = ON (HISTORY_TABLE = dbo.DepartmentHistory))   
; 

ALTER TABLE dbo.Department SET (SYSTEM_VERSIONING=OFF);
DROP TABLE IF EXISTS dbo.DepartmentHistory;
DROP TABLE IF EXISTS dbo.Department;

/*
Adding versioning to an already existing table
Beware of the DEFAULT datetime that you specify for the existing rows
TEST, TEST, TEST



Prerequisites
A primary key must be defined.
The table option SYSTEM_VERSIONING must be set to ON.
Two DATETIME2 columns must be defined to record the start and end date.


*/
CREATE SCHEMA History;   
GO   
CREATE TABLE dbo.Department   
(    
     DeptID int NOT NULL  
   , DeptName varchar(50) NOT NULL  
   , ManagerID INT  NULL  
   , ParentDeptID int NULL  
);   

ALTER TABLE dbo.Department
	ADD CONSTRAINT PK_dbo_Department__DeptID PRIMARY KEY CLUSTERED 
		( DeptID );

ALTER TABLE dbo.Department   
   ADD   
      SysStartTime datetime2 GENERATED ALWAYS AS ROW START HIDDEN    
           CONSTRAINT DF_SysStart DEFAULT SYSUTCDATETIME()  
      , SysEndTime datetime2 GENERATED ALWAYS AS ROW END HIDDEN    
           CONSTRAINT DF_SysEnd DEFAULT CONVERT(datetime2 (7), '9999-12-31 23:59:59.9999999'),   
      PERIOD FOR SYSTEM_TIME (SysStartTime, SysEndTime);   
GO   
ALTER TABLE dbo.Department    
   SET (SYSTEM_VERSIONING = ON (HISTORY_TABLE = History.Department))   
;

ALTER TABLE dbo.Department SET (SYSTEM_VERSIONING=OFF);
DROP TABLE IF EXISTS History.Department;
DROP TABLE IF EXISTS dbo.Department;
DROP SCHEMA History;

/* Retention */
CREATE TABLE dbo.WebsiteUserInfo
(  
    [UserID] int NOT NULL PRIMARY KEY CLUSTERED
  , [UserName] nvarchar(100) NOT NULL
  , [PagesVisited] int NOT NULL
  , [ValidFrom] datetime2 (0) GENERATED ALWAYS AS ROW START
  , [ValidTo] datetime2 (0) GENERATED ALWAYS AS ROW END
  , PERIOD FOR SYSTEM_TIME (ValidFrom, ValidTo)
 )  
 WITH
 (
     SYSTEM_VERSIONING = ON
     (
        HISTORY_TABLE = dbo.WebsiteUserInfoHistory,
        HISTORY_RETENTION_PERIOD = 6 MONTHS
     )
 );

/*Create B-tree ordered by the end of period column*/
CREATE CLUSTERED INDEX IX_WebsiteUserInfoHistory 
	ON WebsiteUserInfoHistory (ValidTo)
WITH (DROP_EXISTING = ON);
GO
/*Re-create clustered columnstore index*/
CREATE CLUSTERED COLUMNSTORE INDEX IX_WebsiteUserInfoHistory 
	ON WebsiteUserInfoHistory
WITH (DROP_EXISTING = ON);

/* Cannot create a NCI on the table */
CREATE NONCLUSTERED INDEX IX_WebHistNCI ON WebsiteUserInfoHistory ([UserName])

/* See the provisions of Retention */
SELECT 
	DB.is_temporal_history_retention_enabled,
	SCHEMA_NAME(T1.schema_id) AS TemporalTableSchema,
	T1.name as TemporalTableName,  
	SCHEMA_NAME(T2.schema_id) AS HistoryTableSchema,
	T2.name as HistoryTableName,
	T1.history_retention_period,
	T1.history_retention_period_unit_desc
FROM sys.tables T1  
OUTER APPLY (select 
				is_temporal_history_retention_enabled 
			 from sys.databases
			 where name = DB_NAME()) AS DB
LEFT JOIN sys.tables T2 ON T1.history_table_id = T2.object_id 
WHERE 
	T1.temporal_type = 2;


/* End */

USE master;
DROP DATABASE DemoTemporal;


/*
End Demo
*/



/*
Safeguards in place
*/
DROP TABLE dbo.Department


/*
Turning it off
*/
ALTER TABLE dbo.Department  
SET (SYSTEM_VERSIONING = OFF)

/*
Turn it back on
*/
ALTER TABLE dbo.Department  
SET (SYSTEM_VERSIONING = ON (HISTORY_TABLE = dbo.DepartmentHistory))

/*
Take note that if you have a custom table
You need to specify it when turning it back on
*/






--Real timezone support


SELECT
	SYSDATETIMEOFFSET()
GO




SELECT
	*
FROM sys.time_zone_info
GO




SELECT
	SYSDATETIMEOFFSET() AT TIME ZONE 'Central Standard Time'
GO




--What time is it in London?
SELECT
	SYSDATETIMEOFFSET() AT TIME ZONE 'GMT Standard Time'
GO



--DST awareness
--On March 26 at 05:00 EST, what time was it in London?
SELECT
	CONVERT(DATETIME, '2016-03-26 05:00:00') AT TIME ZONE 'Eastern Standard Time' AT TIME ZONE 'GMT Standard Time'
GO


--And on the 27th?
SELECT
	CONVERT(DATETIME, '2016-03-27 05:00:00') AT TIME ZONE 'Eastern Standard Time' AT TIME ZONE 'GMT Standard Time'
GO




--best practice, use UTC for everything, always, and convert...

DECLARE @desired_time_zone VARCHAR(50) = 'Eastern Standard Time'

SELECT
	SYSUTCDATETIME() AT TIME ZONE 'UTC' AT TIME ZONE @desired_time_zone
GO


