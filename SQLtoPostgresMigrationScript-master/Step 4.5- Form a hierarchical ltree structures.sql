create extension ltree;

-- production.document

-- DROP TABLE IF EXISTS production.document1;

ALTER TABLE production.document RENAME TO document1;

CREATE TABLE IF NOT EXISTS production.document
(
    documentid serial NOT NULL,
    documentnode character varying(255) COLLATE pg_catalog."default",
    documentpath ltree NOT NULL UNIQUE DEFAULT ((lastval())::text)::ltree,
    documentlevel smallint,
    title character varying(50) COLLATE pg_catalog."default",
    owner integer,
    folderflag boolean DEFAULT false,
    filename character varying(400) COLLATE pg_catalog."default",
    fileextension character varying(8) COLLATE pg_catalog."default",
    revision character varying(5) COLLATE pg_catalog."default",
    changenumber integer,
    status smallint,
    documentsummary text COLLATE pg_catalog."default",
    document bytea,
    rowguid uuid,
    modifieddate timestamp with time zone,
    CONSTRAINT document_documentid_pkey PRIMARY KEY (documentid)
)

TABLESPACE pg_default;

CREATE INDEX document_documentpath_idx ON production.document using gist (documentpath);

INSERT INTO production.document (documentnode, documentlevel, title, owner, folderflag, filename, 
fileextension, revision, changenumber, status, documentsummary, document, rowguid, modifieddate)
SELECT documentnode, documentlevel, title, owner, folderflag, filename, 
fileextension, revision, changenumber, status, documentsummary, document, rowguid, modifieddate
FROM production.document1;

DROP TABLE production.document1;

WITH nodes AS
(
SELECT d.documentid, d.documentnode,
(
	SELECT STRING_AGG(d2.documentid::text, '.')
	FROM (SELECT documentid, documentnode FROM production.document order by documentlevel) AS d2
	WHERE d.documentnode LIKE d2.documentnode || '%'
) AS node
FROM production.document d
)

MERGE INTO production.document AS d
USING nodes AS s 
ON s.documentid = d.documentid and s.node is not null
WHEN MATCHED THEN UPDATE SET documentpath = s.node::ltree;

UPDATE production.document SET documentlevel = nlevel(documentpath);

-- production.productdocument

-- DROP TABLE IF EXISTS production.productdocument1;

ALTER TABLE production.productdocument RENAME TO productdocument1;

CREATE TABLE IF NOT EXISTS production.productdocument
(
    productid integer NOT NULL,
    documentid integer NOT NULL,
    documentnode character varying(255) COLLATE pg_catalog."default",
    modifieddate timestamp with time zone,
    CONSTRAINT productdocument_pkey PRIMARY KEY (productid, documentid)
)

TABLESPACE pg_default;

INSERT INTO production.productdocument (productid, documentid, documentnode, modifieddate)
SELECT pd.productid, d.documentid, pd.documentnode, pd.modifieddate
FROM production.productdocument1 pd
INNER JOIN production.document d ON d.documentnode = pd.documentnode;

DROP TABLE production.productdocument1;

ALTER TABLE production.document DROP COLUMN documentnode;
ALTER TABLE production.document RENAME COLUMN documentpath TO documentnode;
ALTER TABLE production.productdocument DROP COLUMN documentnode;

-- HumanResources.Employee

--DROP TABLE IF EXISTS humanresources.employee1;

ALTER TABLE humanresources.employee RENAME TO employee1;

CREATE TABLE IF NOT EXISTS humanresources.employee
(
    businessentityid serial NOT NULL,
    nationalidnumber character varying(15) COLLATE pg_catalog."default",
    loginid character varying(256) COLLATE pg_catalog."default",
    organizationpath ltree NOT NULL DEFAULT ((lastval())::text)::ltree,
    organizationnode character varying(255) COLLATE pg_catalog."default",
    organizationlevel smallint,
    jobtitle character varying(50) COLLATE pg_catalog."default",
    birthdate date,
    maritalstatus character varying(1) COLLATE pg_catalog."default",
    gender character varying(1) COLLATE pg_catalog."default",
    hiredate date,
    salariedflag boolean DEFAULT true,
    vacationhours smallint,
    sickleavehours smallint,
    currentflag boolean DEFAULT true,
    rowguid uuid,
    modifieddate timestamp with time zone,
    CONSTRAINT employee_businessentityid_pkey PRIMARY KEY (businessentityid)
)

TABLESPACE pg_default;

CREATE INDEX employee_organizationpath_idx ON humanresources.employee using gist (organizationpath);

INSERT INTO humanresources.employee(nationalidnumber, loginid, organizationnode, organizationlevel, 
	jobtitle, birthdate, maritalstatus, gender, hiredate, salariedflag, vacationhours, sickleavehours, 
	currentflag, rowguid, modifieddate)
SELECT nationalidnumber, loginid, organizationnode, organizationlevel, 
	jobtitle, birthdate, maritalstatus, gender, hiredate, salariedflag, vacationhours, sickleavehours, 
	currentflag, rowguid, modifieddate
FROM humanresources.employee1;	

DROP TABLE humanresources.employee1;

UPDATE humanresources.employee SET organizationnode = '/', organizationlevel = 0
WHERE businessentityid = 1;

WITH nodes AS
(
SELECT e.businessentityid, e.organizationnode,
(
	SELECT STRING_AGG(e2.businessentityid::text, '.')
	FROM (SELECT businessentityid, organizationnode FROM humanresources.employee order by organizationlevel) AS e2
	WHERE e.organizationnode LIKE e2.organizationnode || '%'
) AS node
FROM humanresources.employee e
)

MERGE INTO humanresources.employee AS e
USING nodes AS s 
ON s.businessentityid = e.businessentityid and s.node is not null
WHEN MATCHED THEN UPDATE SET organizationpath = s.node::ltree;

UPDATE humanresources.employee SET organizationlevel = nlevel(organizationpath);
ALTER TABLE humanresources.employee DROP COLUMN organizationnode;
ALTER TABLE humanresources.employee RENAME COLUMN organizationpath TO organizationnode;

