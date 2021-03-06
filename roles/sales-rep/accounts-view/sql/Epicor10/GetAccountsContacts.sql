SELECT
	c.CustID AS ID
	, case when c.PrimPCon = ct.ConNum then 'True' else NULL end as primaryContactPurchase
	, c.CustNum
	, ct.Name AS ContactName
	, ct.EMailAddress
	, ct.ContactTitle
	, ct.PhoneNum
	, ct.ConNum
	,ct.Twitter
	,ct.FaceBook
	,ct.LinkedIn
FROM 
	Erp.CustCnt ct with(nolock)
	
	INNER JOIN Erp.Customer c with(nolock) ON
	c.Company = ct.Company
	AND c.CustNum = ct.CustNum
	
	INNER JOIN Erp.SalesRep sr with(nolock) ON
	sr.Company = c.Company
	AND sr.SalesRepCode = c.SalesRepCode
WHERE
	c.ZIP <> ''
	AND sr.EMailAddress = '{EmailAddress}'
	--AND c.Company = 'YourCompanyID'  -- Set this to a specific company ID if you have more than one