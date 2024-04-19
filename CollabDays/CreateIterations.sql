CREATE TABLE dbo.Iterations (
	iteration_id int not null identity(1,1),
	gather_date datetime2(3) not null,
	server_starttime datetime2(3) not null,
	constraint PK_Iterations_Id PRIMARY KEY CLUSTERED (
		iteration_id
	)
)
GO

CREATE PROCEDURE dbo.get_iterationId
AS
	SET NOCOUNT ON;

	DECLARE @serverStart datetime,	
		@gatherDate datetime = getdate()

	SELECT TOP (1) 
		@serverStart = s.last_startup_time
	FROM sys.dm_server_services s
	WHERE 
		servicename like 'SQL Server (%'
	
	INSERT INTO dbo.Iterations (gather_date, server_starttime)
	OUTPUT inserted.iteration_id
	VALUES (@gatherDate, ISNULL(@serverStart, '19000101'))

	SET NOCOUNT OFF;
GO


CREATE TABLE dbo.stats_Database (
	ID int,
	Name nvarchar(128),
	Size bigint,
	DataSpaceUsage decimal(18,2),
	IndexSpaceUsage decimal(18,2),
	LastBackupDate datetime2(0),
	RecoveryModel varchar(15),
	PageVerify varchar(20),
	CompatibilityLevel varchar(10),
	IsReadCommittedSnapshotOn bit,
	IterationId int NOT NULL
)
