-- Change the database to use for the repository
CREATE SCHEMA [stat] AUTHORIZATION dbo
GO

CREATE SEQUENCE dbo.seq_Iterations START WITH 1 INCREMENT BY 1;

CREATE TABLE stat.Iterations (
	iteration_id int not null CONSTRAINT DF_iteration_id_seq DEFAULT (NEXT VALUE FOR dbo.seq_Iterations), 
	gather_date datetime2(3) not null constraint DF_gather_date_getdate DEFAULT (getdate()),
	CONSTRAINT PK_Iterations_iteration_id PRIMARY KEY CLUSTERED (
		iteration_id
	)
);


CREATE SEQUENCE stat.TableStatistics_Seq as bigint
START WITH 1 INCREMENT BY 1

CREATE SEQUENCE stat.IndexUsage_Seq as bigint
START WITH 1 INCREMENT BY 1


/****** Object:  Table [stat].[IndexUsage]    Script Date: 4/20/2020 10:59:19 PM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE TABLE [stat].[IndexUsage](
	[server_name] [nvarchar](128) NULL,
	[database_name] [nvarchar](128) NULL,
	[database_id] [smallint] NULL,
	[object_id] [int] NOT NULL,
	[schema_name] [sysname] NOT NULL,
	[table_name] [sysname] NOT NULL,
	[index_name] [sysname] NULL,
	[index_id] [int] NOT NULL,
	[user_seeks] [bigint] NULL,
	[user_scans] [bigint] NULL,
	[user_lookups] [bigint] NULL,
	[user_updates] [bigint] NULL,
	[last_user_seek] [datetime] NULL,
	[last_user_scan] [datetime] NULL,
	[iterationid] [int] NOT NULL,
	[IndexUsageId] [bigint] NOT NULL,
 CONSTRAINT [PK_stat_IndexUsage__IndexUsageId] PRIMARY KEY CLUSTERED 
(
	[IndexUsageId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO

ALTER TABLE [stat].[IndexUsage] ADD  CONSTRAINT [DF_IndexUsage_IndexUsageSeq]  DEFAULT (NEXT VALUE FOR [stat].[IndexUsage_Seq]) FOR [IndexUsageId]
GO


/****** Object:  Table [stat].[TableStatistics]    Script Date: 4/20/2020 10:59:49 PM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE TABLE [stat].[TableStatistics](
	[server_name] [nvarchar](128) NULL,
	[database_name] [nvarchar](128) NULL,
	[schema_name] [sysname] NOT NULL,
	[table_name] [sysname] NOT NULL,
	[index_count] [int] NULL,
	[data_space_mb] [bigint] NULL,
	[index_space_mb] [bigint] NULL,
	[row_count] [bigint] NULL,
	[column_count] [int] NULL,
	[is_clustered] [bit] NULL,
	[definition_length] [int] NULL,
	[clustered_column_count] [int] NULL,
	[primary_key_columns] [nvarchar](max) NULL,
	[is_pk_clustered] [bit] NULL,
	[primary_key_name] [sysname] NULL,
	[is_pk_system_named] [bit] NULL,
	[is_heap] [bit] NULL,
	[iterationid] [int] NOT NULL,
	[TableStatisticsId] [bigint] NOT NULL,
 CONSTRAINT [PK_stat_TableStatistics__TableStatisticsId] PRIMARY KEY CLUSTERED 
(
	[TableStatisticsId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO

ALTER TABLE [stat].[TableStatistics] ADD  CONSTRAINT [DF_TableStatistics_TableStatisticsSeq]  DEFAULT (NEXT VALUE FOR [stat].[TableStatistics_Seq]) FOR [TableStatisticsId]
GO

SELECT
	@@SERVERNAME AS [server_name],
	DB_NAME() as [database_name],
	s.name as [schema_name],
	t.name as [table_name],
	t.object_id as [table_object_id],
	ix.name as [index_name],
	ix.index_id,
	ix.fill_factor,
	ix.has_filter,
	ix.is_disabled,
	ix.is_primary_key,
	ix.is_unique,
	ix.type_desc,
	ius.user_seeks,
	ius.user_scans,
	ius.user_lookups,
	ius.user_updates,
	ius.last_user_seek,
	ius.last_user_scan,
	ius.last_user_update
FROM sys.schemas s
INNER JOIN sys.tables t on s.schema_id = t.schema_id
INNER JOIN sys.indexes ix on t.object_id = ix.object_id
LEFT JOIN sys.dm_db_index_usage_stats ius
	ON ix.object_id = ius.object_id AND ix.index_id = ius.index_id
WHERE 
	t.is_ms_shipped = 0
ORDER BY 
	s.name, t.name, ix.index_id;


WITH ColumnCounts
AS (
    SELECT 
        t.object_id,
        COUNT(*) as column_count
    FROM sys.schemas as s
    inner join sys.tables as t on s.schema_id = t.schema_id
    INNER JOIN sys.columns as c on t.object_id = c.object_id
    GROUP BY t.object_id
),
IndexCounts
AS (
    SELECT 
        t.object_id,
        COUNT(*) as index_count
    FROM sys.tables as t 
    INNER JOIN sys.indexes as ix on t.object_id = ix.object_id
    GROUP BY t.object_id
),
PrimaryKeys
AS (
    SELECT 
        t.object_id,
        c.name as [primary_key_name],
        c.is_system_named,
        c.unique_index_id,
        STUFF((SELECT ',' + col.name
            FROM sys.index_columns as cl
            INNER JOIN sys.columns as col on cl.object_id = col.object_id and cl.column_id = col.column_id
            WHERE 
                cl.object_id = c.parent_object_id 
                and cl.index_id = c.unique_index_id
            ORDER BY cl.key_ordinal
            FOR XML PATH('')),1,1,'') as key_columns
    FROM sys.tables as t 
    LEFT JOIN sys.key_constraints as c ON t.object_id = c.parent_object_id and c.type = 'PK'
),
TableLengths
AS (
    select 
        t.object_id, 
        --CASE WHEN c.system_type_id IN (127, 56, 52, 48, 36, 173, 61, 175, 62, 98, 32, 106, 104, 239, 35, 34, 40, 41, 42, 58, 59, 60, 99, 108, 240, 189, 122) THEN c.max_length
        --     WHEN c.system_type_id IN (231, 165, 167, 240, 241) AND st.max_length > 0 THEN c.max_length ELSE 16 END 
        SUM(CASE WHEN c.max_length > 0 THEN c.max_length
            ELSE 16 
        END) as table_length
    from sys.tables as t
    INNER JOIN sys.columns as c ON t.object_id = c.object_id 
    inner join sys.types as st on c.system_type_id = st.system_type_id
            and st.user_type_id = c.user_type_id
    WHERE t.is_ms_shipped = 0
    GROUP BY t.object_id
)
SELECT
    @@SERVERNAME as [server_name],
    DB_NAME() as [database_name],
    s.name as [schema_name],
    t.name as [table_name],
    ic.index_count,
    dau.data_space_mb,
    dau.index_space_mb,
    dau.rows as [row_count],
    c.column_count as [column_count],
    CAST(ix.index_id as bit) as [is_clustered],
    tl.table_length as [definition_length],
    (SELECT COUNT(*) 
        FROM sys.indexes as iix 
        INNER JOIN sys.index_columns ixc ON iix.object_id = ixc.object_id and iix.index_id = ixc.index_id 
        INNER JOIN sys.columns as ccc ON ixc.object_id = ccc.object_id AND ccc.column_id = ixc.column_id
        WHERE iix.index_id = 1
            AND iix.object_id = ix.object_id 
            AND iix.index_id = ix.index_id
    ) as [clustered_column_count],
    pk.key_columns as [primary_key_columns],
    CAST(CASE WHEN pk.unique_index_id = 1 THEN 1 ELSE 0 END as bit) as [is_pk_clustered],
    pk.primary_key_name as [primary_key_name],
    pk.is_system_named as is_pk_system_named,
	CONVERT(BIT, CASE WHEN ix.index_id = 0 THEN 1 ELSE 0 END) AS is_heap
	--$IterationId AS [iterationid]
--INTO stat.TableStatistics
FROM sys.schemas as s
INNER JOIN sys.tables t (nolock) on s.schema_id = t.schema_id
INNER JOIN ColumnCounts as c ON t.object_id = c.object_id
INNER JOIN sys.indexes as ix (nolock) on t.object_id = ix.object_id
INNER JOIN IndexCounts as ic on t.object_id = ic.object_id
INNER JOIN TableLengths as tl ON t.object_id = tl.object_id
LEFT JOIN PrimaryKeys as pk ON pk.object_id = t.object_id
CROSS APPLY (
        SELECT
            ix.object_id,
            p.[rows],
            SUM(CASE WHEN p.index_id IN (0,1) THEN au.total_pages ELSE 0 END)/128 as data_space_mb,
            SUM(CASE WHEN p.index_id > 1 THEN au.total_pages ELSE 0 END)/128 as index_space_mb
        FROM sys.tables as it (nolock)
        INNER JOIN sys.indexes as ix (nolock) ON it.object_id = ix.object_id
        INNER JOIN sys.partitions as p (nolock) ON ix.object_id = p.object_id and ix.index_id = p.index_id
        INNER JOIN sys.allocation_units as au (nolock) ON p.partition_id = au.container_id 
        WHERE p.object_id = ix.object_id and p.index_id = ix.index_id and ix.object_id = t.object_id
            and it.is_ms_shipped = 0
        GROUP BY ix.object_id, p.[rows]
    ) as dau
WHERE ix.index_id IN (0,1)
    AND t.is_ms_shipped = 0
OPTION (RECOMPILE)

