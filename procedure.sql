USE `Ristorante`;

/*
 * ###############################################################################################
 * PROCEDURE
 */

/* CONTROLLA CONTO */
/* Mantiene il conto aggiornato */
DROP PROCEDURE IF EXISTS ContoCheck;
DELIMITER //
CREATE PROCEDURE ContoCheck()
BEGIN

	DECLARE e INT DEFAULT 0;
	DECLARE F INT DEFAULT 0;
    DECLARE Fat INT DEFAULT 0;
	DECLARE C INT DEFAULT 0;
    DECLARE Com INT DEFAULT 0;
	DECLARE P varchar(10) DEFAULT "";
	DECLARE Q INT DEFAULT 0;
	DECLARE PrezzoServizio FLOAT DEFAULT 0;
	DECLARE Conto FLOAT DEFAULT 0;
    
    DECLARE Fattura CURSOR FOR 
		SELECT IDFattura
		FROM FATTURA
        WHERE StatoConto = "Aperto";
        
	DECLARE Comanda CURSOR FOR
			SELECT IDComanda, Fattura
			FROM COMANDA;
            
	DECLARE Servizio CURSOR FOR
				SELECT Comanda, NomePiatto, Quantita
				FROM SERVIZIO;
    
   DECLARE CONTINUE HANDLER
   FOR NOT FOUND SET e = 1;
   
   OPEN Fattura;
   
   ciclo: LOOP
		OPEN Comanda;
		OPEN Servizio;
		FETCH Fattura INTO F;
		IF e = 1 THEN
			LEAVE ciclo;
		END IF;
		ciclo1: LOOP
			FETCH Comanda INTO C,Fat;
			IF e = 1 THEN
				LEAVE ciclo1;
			END IF;
            IF Fat = F THEN 
				ciclo2: LOOP
					FETCH Servizio INTO Com,P,Q;	
					IF e = 1 THEN
						LEAVE ciclo2;
					END IF;
                    IF Com = C THEN 
						SET PrezzoServizio = (SELECT Prezzo
										FROM PIATTO
										WHERE IDPiatto = P); 
						SET PrezzoServizio = PrezzoServizio*Q;
						SET Conto = PrezzoServizio + Conto;
					END IF;
				END LOOP ciclo2;
                SET e = 0;
			END IF;
		END LOOP ciclo1;
		SET e = 0;
		UPDATE FATTURA
		SET Prezzo = Conto
		WHERE IDFattura = F;
		CLOSE Comanda;
		CLOSE Servizio;
        SET Conto = 0;
	END LOOP ciclo;
    
   CLOSE Fattura;
   CLOSE Comanda;
   CLOSE Servizio;
    
END //
DELIMITER ;

/* CONTROLLA CONTO TA */
/* Mantiene il conto aggiornato */
DROP PROCEDURE IF EXISTS ContoTACheck;
DELIMITER //
CREATE PROCEDURE ContoTACheck()
BEGIN

	DECLARE e INT DEFAULT 0;
	DECLARE F INT DEFAULT 0;
    DECLARE Fat INT DEFAULT 0;
	DECLARE C INT DEFAULT 0;
    DECLARE Com INT DEFAULT 0;
	DECLARE P varchar(10) DEFAULT "";
	DECLARE Q INT DEFAULT 0;
	DECLARE PrezzoServizio FLOAT DEFAULT 0;
	DECLARE Conto FLOAT DEFAULT 0;
    
    DECLARE FatturaTA CURSOR FOR 
		SELECT IDFatturaTA
		FROM FATTURATA
        WHERE StatoConto = "Aperto";
        
	DECLARE ComandaTA CURSOR FOR
			SELECT IDComandaTA, FatturaTA
			FROM COMANDATA;
            
	DECLARE ServizioTA CURSOR FOR
				SELECT ComandaTA, NomePiatto, Quantita
				FROM SERVIZIOTA;
    
   DECLARE CONTINUE HANDLER
   FOR NOT FOUND SET e = 1;
   
   OPEN FatturaTA;
   
   ciclo: LOOP
		OPEN ComandaTA;
		OPEN ServizioTA;
		FETCH FatturaTA INTO F;
		IF e = 1 THEN
			LEAVE ciclo;
		END IF;
		ciclo1: LOOP
			FETCH ComandaTA INTO C,Fat;
			IF e = 1 THEN
				LEAVE ciclo1;
			END IF;
            IF Fat = F THEN 
				ciclo2: LOOP
					FETCH ServizioTA INTO Com,P,Q;	
					IF e = 1 THEN
						LEAVE ciclo2;
					END IF;
                    IF Com = C THEN 
						SET PrezzoServizio = (SELECT Prezzo
										FROM PIATTO
										WHERE IDPiatto = P); 
						SET PrezzoServizio = PrezzoServizio*Q;
						SET Conto = PrezzoServizio + Conto;
					END IF;
				END LOOP ciclo2;
                SET e = 0;
			END IF;
		END LOOP ciclo1;
		SET e = 0;
		UPDATE FATTURATA
		SET Prezzo = Conto
		WHERE IDFatturaTA = F;
		CLOSE ComandaTA;
		CLOSE ServizioTA;
        SET Conto = 0;
	END LOOP ciclo;
    
   CLOSE FatturaTA;
   CLOSE ComandaTA;
   CLOSE ServizioTA;
    
END //
DELIMITER ;

/* CONTROLLA SERVIZIO */
/* Controlla lo stato del servizio */
DROP PROCEDURE IF EXISTS ServizioCheck;
DELIMITER //
CREATE PROCEDURE ServizioCheck()
BEGIN

	DECLARE T TIMESTAMP;
	DECLARE S INT; /* SERVIZIO */
	DECLARE MAXT INT;
	DECLARE e INT DEFAULT 0;

	DECLARE CP CURSOR FOR
	SELECT IDServizio,DataeOra,Durata
	FROM (
		SELECT IDServizio, NomePiatto, Comanda
		FROM SERVIZIO
		WHERE StatoPiatto = "Attesa") AS A INNER JOIN (
			SELECT IDPiatto
			FROM PIATTO) AS B ON NomePiatto = IDPiatto INNER JOIN (
				SELECT PS.Piatto, MAX(PS.Durata) + (SELECT SUM(P.Durata)
											  FROM PROCEDIMENTO P
											  WHERE P.Piatto = PS.Piatto AND P.Dose IS NULL AND P.Fase <> "Attendere") AS Durata
				FROM PROCEDIMENTO PS
				WHERE Fase IS NOT NULL AND Dose IS NOT NULL AND Ingrediente IS NOT NULL
				GROUP BY (Piatto)) AS C ON NomePiatto = C.Piatto INNER JOIN (
		SELECT IDComanda, DataeOra
		FROM comanda
		) AS D ON IDComanda = Comanda;

	DECLARE CONTINUE HANDLER FOR 
	NOT FOUND SET e = 1;

	OPEN CP;

	ciclo: LOOP
		FETCH CP INTO S,T,MAXT;
		IF e = 1 THEN 
			LEAVE ciclo;
		END IF;
		IF CURRENT_TIMESTAMP > T + INTERVAL 3 MINUTE AND CURRENT_TIMESTAMP < T + INTERVAL MAXT MINUTE THEN
			UPDATE SERVIZIO
			SET StatoPiatto = "In preparazione"
			WHERE IDServizio = S;
		END IF;
		IF CURRENT_TIMESTAMP >= T + INTERVAL MAXT MINUTE THEN
			UPDATE SERVIZIO
			SET StatoPiatto = "Servizio"
			WHERE IDServizio = S;
		END IF;
	END LOOP ciclo;

	CLOSE CP;

