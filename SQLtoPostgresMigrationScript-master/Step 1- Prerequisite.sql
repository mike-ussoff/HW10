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
