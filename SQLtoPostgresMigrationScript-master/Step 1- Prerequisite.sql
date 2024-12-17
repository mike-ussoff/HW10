USE [AdventureWorks]
GO

create or alter function [dbo].[GetString](@value as nvarchar(max))
returns nvarchar(max)
as
begin
return case when @value is null then 'null' when @value = '' then '""' else '"'+ replace(@value,'"','""') + '"' end
end
GO

create or alter function [dbo].[GetStringFromXML] (@value as xml)
returns nvarchar(max)
as
begin
    declare @text nvarchar(max);
    select @text = convert(nvarchar(max), @value)
	return case when @text is null then 'null' when @text = '' then '""' else '"'+ replace(@text,'"','""') + '"' end
end
GO

create or alter function [dbo].[ConvertDateAdd](@definition as nvarchar(max))
returns nvarchar(max)
as
begin

DECLARE	@oldpart nvarchar(max) = '';
DECLARE	@newpart nvarchar(max) = '';
DECLARE @start int = 0; 
DECLARE @i int = 0; 
DECLARE @char nvarchar(max) = '';
DECLARE @cycle int = 0; 
DECLARE @len int = 0;
DECLARE @parnum int = 0; 
DECLARE @param1 nvarchar(MAX) = ''; 
DECLARE @param2 nvarchar(MAX) = ''; 

SET @start = CHARINDEX('dateadd', @definition);
SET @i = @start;
SET @len = LEN(@definition);

IF @i > 0
BEGIN
	WHILE @i <= @len
	BEGIN
		SET @char = SUBSTRING(@definition, @i, 1);
		IF @char = '(' SET @cycle = @cycle + 1;
		IF @char = ')' AND @cycle = 1 BREAK;
		IF @char = ')' SET @cycle = @cycle - 1;
		IF @cycle = 1 
		BEGIN
			IF @char = ',' SET @parnum = @parnum + 1;
			IF @char <> '(' AND @char <> ')' AND @char <> ',' AND @parnum = 0 SET @param1 = @param1 + @char;
		END
		IF @cycle = 2 
		BEGIN
			IF @char <> '(' AND @char <> ')' AND @char <> ',' AND @parnum = 1 SET @param2 = @param2 + @char;
		END
		SET @i = @i + 1;
	END

	SET @oldpart = SUBSTRING(@definition, @start, @i - @start + 1);
	SET @newpart = 'CURRENT_DATE + INTERVAL ''' + @param2 + ' ' + @param1 + ''''; 

	RETURN REPLACE(@definition, @oldpart, @newpart)
END

RETURN NULL;

end
GO