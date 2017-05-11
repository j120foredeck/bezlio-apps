

--==== Created by Jon Kantola
--==== RobbJack Corporation
--==== 916-645-6045

/* This query lists sales reps with a total invoice amount
   for the current 30 day period, the prior 30 days, and
   a percentage change value.
*/

select sr.NAME
	, a.Last30d as Last30d
	, b.Prior30d as Prior30d
	,(a.Last30d - b.Prior30d)/nullif(a.Last30d,0) as PerChange
from SALES_REP sr with(nolock)

	left outer join 
	(select SALESREP_ID, sum(TOTAL_AMOUNT) as Last30d
	 from RECEIVABLE with(nolock)
	 where INVOICE_DATE >= getdate() - 30
	 group by SALESREP_ID
	 ) a on a.SALESREP_ID = sr.ID

	left outer join 
	(select SALESREP_ID, sum(TOTAL_AMOUNT) as Prior30d
	 from RECEIVABLE with(nolock)
	 where INVOICE_DATE between getdate() - 60 and getdate() - 30
	 group by SALESREP_ID
	 ) b on b.SALESREP_ID = sr.ID

order by a.Last30d desc