/* 1 */
SELECT Sede, Nome, COUNT(*) AS NumVariazioni
FROM SERVIZIO INNER JOIN RICHIESTA ON IDServizio = Servizio
	INNER JOIN PIATTO ON IDPiatto = NomePiatto
    INNER JOIN COMANDA ON IDComanda = Comanda
    INNER JOIN FATTURA ON IDFattura = Fattura
WHERE StatoConto = "Chiuso" AND DataEmissione >= DataEmissione - INTERVAL 14 DAY
GROUP BY NomePiatto,Sede
HAVING COUNT(*) >= 5; 

/* 2 */
SELECT DISTINCT *
FROM (
	SELECT NomePiatto
	FROM COMANDA INNER JOIN SERVIZIO ON IDComanda = Comanda
	WHERE DataeOra >= CURRENT_TIMESTAMP - INTERVAL 7 DAY
	GROUP BY NomePiatto
	HAVING COUNT(*) = (
		SELECT MAX(Ordinazioni)
		FROM(
			SELECT COUNT(*) AS Ordinazioni
			FROM COMANDA INNER JOIN SERVIZIO ON IDComanda = Comanda
			WHERE DataeOra >= CURRENT_TIMESTAMP - INTERVAL 7 DAY
			GROUP BY NomePiatto
			) AS A
	)
	UNION ALL
	SELECT NomePiatto
	FROM COMANDATA INNER JOIN SERVIZIOTA ON IDComandaTA = ComandaTA
	WHERE DataeOra >= CURRENT_TIMESTAMP - INTERVAL 7 DAY
	GROUP BY NomePiatto
	HAVING COUNT(*) = (
		SELECT MAX(OrdinazioniTA)
		FROM(
			SELECT COUNT(*) AS OrdinazioniTA
			FROM COMANDATA INNER JOIN SERVIZIOTA ON IDComandaTA = ComandaTA
			WHERE DataeOra >= CURRENT_TIMESTAMP - INTERVAL 7 DAY
			GROUP BY NomePiatto
			) AS B
	)
) C;

/* 3 */
SELECT Ingrediente, SUM(Consumo) Consumo
FROM (
	SELECT Ingrediente, SUM(Consumo) Consumo
	FROM (
		SELECT Ingrediente, Dose*Quantita Consumo
		FROM SERVIZIO S INNER JOIN PIATTO ON NomePiatto = IDPiatto
			INNER JOIN PROCEDIMENTO P ON NomePiatto = P.Piatto
		WHERE Dose IS NOT NULL AND Ingrediente IS NOT NULL
	) A
	GROUP BY Ingrediente
	UNION ALL 
	SELECT Ingrediente, SUM(Consumo) Consumo
	FROM (
		SELECT Ingrediente, Dose*Quantita Consumo
		FROM SERVIZIOTA S INNER JOIN PIATTO ON NomePiatto = IDPiatto
			INNER JOIN PROCEDIMENTO P ON NomePiatto = P.Piatto
		WHERE Dose IS NOT NULL AND Ingrediente IS NOT NULL
	) B
    GROUP BY Ingrediente
) C
GROUP BY Ingrediente;

/* 4 */
DROP PROCEDURE IF EXISTS SedeCheck;
DELIMITER //
CREATE PROCEDURE SedeCheck(IN Sed VARCHAR(10))
BEGIN

	/*SELECT IDPony Pony, TipoMezzo
	FROM PONY
	WHERE Sede = Sed;*/
	
	SELECT IDFatturaTA FatturaTA, Prezzo, MetodoPagamento, DataEmissione
	FROM FATTURATA
	WHERE Sede = Sed;
	
	SELECT IDFattura Fattura, Prezzo, MetodoPagamento, DataEmissione
	FROM FATTURA
	WHERE Sede = Sed;
	
	SELECT COUNT(*) AcquistiConAccount
	FROM ACCOUNT INNER JOIN FATTURATA ON Account = IDAccount
	WHERE Sede = Sed;
	
	SELECT "FatturaTA", SUM(Prezzo) Guadagno
	FROM FATTURATA
	WHERE Sede = Sed
	UNION ALL
	SELECT "Fattura", SUM(Prezzo) Guadagno
	FROM FATTURA
	WHERE Sede = Sed;

