use [AdventureWorks];

SELECT
    'ALTER TABLE '+ SCHEMA_NAME(schema_id) + '.' + OBJECT_NAME(parent_object_id) + 
    ' ADD CONSTRAINT ' + dc.name + ' CHECK' + 	
	CASE WHEN CHARINDEX('dateadd', definition) > 0 and CHARINDEX('getdate', definition) > 0
	THEN [dbo].[ConvertDateAdd](REPLACE(REPLACE(definition, '[', ''), ']', ''))
	ELSE REPLACE(REPLACE(REPLACE(definition, '[', ''), ']', ''), 'like ''A-Za-z''', 'similar to ''[A-Za-z]''')
	END + ';'
FROM sys.check_constraints dc
INNER JOIN sys.columns c ON dc.parent_object_id = c.object_id AND dc.parent_column_id = c.column_id