END //
DELIMITER ;

/* CONTROLLA SERVIZIO TA */
/* Controlla lo stato del servizio ta */
DROP PROCEDURE IF EXISTS ServizioTACheck;
DELIMITER //
CREATE PROCEDURE ServizioTACheck()
BEGIN

	DECLARE T TIMESTAMP;
	DECLARE S INT; /* SERVIZIO */
	DECLARE MAXT INT;
	DECLARE e INT DEFAULT 0;

	DECLARE CP CURSOR FOR
	SELECT IDServizioTA,DataeOra,Durata
	FROM (
		SELECT IDServizioTA, NomePiatto, ComandaTA
		FROM SERVIZIOTA
		WHERE StatoPiatto = "Attesa") AS A INNER JOIN (
			SELECT IDPiatto
			FROM PIATTO) AS B ON NomePiatto = IDPiatto INNER JOIN (
				SELECT PS.Piatto, MAX(PS.Durata) + (SELECT SUM(P.Durata)
											  FROM PROCEDIMENTO P
											  WHERE P.Piatto = PS.Piatto AND P.Dose IS NULL AND P.Fase <> "Attendere") AS Durata
				FROM PROCEDIMENTO PS
				WHERE Fase IS NOT NULL AND Dose IS NOT NULL AND Ingrediente IS NOT NULL
				GROUP BY (Piatto)) AS C ON NomePiatto = C.Piatto INNER JOIN (
		SELECT IDComandaTA, DataeOra
		FROM COMANDATA
		) AS D ON IDComandaTA = ComandaTA;

	DECLARE CONTINUE HANDLER FOR 
	NOT FOUND SET e = 1;

	OPEN CP;

	ciclo: LOOP
		FETCH CP INTO S,T,MAXT;
		IF e = 1 THEN 
			LEAVE ciclo;
		END IF;
		IF CURRENT_TIMESTAMP > T + INTERVAL 3 MINUTE AND CURRENT_TIMESTAMP < T + INTERVAL MAXT MINUTE THEN
			UPDATE SERVIZIOTA
			SET StatoPiatto = "In preparazione"
			WHERE IDServizioTA = S;
		END IF;
		IF CURRENT_TIMESTAMP >= T + INTERVAL MAXT MINUTE THEN
			UPDATE SERVIZIOTA
			SET StatoPiatto = "Servizio"
			WHERE IDServizioTA = S;
		END IF;
	END LOOP ciclo;

	CLOSE CP;

END //
DELIMITER ;

/* CONTROLLA COMANDA TA*/
/* Controlla lo stato della comanda ta */
DROP PROCEDURE IF EXISTS ComandaTACheck;
DELIMITER //
CREATE PROCEDURE ComandaTACheck()
BEGIN

	DECLARE e INT DEFAULT 0;
	DECLARE C INT; /* Comanda */
	DECLARE serviti INT DEFAULT 0;
	DECLARE inpreparazione INT DEFAULT 0;
	
	DECLARE CC CURSOR FOR
		SELECT IDComandaTA
		FROM ComandaTA
		WHERE ComandaTA <> "Evasa";
		
	DECLARE CONTINUE HANDLER FOR
	NOT FOUND SET e = 1;
	
	OPEN CC;
	
	ciclo: LOOP
		FETCH CC INTO C;
		IF e = 1 THEN
			LEAVE ciclo;
		END IF;
		SET inpreparazione = (
			SELECT COUNT(*)
			FROM SERVIZIOTA
			WHERE ComandaTA = C AND StatoPiatto = "In preparazione"
		);
		SET serviti = (
			SELECT COUNT(*)
			FROM SERVIZIOTA
			WHERE ComandaTA = C AND StatoPiatto = "Servizio"
		);
		IF serviti = 0 AND inpreparazione > 0 THEN
			UPDATE COMANDATA
			SET StatoComanda = "In preparazione"
			WHERE IDComandaTA = C;
		END IF;
		IF serviti > 0 AND inpreparazione > 0 THEN
			UPDATE COMANDATA
			SET StatoComanda = "Parziale"
			WHERE IDComandaTA = C;
		END IF;
		IF serviti > 0 AND inpreparazione = 0 THEN
			UPDATE COMANDATA
			SET StatoComanda = "Evasa"
			WHERE IDComandaTA = C;
		END IF;
	END LOOP ciclo;

	CLOSE CC;
	
END //
DELIMITER ;

/* CONTO CHIUSO, RILASCIA SCRONTRINO */
/* L'operatore decide di chiudere il conto allora si aggiorna la spesa finale e si liberano i tavoli */
DROP PROCEDURE IF EXISTS ContoChiuso;
DELIMITER //
CREATE PROCEDURE ContoChiuso (IN F INT)
BEGIN

	SET @Conto = (
		SELECT SUM(Spesa)
		FROM (
			SELECT Prezzo*Quantita AS Spesa
			FROM COMANDA INNER JOIN SERVIZIO ON Comanda = IDComanda
				INNER JOIN PIATTO ON NomePiatto = IDPiatto
			WHERE Fattura = F
			) A
	);

	UPDATE FATTURA
	SET Prezzo = @Conto, StatoConto = "Chiuso", DataEmissione = CURRENT_TIMESTAMP, MetodoPagamento = "Contanti"
	WHERE IDFattura = F;
	
	CALL TavoliEmpty(F);

END //
DELIMITER ;