END //
DELIMITER ;

CALL SedeCheck("SA1");

/* 5 */
DROP PROCEDURE IF EXISTS ServCheck;
DELIMITER //
CREATE PROCEDURE ServCheck(IN Sed VARCHAR(255),IN P VARCHAR(50), IN Quantita INT, OUT Risposta BOOL)
BEGIN
	
	DECLARE e INT DEFAULT 0;
    DECLARE ING VARCHAR(50);
    DECLARE PESO FLOAT DEFAULT 0;
    DECLARE NECESSARIO FLOAT DEFAULT 0;

	DECLARE CP CURSOR FOR 
		SELECT A.Ingrediente, Peso Magazzino, Necessario
		FROM (
			SELECT Ingrediente, SUM(Peso) Peso
			FROM ORDINE O INNER JOIN INGREDIENTE I ON O.Ingrediente = I.Nome
				INNER JOIN MAGAZZINO ON IDMagazzino = O.Magazzino
				INNER JOIN RIFORNIMENTO R ON IDMagazzino = R.Magazzino
				INNER JOIN SEDE ON R.Sede = IDSede
				INNER JOIN CONFEZIONE ON IDOrdine = Ordine
			WHERE R.Sede = Sed
			GROUP BY Ingrediente
			) A INNER JOIN (
			SELECT P.Ingrediente, Dose*Quantita Necessario
			FROM PIATTO INNER JOIN PROCEDIMENTO P ON Piatto = IDPiatto
			WHERE Dose IS NOT NULL AND P.Ingrediente IS NOT NULL AND Nome = P
			GROUP BY Ingrediente, Dose) B ON A.Ingrediente = B.Ingrediente;
            
            
	
	DECLARE CONTINUE HANDLER FOR NOT FOUND
		SET e = 1;
    
	SET Risposta = 0;
    
    OPEN CP;
    
	ciclo: LOOP
		FETCH CP INTO ING,PESO,NECESSARIO;
		IF e = 1 THEN
			LEAVE ciclo;
		END IF;
		IF PESO < NECESSARIO THEN
			SET Risposta = 1;
			SET e = 1;
		END IF;
	END LOOP ciclo;
    
    CLOSE CP;
    
END //
DELIMITER ;

call servcheck("SA1","PI10",2,@Ris);
select @ris;

/* 6 */
DROP PROCEDURE IF EXISTS Magazzino_SedeCheck;
DELIMITER //
CREATE PROCEDURE Magazzino_SedeCheck(IN Sed VARCHAR(10))
BEGIN
	
	SELECT R.Magazzino, (SELECT COUNT(*)
						FROM ORDINE INNER JOIN CONFEZIONE ON Ordine = IDOrdine
						WHERE Magazzino = R.Magazzino) CapacitaAttuale, Capacita CapacitaMassima
	FROM SEDE INNER JOIN RIFORNIMENTO R ON Sede = IDSede 
		INNER JOIN MAGAZZINO ON Magazzino = IDMagazzino
	WHERE Sede = Sed;
	
	SELECT Ingrediente, Peso, Stato, DataAcquisto, DataScadenza
	FROM ORDINE O INNER JOIN CONFEZIONE ON Ordine = IDOrdine
		INNER JOIN RIFORNIMENTO R ON R.Magazzino = O.Magazzino
	WHERE Sede = Sed;
	
END //
DELIMITER ;

CALL Magazzino_SedeCheck("SA1");

/* 7 */
SELECT Nome, COUNT(*) PresenzaNeiMenu
FROM MENU INNER JOIN COMPOSIZIONE ON IDMenu = Menu 
	INNER JOIN PIATTO ON Piatto = IDPiatto
GROUP BY IDPiatto;

/* 8 */
SELECT IDAccount, AVG(Votazione) QualitaMediaNuoviPiatti
FROM (
	SELECT IDAccount, VotoPiatto/NumeroVoti Votazione
	FROM ACCOUNT INNER JOIN NUOVOPIATTO ON IDAccount = Account
	WHERE VotoPiatto <> 0
	GROUP BY IDAccount, NumeroVoti, VotoPiatto
	) A
GROUP BY IDAccount