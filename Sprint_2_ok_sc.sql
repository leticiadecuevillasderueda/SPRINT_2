# NIVEL 1

# Ejercicio 1
-- Se crea la BBDD transaction con las tablas company y transaction a partir del documento sql estructura_dades. 
USE transactions; 

# Ejercicio 2. Utilizando JOINS:
# 2.1 Llistat dels països que estan generant vendes.
SELECT distinct country 
FROM company
JOIN transaction 
ON company.id = transaction.company_id
WHERE declined = 0;

# 2.2 Des de quants països es generen les vendes.
SELECT count(DISTINCT country) AS total_paises 
FROM company
JOIN transaction
ON company.id = transaction.company_id
WHERE declined = 0;

# 2.3 Identifica la companyia amb la mitjana més gran de vendes.
SELECT company_name, avg(amount) AS media_ventas 
FROM company
JOIN transaction 
ON company.id = transaction.company_id
WHERE declined = 0
GROUP BY company_name 
ORDER BY media_ventas DESC
LIMIT 1;

# Ejercicio 3. Utilizando Subquerys:
# 3.1 Mostra totes les transaccions realitzades per empreses d'Alemanya.
SELECT * 
FROM transaction
WHERE company_id IN (SELECT id
		FROM company
        WHERE country = "Germany");
        
# 3.2 Llista les empreses que han realitzat transaccions per un amount superior a la mitjana de totes les transaccions.
SELECT company_name
FROM company
WHERE id IN (SELECT company_id
				FROM transaction
                WHERE amount > (SELECT AVG(amount)
									FROM transaction));

#3.3 Eliminaran del sistema les empreses que no tenen transaccions registrades, entrega el llistat d'aquestes empreses.
SELECT company_name
FROM company
WHERE id NOT IN (SELECT company_id
				FROM transaction); -- No existen empresas sin transacciones registradas.
-- De existir, se eliminarian de la siguiente manera:
SET SQL_SAFE_UPDATES = 0; 
DELETE FROM company
WHERE id NOT IN (SELECT DISTINCT company_id
				FROM transaction); 
SET SQL_SAFE_UPDATES = 1; 

#Ejercicio 4. Creación nueva tabla en la BBDD:
-- Creacion tabla:
CREATE TABLE IF NOT EXISTS credit_card (
	id VARCHAR(45) PRIMARY KEY NOT NULL,
    iban VARCHAR(50),
    pan VARCHAR(50), 
    pin VARCHAR (50),
    cvv VARCHAR (10),
    expiring_date DATE);
-- Se cargan los datos a partir del docuemnto sql facilitado
--  Por falsa suposición, al crear la tabla fije como tipo de dato DATE a la columns expiring_date
-- el formato facilitado en expiring_date no coincide con el formato DATE y no permite subir los datos. 
-- Para solucionarlo:
-- Primero modifico el tipo de dato que es el campo expering_date como VARCHAR y poder subir la informacion a la tabla.
ALTER TABLE credit_card
MODIFY COLUMN expiring_date VARCHAR(10);
-- Se vuelve a realizar carga datos. Compruebo que los datos se han subido:
SELECT *
FROM credit_card;
-- Modifico el formato de la fecha facilitada: 
SET SQL_SAFE_UPDATES = 0; 
UPDATE credit_card 
SET expiring_date = STR_TO_DATE(expiring_date, "%m/%d/%y"); 
SET SQL_SAFE_UPDATES = 1;
-- Por último se modifica el tipo de dato del campo expiring_date de varchar a date.
ALTER TABLE credit_card
MODIFY COLUMN expiring_date DATE;

-- Se establece restriccion Foreign Key para la tabla de hechos:
ALTER TABLE transaction
ADD CONSTRAINT trans_ccfk_2 FOREIGN KEY (credit_card_id) REFERENCES credit_card(id);

#Ejercicio 5. Cambio en el registro de una tarjeta
-- Se visualiza la tarjeta solicitada con información incorrecta para comprobar que es así.
SELECT id, iban
FROM credit_card
WHERE id = "CcU-2938"; 
-- Se actualiza la informacion (se desactiva safe update mode, se realiza el cambio y se vuelve a reactivar):
SET SQL_SAFE_UPDATES = 0;
UPDATE credit_card
SET iban = "TR323456312213576817699999" 
WHERE id = "CcU-2938"; 
SET SQL_SAFE_UPDATES = 1;
-- Visualización cambio
SELECT id, iban
FROM credit_card
WHERE id = "CcU-2938";