/* ASSEGNA TAVOLO */
/* Assegna tavolo automaticamente a chi prenota, se ci sono posti, altrimenti blocca prenotazione */
DROP PROCEDURE IF EXISTS AssegnaTavolo;
DELIMITER //
CREATE PROCEDURE AssegnaTavolo(IN idp INT, IN DataOra TIMESTAMP, IN SED VARCHAR(10), IN NP INT)
BEGIN

	DECLARE e INT DEFAULT 0;
    DECLARE IDT VARCHAR(10);
    DECLARE POSTI INT;
	DECLARE CONT INT;
    
    DECLARE TC CURSOR FOR 
        SELECT IDTavolo, NumeroPosti
		FROM TAVOLO INNER JOIN POSIZIONE ON IDTavolo = Tavolo
			INNER JOIN PRENOTAZIONE P
		WHERE DataeOra > DataOra + INTERVAL 2 HOUR  AND StatoTavolo = "Libero" AND P.Sede = SED
        ORDER BY NumeroPosti ASC;

	DECLARE CONTINUE HANDLER FOR NOT FOUND 
    SET e = 1;
    
    SELECT COUNT(DISTINCT IDTavolo)
		FROM TAVOLO INNER JOIN POSIZIONE ON IDTavolo = Tavolo
			INNER JOIN PRENOTAZIONE P
		WHERE DataeOra > DataOra + INTERVAL 2 HOUR 
			AND StatoTavolo = "Libero" AND (NumeroPosti = NP OR NumeroPosti > NP) AND P.Sede = SED;

	SET @Tavolo = (
		SELECT COUNT(DISTINCT IDTavolo)
		FROM TAVOLO INNER JOIN POSIZIONE ON IDTavolo = Tavolo
			INNER JOIN PRENOTAZIONE P
		WHERE DataeOra > DataOra + INTERVAL 2 HOUR 
			AND StatoTavolo = "Libero" AND (NumeroPosti = NP OR NumeroPosti > NP) AND P.Sede = SED
	);
    
    SELECT SUM(NumeroPosti) 
        FROM (
			SELECT DISTINCT(IDTavolo), NumeroPosti
			FROM TAVOLO INNER JOIN POSIZIONE ON IDTavolo = Tavolo
				INNER JOIN PRENOTAZIONE P
			WHERE DataeOra > DataOra + INTERVAL 2 HOUR AND StatoTavolo = "Libero" AND P.Sede = SED
            ) A;
    	
	SET @PostiDisponibili = (
		SELECT SUM(NumeroPosti) 
        FROM (
			SELECT DISTINCT(IDTavolo), NumeroPosti
			FROM TAVOLO INNER JOIN POSIZIONE ON IDTavolo = Tavolo
				INNER JOIN PRENOTAZIONE P
			WHERE DataeOra > DataOra + INTERVAL 2 HOUR AND StatoTavolo = "Libero" AND P.Sede = SED
            ) A
	);
	
	SET @Tavoli = 0;
	IF @PostiDisponibili IS NOT NULL AND @PostiDisponibili >= NP THEN
		SET @Tavoli = 1;
	END IF;
	
	IF (@Tavolo = 0 AND @Tavoli = 0) THEN
		SIGNAL SQLSTATE '45000'
		SET MESSAGE_TEXT = "Tavolo non disponibile";
	END IF;
	
	IF @Tavolo > 0 THEN
		SET @idTav = (
			SELECT IDTavolo
			FROM TAVOLO INNER JOIN POSIZIONE ON IDTavolo = Tavolo
				INNER JOIN PRENOTAZIONE P
			WHERE DataeOra > DataOra + INTERVAL 2 HOUR 
				AND StatoTavolo = "Libero" AND (NumeroPosti = NP OR NumeroPosti > NP) AND P.Sede = SED
			ORDER BY NumeroPosti ASC
            LIMIT 1);
		INSERT INTO POSIZIONE VALUE (idp,@idTav);
	END IF;
	
	IF (@Tavolo = 0 AND @Tavoli > 0) THEN
		OPEN TC;
        ciclo: LOOP
			FETCH TC INTO IDT, POSTI;
            IF e = 1 OR CONT>=NP THEN
				LEAVE ciclo;
            END IF;
            INSERT INTO POSIZIONE VALUE (idp,IDT);
			SET CONT = CONST + POSTI;
        END LOOP;
        CLOSE TC;
	END IF;

END //
DELIMITER ;

/* CONTROLLO TAVOLI */
/* Occupa tavolo */
DROP PROCEDURE IF EXISTS TavoliBusy;
DELIMITER //
CREATE PROCEDURE TavoliBusy()
BEGIN

	UPDATE FATTURA INNER JOIN COMANDA ON IDFattura = Fattura 
			INNER JOIN TAVOLO ON IDTavolo = TAVOLO
	SET StatoTavolo = "Occupato"
	WHERE StatoConto = "Aperto";
		
END //
DELIMITER ;

/* Libera tavolo */
DROP PROCEDURE IF EXISTS TavoliEmpty;
DELIMITER //
CREATE PROCEDURE TavoliEmpty(IN F INT)
BEGIN

	UPDATE FATTURA INNER JOIN COMANDA ON IDFattura = Fattura 
			INNER JOIN TAVOLO ON IDTavolo = TAVOLO
	SET StatoTavolo = "Disponibile"
	WHERE StatoConto = "Chiuso" AND StatoTavolo = "Occupato" AND IDFattura = F;
		
END //
DELIMITER ;

/* CONTO TA CHIUSO, RILASCIA SCRONTRINO */
/* Quando il carello è pronto per la spedizione l'operatore chiude il conto, aggiorna la spesa finale e chiama i fattorini */
DROP PROCEDURE IF EXISTS ContoTAChiuso;
DELIMITER //
CREATE PROCEDURE ContoTAChiuso (IN F INT)
BEGIN

	SET @Conto = (
		SELECT SUM(Spesa)
		FROM (
			SELECT Prezzo*Quantita AS Spesa
			FROM COMANDATA INNER JOIN SERVIZIOTA ON ComandaTA = IDComandaTA
				INNER JOIN PIATTO ON NomePiatto = IDPiatto
			WHERE FatturaTA = F
			) A
	);
	
	SET @Sede = (
		SELECT Sede
		FROM FATTURATA
		WHERE IDFatturaTA = F);

	UPDATE FATTURATA
	SET Prezzo = @Conto, DataEmissione = CURRENT_TIMESTAMP, StatoConto = "Chiuso", MetodoPagamento = "Contanti"
	WHERE IDFatturaTA = F;
	
	CALL FindPony(F,@Sede);

END //
DELIMITER ;

/* CERCA PONY ED INVIA L'ORDINE */
/* Si cerca il primo pony disponibile per spedire la merce */
DROP PROCEDURE IF EXISTS FindPony;
DELIMITER //
CREATE PROCEDURE FindPony(IN F INT, IN S VARCHAR(255))
BEGIN
	
	SET @e = (SELECT COUNT(*)
			FROM PONY
			WHERE StatoPony = "Libero" AND Sede = S);
	
	IF @e > 0 THEN 
		SET @Pony = (SELECT IDPony
					FROM PONY
					WHERE StatoPony = "Libero" AND Sede = S
					LIMIT 1);
		
		UPDATE PONY
		SET StatoPony = "Occupato"
		WHERE IDPony = @Pony;
	
		UPDATE FATTURATA
		SET Pony = @Pony, 
			ConsegnaalPony = CURRENT_TIMESTAMP, 
			Arrivo = CURRENT_TIMESTAMP + INTERVAL 10*RAND() MINUTE,
			Rientro = CURRENT_TIMESTAMP + INTERVAL 10 + 10*RAND() MINUTE			
		WHERE IDFatturaTA = F;
	END IF;	
	
