select sup.SUPPLIER_NAME "Supplier Name"
,sup.supplier_contact_name "Supplier Contact Name"
,max(case when rn = 1 then regexp_replace(sup.contact_number, '\s+', '') end) "Supplier Contact No. 1"
,max(case when rn = 2 then regexp_replace(sup.contact_number, '\s+', '') end) "Supplier Contact No. 2"
,sum(order_count) "Total Orders"
,to_char(sum(order_total_amt),'fm999G999G999D00') "Order Total Amount"
from 
(
select supp.supplier_name 
,supp.supplier_contact_name 
,count(order_ref_number) Order_count
,decode(length(supp_con.contact_number),7,substr(supp_con.contact_number,1,3)||'-'||substr(supp_con.contact_number,4,7), substr(supp_con.contact_number,1,4)||'-'||substr(supp_con.contact_number,5,8)) contact_number
,sum(order_total_amount) order_total_amt
,row_number() over (partition by supp.supplier_name order by supp_con.contact_number) rn
from XXBCM_ORDER_HEADERS_TBL odr
,XXBCM_SUPPLIERS_TBL supp
,XXBCM_SUPPLIER_CONTACTS_TBL supp_con
where 1=1
and odr.supplier_id = supp.supplier_id
and supp_con.supplier_id = supp.supplier_id
and order_date between '01-JAN-2022' and '31-AUG-2022'
group by supp.supplier_name 
,supp.supplier_contact_name 
,supp_con.contact_number 
)sup
group by sup.SUPPLIER_NAME, sup.SUPPLIER_CONTACT_NAME
order by sup.SUPPLIER_NAME, sup.SUPPLIER_CONTACT_NAME
;