#Ejercicio 6. Nueva transacción en la tabla transacciones.
-- Dara error en la restricción FK, al querer subir registros en los campos credit_card_id y company_id que no se encientran en las tablas padres
-- Añadir registro credit_card_id CcU-9999 en la tabla credit_card:
INSERT INTO credit_card (id) VALUES ('CcU-9999');
-- Añadir registro business_id b-9999 en la tabla company:
INSERT INTO company (id) VALUES ('b-9999');
INSERT INTO transaction (id, credit_card_id, company_id, user_id, lat, longitude, timestamp, amount, declined) VALUES ('108B1D1D-5B23-A76C-55EF-C568E49A99DD', 'CcU-9999', 'b-9999', '9999', '829.999', '-117.999', '', '111.11', '0');
-- Da error en subida al no presentar valor en el campo fecha. Se establece fecha a dia de hoy con la funcion NOW()
INSERT INTO transaction (id, credit_card_id, company_id, user_id, lat, longitude, timestamp, amount, declined) VALUES ('108B1D1D-5B23-A76C-55EF-C568E49A99DD', 'CcU-9999', 'b-9999', '9999', '829.999', '-117.999', NOW(), '111.11', '0');

#Ejercicio 7. Eliminación de un campo.
-- Se comprueba existencia del campo "pan" en la tabla credit_card:
SELECT * 
FROM credit_card;
-- Se procede a eliminar campo:
ALTER TABLE credit_card
DROP COLUMN pan;
-- Se comprueba que no existe campo:
SELECT * 
FROM credit_card;

#Ejercicio 8. Crear nueva BBDD, con sus tablas y subir datos de archivos csv.
-- Se crea BBDD nueva:
CREATE DATABASE IF NOT EXISTS ventas_mundiales;
USE ventas_mundiales; 
-- Se crean las nuevas tablas:
-- Primero creo las tablas de dimensiones, junto con la carga de datos y por ultimo la tabla de hechos con las resticciones FK.
-- Para ver si permite la subida de archivos desde carpeta locales, se mira permisos:
SHOW VARIABLES LIKE 'local_infile'; -- No permite subir archivos desde carpetas locales
-- Para saber en que ruta poner los archivos y de donde copiar la ruta de los archivos a subir:
SHOW VARIABLES LIKE 'secure_file_priv';
CREATE TABLE IF NOT EXISTS companias (
	company_id VARCHAR(10) PRIMARY KEY,
	company_name VARCHAR(255),
	phone VARCHAR (255),
	email VARCHAR (255),
	country VARCHAR (45),
	website VARCHAR (255));
LOAD DATA 
INFILE 'C:/ProgramData//MySQL/MySQL Server 8.0/Uploads/SPRINT2_ventas_mundiales/N1.Ex.8__ companies.csv'
INTO TABLE companias
FIELDS TERMINATED BY ","
IGNORE 1 ROWS; 
-- Revisión tabla 
SELECT *
FROM companias;

CREATE TABLE IF NOT EXISTS tarjetas_credito (
	id VARCHAR(45) PRIMARY KEY,
    user_id VARCHAR(45),
    iban VARCHAR (250),
    pan VARCHAR (250),
    pin VARCHAR(45),
    cvv VARCHAR(45),
    track1 VARCHAR (250),
    track2 VARCHAR (250),
    expiring_date DATE);
LOAD DATA INFILE "C:\\ProgramData\\MySQL\\MySQL Server 8.0\\Uploads\\SPRINT2_ventas_mundiales\\N1.Ex.8__ credit_cards.csv"
INTO TABLE tarjetas_credito
FIELDS TERMINATED BY ","
IGNORE 1 ROWS
(id, user_id, iban, pan, pin, cvv, track1, track2, @expiring_date) 
SET expiring_date = STR_TO_DATE(@expiring_date, '%m/%d/%y'); 

CREATE TABLE IF NOT EXISTS usuarios_europeos (
	id VARCHAR(45) PRIMARY KEY,
    name VARCHAR(45),
    surname VARCHAR(45),
    phone VARCHAR(45),
    email VARCHAR(45),
    birth_date DATE, 
    country VARCHAR(45),
    city VARCHAR(45),
    postal_code VARCHAR(45),
    address VARCHAR(200),
    continente VARCHAR(10));-- Se añade campo porque posteriormente se unificará con tabla usuarios_americanos, para distinguir origen.
LOAD DATA 
INFILE "C:\\ProgramData\\MySQL\\MySQL Server 8.0\\Uploads\\SPRINT2_ventas_mundiales\\N1.Ex.8__ european_users.csv"
INTO TABLE usuarios_europeos
FIELDS TERMINATED BY ","
ENCLOSED BY '"' 
IGNORE 1 ROWS
(id, name, surname, phone, email, @birth_date, country, city, postal_code, address)
SET birth_date = STR_TO_DATE(@birth_date, '%b %e, %Y'),  
continente = "europa"; -- Añade informacion al campo creado

