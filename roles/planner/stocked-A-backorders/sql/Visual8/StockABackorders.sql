


--==== Created by Jon Kantola
--==== RobbJack Corporation
--==== 916-645-6045

/*
This query generates a list of "A" items with Safety Stock as set in
Part Maintenance, where the quantity on hand is less than total demand.

Typically, A items are the top moving parts that generate the greatest
sales revenue, are cycle counted more frequently to ensure stock
accuracy, and often have safety levels established for planning.

*/

--==== Current Stock A Backorders
select p.ID, p.PRODUCT_CODE, p.QTY_ON_HAND
	, p.QTY_IN_DEMAND, isnull(so.CUST_ORDER_ID, req.WORKORDER_BASE_ID) as NEXT_DEMAND
	, p.QTY_ON_ORDER, wo.BASE_ID as NEXT_WO_DUE, convert(varchar,wo.SCHED_FINISH_DATE,101) as SCHED_FINISH_DATE
from PART p with(nolock)
	inner join PART_WAREHOUSE w with(nolock) on w.PART_ID = p.ID
	left outer join
		(select ROW_NUMBER() OVER(partition by PART_ID order by l.PROMISE_DATE)as ROWID, PART_ID, CUST_ORDER_ID 
			from CUST_ORDER_LINE l with(nolock) inner join CUSTOMER_ORDER c with(nolock) on l.CUST_ORDER_ID = c.ID 
			where ORDER_QTY > TOTAL_SHIPPED_QTY and c.STATUS = 'R' and LINE_STATUS = 'A' 
			) so on so.PART_ID = p.ID and so.ROWID = 1
	left outer join
		(select ROW_NUMBER() OVER(partition by PART_ID order by REQUIRED_DATE )as ROWID, PART_ID, WORKORDER_BASE_ID
			from REQUIREMENT with(nolock)
			where CALC_QTY > ISSUED_QTY and STATUS = 'R'
			) req on req.PART_ID = p.ID and req.ROWID = 1
	left outer join
		(select ROW_NUMBER() OVER(partition by PART_ID order by DESIRED_WANT_DATE)as ROWID, PART_ID, BASE_ID, SCHED_FINISH_DATE 
			from WORK_ORDER with(nolock)
			where DESIRED_QTY > RECEIVED_QTY and STATUS = 'R'
			) wo on wo.PART_ID = p.ID and wo.ROWID = 1

where p.ABC_CODE = 'A'
	and w.SAFETY_STOCK_QTY > 0
	and p.QTY_ON_HAND < p.QTY_IN_DEMAND