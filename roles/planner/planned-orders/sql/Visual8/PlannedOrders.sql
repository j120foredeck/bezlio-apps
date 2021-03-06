--==== Created by Jon Kantola
--==== RobbJack Corporation
--==== 916-645-6045

-- Simple list of planned orders

SELECT pl.PART_ID as PartNo
	, convert(varchar,pl.WANT_DATE,101) as DueDate
	, p.PLANNING_LEADTIME as LTDays
	, p.QTY_IN_DEMAND as ReqQty
	, p.QTY_ON_HAND as QOH
	, p.QTY_ON_ORDER as OnOrder
	, pl.ORDER_QTY as PlanQty
	, pw.SAFETY_STOCK_QTY as Safety
	, cast(cast(pw.MINIMUM_ORDER_QTY as int) as varchar) + '/' + cast(cast(pw.MAXIMUM_ORDER_QTY as int) as varchar) + '/' + cast(cast(pw.MULTIPLE_ORDER_QTY as int) as varchar) as MinMaxMult

FROM PLANNED_ORDER AS pl with(nolock)
	INNER JOIN PART AS p with(nolock) ON p.ID = pl.PART_ID 
	INNER JOIN PART_WAREHOUSE AS pw with(nolock) ON pl.PART_ID = pw.PART_ID AND pl.WAREHOUSE_ID = pw.WAREHOUSE_ID

ORDER BY 2
