select to_number(substr(odr.order_ref_number,3,length(odr.order_ref_number))) "Order Reference",
to_char(odr.order_date,'MON-YY') "Order Period"
,initcap(sup.supplier_name) "Supplier Name"
,to_char(odr.order_total_amount,'fm999G999G999D00') "Order Total Amount"
,odr.order_status "Order Status"
,ih.invoice_number "Invoice Reference"
,to_char(sum(il.invoice_amount),'fm999G999G999D00') "Invoice Total Amount"
,case  
when (sum(decode(il.INVOICE_STATUS,'Paid','0','Pending','1','-1000'))=0)
then 'OK'
when (sum(decode(il.INVOICE_STATUS,'Paid','0','Pending','1','-1000')) >0)
then 'To follow up'
when (sum(decode(il.INVOICE_STATUS,'Paid','0','Pending','1','-1000')) <0)
then 'To verify'
end "Action"
from XXBCM_ORDER_HEADERS odr
,XXBCM_SUPPLIERS sup
,XXBCM_ORDER_LINES Odrl
,XXBCM_INVOICE_HEADERS ih
,XXBCM_INVOICE_LINES il
where 1=1
and odr.supplier_id = sup.supplier_id
and odr.order_header_id = odrl.order_header_id
and ih.invoice_header_id = il.invoice_header_id
and il.order_line_id = odrl.order_line_id
group by odr.order_ref_number
,to_char(odr.order_date,'MON-YY')
,sup.supplier_name
,to_char(odr.order_total_amount,'fm999G999G999D00')
,odr.order_status
,ih.invoice_number
order by odr.order_ref_number
;