END //
DELIMITER ;

/* CERCA CONTI TA IN STATO CHIUSO ED INVIA PONY */
/* Se, al momento della chiusura del conto, non vi erano pony disponibili, allora
 un event controlla periodicamente questi conti, ed appena vi è un pony libero fa partire la consegna */
DROP PROCEDURE IF EXISTS SendPony;
DELIMITER //
CREATE PROCEDURE SendPony()
BEGIN
	SET @e = (SELECT COUNT(*)
			FROM FATTURATA
			WHERE StatoConto = "Chiuso" AND ConsegnaalPony IS NULL);
			
	IF @e > 0 THEN
		SET @Sede = (SELECT Sede
					FROM FATTURATA
					WHERE StatoConto = "Chiuso" AND ConsegnaalPony IS NULL
					LIMIT 1);
	END IF;
	
	SET @Pony = (SELECT COUNT(IDPony)
					FROM PONY
					WHERE StatoPony = "Libero" AND Sede = @Sede);
	
	IF @e > 0 AND @Pony > 0 THEN
		SET @F = (SELECT IDFatturaTA
				FROM FATTURATA
				WHERE StatoConto = "Chiuso" AND ConsegnaalPony IS NULL AND Sede = @Sede
				LIMIT 1);
				
		SET @Pony = (SELECT IDPony
					FROM PONY
					WHERE StatoPony = "Libero" AND Sede = @Sede
					LIMIT 1);
		
		UPDATE PONY
		SET StatoPony = "Occupato"
		WHERE IDPony = @Pony;
	
		UPDATE FATTURATA
		SET Pony = @Pony, 
			ConsegnaalPony = CURRENT_TIMESTAMP, 
			Arrivo = CURRENT_TIMESTAMP + INTERVAL 10*RAND() MINUTE,
			Rientro = CURRENT_TIMESTAMP + INTERVAL 10 + 10*RAND() MINUTE			
		WHERE IDFatturaTA = @F;		
	END IF;

END //
DELIMITER ;

/* CONTROLLO PONY */
/* Event - Controlla se ci sono pony in stato "occupato" e se sono tornati li libera */
DROP PROCEDURE IF EXISTS CheckPony;
DELIMITER //
CREATE PROCEDURE CheckPony()
BEGIN
	
	DECLARE e INT DEFAULT 0;
	DECLARE Pon VARCHAR(10);
	DECLARE Rientr TIMESTAMP;
	
	DECLARE PC CURSOR FOR
		SELECT IDPony, MAX(Rientro) AS Rientro
		FROM PONY INNER JOIN FatturaTA ON IDPony = Pony
		WHERE StatoPony = "Occupato" AND Rientro IS NOT NULL
		GROUP BY IDPony
		ORDER BY Rientro DESC;
		
	DECLARE CONTINUE HANDLER FOR NOT FOUND
	SET e = 1;
	
	OPEN PC;
		
	ciclo: LOOP
		FETCH PC INTO Pon, Rientr;
		IF e = 1 THEN
			LEAVE ciclo;
		END IF;
		IF Rientr < CURRENT_TIMESTAMP THEN
			UPDATE PONY
			SET StatoPony = "Libero"
			WHERE IDPony = Pon;
		END IF;
	END LOOP;
	
	CLOSE PC;
	
END //
DELIMITER ;

/* CONTROLLO PRENOTAZIONI */
/* Aggiorna stato prenotazione */
DROP PROCEDURE IF EXISTS CheckPrenotazioni;
DELIMITER //
CREATE PROCEDURE CheckPrenotazioni()
BEGIN

	UPDATE PRENOTAZIONE
	SET StatoPrenotazione = "Modificabile"
	WHERE StatoPrenotazione = "Attesa";
	
	UPDATE PRENOTAZIONE
	SET StatoPrenotazione = "Confermata"
	WHERE StatoPrenotazione = "Modificabile" 
		AND DataeOra < CURRENT_TIMESTAMP + INTERVAL 2 DAY AND (Tipo <> "Evento" OR Tipo <> "Festa" OR Tipo IS NULL);

END //
DELIMITER ;

/* MODIFICA/ELIMINA PRENOTAZIONE */
DROP PROCEDURE IF EXISTS EditPrenotazione;
DELIMITER //
CREATE PROCEDURE EditPrenotazione(IN idp INT,IN DataOra TIMESTAMP,IN tele VARCHAR(10),IN Info VARCHAR(255),IN remove BOOLEAN)
BEGIN
	SET @e = (
		SELECT StatoPrenotazione
        FROM PRENOTAZIONE
        WHERE IDPrenotazione = idp);
	
    IF @e = "Confermata" THEN
		SIGNAL SQLSTATE '45000'
		SET MESSAGE_TEXT = "Prenotazione confermata! Impossibile modificare!";
    END IF;
    
	IF remove = 1 THEN
		DELETE FROM PRENOTAZIONE
		WHERE IDPrenotazione = idp;
		DELETE FROM POSIZIONE /* LIBERO I TAVOLI */
		WHERE Prenotazione = idp;
		SELECT "Prenotazione eliminata!";
	END IF;
	IF remove = 0 THEN
		IF DataOra IS NOT NULL AND DataOra < CURRENT_TIMESTAMP THEN
			SIGNAL SQLSTATE '45000'
			SET MESSAGE_TEXT = "Data e ora prenotazione non corretta!";
		END IF;
		
		IF DataOra IS NOT NULL THEN
			UPDATE PRENOTAZIONE
			SET DataeOra = DataOra
			WHERE IDPrenotazione = idp;
		END IF;
		
		IF tele IS NOT NULL THEN
			UPDATE PRENOTAZIONE
			SET Telefono = tele
			WHERE idp = IDPrenotazione;
		END IF;
		
		IF Info IS NOT NULL THEN
			UPDATE PRENOTAZIONE
			SET Informazioni = Info
			WHERE idp = IDPrenotazione;
		END IF;
		SELECT "Prenotazione modificata!";
	END IF;
	
END //
DELIMITER ;

