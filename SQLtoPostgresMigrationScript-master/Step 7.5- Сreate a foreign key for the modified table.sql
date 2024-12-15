ALTER TABLE Production.ProductDocument  ADD CONSTRAINT FK_ProductDocument_Document_DocumentId FOREIGN KEY(DocumentId) 
REFERENCES Production.Document (DocumentId);
select 1;