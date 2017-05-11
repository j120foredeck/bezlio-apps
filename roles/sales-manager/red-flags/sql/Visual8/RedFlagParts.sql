

--==== Created by Jon Kantola
--==== RobbJack Corporation
--==== 916-645-6045

/* This query displays part numbers with average monthly sales
   beyond a set threshold dollar amount, where the average for the
   last three months is either greater than or less than the threshold
   when compared to the prior three months.
   
   The threshold value is company-specific and intended to highlight
   a subset of parts with a change in average sales that needs
   investigation.
*/

Declare @Threshold as Int
Set @Threshold = 2000

--==== Temp table of sales data within the 270 days
select PART_ID, SHIPPED_DATE, SUM(b.SHIPPED_QTY * b.UNIT_PRICE * (1-b.TRADE_DISC_PERCENT/100)) as SHIP_AMT,
	cast(count(distinct a.PACKLIST_ID) as float) as OrderCount, min(b.SHIPPED_QTY) as MinQty, max(b.SHIPPED_QTY) as MaxQty
into #t
from SHIPPER a with(nolock), SHIPPER_LINE b with(nolock), PART c with(nolock), CUST_ORDER_LINE d with(nolock), CUSTOMER_ORDER e with(nolock)
where a.PACKLIST_ID = b.PACKLIST_ID and d.PART_ID = c.ID 
	and (b.CUST_ORDER_ID = d.CUST_ORDER_ID and b.CUST_ORDER_LINE_NO = d.LINE_NO)
	and d.CUST_ORDER_ID = e.ID
	and convert(varchar,a.SHIPPED_DATE,111) >= getdate() - 270
	and b.SHIPPED_QTY > 0
	and d.PART_ID not like '%sludge%' and d.PART_ID not like '%scrap%'
group by PART_ID, SHIPPED_DATE

--==== Consolidate into time buckets
select temp.PART_ID,
	(Select ISNULL(SUM(SHIP_AMT),0)/3 from #t where SHIPPED_DATE between getdate() - 90 and getdate() and PART_ID = temp.PART_ID) as ThreeMonth,
	(Select ISNULL(SUM(SHIP_AMT),0)/6 from #t where SHIPPED_DATE between getdate() - 270 and getdate() - 90 and PART_ID = temp.PART_ID) as PriorSix,
	(
	(Select ISNULL(SUM(SHIP_AMT),0)/3 from #t where SHIPPED_DATE between getdate() - 90 and getdate() and PART_ID = temp.PART_ID) -
	(Select ISNULL(SUM(SHIP_AMT),0)/6 from #t where SHIPPED_DATE between getdate() - 270 and getdate() - 90 and PART_ID = temp.PART_ID)
	) as delta,
	(Select ISNULL(SUM(OrderCount),0)/3 from #t where SHIPPED_DATE between getdate() - 90 and getdate() and PART_ID = temp.PART_ID) as [3mAvgOrdCt],
	(Select ISNULL(Min(MinQty),0) from #t where SHIPPED_DATE between getdate() - 90 and getdate() and PART_ID = temp.PART_ID) as [3mMinQty],
	(Select ISNULL(Max(MaxQty),0) from #t where SHIPPED_DATE between getdate() - 90 and getdate() and PART_ID = temp.PART_ID) as [3mMaxQty],
	(Select ISNULL(SUM(OrderCount),0)/3 from #t where SHIPPED_DATE between getdate() - 270 and getdate() - 90  and PART_ID = temp.PART_ID) as [6mAvgOrdCt],
	(Select ISNULL(Min(MinQty),0) from #t where SHIPPED_DATE between getdate() - 270 and getdate() - 90 and PART_ID = temp.PART_ID) as [6mMinQty],
	(Select ISNULL(Max(MaxQty),0) from #t where SHIPPED_DATE between getdate() - 270 and getdate() - 90  and PART_ID = temp.PART_ID) as [6mMaxQty]
into #t2
from #t temp
where (Select ISNULL(SUM(SHIP_AMT),0)/6 from #t where SHIPPED_DATE between getdate() - 270 and getdate() - 90 and PART_ID = temp.PART_ID) > @Threshold
group by temp.PART_ID
order by 4

--==== Filter the output to the threshold amount
SELECT #t2.PART_ID as PartNo
	,isnull(p.DESCRIPTION,'') as PartDesc
	,#t2.ThreeMonth as m3InvAmt
	,#t2.PriorSix as m6InvAmt
	,(#t2.ThreeMonth - #t2.PriorSix)/#t2.PriorSix as Delta
	,#t2.[3mAvgOrdCt] as m3AvgOPM
	,#t2.[6mAvgOrdCt] as m6AvgOPM
FROM #t2 inner join PART p on #t2.PART_ID = p.ID
where #t2.ThreeMonth - #t2.PriorSix  < @Threshold * -1 OR #t2.ThreeMonth - #t2.PriorSix > @Threshold
order by 5


drop table #t
drop table #t2

