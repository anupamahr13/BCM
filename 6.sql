DROP PROCEDURE viewOrdersTotal;
------------------------------------------------------------------------------------------------------------
CREATE OR REPLACE PROCEDURE viewOrdersTotal
IS
BEGIN
	DECLARE
	name				supplier.name%TYPE;
	contact_name		supplier.contact_name%TYPE;
	contact_number_1	supplier.contact_number_1%TYPE;
	contact_number_2	supplier.contact_number_2%TYPE;
	total_orders		NUMBER;
	order_total_amount	VARCHAR(15);
	CURSOR supplier_cursor
	IS
		SELECT DISTINCT
		s.name,
		s.contact_name,
		s.contact_number_1,
		s.contact_number_2,
		COUNT(s.email) AS total_orders,
		TO_CHAR(SUM(o.total_amount), 'fm99G999G990D00') AS order_total_amount
		INTO
		name,
		contact_name,
		contact_number_1,
		contact_number_2,
		total_orders,
		order_total_amount
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
		
	BEGIN
		DBMS_OUTPUT.PUT_LINE('(6) Number of orders and total amount ordered between 01 January 2017 and 31 August 2017:- ' || CHR(10));
		
		DBMS_OUTPUT.PUT_LINE('NAME'
								|| ', ' || 'CONTACT_NAME'
								|| ', ' || 'CONTACT_NUMBER_1'
								|| ', ' || 'CONTACT_NUMBER_2'
								|| ', ' || 'TOTAL_ORDERS'
								|| ', ' || 'ORDER_TOTAL_AMOUNT');

		FOR supplier_row IN supplier_cursor
		LOOP
			DBMS_OUTPUT.PUT_LINE(supplier_row.name
								|| ', ' || supplier_row.contact_name
								|| ', ' || supplier_row.contact_number_1
								|| ', ' || supplier_row.contact_number_2
								|| ', ' || supplier_row.total_orders
								|| ', ' || supplier_row.order_total_amount);
		END LOOP;
	END;
END viewOrdersTotal;
------------------------------------------------------------------------------------------------------------
BEGIN
viewOrdersTotal;
END;