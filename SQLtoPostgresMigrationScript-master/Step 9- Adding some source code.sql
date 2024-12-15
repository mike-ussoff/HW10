CREATE OR REPLACE FUNCTION dbo.uspgetbillofmaterials (
    IN startproductid int,
    IN checkdate timestamptz)
RETURNS TABLE (
productassemblyid int, 
componentid int, 
componentdesc varchar(50), 
totalquantity numeric(8,2), 
standardcost numeric(18,2), 
listprice numeric(18,2), 
bomlevel smallint, 
recursionlevel int
)
AS $$
BEGIN
	RETURN QUERY
    WITH RECURSIVE bom_cte(productassemblyid, componentid, componentdesc, perassemblyqty, standardcost, listprice, bomlevel, recursionlevel)
    AS (
        SELECT b.productassemblyid, b.componentid, p.name, b.perassemblyqty, p.standardcost, p.listprice, b.bomlevel, 0 
		FROM production.billofmaterials b
            INNER JOIN production.product p 
            ON b.componentid = p.productid 
        WHERE b.productassemblyid = startproductid 
            AND checkdate >= b.startdate 
            AND checkdate <= COALESCE(b.enddate, checkdate)
        UNION ALL
        SELECT b.productassemblyid, b.componentid, p.name, b.perassemblyqty, p.standardcost, p.listprice, b.bomlevel, cte.recursionlevel + 1 
        FROM bom_cte cte
            INNER JOIN production.billofmaterials b 
            ON b.productassemblyid = cte.componentid
            INNER JOIN production.product p 
            ON b.componentid = p.productid 
        WHERE checkdate >= b.startdate AND checkdate <= COALESCE(b.enddate, checkdate)
        )

	SELECT b.productassemblyid, b.componentid, b.componentdesc, sum(b.perassemblyqty) as totalquantity , b.standardcost, b.listprice, b.bomlevel, b.recursionlevel
    FROM bom_cte b
    GROUP BY b.componentid, b.componentdesc, b.productassemblyid, b.bomlevel, b.recursionlevel, b.standardcost, b.listprice
    ORDER BY b.bomlevel, b.productassemblyid, b.componentid;

END;
$$
LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION humanresources.fn_demployee()
RETURNS TRIGGER AS
$$
BEGIN
	RAISE EXCEPTION 'Employees cannot be deleted. They can only be marked as not current.';
	RETURN NULL;
END
$$
LANGUAGE plpgsql;

CREATE OR REPLACE TRIGGER demployee
BEFORE DELETE
ON humanresources.employee
FOR EACH ROW
EXECUTE FUNCTION humanresources.fn_demployee();

CREATE OR REPLACE VIEW sales.vsalesperson
AS SELECT s.businessentityid,
    p.title,
    p.firstname,
    p.middlename,
    p.lastname,
    p.suffix,
    e.jobtitle,
    pp.phonenumber,
    pnt.name AS phonenumbertype,
    ea.emailaddress,
    p.emailpromotion,
    a.addressline1,
    a.addressline2,
    a.city,
    sp.name AS province,
    a.postalcode,
    cr.name AS countryregion,
    st.name AS territory,
    st.grouping AS territorygroup,
    s.salesquota,
    s.salesytd,
    s.saleslastyear
   FROM sales.salesperson s
     JOIN humanresources.employee e ON e.businessentityid = s.businessentityid
     JOIN person.person p ON p.businessentityid = s.businessentityid
     JOIN person.businessentityaddress bea ON bea.businessentityid = s.businessentityid
     JOIN person.address a ON a.addressid = bea.addressid
     JOIN person.stateprovince sp ON sp.stateprovinceid = a.stateprovinceid
     JOIN person.countryregion cr ON cr.countryregioncode::text = sp.countryregioncode::text
     LEFT JOIN sales.salesterritory st ON st.territoryid = s.territoryid
     LEFT JOIN person.emailaddress ea ON ea.businessentityid = p.businessentityid
     LEFT JOIN person.personphone pp ON pp.businessentityid = p.businessentityid
     LEFT JOIN person.phonenumbertype pnt ON pnt.phonenumbertypeid = pp.phonenumbertypeid;

CREATE OR REPLACE VIEW sales.vindividualcustomer 
AS 
SELECT 
    p.businessentityid
    ,p.title
    ,p.firstname
    ,p.middlename
    ,p.lastname
    ,p.suffix
    ,pp.phonenumber
	,pnt.name AS phonenumbertype
    ,ea.emailaddress
    ,p.emailpromotion
    ,at.name AS addresstype
    ,a.addressline1
    ,a.addressline2
    ,a.city
    ,sp.name AS stateprovincename
    ,a.postalcode
    ,cr.name AS countryregionname
    ,p.demographics
FROM person.person p
    INNER JOIN person.businessentityaddress bea 
    ON bea.businessentityid = p.businessentityid 
    INNER JOIN person.address a 
    ON a.addressid = bea.addressid
    INNER JOIN person.stateprovince sp 
    ON sp.stateprovinceid = a.stateprovinceid
    INNER JOIN person.countryregion cr 
    ON cr.countryregioncode = sp.countryregioncode
    INNER JOIN person.addresstype at 
    ON at.addresstypeid = bea.addresstypeid
    INNER JOIN sales.customer c
    ON c.personid = p.businessentityid
    LEFT OUTER JOIN person.emailaddress ea
    ON ea.businessentityid = p.businessentityid
    LEFT OUTER JOIN person.personphone pp
    ON pp.businessentityid = p.businessentityid
    LEFT OUTER JOIN person.phonenumbertype pnt
    ON pnt.phonenumbertypeid = pp.phonenumbertypeid
WHERE c.storeid IS NULL;

CREATE OR REPLACE VIEW sales.vstorewithcontacts AS 
SELECT 
    s.businessEntityID 
    ,s.name 
    ,ct.name AS ContactType 
    ,p.title 
    ,p.firstname 
    ,p.middlename 
    ,p.lastname 
    ,p.suffix 
    ,pp.phonenumber 
    ,pnt.name AS phonenumbertype
    ,ea.emailaddress 
    ,p.emailpromotion 
FROM sales.store s
    INNER JOIN person.businessentitycontact bec 
    ON bec.businessentityid = s.businessentityid
    INNER JOIN person.contacttype ct
    ON ct.contacttypeid = bec.contacttypeid
    INNER JOIN person.person p
    ON p.businessentityid = bec.personid
    LEFT OUTER JOIN person.emailaddress ea
    ON ea.businessentityid = p.businessentityid
    LEFT OUTER JOIN person.personphone pp
    ON pp.businessentityid = p.businessentityid
    LEFT OUTER JOIN person.phonenumbertype pnt
    ON pnt.phonenumbertypeid = pp.phonenumbertypeid;

