DROP VIEW order_summary;
/********************************************************/

CREATE VIEW order_summary AS
	SELECT DISTINCT
	TO_NUMBER(SUBSTR(o.oref, '3', '3')) AS order_ref,
	o.odate,
	TO_CHAR(TO_DATE(o.odate, 'MM/DD/YYYY'),'MON-YY') AS order_period,
	INITCAP(s.name) AS supplier_name,
	TO_CHAR(SUM(o.total_amount), 'fm99G999G990D00') AS order_total_amount,
	o.status AS order_status,
	i.iref AS invoice_reference,
	TO_CHAR(SUM(i.amount), 'fm99G999G990D00') AS invoice_total_amount,
	DECODE (i.status,
			'Paid', 'OK',
			'Pending', 'To follow up',
			'', 'To verify',
			''
	) AS action
	FROM
	supplier s,
	orders o,
	invoice i
	WHERE 1=1
	AND s.email = o.email
	AND ((TO_NUMBER(SUBSTR(o.oref, '3', '3'))) = (TO_NUMBER(SUBSTR(i.iref, '7', '3'))))
	AND o.status <> 'Cancelled'
	GROUP BY
	s.name,
	i.iref,
	TO_NUMBER(SUBSTR(o.oref, '3', '3')),
	o.odate,
	o.total_amount,
	o.status,
	i.amount,
	TO_NUMBER(SUBSTR(i.iref, '7', '3')),
	i.status
	ORDER BY
	o.odate DESC;

/********************************************************/
SELECT
order_ref,
order_period,
supplier_name,
order_total_amount,
order_status,
invoice_reference,
invoice_total_amount,
action
FROM
order_summary;