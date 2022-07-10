/**********************PREREQUISITE STARTS*******************************************/
--drop tables in case they exist
DROP TABLE supplier;
DROP TABLE orders;
DROP TABLE invoice;

DROP PACKAGE bcm_ltd;
DROP PACKAGE BODY bcm_ltd;

DROP TRIGGER bcm_ltd_trigger;
/*****************************************************************/
--create new tables
CREATE TABLE supplier 
(	
	name 				VARCHAR2(40), 
	contact_name 		VARCHAR2(40), 
	address 			VARCHAR2(60), 
	contact_number_1 	VARCHAR2(9), 
	contact_number_2 	VARCHAR2(9), 
	email 				VARCHAR2(35),
	CONSTRAINT supplier_pk PRIMARY KEY (email)
);

CREATE TABLE orders
(	
	email 			VARCHAR2(35) NOT NULL,
	oref 			VARCHAR2(7), 
	odate 			VARCHAR2(10), 
	total_amount 	VARCHAR2(15), 
	descriptions 	VARCHAR2(75), 
	status 			VARCHAR2(9)
);

CREATE TABLE invoice 
(	
	oref 			VARCHAR2(7), 
	iref 			VARCHAR2(11), 
	idate 			VARCHAR2(10), 
	status 			VARCHAR2(9), 
	hold_reason		VARCHAR2(50), 
	amount 			VARCHAR2(15),
	description		VARCHAR2(50)
	--PRIMARY KEY(oref, iref)
	-- iref 			VARCHAR2(35) PK
);
/**********************PREREQUISITE ENDS*******************************************/

CREATE OR REPLACE PACKAGE bcm_ltd AS
	PROCEDURE createSupplier;
	PROCEDURE createOrder;
	PROCEDURE createInvoice;
	PROCEDURE viewOrdersSummary;
	PROCEDURE viewThirdHighestOrder;
	PROCEDURE viewOrdersTotal;
END bcm_ltd;
/**************************************************/

