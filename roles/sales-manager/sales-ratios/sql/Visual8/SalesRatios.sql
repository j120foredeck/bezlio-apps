


--==== Created by Jon Kantola
--==== RobbJack Corporation
--==== 916-645-6045

/* This query creates a trend chart for sales,
   with one month over one month, three over three,
   and twelve over twelve comparatives.  Rather than a moving
   average, this chart is simply a ratio of one value
   to another that indicates degree of growth or decline.
*/

--==== Create a temp table for the sales data
select RowNumber = IDENTITY(INT,1,1), year(SHIPPED_DATE) as OrdYear, month(SHIPPED_DATE) as InvMonth,
	SUM(b.SHIPPED_QTY * b.UNIT_PRICE * (1-b.TRADE_DISC_PERCENT/100)) as OneTotal
into #t
from SHIPPER a with(nolock), SHIPPER_LINE b with(nolock), PART c with(nolock), CUST_ORDER_LINE d with(nolock), CUSTOMER_ORDER e with(nolock)
where a.PACKLIST_ID = b.PACKLIST_ID and d.PART_ID = c.ID 
	and (b.CUST_ORDER_ID = d.CUST_ORDER_ID and b.CUST_ORDER_LINE_NO = d.LINE_NO)
	and d.CUST_ORDER_ID = e.ID
	and a.SHIPPED_DATE BETWEEN getdate() - 365 * 3 and getdate()
group by year(SHIPPED_DATE),month(SHIPPED_DATE)
order by 2,3

--==== Compile the info into comparitive ratios using RowNumber
select nr.RowNumber, nr.OrdYear, nr.InvMonth, nr.OneTotal,
	(SELECT sum(OneTotal) from #t where RowNumber between nr.RowNumber - 3 and nr.RowNumber and nr.RowNumber > 3) as ThreeTotal,
	(SELECT sum(OneTotal) from #t where RowNumber between nr.RowNumber - 12 and nr.RowNumber and nr.RowNumber > 12) as TwelveTotal
into #t2
from #t nr

--==== Data points for one, three, and twelve months compared to same period prior year
select top 12 cast(nr2.InvMonth as varchar(2)) as InvMonth,
	(nr2.OneTotal/(SELECT OneTotal from #t2 where RowNumber = nr2.RowNumber -12))*100 as OneMonth,
	(nr2.ThreeTotal/(SELECT ThreeTotal from #t2 where RowNumber = nr2.RowNumber -12))*100 as ThreeMonths,
	(nr2.TwelveTotal/(SELECT TwelveTotal from #t2 where RowNumber = nr2.RowNumber -12))*100 as TwelveMonths,
	100 as Threshold
from #t2 nr2
where ((nr2.TwelveTotal/(SELECT TwelveTotal from #t2 where RowNumber = nr2.RowNumber -12))*100) is not null
order by OrdYear, nr2.InvMonth

drop table #t
drop table #t2