SET NAMES latin1;
SET FOREIGN_KEY_CHECKS = 1;

BEGIN;
DROP DATABASE IF EXISTS `Ristorante`;
CREATE DATABASE `Ristorante`; 
COMMIT;

USE `Ristorante`;

/*
 * ###############################################################################################
 * AREA MAGAZZINO
 */

-- TABELLA INGREDIENTE
DROP TABLE IF EXISTS `INGREDIENTE`;
CREATE TABLE `INGREDIENTE` (
  `Nome` char(50) NOT NULL,
  `Provenienza` char(50) NOT NULL,
  `Produzione` char(50) NOT NULL,
  `Genere` char(50) NOT NULL,
  `Allergene` boolean NOT NULL DEFAULT 0,
  PRIMARY KEY (`Nome`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

-- Controllo tipo di produzione (INGREDIENTE)
DELIMITER //
DROP TRIGGER IF EXISTS check_produzione_input;
CREATE TRIGGER check_produzione_input BEFORE INSERT ON INGREDIENTE
FOR EACH ROW 
	BEGIN
	
	IF (NEW.Produzione <> "Industriale") AND (NEW.Produzione <> "Intensiva") AND (NEW.Produzione <> "Biologica") THEN
		SIGNAL SQLSTATE '45000'
		SET MESSAGE_TEXT = "Inserito valore produzione non consentito!";
	END IF;
	
	IF (NEW.Genere <> "Carne" AND NEW.Genere <> "Pesce" AND NEW.Genere <> "Verdura"
		AND NEW.Genere <> "Acqua" AND NEW.Genere <> "Formaggio" AND NEW.Genere <> "Pasta" AND NEW.Genere <> "Spezia"
		AND NEW.Genere <> "Pane" AND NEW.Genere <> "Olio") THEN
		SIGNAL SQLSTATE '45000'
		SET MESSAGE_TEXT = "Inserito valore genere non consentito!";
	END IF;  
	
	END //
DELIMITER ;

DELIMITER //
DROP TRIGGER IF EXISTS check_produzione_modifica;
CREATE TRIGGER check_produzione_modifica BEFORE UPDATE ON INGREDIENTE
FOR EACH ROW 
	BEGIN 
	
	
	IF (NEW.Produzione <> "Industriale") AND (NEW.Produzione <> "Intensiva") AND (NEW.Produzione <> "Biologica") THEN
		SIGNAL SQLSTATE '45000'
		SET MESSAGE_TEXT = "Inserito valore produzione non consentito!";
	END IF;
	
	IF (NEW.Genere <> "Carne" AND NEW.Produzione <> "Pesce" AND NEW.Produzione <> "Verdura"
		AND NEW.Produzione <> "Acqua" AND NEW.Produzione <> "Formaggio" AND NEW.Produzione <> "Pasta" AND NEW.Genere <> "Spezia" 
		AND NEW.Genere <> "Pane" AND NEW.Genere <> "Olio") THEN
		SIGNAL SQLSTATE '45000'
		SET MESSAGE_TEXT = "Inserito valore genere non consentito!";
	END IF;
	
	END //
DELIMITER ;

BEGIN;
INSERT INTO `INGREDIENTE` VALUES 
	('Pomodoro','Italia','Intensiva','Verdura','1'),
	('Fettina di manzo','Italia','Intensiva','Carne','1'),
	('Spaghetti','Italia','Industriale','Pasta','0'),
	('Rigatoni','Italia','Industriale','Pasta','0'),
	('Fagioli','Italia','Biologica','Verdura','0'),
	('Merluzzo','Italia','Intensiva','Pesce','1'),
	('Peporoncino','Italia','Biologica','Verdura','1'),
	('Fave','Italia','Biologica','Verdura','0'),
	('Vitello','Italia','Intensiva','Carne','1'),
	('Mozzarella','Italia','Industriale','Formaggio','1'),
	('Acqua','Italia','Industriale','Acqua','0'),
	('Passata','Italia','Industriale','Verdura','1'),
	('Pesto','Italia','Industriale','Verdura','1'),
	('Parmigiano','Italia','Industriale','Formaggio','1'),
	('Pecorino','Italia','Industriale','Formaggio','1'),
	('Basilico','Italia','Industriale','Spezia','1'),
	('Sale','Italia','Industriale','Spezia','1'),
	('Olio','Italia','Industriale','Olio','1'),
	('Pane','Italia','Industriale','Pane','1'),
	('Zucchero','Italia','Industriale','Spezia','1'),
	('Macinato di manzo','Italia','Intensiva','Carne','1');
COMMIT;

-- TABELLA MAGAZZINO
DROP TABLE IF EXISTS `MAGAZZINO`;
CREATE TABLE `MAGAZZINO` (
  `IDMagazzino` char(3) NOT NULL,
  `Citta` char(50) NOT NULL,
  `Via` char(50) NOT NULL,
  `N.C.` char(5) NOT NULL,
  `Telefono` char(10) NOT NULL,
  `Capacita` int(10) NOT NULL,
  PRIMARY KEY (`IDMagazzino`),
  UNIQUE (`Citta`,`Via`,`N.C.`),
  UNIQUE (`Telefono`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

BEGIN;
INSERT INTO `MAGAZZINO` VALUES 
	('MA1','Vasto','Dante Rossetti','10','2874241029','15000'),
	('MB1','Pollutri','Ganfalone','17','0873241029','50000'),
	('MC1','Pisa','Pollino','26','0870271029','50000'),
	('MD1','Livorno','Genovesi','74','2871241020','500'),
	('ME1','Lanciano','Miracoli','20','3570241049','1000'),
	('MF1','Pescara','Martiri','35','1973244629','10000'),
	('MG1','Chieti','S. Marco','24','1870361429','70000'),
	('MH1','Teramo','Tiro a segno','23','1873241029','20000'),
	('MI1','Giulianova','S. Nicola','11','1820241129','5000'),
	('ML1','Termoli','Dei banchieri','120','2270241029','25000');	
COMMIT;

-- TABELLA ORDINE
DROP TABLE IF EXISTS `ORDINE`;
CREATE TABLE `ORDINE` (
  `IDOrdine` int NOT NULL AUTO_INCREMENT,
  `Ingrediente` char(50) NOT NULL,
  `Magazzino` char(3) NOT NULL,
  `DataAcquisto` date,
  `DataArrivo` date,
  `Prezzo` decimal(4,2) NOT NULL,
  `Quantita` int(10) NOT NULL, /* NumeroConfezioni */
  `NettoConfezione` FLOAT NOT NULL,
  PRIMARY KEY (`IDOrdine`),
  FOREIGN KEY (`Magazzino`) REFERENCES MAGAZZINO(IDMagazzino)
	ON DELETE CASCADE
	ON UPDATE CASCADE,
  FOREIGN KEY (`Ingrediente`) REFERENCES INGREDIENTE(Nome)
	ON DELETE NO ACTION
	ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

DELIMITER //
DROP TRIGGER IF EXISTS check_data_acquisto_input;
CREATE TRIGGER check_data_acquisto__input BEFORE INSERT ON ORDINE
FOR EACH ROW 
	BEGIN
	
	IF (NEW.DataAcquisto IS NULL AND NEW.DataArrivo IS NULL) THEN
		SET NEW.DataAcquisto = CURRENT_DATE - INTERVAL 3 DAY;
		SET NEW.DataArrivo = CURRENT_DATE;
	END IF;
	
	IF (NEW.DataAcquisto > NEW.DataArrivo) THEN
		SIGNAL SQLSTATE '45000'
		SET MESSAGE_TEXT = "Dati non coerenti! Data arrivo precede Data acquisto!";
	END IF;
	
	IF (NEW.Quantita = "0") THEN
		SIGNAL SQLSTATE '45000'
		SET MESSAGE_TEXT = "Numero confezioni non consentito!";
	END IF;
	
	IF (NEW.NettoConfezione = "0") THEN
		SIGNAL SQLSTATE '45000'
		SET MESSAGE_TEXT = "Netto confezione non consentito!";
	END IF;
	
	END //
DELIMITER ;

DELIMITER //
DROP TRIGGER IF EXISTS check_data_acquisto_modifica;
CREATE TRIGGER check_data_acquisto__modifica BEFORE UPDATE ON ORDINE
FOR EACH ROW 
	BEGIN 
	
	IF (NEW.DataAcquisto > NEW.DataArrivo) THEN
		SIGNAL SQLSTATE '45000'
		SET MESSAGE_TEXT = "Dati non coerenti! Data arrivo precede Data acquisto!";
	END IF;
	
	IF (NEW.Quantita = "0") THEN
		SIGNAL SQLSTATE '45000'
		SET MESSAGE_TEXT = "Numero confezioni non consentito!";
	END IF;
	
	IF (NEW.NettoConfezione = "0") THEN
		SIGNAL SQLSTATE '45000'
		SET MESSAGE_TEXT = "Netto confezione non consentito!";
	END IF;
	
	END //
DELIMITER ;

BEGIN;
INSERT INTO `ORDINE` (`Ingrediente`, `Magazzino`, `Prezzo`, `Quantita`, `NettoConfezione`) VALUES 
	('Pomodoro','MA1','30.50','5','0.75'),
	('Fettina di manzo','MA1','20.50','3','0.5'),
	('Spaghetti','MA1','10.50','3','0.5'),
	('Rigatoni','MA1','11','10','0.5'),
	('Passata','MA1','15','2','0.75'),
	('Passata','MA1','20','2','0.75'),
	('Mozzarella','MA1','20','3','3'),
	('Merluzzo','MA1','20','3','0.45'),
	('Vitello','MA1','50','3','0.75'),
	('Passata','MA1','30','2','0.75');
COMMIT;

-- TABELLA CONFEZIONE
DROP TABLE IF EXISTS `CONFEZIONE`;
CREATE TABLE `CONFEZIONE` (
  `IDConfezione` int NOT NULL AUTO_INCREMENT,
  `Ordine` int NOT NULL,
  `Locazione` char(1) NOT NULL,
  `Aspetto` char(10) NOT NULL REFERENCES INGREDIENTE(Nome),
  `Stato` char(10) NOT NULL REFERENCES MAGAZZINO(IDMagazzino),
  `Peso` decimal(5,3) NOT NULL,
  `DataScadenza` date NOT NULL,
  `Cod. lotto` char(10) NOT NULL,
  PRIMARY KEY (`IDConfezione`),
  FOREIGN KEY (`Ordine`) REFERENCES ORDINE(IDOrdine)
	ON DELETE NO ACTION
	ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

DELIMITER //
DROP TRIGGER IF EXISTS check_confezione_input;
CREATE TRIGGER check_confezione_input BEFORE INSERT ON CONFEZIONE
FOR EACH ROW 
	BEGIN
	
	IF (NEW.Locazione <> "A" AND NEW.Locazione <> "B" AND NEW.Locazione <> "C" AND NEW.Locazione <> "D" AND NEW.Locazione <> "E" 
		AND NEW.Locazione <> "F" AND NEW.Locazione <> "G" AND NEW.Locazione <> "H" AND NEW.Locazione <> "I" AND NEW.Locazione <> "L" 
		AND NEW.Locazione <> "M" AND NEW.Locazione <> "N" AND NEW.Locazione <> "O" AND NEW.Locazione <> "P" AND 
		NEW.Locazione <> "Q" AND NEW.Locazione <> "R" AND NEW.Locazione <> "S" AND NEW.Locazione <> "T" AND NEW.Locazione <> "U" 
		AND NEW.Locazione <> "V" AND NEW.Locazione <> "Z") THEN
		SIGNAL SQLSTATE '45000'
		SET MESSAGE_TEXT = "Locazione errata!";
	END IF; 
	
	IF (NEW.Aspetto <> "Buono" AND NEW.Aspetto <> "Rovinato") THEN
		SIGNAL SQLSTATE '45000'
		SET MESSAGE_TEXT = "Aspetto confezione non valido!";
	END IF;
	
	IF (NEW.Stato <> "Completa" AND NEW.Stato <> "Parziale" AND NEW.Stato <> "In uso") THEN
		SIGNAL SQLSTATE '45000'
		SET MESSAGE_TEXT = "Stato confezione non corretto!";
	END IF;
	
	END //
DELIMITER ;

DELIMITER //
DROP TRIGGER IF EXISTS check_confezione_modifica;
CREATE TRIGGER check_confezione_modifica BEFORE UPDATE ON CONFEZIONE
FOR EACH ROW 
	BEGIN 
	
	IF (NEW.Locazione <> "A" AND NEW.Locazione <> "B" AND NEW.Locazione <> "C" AND NEW.Locazione <> "D" AND NEW.Locazione <> "E" 
		AND NEW.Locazione <> "F" AND NEW.Locazione <> "G" AND NEW.Locazione <> "H" AND NEW.Locazione <> "I" AND NEW.Locazione <> "L" 
		AND NEW.Locazione <> "M" AND NEW.Locazione <> "N" AND NEW.Locazione <> "O" AND NEW.Locazione <> "P" AND 
		NEW.Locazione <> "Q" AND NEW.Locazione <> "R" AND NEW.Locazione <> "S" AND NEW.Locazione <> "T" AND NEW.Locazione <> "U" 
		AND NEW.Locazione <> "V" AND NEW.Locazione <> "Z") THEN
		SIGNAL SQLSTATE '45000'
		SET MESSAGE_TEXT = "Locazione errata!";
	END IF; 
	
	IF (NEW.Aspetto <> "Buono" AND NEW.Aspetto <> "Rovinato") THEN
		SIGNAL SQLSTATE '45000'
		SET MESSAGE_TEXT = "Aspetto confezione non valido!";
	END IF;
	
	IF (NEW.Stato <> "Completa" AND NEW.Stato <> "Parziale" AND NEW.Stato <> "In uso") THEN
		SIGNAL SQLSTATE '45000'
		SET MESSAGE_TEXT = "Stato confezione non corretto!";
	END IF;
	
	END //
DELIMITER ;

BEGIN;
INSERT INTO `CONFEZIONE` (`Ordine`, `Locazione`, `Aspetto`, `Stato`, `Peso`, `DataScadenza`, `Cod. lotto`) VALUES 
	('1','A','Buono','Completa','0.5','2018-08-10','L1000'),
	('1','A','Buono','Completa','0.5','2018-08-10','L1061'),
	('2','A','Buono','Completa','0.5','2018-08-10','L1002'),
	('3','A','Buono','Completa','0.5','2018-08-10','L1603'),
	('4','A','Buono','Completa','0.5','2018-08-10','L1004'),
	('5','A','Rovinato','Completa','0.5','2018-08-10','L1200'),
	('6','A','Buono','Completa','0.5','2018-08-10','L1210'),
	('7','A','Buono','Completa','0.5','2018-08-10','L1020'),
	('8','A','Rovinato','Completa','0.5','2018-08-10','L1201'),
	('8','A','Buono','Completa','0.5','2018-08-10','L1200');
COMMIT;

-- TABELLA SEDE
DROP TABLE IF EXISTS `SEDE`;
CREATE TABLE `SEDE` (
  `IDSede` char(3) NOT NULL,
  `Citta` char(50) NOT NULL,
  `Via` char(50) NOT NULL,
  `N.C.` char(5) NOT NULL,
  `Telefono` char(10) NOT NULL,
  PRIMARY KEY (`IDSede`),
  UNIQUE (`Citta`,`Via`,`N.C.`),
  UNIQUE (`Telefono`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

BEGIN;
INSERT INTO `SEDE` VALUES 
	('SA1','Casalbordino','Magellano','15','0873921298'),
	('SA2','Vasto','Rossetti','22','0873921299'),
	('SA3','Livorno','Preti','15','0873921296'),
	('SA4','Teramo','Leoni','14','0873921295'),
	('SA5','Pescara','Papa Francesco','12','0873921294'),
	('SA6','Chieti','Alessandrini','20','0873921293'),
	('SA7','Casalbordino','Elefanti','70','0873921292'),
	('SA8','Vasto','Giraffe','20','0873921291'),
	('SA9','Pisa','Paperino','10','0873921290'),
	('SB1','Lucca','Gabriele Martino','10','0873921212');
COMMIT;

-- TABELLA RIFORNIMENTO
DROP TABLE IF EXISTS `RIFORNIMENTO`;
CREATE TABLE `RIFORNIMENTO` (
  `Magazzino` char(3) NOT NULL,
  `Sede` char(3) NOT NULL,
  PRIMARY KEY (Sede, Magazzino),
  FOREIGN KEY (Sede) REFERENCES SEDE(IDSede)
	ON DELETE CASCADE
	ON UPDATE CASCADE,
  FOREIGN KEY (Magazzino) REFERENCES MAGAZZINO(IDMagazzino)
	ON DELETE CASCADE
	ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

BEGIN;
INSERT INTO `RIFORNIMENTO` VALUES 
	('MA1','SA1'),
	('MB1','SA2'),
	('MC1','SA3'),
	('MD1','SA4'),
	('ME1','SA5'),
	('MF1','SA6'),
	('MG1','SA7'),
	('MH1','SA8'),
	('MI1','SA9'),
	('ML1','SB1'),
	('MA1','SA2'),
	('MB1','SA3'),
	('MC1','SA4'),
	('MD1','SA5'),
	('ME1','SA6'),
	('MF1','SA7'),
	('MG1','SA8'),
	('MH1','SA9'),
	('MI1','SB1');
COMMIT;

/*
 * ###############################################################################################
 * AREA COMANDA E MENU'
 */

-- TABELLA FATTURA
DROP TABLE IF EXISTS `FATTURA`;
CREATE TABLE `FATTURA` (
  `IDFattura` int NOT NULL AUTO_INCREMENT,
  `Sede` varchar(50) NOT NULL,
  `Prezzo` decimal(6,2) NOT NULL DEFAULT 0,
  `DataEmissione` timestamp DEFAULT CURRENT_TIMESTAMP,
  `MetodoPagamento` varchar(255) DEFAULT NULL,
  `StatoConto` varchar(255) NOT NULL DEFAULT "Aperto",
  PRIMARY KEY (IDFattura),
  FOREIGN KEY (Sede) REFERENCES SEDE(IDSede)
	ON DELETE NO ACTION
	ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

DELIMITER //
DROP TRIGGER IF EXISTS check_fattura_input;
CREATE TRIGGER check_fattura_input BEFORE INSERT ON FATTURA
FOR EACH ROW 
	BEGIN
	
	IF (NEW.MetodoPagamento IS NOT NULL AND NEW.MetodoPagamento <> "Contanti" AND NEW.MetodoPagamento <> "Carta" AND
		NEW.MetodoPagamento <> "Bancomat") THEN
		SIGNAL SQLSTATE '45000'
		SET MESSAGE_TEXT = "Metodo di pagamento non corretto!";
	END IF; 
	
	IF (NEW.StatoConto <> "Aperto" AND NEW.StatoConto <> "Chiuso") THEN
		SIGNAL SQLSTATE '45000'
		SET MESSAGE_TEXT = "Stato conto non corretto!";
	END IF;
	
	END //
DELIMITER ;

DROP TRIGGER IF EXISTS check_fattura_modifica;
DELIMITER //
CREATE TRIGGER check_fattura_modifica BEFORE UPDATE ON FATTURA
FOR EACH ROW 
	BEGIN 
	
	IF (NEW.MetodoPagamento IS NOT NULL AND NEW.MetodoPagamento <> "Contanti" AND NEW.MetodoPagamento <> "Carta" AND
		NEW.MetodoPagamento <> "Bancomat") THEN
		SIGNAL SQLSTATE '45000'
		SET MESSAGE_TEXT = "Metodo di pagamento non corretto!";
	END IF; 
	
	IF (NEW.StatoConto <> "Aperto" AND NEW.StatoConto <> "Chiuso") THEN
		SIGNAL SQLSTATE '45000'
		SET MESSAGE_TEXT = "Stato conto non corretto!";
	END IF;
	
END //
DELIMITER ;

INSERT INTO `FATTURA` (`Sede`) VALUES 
	("SA1"),
	("SA1"),
	("SA1"),
	("SA1"),
	("SA1"),
	("SA1"),
	("SA1"),
	("SA1"),
	("SA1"),
	("SA1");
COMMIT;

-- TABELLA MENU'
DROP TABLE IF EXISTS `MENU`;
CREATE TABLE `MENU` (
  `IDMenu` varchar(5) NOT NULL,
  PRIMARY KEY (IDMenu)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

INSERT INTO `MENU` VALUES 
	("M01"),
	("M02"),
	("M03"),
	("M04"),
	("M05"),
	("M06"),
	("M07"),
	("M08"),
	("M09"),
	("M10");
COMMIT;

-- TABELLA PIATTO
DROP TABLE IF EXISTS `PIATTO`;
CREATE TABLE `PIATTO` (
  `IDPiatto` varchar(6) NOT NULL,
  `Nome` varchar(500) NOT NULL,
  `Procedimento` varchar(10000) NOT NULL,
  `Prezzo` decimal(6,2) NOT NULL,
  PRIMARY KEY (IDPiatto),
  UNIQUE (Nome)
  /*UNIQUE (Procedimento)  */
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

INSERT INTO `PIATTO` VALUES 
	("PI01","Agnolotti","Gli agnolotti sono uno dei piatti tipici della cucina Piemontese e sono conosciuti ed apprezzati all'estero come in Italia per la","15"),
	("PI02","Anelletti al forno","Gli anelletti al forno sono una preparazione tipicamente siciliana a base di anelletti, un particolare formato di pasta, conditi","18"),
	("PI03","Anello di riso con cuore di mozzarella e gamberi","L'anello di riso con cuore di mozzarella e gamberi è un deliziosa ciambella di riso farcita, dall’aspetto elegante e scenografico","12"),
	("PI04","Arancini di spaghetti","Gli arancini di spaghetti sono una gustosa alternativa ai classici arancini di riso, preparati con spaghetti e un ricco ripieno di","8"),
	("PI05","Bavette ai carciofi e sardine","Le bavette ai carciofi e sardine sono un gustoso primo piatto che unisce i sapori della terra ai profumi del mare! ","8"),
	("PI06","Bavette al pesto","Le bavette al pesto sono un primo piatto che racchiude tutta la bontà del pesto fresco preparato in casa; un classico perfetto per stupire.","13"),
	("PI07","Bavette al pesto, pasta e fagiolini","Le bavette al pesto, fagiolini e patate è una versione antica e arricchita della pasta con pesto, definita pesto ricco (o avvantaggiato). ","15"),
	("PI08","Bavette con polpo e gamberi","Le bavette con polpo e gamberi, sono un primo piatto a base di pesce che racchiude tutti i sapori e i profumi del mare.","12"),
	("PI09","Bigoli agli asparagi, carciofi e pesto di piselli","I bigoli agli asparagi carciofi e pesto di piselli sono un primo piatto che racchiude tutti i sapori delle verdure primaverili. ","16"),
	("PI10","Pasta al sugo","Prendi la pasta, la riscandi, ci metti il sugo e te la mangi.","9");
COMMIT;

-- TABELLA PONY
DROP TABLE IF EXISTS `PONY`;
CREATE TABLE `PONY` (
  `IDPony` varchar(255) NOT NULL,
  `Sede` varchar(50) NOT NULL,
  `StatoPony` varchar(20) NOT NULL,
  `TipoMezzo` varchar(20) NOT NULL,
  PRIMARY KEY (IDPony),
  FOREIGN KEY (Sede) REFERENCES SEDE(IDSede)
	ON DELETE CASCADE
	ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

DELIMITER //
DROP TRIGGER IF EXISTS check_pony_input;
CREATE TRIGGER check_pony_input BEFORE INSERT ON PONY
FOR EACH ROW 
	BEGIN
	
	IF (NEW.StatoPony <> "Libero" AND NEW.StatoPony <> "Occupato") THEN
		SIGNAL SQLSTATE '45000'
		SET MESSAGE_TEXT = "Stato pony non corretto!";
	END IF; 
	
	IF (NEW.TipoMezzo <> "2 ruote" AND NEW.TipoMezzo <> "4 ruote") THEN
		SIGNAL SQLSTATE '45000'
		SET MESSAGE_TEXT = "Stato del tipo di mezzo non corretto!";
	END IF;
	
	END //
DELIMITER ;

DELIMITER //
DROP TRIGGER IF EXISTS check_pony_modifica;
CREATE TRIGGER check_pony_modifica BEFORE UPDATE ON PONY
FOR EACH ROW 
	BEGIN 
	
	IF (NEW.StatoPony <> "Libero" AND NEW.StatoPony <> "Occupato" AND NEW.StatoPony <> "Fantasma") THEN
		SIGNAL SQLSTATE '45000'
		SET MESSAGE_TEXT = "Stato pony non corretto!";
	END IF; 
	
	IF (NEW.TipoMezzo <> "2 ruote" AND NEW.TipoMezzo <> "4 ruote" AND NEW.TipoMezzo <> "Fantasma") THEN
		SIGNAL SQLSTATE '45000'
		SET MESSAGE_TEXT = "Stato del tipo di mezzo non corretto!";
	END IF;
	
	END //
DELIMITER ;

INSERT INTO `PONY` VALUES 
	/*("P00","SA1","Fantasma","Fantasma"),*/
	("P01","SA1","Libero","2 ruote"),
	("P02","SA1","Libero","4 ruote"),
	("P03","SA1","Libero","2 ruote"),
	("P04","SA2","Libero","4 ruote"),
	("P05","SA3","Libero","4 ruote"),
	("P06","SA4","Libero","2 ruote"),
	("P07","SA7","Libero","2 ruote"),
	("P08","SA7","Libero","4 ruote"),
	("P09","SA1","Libero","2 ruote");
COMMIT;

 -- TABELLA ACCOUNT
DROP TABLE IF EXISTS `ACCOUNT`;
CREATE TABLE `ACCOUNT` (
  `IDAccount` int NOT NULL AUTO_INCREMENT,
  `Email` varchar(50) NOT NULL,
  `Citta` varchar(50) NOT NULL,
  `Via` varchar(50) NOT NULL,
  `N.C.` int NOT NULL,
  `Nome` varchar(50) NOT NULL,
  `Cognome` varchar(50) NOT NULL,
  `Telefono` varchar(10) NOT NULL,
  `Sesso` char(1) NOT NULL DEFAULT "M",
  PRIMARY KEY (IDAccount),
  UNIQUE (Email)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

DELIMITER //
DROP TRIGGER IF EXISTS check_account_input;
CREATE TRIGGER check_account_input BEFORE INSERT ON ACCOUNT
FOR EACH ROW 
	BEGIN
	
	IF (NEW.Sesso <> "M" AND NEW.Sesso <> "F") THEN
		SIGNAL SQLSTATE '45000'
		SET MESSAGE_TEXT = "Sesso non corretto!";
	END IF;
	
	END //
DELIMITER ;

DELIMITER //
DROP TRIGGER IF EXISTS check_account_modifica;
CREATE TRIGGER check_account_modifica BEFORE UPDATE ON ACCOUNT
FOR EACH ROW 
	BEGIN 
	
	IF (NEW.Sesso <> "M" AND NEW.Sesso <> "F") THEN
		SIGNAL SQLSTATE '45000'
		SET MESSAGE_TEXT = "Sesso non corretto!";
	END IF;
	
END //
DELIMITER ;

INSERT INTO `ACCOUNT` (`Email`,`Citta`,`Via`,`N.C.`,`Nome`, `Cognome`,`Telefono`,`Sesso`) VALUES 
	("a@live.it","Vasto","Pinco","10","Pippo","Blu","0873902350","M"),
	("b@live.it","Pozzuoli","Pallino","17","Paperina","Gialli","0873902450","F"),
	("c@live.it","Villalfonsina","Martiri","12","Topolino","Verdi","0874902050","M"),
	("d@live.it","Pisa","Don Abbondio","21","Pluto","Bianchi","0823902050","M"),
	("e@live.it","Milano","Diotisalvi","31","Gastone","Verdi","1873902050","M"),
	("f@live.it","Vasto","Diocisalvi","51","Eugenio","Sonio","0873902059","M"),
	("g@live.it","Vasto","Dei Matti","30","Gabriele","Martino","0873342050","M"),
	("i@live.it","Vasto","Fabio Filzi","11","Giuseppe","Sconosciuto","0834902050","M"),
	("l@live.it","Pollutri","Montale","21","Alessio","Felice","0873902440","M"),
	("m@live.it","Scerni","Protettori","12","Peppina","Di Risio","0845902050","F");
COMMIT;

-- TABELLA FATTURA TA
DROP TABLE IF EXISTS `FATTURATA`;
CREATE TABLE `FATTURATA` (
  `IDFatturaTA` int NOT NULL AUTO_INCREMENT,
  `Account` int NULL,
  `Pony` varchar(3) NULL,
  `Sede` varchar(50) NOT NULL,
  `Prezzo` decimal(6,2) NOT NULL DEFAULT 0,
  `Informazioni` varchar(255) DEFAULT NULL,
  `Telefono` varchar(10) NOT NULL,
  `Citta` varchar(50) NOT NULL,
  `Via` varchar(50) NOT NULL,
  `N.C.` varchar(20) NOT NULL,
  `Piano` int(2) DEFAULT 0,
  `DataEmissione` Timestamp NULL,
  `StatoConto` varchar(255) NOT NULL DEFAULT "Aperto",
  `MetodoPagamento` varchar(20) DEFAULT NULL,
  `ConsegnaalPony` varchar(20) DEFAULT NULL,
  `Arrivo` timestamp NULL,
  `Rientro` timestamp NULL,
  PRIMARY KEY (IDFatturata),
  FOREIGN KEY (Account) REFERENCES ACCOUNT(IDAccount)
	ON DELETE NO ACTION
	ON UPDATE CASCADE,
  FOREIGN KEY (Sede) REFERENCES SEDE(IDSede)
	ON DELETE NO ACTION
	ON UPDATE CASCADE,
  FOREIGN KEY (Pony) REFERENCES Pony(IDPony)
	ON DELETE NO ACTION
	ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

DELIMITER //
DROP TRIGGER IF EXISTS check_fatturata_input;
CREATE TRIGGER check_fatturata_input BEFORE INSERT ON FATTURATA
FOR EACH ROW 
	BEGIN
	
	IF (NEW.MetodoPagamento IS NOT NULL AND NEW.MetodoPagamento <> "Contanti" AND NEW.MetodoPagamento <> "Carta" AND
		NEW.MetodoPagamento <> "Bancomat" AND NEW.MetodoPagamento <> "Paypal") THEN
		SIGNAL SQLSTATE '45000'
		SET MESSAGE_TEXT = "Metodo di pagamento non corretto!";
	END IF; 
	
	IF (NEW.StatoConto <> "Aperto" AND NEW.StatoConto <> "Chiuso") THEN
		SIGNAL SQLSTATE '45000'
		SET MESSAGE_TEXT = "Stato conto non corretto!";
	END IF;
	
	IF (NEW.Arrivo > NEW.Rientro) THEN
		SIGNAL SQLSTATE '45000'
		SET MESSAGE_TEXT = "Errore nell'arrivo/rientro pony!";
	END IF;
	
	IF (NEW.ConsegnaalPony > NEW.Arrivo) THEN
		SIGNAL SQLSTATE '45000'
		SET MESSAGE_TEXT = "Errore nella consegna/arrivo pony!";
	END IF;
	
	IF (NEW.DataEmissione > NEW.ConsegnaalPony) THEN
		SIGNAL SQLSTATE '45000'
		SET MESSAGE_TEXT = "Errore nella emissione/consegna al pony!";
	END IF;
	
	IF NEW.DataEmissione IS NULL THEN 
		SET NEW.DataEmissione = CURRENT_TIMESTAMP;
	END IF;
	
	END //
DELIMITER ;

DELIMITER //
DROP TRIGGER IF EXISTS check_fatturata_modifica;
CREATE TRIGGER check_fatturata_modifica BEFORE UPDATE ON FATTURATA
FOR EACH ROW 
	BEGIN 
	
	IF (NEW.MetodoPagamento IS NOT NULL AND NEW.MetodoPagamento <> "Contanti" AND NEW.MetodoPagamento <> "Carta" AND
		NEW.MetodoPagamento <> "Bancomat" AND NEW.MetodoPagamento <> "Paypal") THEN
		SIGNAL SQLSTATE '45000'
		SET MESSAGE_TEXT = "Metodo di pagamento non corretto!";
	END IF; 
	
	IF (NEW.StatoConto <> "Aperto" AND NEW.StatoConto <> "Chiuso") THEN
		SIGNAL SQLSTATE '45000'
		SET MESSAGE_TEXT = "Stato conto non corretto!";
	END IF;
	
	IF (NEW.Arrivo > NEW.Rientro) THEN
		SIGNAL SQLSTATE '45000'
		SET MESSAGE_TEXT = "Errore nell'arrivo/rientro pony!";
	END IF;
	
	IF (NEW.ConsegnaalPony > NEW.Arrivo) THEN
		SIGNAL SQLSTATE '45000'
		SET MESSAGE_TEXT = "Errore nella consegna/arrivo pony!";
	END IF;
	
	IF (NEW.DataEmissione > NEW.ConsegnaalPony) THEN
		SIGNAL SQLSTATE '45000'
		SET MESSAGE_TEXT = "Errore nella emissione/consegna al pony!";
	END IF;
	
	/* Alla ricerca delle comande, dei servizi e dei piatti, per trovare il prezzo da dover sommare e sostituire al conto */
	/* IF (OLD.StatoConto = "Aperto" AND NEW.StatoConto = "Chiuso") THEN
		SET NEW.DataEmissione = CURRENT_TIMESTAMP;
		CALL ContoTAChiuso(NEW.FatturaTA);
		CALL FindPony(NEW.FatturaTA,NEW.Sede);
	END IF; */
	
	END //
DELIMITER ;

INSERT INTO `FATTURATA` (`Pony`,`Sede`,`Prezzo`,`Informazioni`,`Telefono`,`Citta`,`Via`,`N.C.`,`Piano`,`DataEmissione`, `MetodoPagamento`,`ConsegnaalPony`,`Arrivo`,`Rientro`,`StatoConto`)VALUES
	("P01","SA1","90.50","","0873902020","Casalbordino","Magellano","10","4","2015-12-30","Paypal","2015-12-30 20:15:20", "2015-12-30 20:25:20", "2015-12-30 20:35:20","Chiuso"),
	("P01","SA1","11.50","","0873902120","Casalbordino","Magellano","11","0","2015-12-29","Carta","2015-12-29 20:15:20", "2015-12-29 20:25:20", "2015-12-29 20:35:20","Chiuso"),
	("P01","SA1","10.50","","1873902020","Casalbordino","Magellano","11","0","2015-12-28","Carta","2015-12-28 20:15:20", "2015-12-28 20:25:20", "2015-12-28 20:35:20","Chiuso"),
	("P01","SA1","10.50","","2873902021","Casalbordino","Magellano","19","3","2015-12-27","Paypal","2015-12-27 20:15:20", "2015-12-27 20:25:20", "2015-12-27 20:35:20","Chiuso"),
	("P01","SA1","10.50","","0873932020","Casalbordino","Magellano","12","0","2015-12-25","Carta","2015-12-25 20:15:20", "2015-12-25 20:25:20", "2015-12-25 20:35:20","Chiuso"),
	("P01","SA1","13.50","","0873902020","Casalbordino","Magellano","18","0","2015-12-24","Carta","2015-12-24 20:15:20", "2015-12-24 20:25:20", "2015-12-24 20:35:20","Chiuso"),
	("P01","SA1","17.50","","0873902220","Casalbordino","Magellano","17","2","2015-12-23","Carta","2015-12-23 20:15:20", "2015-12-23 20:25:20", "2015-12-23 20:35:20","Chiuso"),
	("P01","SA1","12.50","","3873902020","Casalbordino","Magellano","16","0","2015-12-22","Paypal","2015-12-22 20:15:20", "2015-12-22 20:25:20", "2015-12-22 20:35:20","Chiuso"),
	("P01","SA1","50.50","","0873902020","Casalbordino","Magellano","15","0","2015-12-21","Contanti","2015-12-21 20:15:20", "2015-12-21 20:25:20", "2015-12-21 20:35:20","Chiuso"),
	("P01","SA1","10.50","","0875902020","Casalbordino","Magellano","14","0","2015-12-20","Carta","2015-12-20 20:15:20", "2015-12-20 20:25:20", "2015-12-20 20:35:20","Chiuso"),
	("P01","SA1","11.50","","0873902020","Casalbordino","Magellano","13","0","2015-12-23","Carta","2015-12-23 20:15:20", "2015-12-23 20:25:20", "2015-12-23 20:35:20","Chiuso");		
COMMIT;

-- TABELLA COMPOSIZIONE
DROP TABLE IF EXISTS `COMPOSIZIONE`;
CREATE TABLE `COMPOSIZIONE` (
  `Menu` varchar(255) NOT NULL,
  `Piatto` varchar(4) NOT NULL,
  PRIMARY KEY (Menu,Piatto),
  FOREIGN KEY (Menu) REFERENCES MENU(IDMenu)
	ON DELETE CASCADE
	ON UPDATE CASCADE,
  FOREIGN KEY (Piatto) REFERENCES PIATTO(IDPiatto)
	ON DELETE CASCADE
	ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

INSERT INTO `COMPOSIZIONE` VALUES 
	("M01","PI01"),
	("M01","PI02"),
	("M01","PI03"),
	("M01","PI04"),
	("M01","PI05"),
	("M01","PI06"),
	("M01","PI07"),
	("M01","PI08"),
	("M01","PI10"),
	("M02","PI01");
COMMIT;

-- TABELLA OFFERTA
DROP TABLE IF EXISTS `OFFERTA`;
CREATE TABLE `OFFERTA` (
  `Sede` varchar(50) NOT NULL,
  `Menu` varchar(3) NOT NULL,
  `DataInizio` date NOT NULL,
  `DataScadenza` date DEFAULT NULL,
  PRIMARY KEY (Sede,Menu,DataInizio),
  FOREIGN KEY (Menu) REFERENCES MENU(IDMenu)
	ON DELETE CASCADE
	ON UPDATE CASCADE,
  FOREIGN KEY (Sede) REFERENCES SEDE(IDSede)
	ON DELETE CASCADE
	ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

DELIMITER //
DROP TRIGGER IF EXISTS check_OFFERTA_input;
CREATE TRIGGER check_OFFERTA_input BEFORE INSERT ON OFFERTA
FOR EACH ROW 
	BEGIN
	
	IF (NEW.DataScadenza IS NOT NULL AND NEW.DataInizio > NEW.DataScadenza) THEN
		SIGNAL SQLSTATE '45000'
		SET MESSAGE_TEXT = "Data scadenza non corretta!";
	END IF;
	
	/* SOLO UN MENU' ATTIVO PER OGNI SEDE */
	SET @conta = (SELECT COUNT(*)
				FROM OFFERTA
				WHERE Sede = NEW.Sede AND DataScadenza IS NULL);
	
	IF @conta = 1 AND NEW.DataScadenza IS NULL THEN
		/*SET DataScadenza = CURRENT_DATE
		WHERE Sede = NEW.Sede AND DataScadenza IS NULL;*/
		SIGNAL SQLSTATE '45000'
		SET MESSAGE_TEXT = "Non possono esistere due menu attivi contemporaneamente! Disattivare prima il menu attivo e poi riprovare!";
	END IF;
	
	END //
DELIMITER ;

DELIMITER //
DROP TRIGGER IF EXISTS check_OFFERTA_modifica;
CREATE TRIGGER check_OFFERTA_modifica BEFORE UPDATE ON OFFERTA
FOR EACH ROW 
	BEGIN 
	
	IF (NEW.DataScadenza IS NOT NULL AND NEW.DataInizio > NEW.DataScadenza) THEN
		SIGNAL SQLSTATE '45000'
		SET MESSAGE_TEXT = "Data scadenza non corretta!";
	END IF; 
	
	END //
DELIMITER ;

INSERT INTO `OFFERTA` VALUES 
	("SA1","M01","2015-12-20",NULL),
	("SA2","M01","2015-12-20",NULL),
	("SA3","M01","2015-12-20",NULL),
	("SA4","M01","2015-12-20",NULL),
	("SA5","M01","2015-12-20",NULL),
	("SA6","M01","2015-12-20",NULL),
	("SA7","M01","2015-12-20",NULL),
	("SA8","M01","2015-12-20",NULL),
	("SA9","M01","2015-12-20",NULL),
	("SA1","M02","2013-12-20","2015-12-19");
COMMIT;

-- TABELLA TAVOLO
DROP TABLE IF EXISTS `TAVOLO`;
CREATE TABLE `TAVOLO` (
  `IDTavolo` varchar(10) NOT NULL,
  `Sede` varchar(10) NOT NULL,
  `NumeroPosti` int(3) NOT NULL,
  `StatoTavolo` varchar(15) NOT NULL DEFAULT "Libero",
  PRIMARY KEY (IDTavolo),
  FOREIGN KEY (Sede) REFERENCES SEDE(IDSede)
	ON DELETE CASCADE
	ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

DELIMITER //
DROP TRIGGER IF EXISTS check_tavolo_input;
CREATE TRIGGER check_tavolo_input BEFORE INSERT ON TAVOLO
FOR EACH ROW 
	BEGIN
	
	IF (NEW.StatoTavolo <> "Libero" AND NEW.StatoTavolo <> "Occupato") THEN
		SIGNAL SQLSTATE '45000'
		SET MESSAGE_TEXT = "Stato tavolo non corretto!";
	END IF;
	
	END //
DELIMITER ;

DELIMITER //
DROP TRIGGER IF EXISTS check_tavolo_modifica;
CREATE TRIGGER check_tavolo_modifica BEFORE UPDATE ON TAVOLO
FOR EACH ROW 
	BEGIN 
	
	IF (NEW.StatoTavolo <> "Libero" AND NEW.StatoTavolo <> "Occupato") THEN
		SIGNAL SQLSTATE '45000'
		SET MESSAGE_TEXT = "Stato tavolo non corretto!";
	END IF;
	
	END //
DELIMITER ;

INSERT INTO `TAVOLO` (IDTavolo, Sede, NumeroPosti) VALUES 
	("T01","SA1","3"),
	("T02","SA1","4"),
	("T03","SA1","5"),
	("T04","SA1","6"),
	("T05","SA1","7"),
	("T06","SA1","3"),
	("T07","SA1","2"),
	("T08","SA1","2"),
	("T09","SA2","3"),
	("T10","SA3","3");
COMMIT;

-- TABELLA COMANDA
DROP TABLE IF EXISTS `COMANDA`;
CREATE TABLE `COMANDA` (
  `IDComanda` int NOT NULL AUTO_INCREMENT,
  `Fattura` int NOT NULL,
  `Tavolo` varchar(10) NOT NULL,
  `DataeOra` Timestamp DEFAULT CURRENT_TIMESTAMP,
  `StatoComanda` varchar(20) NOT NULL DEFAULT "Nuova",
  PRIMARY KEY (IDComanda),
  FOREIGN KEY (Fattura) REFERENCES FATTURA(IDFattura)
	ON DELETE CASCADE
	ON UPDATE CASCADE,
  FOREIGN KEY (Tavolo) REFERENCES TAVOLO(IDTavolo)
	ON DELETE CASCADE
	ON UPDATE CASCADE	
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

DELIMITER //
DROP TRIGGER IF EXISTS check_comanda_input;
CREATE TRIGGER check_comanda_input BEFORE INSERT ON COMANDA
FOR EACH ROW 
	BEGIN
	
	IF (NEW.StatoComanda <> "Nuova" AND NEW.StatoComanda <> "In preparazione" AND
		NEW.StatoComanda <> "Parziale" AND NEW.StatoComanda <> "Evasa") THEN
		SIGNAL SQLSTATE '45000'
		SET MESSAGE_TEXT = "Stato comanda non corretto!";
	END IF;
	
	IF NEW.DataeOra IS NULL THEN 
		SET NEW.DataeOra = CURRENT_TIMESTAMP;
	END IF;
	
	END //
DELIMITER ;

DELIMITER //
DROP TRIGGER IF EXISTS check_comanda_modifica;
CREATE TRIGGER check_comanda_modifica BEFORE UPDATE ON COMANDA
FOR EACH ROW 
	BEGIN 
	
	IF (NEW.StatoComanda <> "Nuova" AND NEW.StatoComanda <> "In preparazione" AND
		NEW.StatoComanda <> "Parziale" AND NEW.StatoComanda <> "Evasa") THEN
		SIGNAL SQLSTATE '45000'
		SET MESSAGE_TEXT = "Stato comanda non corretto!";
	END IF;
	
	END //
DELIMITER ;

INSERT INTO `COMANDA` (Fattura,Tavolo) VALUES 
	("1","T01"),
	("2","T01"),
	("3","T01"),
	("4","T01"),
	("5","T01"),
	("6","T01"),
	("7","T01"),
	("8","T01"),
	("9","T01"),
	("10","T01");
COMMIT;

-- TABELLA COMANDA TA
DROP TABLE IF EXISTS `COMANDATA`;
CREATE TABLE `COMANDATA` (
  `IDComandaTA` int NOT NULL AUTO_INCREMENT,
  `FatturaTA` int NOT NULL,
  `DataeOra` Timestamp DEFAULT CURRENT_TIMESTAMP,
  `StatoComanda` varchar(20) NOT NULL DEFAULT "Nuova",
  PRIMARY KEY (IDComandaTA),
  FOREIGN KEY (FatturaTA) REFERENCES FATTURATA(IDFatturaTA)
	ON DELETE CASCADE
	ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

DELIMITER //
DROP TRIGGER IF EXISTS check_comanda_input;
CREATE TRIGGER check_comanda_input BEFORE INSERT ON COMANDA
FOR EACH ROW 
	BEGIN
	
	IF (NEW.StatoComanda <> "Nuova" AND NEW.StatoComanda <> "In preparazione" AND
		NEW.StatoComanda <> "Parziale" AND NEW.StatoComanda <> "Evasa") THEN
		SIGNAL SQLSTATE '45000'
		SET MESSAGE_TEXT = "Stato comanda non corretto!";
	END IF;
	
	IF NEW.DataeOra IS NULL THEN 
		SET NEW.DataeOra = CURRENT_TIMESTAMP;
	END IF;
	
	END //
DELIMITER ;

DELIMITER //
DROP TRIGGER IF EXISTS check_comanda_modifica;
CREATE TRIGGER check_comanda_modifica BEFORE UPDATE ON COMANDA
FOR EACH ROW 
	BEGIN 
	
	IF (NEW.StatoComanda <> "Nuova" AND NEW.StatoComanda <> "In preparazione" AND
		NEW.StatoComanda <> "Parziale" AND NEW.StatoComanda <> "Evasa") THEN
		SIGNAL SQLSTATE '45000'
		SET MESSAGE_TEXT = "Stato comanda non corretto!";
	END IF;
	
	END //
DELIMITER ;

INSERT INTO `COMANDATA` (FatturaTA) VALUES 
	("1"),
	("2"),
	("3"),
	("4"),
	("5"),
	("6"),
	("7"),
	("8"),
	("9"),
	("10");
COMMIT;

-- TABELLA SERVIZIO
DROP TABLE IF EXISTS `SERVIZIO`;
CREATE TABLE `SERVIZIO` (
  `IDServizio` int NOT NULL AUTO_INCREMENT,
  `NomePiatto` varchar(6) NOT NULL,
  `Comanda` int NOT NULL,
  `StatoPiatto` varchar(20) NOT NULL DEFAULT "Attesa",
  `Quantita` int NOT NULL DEFAULT 1,
  PRIMARY KEY (IDServizio),
  FOREIGN KEY (NomePiatto) REFERENCES PIATTO(IDPiatto)
	ON DELETE NO ACTION
	ON UPDATE CASCADE,
  FOREIGN KEY (Comanda) REFERENCES COMANDA(IDComanda)
	ON DELETE NO ACTION
	ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

DELIMITER //
DROP TRIGGER IF EXISTS check_servizio_input;
CREATE TRIGGER check_servizio_input BEFORE INSERT ON SERVIZIO
FOR EACH ROW 
	BEGIN
	
	DECLARE NomeSede VARCHAR(50);
	
	IF (NEW.StatoPiatto <> "Attesa" AND NEW.StatoPiatto <> "In preparazione" AND
		NEW.StatoPiatto <> "Servizio") THEN
		SIGNAL SQLSTATE '45000'
		SET MESSAGE_TEXT = "Stato piatto non corretto!";
	END IF;
	
	SET NomeSede = (
		SELECT Sede
		FROM COMANDA INNER JOIN FATTURA ON IDFattura = Fattura
		WHERE IDComanda = NEW.Comanda
	);
	
	/*CALL ConfezioneCheck(NomeSede,NEW.NomePiatto,NEW.Quantita);*/
	
	END //
DELIMITER ;

DELIMITER //
DROP TRIGGER IF EXISTS check_servizio_modifica;
CREATE TRIGGER check_servizio_modifica BEFORE UPDATE ON SERVIZIO
FOR EACH ROW 
	BEGIN 
	
	IF (NEW.StatoPiatto <> "Attesa" AND NEW.StatoPiatto <> "In preparazione" AND
		NEW.StatoPiatto <> "Servizio") THEN
		SIGNAL SQLSTATE '45000'
		SET MESSAGE_TEXT = "Stato piatto non corretto!";
	END IF;
	
	END //
DELIMITER ;

INSERT INTO `SERVIZIO` (NomePiatto,Comanda,Quantita) VALUES 
	("PI10","1","2"),
	("PI10","2","2"),
	("PI10","3","2"),
	("PI10","4","2"),
	("PI10","5","2"),
	("PI10","6","2"),
	("PI10","7","2"),
	("PI10","8","2"),
	("PI10","9","2"),
	("PI10","10","2");
COMMIT;

-- TABELLA SERVIZIOTA
DROP TABLE IF EXISTS `SERVIZIOTA`;
CREATE TABLE `SERVIZIOTA` (
  `IDServizioTA` int NOT NULL AUTO_INCREMENT,
  `NomePiatto` varchar(6) NOT NULL,
  `ComandaTA` int NOT NULL,
  `StatoPiatto` varchar(20) NOT NULL DEFAULT "Attesa",
  `Quantita` int NOT NULL DEFAULT 1,
  PRIMARY KEY (IDServizioTA),
  FOREIGN KEY (NomePiatto) REFERENCES PIATTO(IDPiatto)
	ON DELETE NO ACTION
	ON UPDATE CASCADE,
  FOREIGN KEY (ComandaTA) REFERENCES COMANDATA(IDComandaTA)
	ON DELETE NO ACTION
	ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

DELIMITER //
DROP TRIGGER IF EXISTS check_serviziota_input;
CREATE TRIGGER check_serviziota_input BEFORE INSERT ON SERVIZIOTA
FOR EACH ROW 
	BEGIN
	
	IF (NEW.StatoPiatto <> "Attesa" AND NEW.StatoPiatto <> "In preparazione" AND
		NEW.StatoPiatto <> "Servizio") THEN
		SIGNAL SQLSTATE '45000'
		SET MESSAGE_TEXT = "Stato piatto non corretto!";
	END IF;
	
	END //
DELIMITER ;

DELIMITER //
DROP TRIGGER IF EXISTS check_serviziota_modifica;
CREATE TRIGGER check_serviziota_modifica BEFORE UPDATE ON SERVIZIOTA
FOR EACH ROW 
	BEGIN 
	
	IF (NEW.StatoPiatto <> "Attesa" AND NEW.StatoPiatto <> "In preparazione" AND
		NEW.StatoPiatto <> "Servizio") THEN
		SIGNAL SQLSTATE '45000'
		SET MESSAGE_TEXT = "Stato piatto non corretto!";
	END IF;
	
	END //
DELIMITER ;

INSERT INTO `SERVIZIOTA` (NomePiatto,ComandaTA,Quantita) VALUES 
	("PI10","1","2"),
	("PI10","2","2"),
	("PI10","3","2"),
	("PI10","4","2"),
	("PI10","5","2"),
	("PI10","6","2"),
	("PI10","7","2"),
	("PI10","8","2"),
	("PI10","9","2"),
	("PI10","10","2");
COMMIT;

/*
 * ###############################################################################################
 * AREA ACCOUNT
 */
 
 -- TABELLA ACCOUNT
/*DROP TABLE IF EXISTS `ACCOUNT`;
CREATE TABLE `ACCOUNT` (
  `IDAccount` int NOT NULL AUTO_INCREMENT,
  `Email` varchar(50) NOT NULL,
  `Citta` varchar(50) NOT NULL,
  `Via` varchar(50) NOT NULL,
  `N.C.` int NOT NULL,
  `Nome` varchar(50) NOT NULL,
  `Cognome` varchar(50) NOT NULL,
  `Telefono` varchar(10) NOT NULL,
  `Sesso` char(1) NOT NULL DEFAULT "M",
  PRIMARY KEY (IDAccount),
  UNIQUE (Email)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

DELIMITER //
DROP TRIGGER IF EXISTS check_account_input;
CREATE TRIGGER check_account_input BEFORE INSERT ON ACCOUNT
FOR EACH ROW 
	BEGIN
	
	IF (NEW.Sesso <> "M" AND NEW.Sesso <> "F") THEN
		SIGNAL SQLSTATE '45000'
		SET MESSAGE_TEXT = "Sesso non corretto!";
	END IF;
	
	END //
DELIMITER ;

DELIMITER //
DROP TRIGGER IF EXISTS check_account_modifica;
CREATE TRIGGER check_account_modifica BEFORE UPDATE ON ACCOUNT
FOR EACH ROW 
	BEGIN 
	
	IF (NEW.Sesso <> "M" AND NEW.Sesso <> "F") THEN
		SIGNAL SQLSTATE '45000'
		SET MESSAGE_TEXT = "Sesso non corretto!";
	END IF;
	
END //
DELIMITER ;

INSERT INTO `ACCOUNT` (`Email`,`Citta`,`Via`,`N.C.`,`Nome`, `Cognome`,`Telefono`,`Sesso`) VALUES 
	("a@live.it","Vasto","Pinco","10","Pippo","Blu","0873902350","M"),
	("b@live.it","Pozzuoli","Pallino","17","Paperina","Gialli","0873902450","F"),
	("c@live.it","Villalfonsina","Martiri","12","Topolino","Verdi","0874902050","M"),
	("d@live.it","Pisa","Don Abbondio","21","Pluto","Bianchi","0823902050","M"),
	("e@live.it","Milano","Diotisalvi","31","Gastone","Verdi","1873902050","M"),
	("f@live.it","Vasto","Diocisalvi","51","Eugenio","Sonio","0873902059","M"),
	("g@live.it","Vasto","Dei Matti","30","Gabriele","Martino","0873342050","M"),
	("i@live.it","Vasto","Fabio Filzi","11","Giuseppe","Sconosciuto","0834902050","M"),
	("l@live.it","Pollutri","Montale","21","Alessio","Felice","0873902440","M"),
	("m@live.it","Scerni","Protettori","12","Peppina","Di Risio","0845902050","F");
COMMIT;*/

-- TABELLA NUOVO PIATTO
DROP TABLE IF EXISTS `NUOVOPIATTO`;
CREATE TABLE `NUOVOPIATTO` (
  `IDNuovoPiatto` int NOT NULL AUTO_INCREMENT,
  `Account` int NOT NULL,
  `Testo` varchar(10000) NOT NULL,
  `Nome` varchar(200) NULL,
  `DataeOra` timestamp NOT NULL,
  `NumeroVoti` int NOT NULL DEFAULT 0,
  `VotoPiatto` int NOT NULL DEFAULT 0,
  PRIMARY KEY (IDNuovoPiatto),
  FOREIGN KEY (Account) REFERENCES ACCOUNT(IDAccount)
	ON DELETE CASCADE
	ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

INSERT INTO `NUOVOPIATTO` (`Account`,`Testo`,`DataeOra`) VALUES 
	("1","BlaBlaBla","2013-10-10"),
	("2","BlaBlaBla","2013-10-11"),
	("3","BlaBlaBla","2013-11-10"),
	("4","BlaBlaBla","2013-12-10"),
	("5","BlaBlaBla","2014-10-10"),
	("6","BlaBlaBla","2014-12-10"),
	("7","BlaBlaBla","2015-10-11"),
	("8","BlaBlaBla","2015-12-10"),
	("9","BlaBlaBla","2015-12-11"),
	("10","BlaBlaBla","2015-12-19");
COMMIT;

-- TABELLA PRENOTAZIONE
DROP TABLE IF EXISTS `PRENOTAZIONE`;
CREATE TABLE `PRENOTAZIONE` (
  `IDPrenotazione` int NOT NULL AUTO_INCREMENT,
  `Account` int NULL,
  `Sede` varchar(10) NOT NULL,
  `StatoPrenotazione` varchar(20) NOT NULL DEFAULT "Attesa",
  `Cognome` varchar(50) NOT NULL,
  `NumeroPersone` int NOT NULL DEFAULT "2",
  `DataeOra` timestamp NOT NULL,
  `Telefono` varchar(10) NOT NULL,
  `Tipo` varchar(20) NULL,
  `Informazioni` varchar(1000) DEFAULT NULL,
  PRIMARY KEY (IDPrenotazione),
  UNIQUE (DataeOra,Telefono),
  FOREIGN KEY (Account) REFERENCES ACCOUNT(IDAccount)
	ON DELETE NO ACTION
	ON UPDATE CASCADE,
  FOREIGN KEY (Sede) REFERENCES SEDE(IDSede)
	ON DELETE CASCADE
	ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

DROP TRIGGER IF EXISTS check_prenotazione_input; 
DELIMITER //
CREATE TRIGGER check_prenotazione_input BEFORE INSERT ON PRENOTAZIONE
FOR EACH ROW 
	BEGIN
	
	IF NEW.Account IS NOT NULL THEN
		SET @e = (
			SELECT COUNT(*)
			FROM PRENOTAZIONE 
			WHERE Account = NEW.Account AND StatoPrenotazione = "Rinuncia"		
		);
		IF @e > 0 THEN
			SIGNAL SQLSTATE '45000'
			SET MESSAGE_TEXT = "Impossibile prenotare!";
		END IF;
	END IF;
    	
	IF NEW.DataeOra IS NULL THEN
		SET NEW.DataeOra = CURRENT_TIMESTAMP + INTERVAL 3 HOUR;
	END IF;
	
	IF (NEW.StatoPrenotazione <> "Attesa" AND NEW.StatoPrenotazione <> "Modificabile" AND NEW.StatoPrenotazione <> "Confermata" 
		AND NEW.StatoPrenotazione <> "Rifiutata" AND NEW.StatoPrenotazione <> "Rinuncia") THEN
		SIGNAL SQLSTATE '45000'
		SET MESSAGE_TEXT = "Stato prenotazione non corretto!";
	END IF;
	
	IF (NEW.Tipo IS NOT NULL AND NEW.Tipo <> "Festa" AND NEW.Tipo <> "Evento") THEN
		SIGNAL SQLSTATE '45000'
		SET MESSAGE_TEXT = "Tipo prenotazione non corretto!";
	END IF;
	
	IF (NEW.Tipo = "Festa" AND NEW.Informazioni IS NULL) THEN
		SIGNAL SQLSTATE '45000'
		SET MESSAGE_TEXT = "Descrizione dell'evento non disponibile!";
	END IF;
	
    /*CALL AssegnaTavolo(NEW.IDPrenotazione,NEW.DataeOra,NEW.Sede,NEW.NumeroPersone);*/
    
	END //
DELIMITER ;

DELIMITER //
DROP TRIGGER IF EXISTS check_prenotazione_modifica;
CREATE TRIGGER check_prenotazione_modifica BEFORE UPDATE ON PRENOTAZIONE
FOR EACH ROW 
	BEGIN 
	
		IF (NEW.StatoPrenotazione <> "Attesa" AND NEW.StatoPrenotazione <> "Modificabile" AND NEW.StatoPrenotazione <> "Confermata" 
		AND NEW.StatoPrenotazione <> "Rifiutata") THEN
		SIGNAL SQLSTATE '45000'
		SET MESSAGE_TEXT = "Stato prenotazione non corretto!";
	END IF;
	
	IF (NEW.Tipo IS NOT NULL AND NEW.Tipo <> "Festa" AND NEW.Tipo <> "Evento") THEN
		SIGNAL SQLSTATE '45000'
		SET MESSAGE_TEXT = "Tipo prenotazione non corretto!";
	END IF;
	
	IF (NEW.Tipo = "Festa" AND NEW.Informazioni IS NULL) THEN
		SIGNAL SQLSTATE '45000'
		SET MESSAGE_TEXT = "Descrizione dell'evento non disponibile!";
	END IF;
	
END //
DELIMITER ;

INSERT INTO `PRENOTAZIONE` (`Account`,`Sede`,`StatoPrenotazione`,`Cognome`,`NumeroPersone`,`DataeOra`,`Telefono`,`Tipo`) VALUES 
	("1","SA1","Confermata","Di Tecco","3","2016-04-30","0873121297","Evento"),
	("2","SA1","Confermata","Di Risio","7","2013-06-30","1873121297",NULL),
	("3","SA1","Confermata","Martino","4","2012-03-30","2873923293","Evento"),
	("4","SA1","Confermata","Celesti","5","2014-01-30","3873922897","Evento"),
	("5","SA1","Confermata","Azzurri","6","2013-08-30","4273971297",NULL),
	("6","SA1","Confermata","Verdi","3","2014-04-30","5873961297","Evento"),
	("7","SA1","Confermata","Fucsi","2","2015-04-30","6873925297",NULL),
	("8","SA1","Confermata","Neri","2","2011-04-30","7345521297",NULL),
	("8","SA1","Confermata","Rossi","3","2011-05-30","8973921217","Evento"),
	("1","SA1","Confermata","Bianchi","3","2011-06-28","9873921297",NULL);
COMMIT;

-- TABELLA POSIZIONE
DROP TABLE IF EXISTS `POSIZIONE`;
CREATE TABLE `POSIZIONE` (
  `Prenotazione` int NOT NULL AUTO_INCREMENT,
  `Tavolo` varchar(10) NOT NULL,
  PRIMARY KEY (Prenotazione,Tavolo),
  FOREIGN KEY (Prenotazione) REFERENCES PRENOTAZIONE(IDPrenotazione)
	ON DELETE CASCADE
	ON UPDATE CASCADE,
  FOREIGN KEY (Tavolo) REFERENCES TAVOLO(IDTavolo)
	ON DELETE CASCADE
	ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

/* FARE CONTROLLO NUMERO PERSONE E NUMERO POSTI A SEDERE */

INSERT INTO `POSIZIONE` (`Prenotazione`,`Tavolo`) VALUES
	("1","T01"),
	("2","T05"),
	("3","T02"),
	("4","T03"),
	("5","T04"),
	("6","T01"),
	("7","T07"),
	("8","T07"),
	("9","T01"),
	("10","T01");
COMMIT;

-- TABELLA RECENSIONE
DROP TABLE IF EXISTS `RECENSIONE`;
CREATE TABLE `RECENSIONE` (
  `IDRecensione` int NOT NULL AUTO_INCREMENT,
  `Account` int NOT NULL,
  `Sede` varchar(50) NOT NULL,
  `Piatto` varchar(255) NULL,
  `Voto1` int NOT NULL DEFAULT 3,
  `Voto2` int NOT NULL DEFAULT 3,
  `Voto3` int NOT NULL DEFAULT 3,
  `Voto4` int NOT NULL DEFAULT 3,
  `Voto5` int NOT NULL DEFAULT 3,
  `Voto` int NOT NULL DEFAULT 0,
  `Testo` varchar(10000) NOT NULL,
  `DataeOra` timestamp NOT NULL,
  `NumeroVoti` int NOT NULL DEFAULT 0,
  `Veridicita` int NOT NULL DEFAULT 0,
  `Accuratezza` int NOT NULL DEFAULT 0,
  PRIMARY KEY (IDRecensione),
  UNIQUE (Account,DataeOra),
  FOREIGN KEY (Account) REFERENCES ACCOUNT(IDAccount)
	ON DELETE CASCADE
	ON UPDATE CASCADE,
  FOREIGN KEY (Sede) REFERENCES SEDE(IDSede)
	ON DELETE CASCADE
	ON UPDATE CASCADE,
  FOREIGN KEY (Piatto) REFERENCES PIATTO(IDPiatto)
	ON DELETE CASCADE
	ON UPDATE CASCADE 
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

DELIMITER //
DROP TRIGGER IF EXISTS check_recensione_input;
CREATE TRIGGER check_recensione_input BEFORE INSERT ON RECENSIONE
FOR EACH ROW 
	BEGIN
	
	IF (NEW.Voto1 <=0 AND NEW.Voto1 >= 6) THEN
		SIGNAL SQLSTATE '45000'
		SET MESSAGE_TEXT = "Voto1 non corretto!";
	END IF;
	
	IF (NEW.Voto2 <=0 AND NEW.Voto2 >= 6) THEN
		SIGNAL SQLSTATE '45000'
		SET MESSAGE_TEXT = "Voto2 non corretto!";
	END IF;
	
	IF (NEW.Voto3 <=0 AND NEW.Voto3 >= 6) THEN
		SIGNAL SQLSTATE '45000'
		SET MESSAGE_TEXT = "Voto3 non corretto!";
	END IF;
	
	IF (NEW.Voto4 <=0 AND NEW.Voto4 >= 6) THEN
		SIGNAL SQLSTATE '45000'
		SET MESSAGE_TEXT = "Voto4 non corretto!";
	END IF;
	
	IF (NEW.Voto5 <=0 AND NEW.Voto5 >= 6) THEN
		SIGNAL SQLSTATE '45000'
		SET MESSAGE_TEXT = "Voto5 non corretto!";
	END IF;
	
	IF (NEW.Voto <=0 AND NEW.Voto >= 11) THEN
		SIGNAL SQLSTATE '45000'
		SET MESSAGE_TEXT = "Voto1 non corretto!";
	END IF;
	
	END //
DELIMITER ;

DELIMITER //
DROP TRIGGER IF EXISTS check_recensione_modifica;
CREATE TRIGGER check_recensione_modifica BEFORE UPDATE ON RECENSIONE
FOR EACH ROW 
	BEGIN 
	
	IF (NEW.Voto1 <=0 AND NEW.Voto1 >= 6) THEN
		SIGNAL SQLSTATE '45000'
		SET MESSAGE_TEXT = "Voto1 non corretto!";
	END IF;
	
	IF (NEW.Voto2 <=0 AND NEW.Voto2 >= 6) THEN
		SIGNAL SQLSTATE '45000'
		SET MESSAGE_TEXT = "Voto2 non corretto!";
	END IF;
	
	IF (NEW.Voto3 <=0 AND NEW.Voto3 >= 6) THEN
		SIGNAL SQLSTATE '45000'
		SET MESSAGE_TEXT = "Voto3 non corretto!";
	END IF;
	
	IF (NEW.Voto4 <=0 AND NEW.Voto4 >= 6) THEN
		SIGNAL SQLSTATE '45000'
		SET MESSAGE_TEXT = "Voto4 non corretto!";
	END IF;
	
	IF (NEW.Voto5 <=0 AND NEW.Voto5 >= 6) THEN
		SIGNAL SQLSTATE '45000'
		SET MESSAGE_TEXT = "Voto5 non corretto!";
	END IF;
	
	IF (NEW.Voto <=0 AND NEW.Voto >= 11) THEN
		SIGNAL SQLSTATE '45000'
		SET MESSAGE_TEXT = "Voto1 non corretto!";
	END IF;
	
END //
DELIMITER ;

INSERT INTO `RECENSIONE` (`Account`,`Sede`,`Voto1`,`Voto2`,`Voto3`,`Voto4`,`Voto5`,`Voto`,`Testo`,`DataeOra`) VALUES 
	("1","SA1","2","5","3","3","4","3","BlaBlaBla","2013-10-10"),
	("2","SA1","4","2","3","3","4","6","BlaBlaBla","2013-10-11"),
	("3","SA1","3","2","3","4","4","10","BlaBlaBla","2013-11-10"),
	("4","SA1","2","2","3","3","4","3","BlaBlaBla","2013-12-10"),
	("5","SA1","2","2","3","1","4","5","BlaBlaBla","2014-10-10"),
	("6","SA1","2","2","3","3","4","3","BlaBlaBla","2014-12-10"),
	("7","SA1","1","2","1","1","1","7","BlaBlaBla","2015-10-11"),
	("8","SA1","1","2","3","3","4","8","BlaBlaBla","2015-12-10"),
	("9","SA1","2","1","3","3","4","1","BlaBlaBla","2015-12-11"),
	("2","SA1","2","2","1","3","4","3","BlaBlaBla","2015-12-19");
COMMIT;

-- TABELLA VALUTAZIONE RECENSIONE
DROP TABLE IF EXISTS `VALUTAZIONERECENSIONE`;
CREATE TABLE `VALUTAZIONERECENSIONE` (
  `Recensione` int NOT NULL,
  `Account` int NOT NULL,
  `Commento` varchar(500) NOT NULL,
  `DataeOra` timestamp NOT NULL,
  `Veridicita` int NOT NULL DEFAULT 0,
  `Accuratezza` int NOT NULL DEFAULT 0,
  PRIMARY KEY (Recensione,Account),
  FOREIGN KEY (Recensione) REFERENCES RECENSIONE(IDRecensione)
	ON DELETE CASCADE
	ON UPDATE CASCADE,
  FOREIGN KEY (Account) REFERENCES ACCOUNT(IDAccount)
	ON DELETE CASCADE
	ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

DELIMITER //
DROP TRIGGER IF EXISTS check_valutazionerecensione_input;
CREATE TRIGGER check_valutazionerecensione_input BEFORE INSERT ON VALUTAZIONERECENSIONE
FOR EACH ROW 
	BEGIN
	
	IF (NEW.Veridicita <=0 AND NEW.Veridicita >= 6) THEN
		SIGNAL SQLSTATE '45000'
		SET MESSAGE_TEXT = "Veridicita non corretto!";
	END IF;
	
	IF (NEW.Accuratezza <=0 AND NEW.Accuratezza >= 6) THEN
		SIGNAL SQLSTATE '45000'
		SET MESSAGE_TEXT = "Accuratezza non corretto!";
	END IF;
	
	SET @e = (SELECT COUNT(*)
			  FROM RECENSIONE R
			  WHERE R.IDRecensione = NEW.Recensione AND R.Account = NEW.Account);
	
	/* NON SI PUO' VALUTARE LA PROPRIA RECENSIONE */
	IF @e = 1 THEN
		SIGNAL SQLSTATE '45000'
		SET MESSAGE_TEXT = "Non si può valurare la propria recensione!";
	END IF;
	
	/* INSERISCI I VALORI NELLE RECENSIONI */
	SET @Veridicita = (SELECT Veridicita
					FROM RECENSIONE
					WHERE IDRecensione = NEW.Recensione);
					
	SET @Accuratezza = (SELECT Accuratezza
					FROM RECENSIONE
					WHERE IDRecensione = NEW.Recensione);
					
	SET @newVeridicita = @Veridicita + NEW.Veridicita;
	SET @newAccuratezza = @Accuratezza + NEW.Accuratezza;
	
	UPDATE RECENSIONE
	SET Veridicita = @newVeridicita, Accuratezza = @newAccuratezza, NumeroVoti = NumeroVoti + 1
	WHERE IDRecensione = NEW.Recensione;
	
	END //
DELIMITER ;

DELIMITER //
DROP TRIGGER IF EXISTS check_valutazionerecensione_update;
CREATE TRIGGER check_valutazionerecensione_update BEFORE UPDATE ON VALUTAZIONERECENSIONE
FOR EACH ROW 
	BEGIN
	
	IF (NEW.Recensione <> OLD.Recensione) THEN
		SIGNAL SQLSTATE '45000'
		SET MESSAGE_TEXT = "Modifica non consentita!";
	END IF;
	
	IF (NEW.Account <> OLD.Account) THEN
		SIGNAL SQLSTATE '45000'
		SET MESSAGE_TEXT = "Modifica non consentita!";
	END IF;
	
	IF (NEW.DataeOra <> OLD.DataeOra) THEN
		SIGNAL SQLSTATE '45000'
		SET MESSAGE_TEXT = "Modifica non consentita!";
	END IF;
	
	IF (NEW.Veridicita <> OLD.Veridicita) THEN
		SIGNAL SQLSTATE '45000'
		SET MESSAGE_TEXT = "Modifica non consentita!";
	END IF;
	
	IF (NEW.Accuratezza <> OLD.Accuratezza) THEN
		SIGNAL SQLSTATE '45000'
		SET MESSAGE_TEXT = "Modifica non consentita!";
	END IF;
	
	IF (NEW.Commento <> OLD.Commento) THEN
		SET NEW.DataeOra = CURRENT_TIMESTAMP;
	END IF;
	
	END //
DELIMITER ;

INSERT INTO `VALUTAZIONERECENSIONE` (`Recensione`,`Account`,`Commento`,`DataeOra`,`Veridicita`,`Accuratezza`) VALUES 
	("2","1","BlaBlaBla","2013-10-10","3","1"),
	("1","2","BlaBlaBla","2013-10-10","2","1"),
	("1","3","BlaBlaBla","2013-10-10","2","5"),
	("1","4","BlaBlaBla","2013-10-10","4","1"),
	("1","5","BlaBlaBla","2013-10-10","1","1"),
	("1","6","BlaBlaBla","2013-10-10","2","4"),
	("1","7","BlaBlaBla","2013-10-10","1","3"),
	("1","8","BlaBlaBla","2013-10-10","4","2"),
	("1","9","BlaBlaBla","2013-10-10","2","2"),
	("1","10","BlaBlaBla","2013-10-10","2","2");
COMMIT;

-- TABELLA VALUTAZIONE PIATTO
DROP TABLE IF EXISTS `VALUTAZIONEPIATTO`;
CREATE TABLE `VALUTAZIONEPIATTO` (
  `NuovoPiatto` int NOT NULL,
  `Account` int NOT NULL,
  `Voto` int NOT NULL,
  `DataeOra` timestamp NOT NULL,
  PRIMARY KEY (NuovoPiatto,Account),
  FOREIGN KEY (NuovoPiatto) REFERENCES NUOVOPIATTO(IDNuovoPiatto)
	ON DELETE CASCADE
	ON UPDATE CASCADE,
  FOREIGN KEY (Account) REFERENCES ACCOUNT(IDAccount)
	ON DELETE CASCADE
	ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

DELIMITER //
DROP TRIGGER IF EXISTS check_valutazionepiatto_input;
CREATE TRIGGER check_valutazionepiatto_input BEFORE INSERT ON VALUTAZIONEPIATTO
FOR EACH ROW 
	BEGIN
	
	IF (NEW.Voto <=0 AND NEW.Voto >= 6) THEN
		SIGNAL SQLSTATE '45000'
		SET MESSAGE_TEXT = "Voto non corretto!";
	END IF;
	
	SET @e = (SELECT COUNT(*)
			  FROM NUOVOPIATTO P
			  WHERE P.IDNuovoPiatto = NEW.NuovoPiatto AND P.Account = NEW.Account);
	
	/* NON SI PUO' VALUTARE IL PROPRIO PIATTO */
	IF @e = 1 THEN
		SIGNAL SQLSTATE '45000'
		SET MESSAGE_TEXT = "Non si può valurare il proprio piatto!";
	END IF;
	
	/* INSERISCI I VALORI NEI PIATTI */
	SET @Punteggio = (SELECT VotoPiatto
					FROM NUOVOPIATTO
					WHERE IDNuovoPiatto = NEW.NuovoPiatto);
					
	SET @newPunteggio = @Punteggio + NEW.Voto;
	
	UPDATE NUOVOPIATTO
	SET VotoPiatto = @newPunteggio, NumeroVoti = NumeroVoti + 1
	WHERE IDNuovoPiatto = NEW.NuovoPiatto;
	
	END //
DELIMITER ;

DELIMITER //
DROP TRIGGER IF EXISTS check_valutazionepiatto_update;
CREATE TRIGGER check_valutazionepiatto_update BEFORE UPDATE ON VALUTAZIONEPIATTO
FOR EACH ROW 
	BEGIN
	
	IF (NEW.Voto <> OLD.Voto) THEN
		SIGNAL SQLSTATE '45000'
		SET MESSAGE_TEXT = "Modifica non consentita!";
	END IF;
	
	IF (NEW.NuovoPiatto <> OLD.NuovoPiatto) THEN
		SIGNAL SQLSTATE '45000'
		SET MESSAGE_TEXT = "Modifica non consentita!";
	END IF;
	
	IF (NEW.Account <> OLD.Account) THEN
		SIGNAL SQLSTATE '45000'
		SET MESSAGE_TEXT = "Modifica non consentita!";
	END IF;
	
	IF (NEW.DataeOra <> OLD.DataeOra) THEN
		SIGNAL SQLSTATE '45000'
		SET MESSAGE_TEXT = "Modifica non consentita!";
	END IF;
	
	END //
DELIMITER ;

INSERT INTO `VALUTAZIONEPIATTO` (`NuovoPiatto`,`Account`,`Voto`,`DataeOra`) VALUES 
	("2","1","2","2013-10-10"),
	("1","2","3","2013-10-10"),
	("1","3","4","2013-10-10"),
	("1","4","5","2013-10-10"),
	("1","5","3","2013-10-10"),
	("1","6","4","2013-10-10"),
	("1","7","5","2013-10-10"),
	("1","8","4","2013-10-10"),
	("1","9","3","2013-10-10"),
	("1","10","2","2013-10-10");
COMMIT;

/*
 * ###############################################################################################
 * AREA PREPARAZIONE
 */

-- TABELLA FASE DI PREPARAZIONE
DROP TABLE IF EXISTS `COMPITO`;
CREATE TABLE `COMPITO` (
  `Tipo` varchar(50) NOT NULL,
  PRIMARY KEY (Tipo)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

INSERT INTO COMPITO VALUES
	("Scaldare"),("Mescolare"),("Impastare"),("Macinare"),
	("Tritare"),("Affettare"),("Scolare"),("Tagliare"),("Agitare"),("Frullare"),("Montare"),("Pesare"),("Gettare"),
	("Attendere"),("Cacciare"),("Versare"),("Servire"),("Grattugiare");
COMMIT;

-- TABELLA ATTREZZATURA
DROP TABLE IF EXISTS `ATTREZZATURA`;
CREATE TABLE `ATTREZZATURA` (
  `Nome` varchar(50) NOT NULL,
  `Tipo` varchar(50) NOT NULL,
  PRIMARY KEY (Nome)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

DELIMITER //
DROP TRIGGER IF EXISTS check_attrezzatura_input;
CREATE TRIGGER check_attrezzatura_input BEFORE INSERT ON ATTREZZATURA
FOR EACH ROW 
	BEGIN
	
	IF (NEW.Tipo <> "Macchinario" AND NEW.Tipo <> "Attrezzo") THEN
		SIGNAL SQLSTATE '45000'
		SET MESSAGE_TEXT = "Tipo macchinario non corretto!";
	END IF;
	
	END //
DELIMITER ;

DELIMITER //
DROP TRIGGER IF EXISTS check_attrezzatura_update;
CREATE TRIGGER check_attrezzatura_update BEFORE UPDATE ON ATTREZZATURA
FOR EACH ROW 
	BEGIN
	
	IF (NEW.Tipo <> "Macchinario" AND NEW.Tipo <> "Attrezzo") THEN
		SIGNAL SQLSTATE '45000'
		SET MESSAGE_TEXT = "Tipo macchinario non corretto!";
	END IF;
	
	END //
DELIMITER ;

INSERT INTO ATTREZZATURA VALUES
	("Forno","Macchinario"),("Impastatrice","Macchinario"),("Abbattitore","Macchinario"),
	("Fuochi","Attrezzo"),("Lavello","Attrezzo"),("Piano di lavoro","Attrezzo"),
	("Coltello","Attrezzo"),("Frullatore","Macchinario"),("Frusta","Attrezzo"),("Padella","Attrezzo"),("Tegame","Attrezzo"),
	("Bilancia","Macchinario"),("Scolapasta","Attrezzo"),("Cucchiaio","Attrezzo"),("Piatto","Attrezzo"),("Grattugia","Attrezzo");
COMMIT;

-- TABELLA STRUMENTO
DROP TABLE IF EXISTS `STRUMENTO`;
CREATE TABLE `STRUMENTO` (
  `CodSerie` varchar(50) NOT NULL,
  `Sede` varchar(50) NOT NULL,
  `Attrezzo` varchar(50) NOT NULL,
  `StatoUtilizzo` boolean DEFAULT 0,
  PRIMARY KEY (CodSerie),
  UNIQUE (CodSerie,Attrezzo),
  FOREIGN KEY (Sede) REFERENCES SEDE(IDSede)
	ON DELETE CASCADE
	ON UPDATE CASCADE,
  FOREIGN KEY (Attrezzo) REFERENCES ATTREZZATURA(Nome)
    ON DELETE CASCADE
	ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

INSERT INTO STRUMENTO (CodSerie,Sede,Attrezzo) VALUES
	("S001","SA1","Coltello"),
	("S002","SA1","Forno"),
	("S003","SA1","Frullatore"),
	("S004","SA1","Fuochi"),
	("S005","SA1","Lavello"),
	("S006","SA1","Piano di lavoro"),
	("S007","SA1","Frusta"),
	("S008","SA1","Padella"),
	("S009","SA1","Coltello"),
	("S010","SA1","Impastatrice"),
	("S011","SA1","Tegame"),
	("S012","SA1","Bilancia"),
	("S013","SA1","Scolapasta"),
	("S014","SA1","Cucchiaio"),
	("S015","SA1","Piatto"),
	("S016","SA1","Grattugia");
COMMIT;

-- TABELLA FASE
DROP TABLE IF EXISTS `FASE`;
CREATE TABLE `FASE` (
  `Strumento` varchar(50) NOT NULL,
  `Fase`  varchar(50) NOT NULL,
  PRIMARY KEY (Strumento,Fase),
  FOREIGN KEY (Fase) REFERENCES COMPITO(Tipo)
	ON DELETE CASCADE
	ON UPDATE CASCADE,
  FOREIGN KEY (Strumento) REFERENCES ATTREZZATURA(Nome)
    ON DELETE CASCADE
	ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

INSERT INTO FASE VALUES
	("Coltello","Affettare"),
	("Coltello","Tagliare"),
	("Padella","Scaldare"),
	("Frullatore","Frullare"),
	("Frusta","Montare"),
	("Fuochi","Scaldare"),
	("Forno","Scaldare"),
	("Impastatrice","Impastare"),
	("Frullatore","Agitare"),
	("Tegame","Scaldare"),
	("Tegame","Gettare"),
	("Bilancia","Pesare"),
	("Scolapasta","Scolare"),
	("Cucchiaio","Mescolare"),
	("Piatto","Servire"),
	("Grattugia","Grattugiare");
COMMIT;

-- TABELLA PROCEDIMENTO STRUTTURATO
DROP TABLE IF EXISTS `PROCEDIMENTO`;
CREATE TABLE `PROCEDIMENTO` (
  `IDps` int NOT NULL AUTO_INCREMENT,
  `Attrezzo` varchar(50) NULL,
  `Fase`  varchar(50) NOT NULL,
  `Ingrediente`  varchar(50) NULL,
  `Piatto`  varchar(50) NOT NULL,
  `Consiglio`  varchar(255) NULL,
  `Dose`  decimal(5,2) NULL,
  `Durata`  int NOT NULL,
  `RuoloNelPiatto`  varchar(50) NULL,
  `DescrizioneRicetta`  varchar(50) NOT NULL,
  `OrdineDiProcedimento` int NULL,
  PRIMARY KEY (IDps),
  FOREIGN KEY (Fase) REFERENCES COMPITO(Tipo)
	ON DELETE CASCADE
	ON UPDATE CASCADE,
  FOREIGN KEY (Attrezzo) REFERENCES ATTREZZATURA(Nome)
    ON DELETE SET NULL
	ON UPDATE CASCADE,
  FOREIGN KEY (Ingrediente) REFERENCES INGREDIENTE(Nome)
    ON DELETE SET NULL
	ON UPDATE CASCADE,
  FOREIGN KEY (Piatto) REFERENCES PIATTO(IDPiatto)
    ON DELETE CASCADE
	ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

DELIMITER //
DROP TRIGGER IF EXISTS check_ps_input;
CREATE TRIGGER check_ps_input BEFORE INSERT ON PROCEDIMENTO
FOR EACH ROW 
	BEGIN
	
	/*IF (NEW.Ingrediente IS NOT NULL AND NEW.Dose IS NULL) THEN
		SIGNAL SQLSTATE '45000'
		SET MESSAGE_TEXT = "Specificare dose dell'ingrediente!";
	END IF;*/
	
	IF (NEW.Dose IS NOT NULL AND NEW.RuoloNelPiatto IS NULL) THEN
		SIGNAL SQLSTATE '45000'
		SET MESSAGE_TEXT = "Specificare ruolo nel piatto dell'ingrediente!";
	END IF;
	
	IF(NEW.RuoloNelPiatto IS NOT NULL AND NEW.RuoloNelPiatto <> "Primario" AND NEW.RuoloNelPiatto <> "Secondario" 
		AND NEW.RuoloNelPiatto <> "Ininfluente") THEN
		SIGNAL SQLSTATE '45000'
		SET MESSAGE_TEXT = "Ruolo nel piatto non corretto!";
	END IF;
	
	IF (NEW.Attrezzo IS NOT NULL AND NEW.Fase IS NULL) THEN
		SIGNAL SQLSTATE '45000'
		SET MESSAGE_TEXT = "Errore! Fase non registrata!";
	END IF;
	
	IF NEW.Attrezzo IS NOT NULL THEN
		SET @e = (SELECT COUNT(*)
					FROM FASE
					WHERE Strumento = NEW.Attrezzo AND Fase = NEW.Fase);
		
		IF @e = 0 THEN
			SIGNAL SQLSTATE '45000'
			SET MESSAGE_TEXT = "Errore! Integrita' delle informazioni non verificata!";
		END IF;
	END IF;
	
	IF NEW.OrdineDiProcedimento IS NULL THEN
		SET @Ordine = (SELECT COUNT(*)
			FROM PROCEDIMENTO
			WHERE Piatto = NEW.Piatto);
		SET NEW.OrdineDiProcedimento = @Ordine + 1;
	END IF;
	
	END //
DELIMITER ;

DELIMITER //
DROP TRIGGER IF EXISTS check_ps_update;
CREATE TRIGGER check_ps_update BEFORE UPDATE ON PROCEDIMENTO
FOR EACH ROW 
	BEGIN
	
	/*IF (NEW.Ingrediente IS NOT NULL AND NEW.Dose IS NULL) THEN
		SIGNAL SQLSTATE '45000'
		SET MESSAGE_TEXT = "Specificare dose dell'ingrediente!";
	END IF;*/
	
	IF (NEW.Dose IS NOT NULL AND NEW.RuoloNelPiatto IS NULL) THEN
		SIGNAL SQLSTATE '45000'
		SET MESSAGE_TEXT = "Specificare ruolo nel piatto dell'ingrediente!";
	END IF;
	
	IF(NEW.RuoloNelPiatto IS NOT NULL AND NEW.RuoloNelPiatto <> "Primario" AND NEW.RuoloNelPiatto <> "Secondario" 
		AND NEW.RuoloNelPiatto <> "Ininfluente") THEN
		SIGNAL SQLSTATE '45000'
		SET MESSAGE_TEXT = "Ruolo nel piatto non corretto!";
	END IF;
	
	IF (NEW.Attrezzo IS NOT NULL AND NEW.Fase IS NULL) THEN
		SIGNAL SQLSTATE '45000'
		SET MESSAGE_TEXT = "Errore! Fase non registrata!";
	END IF;
	
	IF NEW.Attrezzo IS NOT NULL THEN
		SET @e = (SELECT COUNT(*)
					FROM FASE
					WHERE Strumento = NEW.Attrezzo AND Fase = NEW.Fase);
		
		IF @e = 0 THEN
			SIGNAL SQLSTATE '45000'
			SET MESSAGE_TEXT = "Errore! Integrita' delle informazioni non verificata!";
		END IF;
	END IF;
	
	/*IF NEW.OrdineDiProcedimento IS NULL THEN
		SET @Ordine = (SELECT COUNT(*)
			FROM PROCEDIMENTO
			WHERE Piatto = NEW.Piatto);
		SET NEW.OrdineDiProcedimento = @Ordine + 1;
	END IF;*/
	
	END //
DELIMITER ;
/* LA DOSE E IL RUOLO NEL PIATTO DI UN INGREDIENTE SONO SPECIFICATI SOLAMENTE NELLE PRIME FASI DI PREPARAZIONE */
INSERT INTO PROCEDIMENTO (OrdineDiProcedimento,Attrezzo,Fase,Ingrediente,Piatto,Consiglio,Dose,Durata,RuoloNelPiatto,DescrizioneRicetta) VALUES
	("1","Tegame","Scaldare","Acqua","PI10","Far arrivare a ebollizione.",NULL,"15","Ininfluente","Scaldare l'acqua, fino a vederla bollire."),
	("2","Bilancia","Pesare","Spaghetti","PI10",NULL,"0.2","2","Primario","Pesare 200 grammi di pasta."),
	("3","Tegame","Scaldare","Passata","PI10",NULL,"0.15","20","Secondario","Scaldare 150 grammi di sugo."),
	("4",NULL,"Gettare","Spaghetti","PI10","Attenzione a non scottarsi!",NULL,"1",NULL,"Versare la pasta nell'acqua bollente."),
	("5",NULL,"Attendere",NULL,"PI10",NULL,NULL,"12",NULL,"Attendere che la pasta sia cotta."),
	("6","Scolapasta","Scolare","Spaghetti","PI10","Attenzione a non bruciarsi!",NULL,"2",NULL,"Scolare la pasta."),
	("7","Tegame","Gettare","Spaghetti","PI10",NULL,NULL,"2",NULL,"Gettare la pasta nel sugo."),
	("8","Cucchiaio","Mescolare","Spaghetti","PI10",NULL,NULL,"2",NULL,"Mischiare la pasta col sugo."),
	("9",NULL,"Cacciare","Spaghetti","PI10",NULL,NULL,"2",NULL,"Cacciare la pasta dal tegame."),
	("10","Piatto","Servire","Spaghetti","PI10",NULL,NULL,"2",NULL,"Servire in un piatto.");
COMMIT;

-- TABELLA VARIAZIONE
DROP TABLE IF EXISTS `VARIAZIONE`;
CREATE TABLE `VARIAZIONE` (
  `IDVariazione` int NOT NULL AUTO_INCREMENT,
  `Procedimento` int NOT NULL,
  `Attrezzo` varchar(50) NULL,
  `Fase`  varchar(50) NULL,
  `Ingrediente`  varchar(50) NULL,
  `Tipo`  int NOT NULL DEFAULT 0, /* Agg o rim */
  `Dose`  decimal(5,2) NULL,
  `RuoloNelPiatto`  varchar(50) NULL,
  `Durata`  varchar(50) NULL,
  PRIMARY KEY (IDVariazione),
  FOREIGN KEY (Fase) REFERENCES COMPITO(Tipo)
	ON DELETE CASCADE
	ON UPDATE CASCADE,
  FOREIGN KEY (Attrezzo) REFERENCES ATTREZZATURA(Nome)
    ON DELETE SET NULL
	ON UPDATE CASCADE,
  FOREIGN KEY (Ingrediente) REFERENCES INGREDIENTE(Nome)
    ON DELETE SET NULL
	ON UPDATE CASCADE,
  FOREIGN KEY (Procedimento) REFERENCES PROCEDIMENTO(IDps)
    ON DELETE CASCADE
	ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

DELIMITER //
DROP TRIGGER IF EXISTS check_v_input;
CREATE TRIGGER check_v_input BEFORE INSERT ON VARIAZIONE
FOR EACH ROW 
	BEGIN
	
	IF (NEW.Tipo IS NOT NULL AND NEW.Tipo <> 0 AND NEW.Tipo <> 1 AND NEW.Tipo <> -1) THEN
		SIGNAL SQLSTATE '45000'
		SET MESSAGE_TEXT = "Errore! Tipo non corretto!";
	END IF;
	
	IF (NEW.Ingrediente IS NOT NULL AND (NEW.Dose IS NULL OR NEW.RuoloNelPiatto IS NULL) AND NEW.Tipo <> "-1") THEN
		SIGNAL SQLSTATE '45000'
		SET MESSAGE_TEXT = "Specificare dose/ruolo nel piatto dell'ingrediente!";
	END IF;
	
	IF(NEW.RuoloNelPiatto IS NOT NULL AND NEW.RuoloNelPiatto <> "Primario" AND NEW.RuoloNelPiatto <> "Secondario" 
		AND NEW.RuoloNelPiatto <> "Ininfluente") THEN
		SIGNAL SQLSTATE '45000'
		SET MESSAGE_TEXT = "Ruolo nel piatto non corretto!";
	END IF;
	
	IF (NEW.Attrezzo IS NOT NULL AND NEW.Fase IS NULL) THEN
		SIGNAL SQLSTATE '45000'
		SET MESSAGE_TEXT = "Errore! Fase non registrata!";
	END IF;
	
	IF NEW.Attrezzo IS NOT NULL THEN
		SET @e = (SELECT COUNT(*)
					FROM FASE
					WHERE Strumento = NEW.Attrezzo AND Fase = NEW.Fase);
		
		IF @e = 0 THEN
			SIGNAL SQLSTATE '45000'
			SET MESSAGE_TEXT = "Errore! Integrita' delle informazioni non verificata!";
		END IF;
	END IF;
	
	END //
DELIMITER ;

DELIMITER //
DROP TRIGGER IF EXISTS check_v_update;
CREATE TRIGGER check_v_update BEFORE UPDATE ON VARIAZIONE
FOR EACH ROW 
	BEGIN
	
	IF (NEW.Ingrediente IS NOT NULL AND (NEW.Dose IS NULL OR NEW.RuoloNelPiatto IS NULL) AND NEW.Tipo <> "-1") THEN
		SIGNAL SQLSTATE '45000'
		SET MESSAGE_TEXT = "Specificare dose/ruolo nel piatto dell'ingrediente!";
	END IF;
	
	IF(NEW.RuoloNelPiatto IS NOT NULL AND NEW.RuoloNelPiatto <> "Primario" AND NEW.RuoloNelPiatto <> "Secondario" 
		AND NEW.RuoloNelPiatto <> "Ininfluente") THEN
		SIGNAL SQLSTATE '45000'
		SET MESSAGE_TEXT = "Ruolo nel piatto non corretto!";
	END IF;
	
	IF (NEW.Attrezzo IS NOT NULL AND NEW.Fase IS NULL) THEN
		SIGNAL SQLSTATE '45000'
		SET MESSAGE_TEXT = "Errore! Fase non registrata!";
	END IF;
	
	IF NEW.Attrezzo IS NOT NULL THEN
		SET @e = (SELECT COUNT(*)
					FROM FASE
					WHERE Strumento = NEW.Attrezzo AND Fase = NEW.Fase);
		
		IF @e = 0 THEN
			SIGNAL SQLSTATE '45000'
			SET MESSAGE_TEXT = "Errore! Integrita' delle informazioni non verificata!";
		END IF;
	END IF;
	
	END //
DELIMITER ;

/* LA DOSE E IL RUOLO NEL PIATTO DI UN INGREDIENTE SONO DA SPECIFICARE SOLAMENTE SE L'INGREDIENTE E' DIVERSO DA QUELLO NEL 
   PROCEDIMENTO STRUTTURATO */
INSERT INTO VARIAZIONE (Procedimento,Attrezzo,Fase,Ingrediente,Tipo,Dose,RuoloNelPiatto,Durata) VALUES 
	("3",NULL,NULL,"Pesto","0","0.1","Secondario","5"),
	("10","Grattugia","Grattugiare","Parmigiano","1","0.5","Secondario","1"),
	("10","Grattugia","Grattugiare","Pecorino","1","0.5","Secondario","1"),
	("5",NULL,NULL,NULL,"0","0",NULL,"8"),
	("3",NULL,NULL,"Passata","-1",NULL,NULL,NULL),
	("3",NULL,NULL,"Macinato di manzo","1","0.1","Secondario","3"),
	("10",NULL,NULL,"Basilico","1","0.02","Secondario","1");
COMMIT;

-- TABELLA RICHIESTA
DROP TABLE IF EXISTS `RICHIESTA`;
CREATE TABLE `RICHIESTA` (
  `Servizio` int NOT NULL,
  `Variazione` int NOT NULL,
 PRIMARY KEY (Servizio,Variazione),
 FOREIGN KEY (Servizio) REFERENCES SERVIZIO(IDServizio)
    ON DELETE CASCADE
	ON UPDATE CASCADE,
  FOREIGN KEY (Variazione) REFERENCES VARIAZIONE(IDVariazione)
    ON DELETE CASCADE
	ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

INSERT INTO RICHIESTA VALUES 
	("1","5"),
	("2","4"),
	("3","3"),
	("4","1"),
	("5","1");
COMMIT;

-- TABELLA RICHIESTA TA
DROP TABLE IF EXISTS `RICHIESTATA`;
CREATE TABLE `RICHIESTATA` (
  `ServizioTA` int NOT NULL,
  `Variazione` int NOT NULL,
 PRIMARY KEY (ServizioTA,Variazione),
 FOREIGN KEY (ServizioTA) REFERENCES SERVIZIOTA(IDServizioTA)
    ON DELETE CASCADE
	ON UPDATE CASCADE,
 FOREIGN KEY (Variazione) REFERENCES VARIAZIONE(IDVariazione)
    ON DELETE CASCADE
	ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

INSERT INTO RICHIESTATA VALUES 
	("1","1"),
	("2","2"),
	("3","2"),
	("4","3"),
	("7","4"),
	("10","5");
COMMIT;