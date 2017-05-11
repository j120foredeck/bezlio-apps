

--==== Created by Jon Kantola
--==== RobbJack Corporation
--==== 916-645-6045

-- List of new sales orders, created within last 2 hours


select o.ID as OrdNo
	, l.LINE_NO as Line
	, l.PART_ID as PartNo
	, cast(l.ORDER_QTY as int) as QTY
	, l.USER_1 as OrdStatus
from CUSTOMER_ORDER o with(nolock) inner join CUST_ORDER_LINE l with(nolock) on o.ID = l.CUST_ORDER_ID
where datediff(hh,o.CREATE_DATE,getdate()) < 2