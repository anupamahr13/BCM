CREATE VIEW orderTotalView AS
	SELECT DISTINCT
	s.name,
	s.contact_name,
	s.contact_number_1,
	s.contact_number_2,
	COUNT(s.email) AS total_orders,
	TO_CHAR(SUM(o.total_amount), 'fm99G999G990D00') AS order_total_amount
	FROM
	supplier s,
	orders o
	WHERE 1=1
	AND s.email = o.email
	AND TO_DATE(o.odate, 'MM-DD-YYYY') BETWEEN  TO_DATE('01-01-2017', 'DD-MM-YYYY') AND TO_DATE('31-08-2017', 'DD-MM-YYYY')
	GROUP BY
	s.email,
	s.name,
	s.contact_name,
	s.contact_number_1,
	s.contact_number_2;