/* MODIFICA/ELIMINA SERVIZIO */
DROP PROCEDURE IF EXISTS EditServizio;
DELIMITER //
CREATE PROCEDURE EditServizio(IN IDC INT, IN IDS INT, IN IDP VARCHAR(10), IN QUAN INT, IN DEL BOOLEAN)
BEGIN

	SET @StatoComanda = (
		SELECT StatoComanda 
		FROM COMANDA
		WHERE IDComanda = IDC
		);
		
	IF @StatoComanda = "Nuova" AND DEL = 0 THEN
		UPDATE SERVIZIO
		SET NomePiatto = IDP, Quantita = QUAN
		WHERE IDServizio = IDS;
		DELETE FROM RICHIESTA /* ELIMINA VARIAZIONI PER IL PIATTO PRECEDENTE */
		WHERE Servizio = IDS;
	END IF;
	IF @StatoComanda = "Nuova" AND DEL = 1 THEN
		DELETE FROM SERVIZIO
		WHERE IDServizio = IDS;
		DELETE FROM RICHIESTA
		WHERE Servizio = IDS;
		SET @Cont = ( /* SE LA COMANDA NON FASE PIU' SERVIZI, LA SI PUO' ELIMINARE */
			SELECT COUNT(IDServizio)
			FROM SERVIZIO
			WHERE Comanda = IDC
		);
		IF @Cont = 0 THEN
			DELETE FROM COMANDA
			WHERE IDComanda = IDC;
		END IF;
	END IF;
	
	IF @StatoComanda <> "Nuova" THEN
		SELECT "Comanda in preparazione! Impossibile modificare!";
	END IF;

END //
DELIMITER ;

/* CONTROLLO QUANTITA' CONFEZIONI AL MOMENTO DELL'ORDINAZIONE DEL CLIENTE */
/* Se il contenuto delle confezioni non è sufficiente non è possibile inserire il servizio richiesto dalla comanda */
DROP PROCEDURE IF EXISTS ConfezioneCheck;
DELIMITER //
CREATE PROCEDURE ConfezioneCheck(IN NomeSede varchar(50), IN NomeDelPiatto varchar(50), IN NumeroPiatti INT)
BEGIN
	
	DECLARE I VARCHAR(255);
	DECLARE PESMAX FLOAT;
	DECLARE MAG VARCHAR(255);
	
	DECLARE CON INT;
	DECLARE PES FLOAT;
	DECLARE ING VARCHAR(50);
	DECLARE ASP VARCHAR(50); /* ASPETTO */
    
    DECLARE DOS FLOAT;
    DECLARE INGRED VARCHAR(50);
	DECLARE RNP VARCHAR(50); /* RUOLO NEL PIATTO */
	
	DECLARE CON1 INT;
	DECLARE PES1 FLOAT;
	
	DECLARE CONT FLOAT DEFAULT 0;
	
	DECLARE e INT DEFAULT 0;

	DECLARE CIngredienti CURSOR FOR
		SELECT Ingrediente, Dose, RuoloNelPiatto
        FROM PROCEDIMENTO
		WHERE Piatto = NomeDelPiatto AND Ingrediente IS NOT NULL AND Dose IS NOT NULL AND RuoloNelPiatto IS NOT NULL;
		
	DECLARE CConfezioni CURSOR FOR
		SELECT IDConfezione, O.Ingrediente, Peso
		FROM CONFEZIONE INNER JOIN ORDINE O ON IDOrdine = Ordine
			INNER JOIN RIFORNIMENTO R ON R.Magazzino = O.Magazzino
			INNER JOIN PROCEDIMENTO PR ON PR.Ingrediente = O.Ingrediente
		WHERE Sede = NomeSede AND Piatto = NomeDelPiatto AND Dose IS NOT NULL
		ORDER BY Stato DESC; /* ORDINATO IN MODO DESC PER UTILIZZARE PRIMA LE CONFEZIONI IN STATO "PARZIALE" */
		
	DECLARE CQuantita CURSOR FOR
		SELECT O.Ingrediente,SUM(Peso), C.Aspetto
		FROM CONFEZIONE C INNER JOIN ORDINE O ON IDOrdine = Ordine
			INNER JOIN RIFORNIMENTO R ON R.Magazzino = O.Magazzino
			INNER JOIN PROCEDIMENTO PR ON PR.Ingrediente = O.Ingrediente
		WHERE Sede = "SA1" AND Piatto = "PI10" AND Dose IS NOT NULL
		GROUP BY O.Ingrediente, RuoloNelPiatto
        ORDER BY Aspetto DESC; /* RIORDINO IN BASE ALL'ASPETTO; SE HO TUTTI GLI INGREDIENTI "BUONO", IN CIMA APPARIRA' BUONO, ALTRIMENTI ROVINATO */
        
	DECLARE CONTINUE HANDLER FOR
	NOT FOUND SET e = 1;
    
	/* CONTROLLO SE CI SONO GLI INGREDIENTI IN QUANTITA' NECESSARIA */
    OPEN CIngredienti;
	ciclo: LOOP
		FETCH CIngredienti INTO INGRED, DOS, RNP;
		IF e = 1 THEN
			LEAVE ciclo;
		END IF;
		OPEN CQuantita;
		ciclosp: LOOP
			FETCH CQuantita INTO I, PESMAX, ASP;
			IF RNP = "Secondario" THEN 
				IF e = 1 THEN
					SIGNAL SQLSTATE '45000'
					SET MESSAGE_TEXT = "Confezioni non presenti! Ordinare un altro piatto!";
				END IF;
				IF PESMAX < DOS*NumeroPiatti AND INGRED = I THEN
					SIGNAL SQLSTATE '45000'
					SET MESSAGE_TEXT = "Errore! Ingredienti non sufficienti per preparare il piatto! Cambiare piatto!";
				END IF;
				IF INGRED = I AND PESMAX >= DOS*NumeroPiatti THEN
					LEAVE ciclosp;
				END IF;
			END IF;
			IF RNP = "Primario" THEN
				IF e = 1 THEN
					SIGNAL SQLSTATE '45000'
					SET MESSAGE_TEXT = "Confezioni non presenti! Ordinare un altro piatto!";
				END IF;
				IF PESMAX < DOS*NumeroPiatti AND INGRED = I AND ASP = "Buono" THEN
					SIGNAL SQLSTATE '45000'
					SET MESSAGE_TEXT = "Errore! Ingredienti non sufficienti per preparare il piatto! Cambiare piatto!";
				END IF;
				IF INGRED = I AND PESMAX >= DOS*NumeroPiatti AND ASP = "Buono" THEN
					LEAVE ciclosp;
				END IF;
			END IF;
		END LOOP ciclosp;
		CLOSE CQuantita;
	END LOOP ciclo;
	CLOSE CIngredienti;
    
	SET e = 0;
    
	/* INIZIO A SVUOTARE LE CONFEZIONI DEGLI INGREDIENTI */
	OPEN CIngredienti;
	ciclo: LOOP
		FETCH CIngredienti INTO INGRED, DOS, RNP;
		IF e = 1 THEN
			LEAVE ciclo;
		END IF;
		OPEN CQuantita;
		ciclosp: LOOP
			FETCH CQuantita INTO I, PESMAX, ASP;
			
			IF INGRED = I AND PESMAX >= DOS*NumeroPiatti THEN
				IF RNP <> "Primario" THEN 
					IF PESMAX = DOS*NumeroPiatti THEN
						SET MAG = (
									SELECT Magazzino
									FROM RIFORNIMENTO
									WHERE Sede = NomeSede
									LIMIT 1
								);
						INSERT INTO ORDINE (`Ingrediente`, `Magazzino`, `DataAcquisto`, `DataArrivo`, `Prezzo`, `Quantita`)
						VALUES (I,MAG,CURRENT_DATE,CURRENT_DATE+INTERVAL 3 DAY,20,20);
					END IF;
                    LEAVE ciclosp;
				END IF;
                IF RNP = "Primario" THEN
					IF ASP = "Buono" THEN
						LEAVE ciclosp;
                    END IF;
                END IF;
			END IF;
		END LOOP ciclosp;
		CLOSE CQuantita;
		OPEN CConfezioni;
		ciclo1: LOOP
			FETCH CConfezioni INTO CON, ING, PES;
           	IF CONT = DOS*NumeroPiatti THEN
				LEAVE ciclo1;
			END IF;
			IF e = 1 THEN
				SIGNAL SQLSTATE '45000'
				SET MESSAGE_TEXT = "Errore!";
			END IF;
			IF PES >= (DOS*NumeroPiatti - CONT) AND INGRED = ING THEN
				UPDATE CONFEZIONE
				SET Peso = Peso - DOS*NumeroPiatti, Stato = "Parziale"
				WHERE IDConfezione = CON;
                SET PES = (
					SELECT Peso
					FROM CONFEZIONE
					WHERE IDConfezione = CON);
				IF PES = 0 THEN
					DELETE FROM CONFEZIONE
					WHERE IDConfezione = CON;
                END IF;
				LEAVE ciclo1;
			END IF;
			IF PES < (DOS*NumeroPiatti - CONT) AND INGRED = ING THEN
				DELETE FROM CONFEZIONE
				WHERE IDConfezione = CON;
				SET CONT = PES+CONT;
			END IF;
		END LOOP ciclo1;
		CLOSE CConfezioni;
		SET CONT = 0;
	END LOOP ciclo;
	
	CLOSE CIngredienti;
	
