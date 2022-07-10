DROP PROCEDURE viewOrdersSummary;
------------------------------------------------------------------------------------------------------------
CREATE OR REPLACE PROCEDURE viewOrdersSummary
IS
BEGIN
	DECLARE
	order_ref				orders.oref%TYPE;
	order_date				orders.odate%TYPE;
	order_period			VARCHAR(6);	
	supplier_name			supplier.name%TYPE;
	order_total_amount		VARCHAR(15);
	order_status			orders.status%TYPE;
	invoice_reference		invoice.iref%TYPE;
	invoice_total_amount	VARCHAR(15);
	action					VARCHAR(12);
	
	CURSOR cur
	IS
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
		INTO
		order_ref,
		order_date,
		order_period,
		supplier_name,
		order_total_amount,
		order_status,
		invoice_reference,
		invoice_total_amount,
		action
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
		
	BEGIN
		DBMS_OUTPUT.PUT_LINE('(4) Summary of orders with their corresponding list of distinct invoices and their total amount:- ' || CHR(10));
		
		DBMS_OUTPUT.PUT_LINE('ORDER_REF'
							|| ', ' || 'ORDER_PERIOD'
							|| ', ' || 'SUPPLIER_NAME'
							|| ', ' || 'ORDER_TOTAL_AMOUNT'
							|| ', ' || 'ORDER_STATUS'
							|| ', ' || 'INVOICE_REFERENCE'
							|| ', ' || 'INVOICE_TOTAL_AMOUNT'
							|| ', ' || 'ACTION');

		FOR rec IN cur
		LOOP
			DBMS_OUTPUT.PUT_LINE(rec.order_ref
								|| ', ' || rec.order_period
								|| ', ' || rec.supplier_name
								|| ', ' || rec.order_total_amount
								|| ', ' || rec.order_status
								|| ', ' || rec.invoice_reference
								|| ', ' || rec.invoice_total_amount
								|| ', ' || rec.action);
		END LOOP;
	END;
END viewOrdersSummary;
------------------------------------------------------------------------------------------------------------
BEGIN
viewOrdersSummary;
END;