CREATE TABLE IF NOT EXISTS usuarios_americanos (
	id VARCHAR(45) PRIMARY KEY,
    name VARCHAR(45),
    surname VARCHAR(45),
    phone VARCHAR(45),
    email VARCHAR(45),
    birth_date DATE, 
    country VARCHAR(45),
    city VARCHAR(45),
    postal_code VARCHAR(45),
    address VARCHAR(200),
    continente VARCHAR(15));-- mismo tabla anterior
LOAD DATA 
INFILE "C:\\ProgramData\\MySQL\\MySQL Server 8.0\\Uploads\\SPRINT2_ventas_mundiales\\N1-Ex.8__ american_users.csv"
INTO TABLE usuarios_americanos
FIELDS TERMINATED BY ","
ENCLOSED BY '"' 
IGNORE 1 ROWS
(id, name, surname, phone, email, @birth_date, country, city, postal_code, address)
SET birth_date = STR_TO_DATE(@birth_date, '%b %e, %Y'),  
continente = "norte_america"; 

-- Nueva tabla que une usuarios_americanos y usuarios_europeos
CREATE TABLE usuarios_globales AS
SELECT *
FROM usuarios_europeos
UNION ALL
SELECT *
FROM usuarios_americanos;
-- se ha de volver a de volver a poner la resticcion de la primary key en le tabla usarios_globales que al unir la tabla se ha perdido.
ALTER TABLE usuarios_globales
ADD PRIMARY KEY (id);
-- Comprobación datos:
SELECT * 
FROM usuarios_globales;
-- Eliminacion tablas usuarios_europeos y usuarios_americanos:
DROP TABLES usuarios_americanos, usuarios_europeos;

CREATE TABLE IF NOT EXISTS transacciones (
	id VARCHAR (255) PRIMARY KEY,
    card_id VARCHAR (10),
	business_id VARCHAR (10),
	timestamp TIMESTAMP,
	amount DECIMAL(10, 2),
	declined BOOLEAN,
	product_ids VARCHAR (50),
	user_id VARCHAR (10),
	lat FLOAT,
	longitud FLOAT, 
	CONSTRAINT comp_fk FOREIGN KEY (business_id) REFERENCES companias(company_id), 
	CONSTRAINT tj_cred_fk FOREIGN KEY (card_id) REFERENCES tarjetas_credito(id), 
	CONSTRAINT us_glb_fk FOREIGN KEY (user_id) REFERENCES usuarios_globales(id));
LOAD DATA 
INFILE "C:\\ProgramData\\MySQL\\MySQL Server 8.0\\Uploads\\SPRINT2_ventas_mundiales\\N1.Ex.8__ transactions.csv"
INTO TABLE transacciones
FIELDS TERMINATED BY ";"
IGNORE 1 ROWS; 
SELECT *
FROM transacciones;


#Ejercicio 9 
-- Realitza una subconsulta que mostri tots els usuaris amb més de 80 transaccions utilitzant almenys 2 taules.
SELECT usuarios_globales.id id, usuarios_globales.name nombre, n_transacciones.total_transacciones total_transacciones
FROM usuarios_globales
JOIN (SELECT transacciones.user_id, count(transacciones.id) as total_transacciones
	FROM transacciones
    WHERE declined = 0
	GROUP BY transacciones.user_id
    HAVING total_transacciones > 80) AS n_transacciones 
ON usuarios_globales.id = n_transacciones.user_id
GROUP BY usuarios_globales.id;

#Ejercicio 10
-- Mostra la mitjana d'amount per IBAN de les targetes de crèdit a la companyia Donec Ltd, utilitza almenys 2 taules
SELECT tarjetas_credito.iban iban, ROUND(AVG(transacciones.amount),2) AS media_importe
FROM tarjetas_credito
JOIN transacciones
ON tarjetas_credito.id = transacciones.card_id
JOIN companias
ON transacciones.business_id = companias.company_id
WHERE companias.company_name = "Donec Ltd" and declined = 0
GROUP BY tarjetas_credito.iban;

# Nivel 2

#Ejercicio 1
-- Identifica els cinc dies que es va generar la quantitat més gran d'ingressos a l'empresa per vendes. 
-- Mostra la data de cada transacció juntament amb el total de les vendes.
-- Se utiliza dos CTE (subconsultas) y una funcion ventana
WITH sumas_ventas AS (SELECT timestamp dates, sum(amount) AS total_ventas 
						FROM transacciones
                        WHERE declined = "0" 
						GROUP BY dates), 
	ranking AS (SELECT dates, total_ventas, DENSE_RANK() OVER(ORDER BY total_ventas DESC) AS prueba 
				FROM sumas_ventas) 