END //
DELIMITER ;

/* ORDINE ARRIVATO! INSERIRE CONFEZIONE! */
DROP PROCEDURE IF EXISTS OrdineCheck;
DELIMITER //
CREATE PROCEDURE OrdineCheck()
BEGIN

	DECLARE IDORD INT;
	DECLARE Q INT; /* QUANTITA' */
	DECLARE NTC FLOAT; /* NETTO CONFEZIONE */
	DECLARE MAG VARCHAR(255);
	DECLARE LOTTO INT;
	DECLARE STATOCONFEZ VARCHAR(255);
	
	DECLARE CONT INT DEFAULT 0;
	DECLARE e INT DEFAULT 0;

	DECLARE COrdine CURSOR FOR
		SELECT IDOrdine, Quantita, NettoConfezione
		FROM ORDINE
		WHERE DataArrivo = CURRENT_DATE;
		
	DECLARE CONTINUE HANDLER FOR
	NOT FOUND SET e = 1;
    
    OPEN COrdine;
	
	ciclo: LOOP
		FETCH COrdine INTO IDORD, Q, NTC;
		IF e = 1 THEN
			LEAVE ciclo;
		END IF;
		SET CONT = 0;
		ciclo1: LOOP
			IF CONT = Q THEN
				LEAVE ciclo1;
			END IF;
			SET LOTTO = 1000*RAND();
			IF 10*RAND() >= 2 THEN
				SET STATOCONFEZ = "Buono";
			ELSE
				SET STATOCONFEZ = "Rovinato";
			END IF;
			INSERT INTO `CONFEZIONE` (`Ordine`, `Locazione`, `Aspetto`, `Stato`, `Peso`, `DataScadenza`, `Cod. lotto`) VALUES 
			(IDORD,'A',STATOCONFEZ,'Completa',NTC,CURRENT_DATE + INTERVAL 1 YEAR,CONCAT('L',LOTTO));
			SET CONT = CONT + 1;
		END LOOP ciclo1;
	END LOOP ciclo;
    
    CLOSE COrdine;

END //
DELIMITER ;

/* CONTROLLAMACCHINE */
/* SCATTA OGNI MINUTO */
/* NON CORRETTO AL 100 */
/*DROP PROCEDURE IF EXISTS MacchinaCheck;
DELIMITER //
CREATE PROCEDURE MacchinaCheck(IN NomePiatto VARCHAR(50),IN ts timestamp, IN NomeSede VARCHAR(50))
BEGIN

	CREATE TABLE

	DECLARE ATT VARCHAR(50);
	DECLARE DUR INT;
	DECLARE e INT DEFAULT 0;

	DECLARE CProcedimento CURSOR FOR
		SELECT Attrezzo,Durata
		FROM PROCEDIMENTO P INNER JOIN ATTREZZO A ON A.Attrezzo = P.Attrezzo
		WHERE Piatto = NomePiatto AND Attrezzo IS NOT NULL;
		
	DECLARE CONTINUE HANDLER FOR
	NOT FOUND SET e = 1;
	
	ciclo: LOOP
		FETCH CProcedimento INTO ATT, DUR;
		
	END LOOP ciclo;

END //
DELIMITER ;*/

/*
 * ###############################################################################################
 * ANALITYCS
 */
 
/* 1 */
CREATE OR REPLACE VIEW STIMA AS
	SELECT O.Ingrediente AS ING, SUM(Peso) AS PesoTotale, C.Aspetto, Sede, AVG(Dose) AS QuantitaMediaRichiesta, (
		SELECT DISTINCT COUNT(IDServizio)
		FROM SERVIZIO INNER JOIN PROCEDIMENTO ON Piatto = NomePiatto
		WHERE DOSE IS NOT NULL AND Ingrediente = ING
	) AS RichiesteTotali
	FROM CONFEZIONE C INNER JOIN ORDINE O ON IDOrdine = Ordine
		INNER JOIN RIFORNIMENTO R ON R.Magazzino = O.Magazzino
		INNER JOIN PROCEDIMENTO PR ON PR.Ingrediente = O.Ingrediente
		INNER JOIN PIATTO ON IDPiatto = Piatto
	WHERE Dose IS NOT NULL
	GROUP BY O.Ingrediente, RuoloNelPiatto, Sede
    ORDER BY Aspetto, DataScadenza DESC;

CREATE OR REPLACE VIEW Percentuale AS
	SELECT ING AS Ingrediente, Aspetto, Sede, PesoTotale*RichiesteTotali AS QuantitaNecessaria, QuantitaMediaRichiesta, PesoTotale/(PesoTotale*RichiesteTotali) AS PerCento
	FROM STIMA;

CREATE OR REPLACE VIEW FILTRO AS
	SELECT *
	FROM Percentuale
	WHERE PerCento >= 5 AND PerCento >= QuantitaMediaRichiesta; /* 60 */

