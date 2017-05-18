

--==== Created by Jon Kantola
--==== RobbJack Corporation
--==== 916-645-6045

/* This query displays customer accounts with average monthly sales
   beyond a set threshold dollar amount, where the average for the
   last three months is either greater than or less than the threshold
   when compared to the prior three months.
   
   The threshold value is company-specific and intended to highlight
   a subset of customers with a change in average sales that needs
   investigation.
*/

Declare @Threshold as Int
Set @Threshold = 2000

--==== Temp table of sales data within the 270 days
select e.CUSTOMER_ID, SHIPPED_DATE, SUM(b.SHIPPED_QTY * b.UNIT_PRICE * (1-b.TRADE_DISC_PERCENT/100)) as SHIP_AMT,
	cast(count(distinct a.PACKLIST_ID) as float) as OrderCount, min(b.SHIPPED_QTY) as MinQty, max(b.SHIPPED_QTY) as MaxQty
into #tc
from SHIPPER a with(nolock), SHIPPER_LINE b with(nolock), CUST_ORDER_LINE d with(nolock), CUSTOMER_ORDER e with(nolock)
where a.PACKLIST_ID = b.PACKLIST_ID
	and (b.CUST_ORDER_ID = d.CUST_ORDER_ID and b.CUST_ORDER_LINE_NO = d.LINE_NO)
	and d.CUST_ORDER_ID = e.ID
	and convert(varchar,a.SHIPPED_DATE,111) >= getdate() - 270
	and b.SHIPPED_QTY > 0
group by e.CUSTOMER_ID, SHIPPED_DATE

--==== Consolidate into time buckets
select temp.CUSTOMER_ID,
	(Select ISNULL(SUM(SHIP_AMT),0)/3 from #tc where SHIPPED_DATE between getdate() - 90 and getdate() and CUSTOMER_ID = temp.CUSTOMER_ID) as ThreeMonth,
	(Select ISNULL(SUM(SHIP_AMT),0)/6 from #tc where SHIPPED_DATE between getdate() - 270 and getdate() - 90 and CUSTOMER_ID = temp.CUSTOMER_ID) as PriorSix,
	(
	(Select ISNULL(SUM(SHIP_AMT),0)/3 from #tc where SHIPPED_DATE between getdate() - 90 and getdate() and CUSTOMER_ID = temp.CUSTOMER_ID) -
	(Select ISNULL(SUM(SHIP_AMT),0)/6 from #tc where SHIPPED_DATE between getdate() - 270 and getdate() - 90 and CUSTOMER_ID = temp.CUSTOMER_ID)
	) as delta,
	(Select ISNULL(SUM(OrderCount),0)/3 from #tc where SHIPPED_DATE between getdate() - 90 and getdate() and CUSTOMER_ID = temp.CUSTOMER_ID) as [3mAvgOrdCt],
	(Select ISNULL(Min(MinQty),0) from #tc where SHIPPED_DATE between getdate() - 90 and getdate() and CUSTOMER_ID = temp.CUSTOMER_ID) as [3mMinQty],
	(Select ISNULL(Max(MaxQty),0) from #tc where SHIPPED_DATE between getdate() - 90 and getdate() and CUSTOMER_ID = temp.CUSTOMER_ID) as [3mMaxQty],
	(Select ISNULL(SUM(OrderCount),0)/3 from #tc where SHIPPED_DATE between getdate() - 270 and getdate() - 90  and CUSTOMER_ID = temp.CUSTOMER_ID) as [6mAvgOrdCt],
	(Select ISNULL(Min(MinQty),0) from #tc where SHIPPED_DATE between getdate() - 270 and getdate() - 90 and CUSTOMER_ID = temp.CUSTOMER_ID) as [6mMinQty],
	(Select ISNULL(Max(MaxQty),0) from #tc where SHIPPED_DATE between getdate() - 270 and getdate() - 90  and CUSTOMER_ID = temp.CUSTOMER_ID) as [6mMaxQty]
into #tc2
from #tc temp
where (Select ISNULL(SUM(SHIP_AMT),0)/6 from #tc where SHIPPED_DATE between getdate() - 270 and getdate() - 90 and CUSTOMER_ID = temp.CUSTOMER_ID) > @Threshold
group by temp.CUSTOMER_ID
order by 4

--==== Filter the output to the threshold amount
SELECT #tc2.CUSTOMER_ID as CustID
	,c.NAME as CustName
	,#tc2.ThreeMonth as m3InvAmt
	,#tc2.PriorSix as m6InvAmt
	,(#tc2.ThreeMonth - #tc2.PriorSix)/#tc2.PriorSix as Delta
	,#tc2.[3mAvgOrdCt] as m3AvgOPM
	,#tc2.[6mAvgOrdCt] as m6AvgOPM
FROM #tc2 inner join CUSTOMER c on #tc2.CUSTOMER_ID = c.ID
where (#tc2.ThreeMonth - #tc2.PriorSix  < @Threshold * -1 OR #tc2.ThreeMonth - #tc2.PriorSix > @Threshold)
	and c.NAME not like '%*USE%'
	and c.ID <> 'C2074'
order by 5


drop table #tc
drop table #tc2


