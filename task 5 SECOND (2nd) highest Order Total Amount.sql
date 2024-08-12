select a.order_num "Order Reference"
,a.order_date "Order Date"
,a.order_supp "Supplier Name"
,a.order_total "Order Total Amount"
,a.order_status "Order Status"
,listagg(a.invoice_reference,'|')within group(order by a.order_num)as "Invoice References"
from 
(select distinct to_number(substr(odr.order_ref_number,3,length(odr.order_ref_number))) Order_num
,to_char(odr.order_date,'MONTH DD,YYYY') Order_date
,upper(sup.supplier_name) order_supp
,to_char(odr.order_total_amount,'fm999G999G999D00') order_total
,odr.order_status
,il.invoice_reference
,dense_rank() over(order by odr.order_total_amount desc) r
from XXBCM_ORDER_HEADERS odr
,XXBCM_SUPPLIERS sup
,XXBCM_ORDER_LINES odrl
,XXBCM_INVOICE_HEADERS ih
,XXBCM_INVOICE_LINES il
where 1=1
and odr.supplier_id = sup.supplier_id
and odr.order_header_id = odrl.order_header_id
and ih.invoice_header_id = il.invoice_header_id
and il.order_line_id = odrl.order_line_id
order by il.invoice_reference
) a
where r = 2
group by a.order_num
,a.order_date
,a.order_supp
,a.order_total
,a.order_status
;