/* PIATTI CONSIGLIATI PER OGNI SEDE DA INSERIRE NEL MENU' */
DROP PROCEDURE IF EXISTS TipPiatto;
DELIMITER //
CREATE PROCEDURE TipPiatto()
BEGIN

	SELECT Sede, Piatto
	FROM (
		SELECT Piatto, Sede
		FROM PIATTO INNER JOIN PROCEDIMENTO P ON Piatto = IDPiatto
			INNER JOIN FILTRO F ON P.Ingrediente = F.Ingrediente
			WHERE DOSE IS NOT NULL AND RuoloNelPiatto = "Primario"
			GROUP BY IDPiatto, Sede
		UNION ALL
		SELECT Sede, Piatto
		FROM RECENSIONE
		WHERE NumeroVoti > (SELECT (COUNT(IDAccount)-1)/10
							FROM ACCOUNT)
			AND Accuratezza/NumeroVoti > 3 AND Veridicita/NumeroVoti > 3 AND Piatto IS NOT NULL
	) A
	GROUP BY Sede, Piatto;

END //
DELIMITER ;

/* 2 */
/* MIGLIORI VARIAZIONI CONSIGLIATE DAI CLIENTI */
DROP PROCEDURE IF EXISTS AnalisiVariazioni;
DELIMITER //
CREATE PROCEDURE AnalisiVariazioni(IN OGGI DATE, IN IERI DATE)
BEGIN

	IF IERI > OGGI THEN
		SIGNAL SQLSTATE '45000'
		SET MESSAGE_TEXT = "Errore! Data non valida!";
	END IF;

	SELECT IDNuovoPiatto, Testo
	FROM NUOVOPIATTO
	WHERE NumeroVoti > (SELECT (COUNT(IDAccount)-1)/3
						FROM ACCOUNT)
		AND VotoPiatto/NumeroVoti > 3 AND Nome IS NULL
		AND DataeOra BETWEEN IERI AND OGGI;

END //
DELIMITER ;
	
/* MIGLIORI NUOVI PIATTI CONSIGLIATI DAI CLIENTI */
DROP PROCEDURE IF EXISTS AnalisiNuoviPiatti;
DELIMITER //
CREATE PROCEDURE AnalisiNuoviPiatti(IN OGGI DATE, IN IERI DATE)
BEGIN

	IF IERI > OGGI THEN
		SIGNAL SQLSTATE '45000'
		SET MESSAGE_TEXT = "Errore! Data non valida!";
	END IF;

	SELECT IDNuovoPiatto, Nome, Testo
	FROM NUOVOPIATTO
	WHERE NumeroVoti > (SELECT (COUNT(IDAccount)-1)/3
						FROM ACCOUNT)
		AND VotoPiatto/NumeroVoti > 3 AND Nome IS NOT NULL
		AND DataeOra BETWEEN IERI AND OGGI;
		
END //
DELIMITER ;

/* MIGLIORI PIATTI RECENSITI */
DROP PROCEDURE IF EXISTS AnalisiPiattiRecensiti;
DELIMITER //
CREATE PROCEDURE AnalisiPiattiRecensiti(IN OGGI DATE, IN IERI DATE)
BEGIN

	IF IERI > OGGI THEN
		SIGNAL SQLSTATE '45000'
		SET MESSAGE_TEXT = "Errore! Data non valida!";
	END IF;

	SELECT DISTINCT Sede, Piatto
	FROM RECENSIONE
	WHERE NumeroVoti > (SELECT (COUNT(IDAccount)-1)/10
						FROM ACCOUNT)
		AND Accuratezza/NumeroVoti > 3 AND Veridicita/NumeroVoti > 3 AND Piatto IS NOT NULL AND Voto > 7
		AND DataeOra BETWEEN IERI AND OGGI;
		
END //
DELIMITER ;
	
/* ANALISI PIATTO SEDE PER SEDE */
DROP PROCEDURE IF EXISTS AnalisiPiatto;
DELIMITER //
CREATE PROCEDURE AnalisiPiatto(IN Piat VARCHAR(10), IN OGGI DATE, IN IERI DATE)
BEGIN

	IF IERI > OGGI THEN
		SIGNAL SQLSTATE '45000'
		SET MESSAGE_TEXT = "Errore! Data non valida!";
	END IF;

	SELECT Sede, SUM(Quantita) AS Quantita
	FROM (
		SELECT Sede, SUM(Quantita) AS Quantita
		FROM FATTURA INNER JOIN COMANDA ON Fattura = IDFattura
			INNER JOIN SERVIZIO ON Comanda = IDComanda
		WHERE NomePiatto = Piat AND DataEmissione BETWEEN IERI AND OGGI
		GROUP BY Sede
		UNION ALL
		SELECT Sede, SUM(Quantita) AS Quantita
		FROM FATTURATA INNER JOIN COMANDATA ON FatturaTA = IDFatturaTA
			INNER JOIN SERVIZIOTA ON ComandaTA = IDComandaTA
		WHERE NomePiatto = Piat AND DataEmissione BETWEEN IERI AND OGGI
		GROUP BY Sede
		) A
	GROUP BY Sede;

END //
DELIMITER ;
		
/* PIATTI PREFERITI SEDE PER SEDE */
DROP PROCEDURE IF EXISTS AnalisiPiattiPreferiti;
DELIMITER //
CREATE PROCEDURE AnalisiPiattiPreferiti(IN IERI DATE, IN OGGI DATE)
BEGIN

	IF IERI > OGGI THEN
		SIGNAL SQLSTATE '45000'
		SET MESSAGE_TEXT = "Errore! Data non valida!";
	END IF;

	SELECT Sede, NomePiatto, OrdinazionePerPiatto, OrdinazionePerPiatto*Prezzo Guadagno
	FROM(
		SELECT Sede, SUM(Quantita) OrdinazionePerPiatto, NomePiatto
		FROM FATTURA INNER JOIN COMANDA ON Fattura = IDFattura
			INNER JOIN SERVIZIO ON Comanda = IDComanda
		WHERE DataEmissione BETWEEN IERI AND OGGI
		) A INNER JOIN PIATTO ON NomePiatto = IDPiatto
	GROUP BY Sede
	ORDER BY OrdinazionePerPiatto DESC;

END //
DELIMITER ;

/* 3 */
/* PREPARA ORDINI */
CREATE OR REPLACE VIEW Ordinazione AS
	SELECT IDServizio, Sede, Quantita, NomePiatto
	FROM FATTURA INNER JOIN COMANDA ON IDFattura = Fattura
		INNER JOIN SERVIZIO ON IDComanda = Comanda
		INNER JOIN PIATTO ON NomePiatto = IDPiatto
	WHERE DataEmissione > CURRENT_DATE - INTERVAL 7 DAY
		AND StatoConto = "Chiuso";
		
