

--==== Created by Jon Kantola
--==== RobbJack Corporation
--==== 916-645-6045

/* This query lists open sales order lines where the
   current quantity in demand exceeds the available
   on hand and on order quantities.

   Add part ID and product code filters as necessary
   to exclude unnecessary items.
*/

SELECT co.ID as OrderID
	, CAST(col.LINE_NO AS varchar) + '-' + CAST(ISNULL(cld.DEL_SCHED_LINE_NO, '') AS varchar) AS Line
	, convert(varchar,co.ORDER_DATE,101) as OrderDate
	, convert(varchar,ISNULL(cld.DESIRED_SHIP_DATE, ISNULL(col.PROMISE_DATE,co.PROMISE_DATE)),101) AS DueDate
	, cus.NAME as Customer
	, col.PART_ID as PartID
    , col.PRODUCT_CODE as ProdCode
	, ISNULL(cld.ORDER_QTY, col.ORDER_QTY) - ISNULL(cld.SHIPPED_QTY,col.TOTAL_SHIPPED_QTY) AS LineBal
	, p.QTY_IN_DEMAND AS TotalDemand	
    , isnull((SELECT SUM(QTY) AS QOH FROM dbo.PART_LOCATION with(nolock) WHERE (PART_ID = col.PART_ID) AND (WAREHOUSE_ID = 'RJC') and (LOCATION_ID <> 'TRANSIT')),0) AS QOH
	, p.QTY_ON_ORDER as SupplyDue
	, p.QTY_IN_DEMAND - (p.QTY_ON_HAND + p.QTY_ON_ORDER) as QtyShort

FROM dbo.CUSTOMER_ORDER co with(nolock)
	INNER JOIN  dbo.CUST_ORDER_LINE col with(nolock) ON co.ID = col.CUST_ORDER_ID
	INNER JOIN dbo.CUSTOMER AS cus with(nolock) ON co.CUSTOMER_ID = cus.ID
	INNER JOIN dbo.PART AS p with(nolock) ON col.PART_ID = p.ID
	LEFT OUTER JOIN (select * from dbo.CUST_LINE_DEL with(nolock) where LINE_STATUS = 'A' and ORDER_QTY > SHIPPED_QTY) AS cld ON col.CUST_ORDER_ID = cld.CUST_ORDER_ID

WHERE (col.LINE_STATUS = 'A')
	AND (co.STATUS IN ('R', 'U')) 
	AND (ISNULL(cld.SHIPPED_QTY, col.TOTAL_SHIPPED_QTY) < ISNULL(cld.ORDER_QTY,col.ORDER_QTY))
	and p.QTY_IN_DEMAND > p.QTY_ON_HAND + p.QTY_ON_ORDER

ORDER BY 4