SELECT dates, total_ventas							
FROM ranking  -- Se muestra la consulta solicitada. 
WHERE prueba <= 5 ;

#Ejercicio 2
-- Presenta el nom, telèfon, país, data i amount, d'aquelles empreses que van realitzar transaccions amb un valor comprès entre 350 i 400 euros 
-- i en alguna d'aquestes dates: 29 d'abril del 2015, 20 de juliol del 2018 i 13 de març del 2024. 
-- Ordena els resultats de major a menor quantitat.
SELECT companias.company_name, companias.phone, companias.country, DATE(transacciones.timestamp) fecha, transacciones.amount 
FROM companias 
JOIN transacciones
ON companias.company_id = transacciones.business_id
WHERE (transacciones.amount BETWEEN 350 AND 400) 
	AND (DATE(transacciones.timestamp) in ("2015-04-29", "2018-07-20", "2024-03-13")) 
    AND declined = 0 
ORDER BY transacciones.amount DESC;

#Ejercicio 3
-- Necessitem optimitzar l'assignació dels recursos i dependrà de la capacitat operativa que es requereixi, 
-- per la qual cosa et demanen la informació sobre la quantitat de transaccions que realitzen les empreses,
-- però el departament de recursos humans és exigent i vol un llistat de les empreses on especifiquis si tenen igual o més de 400 transaccions o menys.

SELECT companias.company_name, count(transacciones.id) AS total_transacciones, 
	CASE   
		WHEN count(transacciones.id) >=400 THEN 'SUPERIOR' ELSE 'INFERIOR' END AS categoria  
FROM companias
JOIN transacciones
ON companias.company_id = transacciones.business_id
GROUP BY companias.company_name;

#Ejercicio 4 
-- Elimina de la taula transaction el registre amb ID 000447FE-B650-4DCF-85DE-C7ED0EE1CAAD de la base de dades.
-- Primero se mira si existe registro a eliminar:
SELECT *
FROM transacciones
WHERE id = "000447FE-B650-4DCF-85DE-C7ED0EE1CAAD";
-- Se elimina registro. 
SET SQL_SAFE_UPDATES = 0; 
DELETE FROM transacciones
WHERE id = '000447FE-B650-4DCF-85DE-C7ED0EE1CAAD'; 
SET SQL_SAFE_UPDATES = 1;
-- Se comprueba si registro sigue apareciendo en la tabla:
SELECT *
FROM transacciones
WHERE id = "000447FE-B650-4DCF-85DE-C7ED0EE1CAAD";

#Ejercicio 5
-- Serà necessària que creïs una vista anomenada VistaMarketing que contingui la següent informació: Nom de la companyia. 
-- Telèfon de contacte. País de residència. Mitjana de compra realitzat per cada companyia.
--  Presenta la vista creada, ordenant les dades de major a menor mitjana de compra.
CREATE VIEW VistaMarketing AS -- Se crea la vista. Esta vista se guarda en la BBDD, se podra visulaizar/llamar siempre se quiera.
SELECT companias.company_name, companias.phone, companias.country, ROUND(AVG(transacciones.amount), 2) AS media_compras
FROM companias
JOIN transacciones
ON companias.company_id = transacciones.business_id
WHERE declined = 0
GROUP BY companias.company_name, companias.phone, companias.country;
SELECT * FROM VistaMarketing; -- Se visualiza la vista. 

#NIVEL 3

#Ejercicio 1
-- Crea una nova taula que reflecteixi l'estat de les targetes de crèdit basat en si les tres últimes transaccions han estat declinades 
-- aleshores és inactiu, si almenys una no és rebutjada aleshores és actiu. Partint d’aquesta taula respon:
-- Quantes targetes estan actives?
-- Creo nueva tabla: 
CREATE TABLE estado_tarjetas AS
WITH operaciones_tarjetas AS (SELECT card_id, declined, timestamp dates, ROW_NUMBER() 
													OVER ( PARTITION BY card_id ORDER BY timestamp DESC) AS indice_transacciones
								FROM transacciones), 
	seleccion_fechas AS (SELECT card_id, dates, declined
							FROM operaciones_tarjetas
                            WHERE indice_transacciones <=3), 
	total_declined AS (SELECT card_id, SUM(declined) AS p_estado
						FROM seleccion_fechas
                        GROUP BY card_id) 
SELECT card_id, CASE  
				WHEN p_estado = 3 THEN 'Inactiva' ELSE 'Activa' END AS estado
FROM total_declined;

SELECT count(estado)
FROM estado_tarjetas
WHERE estado = "Activa";

-- RESPUESTA: Hay 4995 tarjetas activas. Es decir que han registrado cobro en una o más de las últimas tres transacciones realizadas con ellas