CREATE OR REPLACE VIEW OrdinazioneTA AS
	SELECT IDServizioTA, Sede, Quantita, NomePiatto
	FROM FATTURATA INNER JOIN COMANDATA ON IDFatturaTA = FatturaTA
		INNER JOIN SERVIZIOTA ON IDComandaTA = ComandaTA
		INNER JOIN PIATTO ON NomePiatto = IDPiatto
	WHERE DataEmissione > CURRENT_DATE - INTERVAL 7 DAY
		AND StatoConto = "Chiuso";

CREATE OR REPLACE VIEW ConsumoVariazione AS
	SELECT Sede, Quantita, Ingrediente, Dose
	FROM Ordinazione LEFT OUTER JOIN RICHIESTA ON IDServizio = Servizio
		INNER JOIN VARIAZIONE V ON IDVariazione = Variazione
	WHERE Dose IS NOT NULL AND Ingrediente IS NOT NULL;
	
CREATE OR REPLACE VIEW ConsumoVariazioneTA AS
	SELECT Sede, Quantita, Ingrediente, Dose
	FROM OrdinazioneTA LEFT OUTER JOIN RICHIESTATA ON IDServizioTA = ServizioTA
		INNER JOIN VARIAZIONE V ON IDVariazione = Variazione
	WHERE Dose IS NOT NULL AND Ingrediente IS NOT NULL;
	
CREATE OR REPLACE VIEW O1 AS 
	SELECT IDServizio, IDps, Sede, Quantita, Ingrediente, Dose
    FROM Ordinazione INNER JOIN PROCEDIMENTO ON Piatto = NomePiatto;
    
CREATE OR REPLACE VIEW O2 AS 
	SELECT IDServizio, IDps, IDVariazione
	FROM Ordinazione INNER JOIN RICHIESTA ON IDServizio = Servizio
    INNER JOIN VARIAZIONE ON IDVariazione = Variazione
	INNER JOIN PROCEDIMENTO P ON IDps = Procedimento;    
        
CREATE OR REPLACE VIEW Consumo AS
SELECT Sede, Quantita, O1.Ingrediente, Dose
	FROM O1 LEFT OUTER JOIN O2 ON O1.IDps = O2.IDps AND O1.IDServizio = O2.IDServizio
    WHERE O2.IDps IS NULL AND O1.Dose IS NOT NULL AND O1.Ingrediente IS NOT NULL;
	
CREATE OR REPLACE VIEW OT1 AS 
	SELECT IDServizioTA, IDps, Sede, Quantita, Ingrediente, Dose
    FROM OrdinazioneTA INNER JOIN PROCEDIMENTO ON Piatto = NomePiatto;
    
CREATE OR REPLACE VIEW OT2 AS 
	SELECT IDServizioTA, IDps, IDVariazione
	FROM OrdinazioneTA INNER JOIN RICHIESTATA ON IDServizioTA = ServizioTA
    INNER JOIN VARIAZIONE ON IDVariazione = Variazione
	INNER JOIN PROCEDIMENTO P ON IDps = Procedimento;    
        
CREATE OR REPLACE VIEW ConsumoTA AS
SELECT Sede, Quantita, OT1.Ingrediente, Dose
	FROM OT1 LEFT OUTER JOIN OT2 ON OT1.IDps = OT2.IDps AND OT1.IDServizioTA = OT2.IDServizioTA
    WHERE OT2.IDps IS NULL AND OT1.Dose IS NOT NULL AND OT1.Ingrediente IS NOT NULL;

CREATE OR REPLACE VIEW Consumazione AS
	SELECT Sede, Quantita*Dose AS Consumo, Ingrediente
	FROM Consumo 
	UNION ALL
	SELECT Sede, Quantita*Dose AS Consumo, Ingrediente
	FROM ConsumoTA
	UNION ALL
	SELECT Sede, Quantita*Dose AS Consumo, Ingrediente
	FROM ConsumoVariazione
	UNION ALL
	SELECT Sede, Quantita*Dose AS Consumo, Ingrediente
	FROM ConsumoVariazioneTA;

CREATE OR REPLACE VIEW EditConsumazione AS
	SELECT Sede, Ingrediente, SUM(Consumo) AS Totale
	FROM Consumazione
	GROUP BY Sede, Ingrediente;

CREATE OR REPLACE VIEW ControlloIngredienti AS
	SELECT R.Sede, Nome AS Ingrediente, SUM(Peso) PesoConfezioniTotale, O.Magazzino, Totale AS ConsumoTotale 
	FROM EditConsumazione E INNER JOIN INGREDIENTE ON Ingrediente = Nome
		INNER JOIN ORDINE O ON O.Ingrediente = Nome 
		INNER JOIN MAGAZZINO ON Magazzino = IDMagazzino
		INNER JOIN RIFORNIMENTO R ON E.Sede = R.Sede
		LEFT OUTER JOIN CONFEZIONE C ON IDOrdine = Ordine
	GROUP BY Nome, Sede, O.Magazzino;

DROP PROCEDURE IF EXISTS DoOrder;
DELIMITER //
CREATE PROCEDURE DoOrder()
BEGIN

	DECLARE e INT DEFAULT 0;
	DECLARE ING VARCHAR(255);
	DECLARE QUAN FLOAT;
	DECLARE SED VARCHAR(255);
	DECLARE MAG VARCHAR(255);

	DECLARE OP CURSOR FOR	
		SELECT Ingrediente, ConsumoTotale, Sede
		FROM ControlloIngredienti
		WHERE PesoConfezioniTotale < ConsumoTotale;
		
	DECLARE CONTINUE HANDLER FOR NOT FOUND
	SET e = 1;

	ciclo: LOOP
		FETCH OP INTO ING, QUAN, SED;
		IF e = 1 THEN
			LEAVE ciclo;
		END IF;
		SET MAG = (SELECT Magazzino
				FROM RIFORNIMENTO
				WHERE Sede = SED
				LIMIT 1);
		INSERT INTO ORDINE (Ingrediente,Magazzino,DataAcquisto,DataArrivo,Prezzo,Quantita,NettoConfezione) VALUES 
			(ING,MAG,CURRENT_DATE,CURRENT_DATE+INTERVAL 3 DAY,"10",QUAN*3/2);
	END LOOP;

END //
DELIMITER ;

DROP PROCEDURE IF EXISTS DayOrder;
DELIMITER //
CREATE PROCEDURE DayOrder(IN Mag VARCHAR)
BEGIN
	INSERT INTO ORDINE (Ingrediente,Magazzino,DataAcquisto,DataArrivo,Prezzo,Quantita,NettoConfezione)VALUES
		("Pane",Mag,CURRENT_DATE,CURRENT_DATE+INTERVAL 3 DAY,5,10,1),
		("Sale",Mag,CURRENT_DATE,CURRENT_DATE+INTERVAL 3 DAY,5,10,1),
		("Zucchero",Mag,CURRENT_DATE,CURRENT_DATE+INTERVAL 3 DAY,5,10,1),
		("Olio",Mag,CURRENT_DATE,CURRENT_DATE+INTERVAL 3 DAY,5,10,1);
END //
DELIMITER ;