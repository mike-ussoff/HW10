USE [AdventureWorks]


-- SQL varbinary to bytea postgresql
-- master.dbo.fn_varbintohexstr
-- encode(decode('68656C6C6F','hex'),'escape')
--Schema script
declare @databaseName varchar(100)

set @databaseName = DB_NAME()

select 'create schema ' + name + '; ALTER SCHEMA public OWNER TO postgres;'
from sys.schemas
where name not like 'db[_]%'
	and name <> 'sys'
	and name <> 'INFORMATION_SCHEMA'

--Table script
select cast('create table ' + TABLE_SCHEMA + '.' + table_name + char(13) + '(' + STUFF((
	select ', ' + char(13) + (
		case 
			when column_name = 'Database Version' then 'database_version'
			when column_name = 'Group' then 'grouping'
			when column_name = 'Primary' then 'IsPrimary'
			else column_name
		end
	) + (
		case 
			when DATA_TYPE in (
				'char',
				'nchar'
			)
				and CHARACTER_MAXIMUM_LENGTH <> - 1
				then ' char(' + cast(isnull(CHARACTER_MAXIMUM_LENGTH, 8000) as varchar(10)) + ')'
			when DATA_TYPE in (
				'nvarchar'
				,'varchar'
			)
				and CHARACTER_MAXIMUM_LENGTH <> - 1 --and CHARACTER_MAXIMUM_LENGTH < 8000
				then ' varchar(' + cast(isnull(CHARACTER_MAXIMUM_LENGTH, 8000) as varchar(10)) + ')'
			when DATA_TYPE in (
				'nvarchar'
				,'text'
				,'varchar',
				'char',
				'nchar',
				'ntext'
			)
				and CHARACTER_MAXIMUM_LENGTH = - 1
				then ' text'
			when DATA_TYPE = 'decimal'
				then ' Numeric(' + cast(NUMERIC_PRECISION as varchar(2)) + ',' + cast(numeric_scale as varchar(2)) + ')' + iif(COLUMN_DEFAULT = '((0.00))', ' Default 0.00', '')
			when DATA_TYPE = 'bit'
				then ' Boolean' + iif(COLUMN_DEFAULT = '((0))', ' Default false', iif(COLUMN_DEFAULT = '((1))', ' Default true', ''))
			when DATA_TYPE in (
				'tinyint'
				,'smallint'
				)
				then ' smallint' + iif(COLUMN_DEFAULT is not null, ' Default ' + replace(replace(COLUMN_DEFAULT, '((', ''), '))', ''), '')
			when DATA_TYPE = 'int'
				then ' integer' + iif(COLUMN_DEFAULT is not null, ' Default ' + replace(replace(COLUMN_DEFAULT, '((', ''), '))', ''), '')
			when DATA_TYPE = 'date'
				then ' date'
			when DATA_TYPE = 'datetime'
				or DATA_TYPE = 'datetime2'
				then ' timestamptz' + iif(COLUMN_DEFAULT = '(getdate())', ' Default current_timestamp', '')
			when DATA_TYPE = 'uniqueidentifier'
				then ' UUID'  + iif(COLUMN_DEFAULT = '(newid())', ' Default gen_random_uuid()', '')
			when DATA_TYPE in (
				'money'
				,'smallmoney'
				)
				then ' Numeric(18,2)' + iif(COLUMN_DEFAULT = '((0.00))', ' Default 0.00', '')
			when DATA_TYPE in (
				'binary'
				,'varbinary'
				,'image'
				,'geography'
				)
				then ' BYTEA'
			when DATA_TYPE = 'hierarchyid'
				then ' varchar(255)'
			else ' ' + 
				case COLUMNPROPERTY(OBJECT_ID(TABLE_SCHEMA + '.' + TABLE_NAME), COLUMN_NAME, 'IsIdentity')
					when 1
						then 'SERIAL'
					else DATA_TYPE
				end
		end
		+ case when IS_NULLABLE = 'NO' then ' NOT NULL' else '' end
		)
	from INFORMATION_SCHEMA.COLUMNS
		where (
				table_name = Results.table_name
				and TABLE_SCHEMA = Results.TABLE_SCHEMA
			  )
		for xml PATH('')
			,TYPE
	).value('(./text())[1]', 'VARCHAR(MAX)'), 1, 2, '') + char(13) + ');' + char(13) as xml)
from INFORMATION_SCHEMA.COLUMNS Results
where TABLE_NAME not in (
		select [name]
		from sys.views
		)
group by Results.TABLE_SCHEMA
	,table_name
for xml PATH('')