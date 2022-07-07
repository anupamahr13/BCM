DROP TABLE supplier;
DROP TABLE orders;
DROP TABLE invoice;

CREATE TABLE supplier 
(	
	name 				VARCHAR2(40), 
	contact_name 		VARCHAR2(40), 
	address 			VARCHAR2(60), 
	contact_number_1 	VARCHAR2(9), 
	contact_number_2 	VARCHAR2(9), 
	email 				VARCHAR2(35) UNIQUE
	-- email 				VARCHAR2(35) PK
);

CREATE TABLE orders
(	
	email 			VARCHAR2(35) NOT NULL,
	oref 			VARCHAR2(7) NOT NULL, 
	odate 			VARCHAR2(10), 
	total_amount 	VARCHAR2(15), 
	descriptions 	VARCHAR2(75), 
	status 			VARCHAR2(9)
	-- oref 			VARCHAR2(7) PK	
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

/*******************************************/
CREATE OR REPLACE PACKAGE bcm_ltd
IS
	PROCEDURE createSupplier;
	PROCEDURE createOrder;
	PROCEDURE createInvoice;
	PROCEDURE get_order_summary;
END bcm_ltd;

/**************************************************/
CREATE OR REPLACE PACKAGE BODY bcm_Ltd AS
		PROCEDURE createSupplier
		AS
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
			
			DBMS_OUTPUT.PUT_LINE (SQL%ROWCOUNT || ' supplier(s) successfully created.');
	END createSupplier;
		
		
		PROCEDURE createOrder
		AS
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
				
				DBMS_OUTPUT.PUT_LINE (SQL%ROWCOUNT || ' order(s) successfully created.');
		END createOrder;
		
		PROCEDURE createInvoice
		AS
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
			
			DBMS_OUTPUT.PUT_LINE (SQL%ROWCOUNT || ' invoice(s) successfully created.');
		END createInvoice;
		
		--
		PROCEDURE get_order_summary 
		IS
			name VARCHAR,
			contact_name VARCHAR,
			contact_number_1 VARCHAR,
			contact_number_2 VARCHAR,
			total_orders VARCHAR,
			order_total_amount VARCHAR;
		BEGIN
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
			
			DBMS_OUTPUT.PUT_LLNE('name: '|| name || ','
					'contact_name: '|| contact_name ','
					'contact_number_1: '|| contact_number_1 ','
					'contact_number_2: '|| contact_number_2 ','
					'total_orders: '|| total_orders ','
					'order_total_amount: '|| order_total_amount
			);
		END;
		
		
END bcm_Ltd;




/********************************************************/
CREATE OR REPLACE TRIGGER BCM_LTD_Trigger
  AFTER INSERT OR UPDATE OR DELETE ON XXBCM_ORDER_MGT
  FOR EACH ROW
BEGIN
	bcm_Ltd.createSupplier;
	bcm_Ltd.createOrder;
	bcm_Ltd.createInvoice;
END;