CREATE OR REPLACE PACKAGE BODY bcm_ltd AS
	PROCEDURE createSupplier AS
	BEGIN
		INSERT INTO supplier
		(
			name, 
			contact_name,
			address, 
			contact_number_1,
			contact_number_2,
			email
		)
		SELECT DISTINCT
			supplier_name,
			supp_contact_name,
			REPLACE(REPLACE(supp_address, '- ,', ''), '-,', '') AS supp_address,
			--SPLIT not working
			CASE
				WHEN (LENGTH(REPLACE (SUBSTR(REPLACE (REPLACE (REPLACE (REPLACE (REPLACE (supp_contact_number,'I','1'),'S','5'),'o','0'),'.',''),' ',''),0,8),',',''))) = 7
				THEN REPLACE (SUBSTR(REPLACE (REPLACE (REPLACE (REPLACE (REPLACE (supp_contact_number,'I','1'),'S','5'),'o','0'),'.',''),' ',''),0,3),',','') || '-' || REPLACE (SUBSTR(REPLACE (REPLACE (REPLACE (REPLACE (REPLACE (supp_contact_number,'I','1'),'S','5'),'o','0'),'.',''),' ',''),4,4),',','')
				WHEN (LENGTH(REPLACE (SUBSTR(REPLACE (REPLACE (REPLACE (REPLACE (REPLACE (supp_contact_number,'I','1'),'S','5'),'o','0'),'.',''),' ',''),0,8),',',''))) = 8
				THEN REPLACE (SUBSTR(REPLACE (REPLACE (REPLACE (REPLACE (REPLACE (supp_contact_number,'I','1'),'S','5'),'o','0'),'.',''),' ',''),0,4),',','') || '-' || REPLACE (SUBSTR(REPLACE (REPLACE (REPLACE (REPLACE (REPLACE (supp_contact_number,'I','1'),'S','5'),'o','0'),'.',''),' ',''),5,4),',','')
			END AS supp_contact_num1,	
			NVL(CASE
				WHEN (LENGTH(REPLACE (SUBSTR(REPLACE (REPLACE (REPLACE (REPLACE (REPLACE (supp_contact_number,'I','1'),'S','5'),'o','0'),'.',''),' ',''),9,8),',',''))) = 7
				THEN REPLACE (SUBSTR(REPLACE (REPLACE (REPLACE (REPLACE (REPLACE (supp_contact_number,'I','1'),'S','5'),'o','0'),'.',''),' ',''),9,4),',','') || '-' || REPLACE (SUBSTR(REPLACE (REPLACE (REPLACE (REPLACE (REPLACE (supp_contact_number,'I','1'),'S','5'),'o','0'),'.',''),' ',''),13,4),',','')
				WHEN (LENGTH(REPLACE (SUBSTR(REPLACE (REPLACE (REPLACE (REPLACE (REPLACE (supp_contact_number,'I','1'),'S','5'),'o','0'),'.',''),' ',''),9,8),',',''))) = 8
				THEN REPLACE (SUBSTR(REPLACE (REPLACE (REPLACE (REPLACE (REPLACE (supp_contact_number,'I','1'),'S','5'),'o','0'),'.',''),' ',''),9,4),',','') || '-' || REPLACE (SUBSTR(REPLACE (REPLACE (REPLACE (REPLACE (REPLACE (supp_contact_number,'I','1'),'S','5'),'o','0'),'.',''),' ',''),13,4),',','')
			END,' ') AS supp_contact_num2,
			supp_email
		FROM xxbcm_order_mgt
		ORDER BY supp_email;
		
		DBMS_OUTPUT.PUT_LINE (SQL%ROWCOUNT || ' supplier(s) successfully migrated.');
	END createSupplier;
	
	PROCEDURE createOrder AS
	BEGIN
		INSERT INTO orders
		(
			email,
			oref, 
			odate,
			total_amount, 
			descriptions, 
			status
		)
		SELECT DISTINCT
		supp_email,
		order_ref,
		TO_DATE(order_date, 'DD-MM-YYYY') AS order_date,
		REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(order_total_amount, ',', ''), 'o', '0'), ',', ''), 'S', '5'), ',', ''), 'o', '0'), ',', ''), 'I', '1') AS order_total_amount,
		order_description,
		order_status
		FROM
		xxbcm_order_mgt
		WHERE 1=1
		AND order_ref IS NOT NULL		
		AND order_total_amount IS NOT NULL
		/*AND (DECODE(TRIM(TRANSLATE(REPLACE(order_total_amount, ',',''), '0123456789', ' ')), NULL,
			'valid', 'invalid'
			)) = 'valid'
		AND (DECODE(TRIM(TRANSLATE(REPLACE(order_line_amount, ',',''), '0123456789', ' ')), NULL,
			'valid', 'invalid'
			)) = 'valid'*/
		ORDER BY order_ref;
		
		DBMS_OUTPUT.PUT_LINE (SQL%ROWCOUNT || ' order(s) successfully migrated.');
	END createOrder;
	
	PROCEDURE createInvoice	AS
	BEGIN
		INSERT INTO invoice
		(
			oref, 
			iref, 
			idate, 
			status, 
			hold_reason, 
			amount,
			description
		)
		SELECT DISTINCT
		order_ref,
		invoice_reference, 	 
		TO_DATE(invoice_date, 'DD-MM-YYYY') AS invoice_date,	 
		invoice_status, 		 
		invoice_hold_reason,  
		REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(invoice_amount, ',', ''), 'o', '0'), ',', ''), 'S', '5'), ',', ''), 'o', '0'), ',', ''), 'I', '1') AS invoice_amount,		
		invoice_description
		FROM
		xxbcm_order_mgt
		WHERE invoice_reference IS NOT NULL
		AND invoice_amount IS NOT NULL
		/*AND (DECODE(TRIM(TRANSLATE(REPLACE(invoice_amount, ',',''), '0123456789', ' ')), NULL,
				'valid', 'invalid'
			)) = 'valid'*/
		ORDER BY order_ref;
		
		DBMS_OUTPUT.PUT_LINE (SQL%ROWCOUNT || ' invoice(s) successfully migrated.');
	END createInvoice;
	
	--4: Summary of orders with their corresponding list of distinct invoices and their total amount
	PROCEDURE viewOrdersSummary	IS
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
			DBMS_OUTPUT.PUT_LINE(CHR(10) || '(4) Summary of orders with their corresponding list of distinct invoices and their total amount:- ');
			
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
	
	--5: Third (3rd) highest Order Total Amount
	PROCEDURE viewThirdHighestOrder	IS
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
		
	--6: Number of orders and total amount ordered between 01 January 2017 and 31 August 2017:- '
	PROCEDURE viewOrdersTotal IS
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
			DBMS_OUTPUT.PUT_LINE(CHR(10) || '(6) Number of orders and total amount ordered between 01 January 2017 and 31 August 2017:- ');
			
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
END bcm_ltd;
/********************************************************/
--check for data existence
-- SELECT * FROM XXBCM_ORDER_MGT;
-- SELECT * FROM supplier;
-- SELECT * FROM orders;
-- SELECT * FROM invoice;
/********************************************************/

CREATE OR REPLACE TRIGGER bcm_ltd_trigger
AFTER INSERT ON XXBCM_ORDER_MGT
	--FOR EACH ROW
	BEGIN
	bcm_ltd.createSupplier;
	bcm_ltd.createOrder;
	bcm_ltd.createInvoice;
	END
/********************************************************/
--test Trigger using unique email --not handling error for now
INSERT INTO XXBCM_ORDER_MGT
(
	order_ref, 
	order_date, 
	supplier_name, 
	supp_contact_name, 
	supp_address, 
	supp_contact_number, 
	supp_email, 
	order_total_amount, 
	order_description, 
	order_status, 
	order_line_amount, 
	invoice_reference, 
	invoice_date, 
	invoice_status, 
	invoice_hold_reason, 
	invoice_amount, 
	invoice_description
) 
VALUES 
(
	'PO111', 
	'13-JUL-2022', 
	'ANUPAMA CO. LTD', 
	'Anupama Hurry', 
	'Royal Road Belle Mare, Flacq, Mauritius', 
	'59085178, 4151450', 
	'anu13796@gmail.com', 
	'13,000', 
	'Laptop sipaki', 
	'Closed', 
	NULL, 
	NULL, 
	NULL, 
	NULL, 
	NULL, 
	NULL, 
	NULL
);
/********************************************************/
--execute procedure to generate required reports
BEGIN
bcm_ltd.viewOrdersSummary;
bcm_ltd.viewThirdHighestOrder;
bcm_ltd.viewOrdersTotal;
END
