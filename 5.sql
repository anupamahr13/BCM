DROP PROCEDURE viewThirdHighestOrder;
------------------------------------------------------------------------------------------------------------
CREATE OR REPLACE PROCEDURE viewThirdHighestOrder
IS
BEGIN
	DECLARE
	CURSOR highestOrderCursor
	IS 
		SELECT * FROM 
		(
			SELECT DISTINCT
			TO_NUMBER(SUBSTR(o.oref, '3', '3')) AS order_ref,
			TO_CHAR(TO_DATE(o.odate, 'MM-DD-YYYY'), 'FMMonth DD, YYYY') AS order_date,
			UPPER(s.name) AS supplier_name,
			TO_NUMBER(o.total_amount) AS order_total_amt,
			TO_CHAR(MAX(TO_NUMBER(o.total_amount)), 'fm99G999G990D00') AS order_total_amount,
			o.status AS order_status,
			LISTAGG(i.iref, ', ') WITHIN GROUP (ORDER BY o.total_amount, i.iref) AS invoice_references,
			RANK() OVER (ORDER BY TO_NUMBER(o.total_amount) DESC) AS row_rank
			FROM
			supplier s,
			orders o,
			invoice i
			WHERE 1=1
			AND s.email = o.email
			AND ((TO_NUMBER(SUBSTR(o.oref, '3', '3'))) = (TO_NUMBER(SUBSTR(i.iref, '7', '3'))))
			AND o.status <> 'Cancelled'
			GROUP BY
			TO_NUMBER(o.total_amount),
			o.oref,
			o.odate,
			s.name,
			o.status
			ORDER BY
			TO_NUMBER(o.total_amount) DESC
		) t
		WHERE row_rank = 3;
		
	orderRow highestOrderCursor%ROWTYPE;

	BEGIN
		DBMS_OUTPUT.PUT_LINE(CHR(10) || '(5) Third (3rd) highest Order Total Amount:- ');
		
		DBMS_OUTPUT.PUT_LINE('ORDER_REFERENCE'
								|| ', ' || 'ORDER_DATE'
								|| ', ' || 'SUPPLIER_NAME'
								|| ', ' || 'ORDER_TOTAL_AMOUNT'
								|| ', ' || 'ORDER_STATUS'
								|| ', ' || 'INVOICE_REFERENCES');

		FOR rec IN highestOrderCursor
		LOOP
			DBMS_OUTPUT.PUT_LINE(rec.order_ref
								|| ', ' || rec.order_date
								|| ', ' || rec.supplier_name
								|| ', ' || rec.order_total_amount
								|| ', ' || rec.order_status
								|| ', ' || rec.invoice_references);
		END LOOP;
	END;
END viewThirdHighestOrder;
------------------------------------------------------------------------------------------------------------
BEGIN
viewThirdHighestOrder;
END;