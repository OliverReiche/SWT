LOAD DATA INFILE 'test/locations.csv' 
INTO TABLE STANDORT
FIELDS TERMINATED BY ',' LINES TERMINATED BY '\r\n'(PLZ, Stadt, Strasse, Sammelpunkt);
