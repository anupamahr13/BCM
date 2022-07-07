DROP VIEW third_highest_order;
/********************************************************/

CREATE VIEW third_highest_order AS
	SELECT DISTINCT
	TO_NUMBER(SUBSTR(o.oref, '3', '3')) AS order_ref,
	TO_CHAR(TO_DATE(o.odate, 'MM-DD-YYYY'), 'FMMonth DD, YYYY') AS order_date,
	UPPER(INITCAP(s.name)) AS supplier_name,
	TO_NUMBER(o.total_amount) AS order_total_amount,
	o.status AS order_status,
	LISTAGG(i.iref, ', ') WITHIN GROUP (ORDER BY 	o.total_amount, i.iref) AS invoice_references
	FROM
	supplier s,
	orders o,
	invoice i
	WHERE 1=1
	AND s.email = o.email
	AND ((TO_NUMBER(SUBSTR(o.oref, '3', '3'))) = (TO_NUMBER(SUBSTR(i.iref, '7', '3'))))
	AND o.status <> 'Cancelled'
	GROUP BY
	o.total_amount,
	o.oref,
	o.odate,
	s.name,
	o.status
	ORDER BY
	o.total_amount;

/********************************************************/
SELECT 
	order_ref,
	order_date,
	supplier_name,
	TO_CHAR(order_total_amt, 'fm99G999G990D00') AS order_total_amount,
	order_status,
	invoice_references
FROM
(
  SELECT
	order_ref,
	order_date,
	supplier_name,
	MAX(order_total_amount) AS order_total_amt,
	order_status,
	invoice_references,
		row_number() over (order by order_total_amount desc) as row_num
	FROM third_highest_order
	GROUP BY
	order_ref,
	order_date,
	supplier_name,
	order_total_amount,
	order_status,
	invoice_references
) temp
WHERE row_num = 3