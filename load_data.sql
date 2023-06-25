LOAD DATA INFILE 'test/locations.csv' 
INTO TABLE STANDORT
FIELDS TERMINATED BY ',' LINES TERMINATED BY '\r\n'(PLZ, Stadt, Strasse, Sammelpunkt);


LOAD DATA INFILE 'test/Kunden.csv' 
INTO TABLE KUNDE
FIELDS TERMINATED BY ',' LINES TERMINATED BY '\r\n'
(Nachname, Vorname, EmailAdress, Mobilnummer, Geschlecht, LetzteNutzung, Inaktiv, KKontoID, WohnortID);
