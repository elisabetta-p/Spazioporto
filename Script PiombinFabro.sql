DROP DATABASE IF EXISTS SpazioportoPiombinFabro;

CREATE DATABASE SpazioportoPiombinFabro;

USE SpazioportoPiombinFabro;

/*per una creazione corretta delle tabelle, pulisco eventuale memoria*/

DROP TABLE IF EXISTS Mansioni;
DROP TABLE IF EXISTS Dipendenti;
DROP TABLE IF EXISTS Spazioporto;
DROP TABLE IF EXISTS Ali;
DROP TABLE IF EXISTS Portale;
DROP TABLE IF EXISTS Destinazione;
DROP TABLE IF EXISTS Acquisto;
DROP TABLE IF EXISTS Biglietto;
DROP TABLE IF EXISTS Assicurazione;
DROP TABLE IF EXISTS AziendeEsterne;

/*Ora creo le tabelle*/
create table Spazioporto (
  CodiceID int(1) primary key,
  Pianeta varchar(10)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

create table Mansioni (
  CodiceID int (2) primary key,
  Tipologia varchar(30),
  Spazioporto int(1),
  foreign key (Spazioporto) references Spazioporto(CodiceID)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

create table Dipendenti (
  IDNumber varchar(20) primary key,
  Turno int(2),
  Nome varchar(30) not null,
  Cognome varchar(30) not null,
  Stipendio int(8) not null,
  DataAssunzione date,
  foreign key (Turno) references Mansioni(CodiceID)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

create table AziendeEsterne (
  PartitaIVA bigint(11) primary key,
  Nome varchar(20),
  Costo int (8),
  Mansione int(2),
  foreign key (Mansione) references Mansioni(CodiceID)
)ENGINE=InnoDB DEFAULT CHARSET=utf8;

create table Ali (
  CodiceID int(1) primary key,
  Spazioporto int(1) ,
  foreign key (Spazioporto) references Spazioporto(CodiceID)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

create table Destinazione (
  IdDestinazione int(7) primary key,
  Pianeta varchar(30) not null,
  Luogo varchar(30) not null,
  Genere varchar(30)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

create table Portale (
	CodiceID int(3) primary key,
	Tipo varchar (20) not null,
	Sovrapprezzo int (4),
	FrequenzaApertura int(3) not null default 30,
	Destinazione int (7),
	DataP date not null default '2018-01-01', 
  	Ora time not null default '08:00:00',
  	Gate int(3),
  	Ala int(1),
    foreign key (Ala) references Ali(CodiceID),
    foreign key (Destinazione) references Destinazione(IdDestinazione)
)ENGINE=InnoDB DEFAULT CHARSET=utf8;

create table Assicurazione (
  Tipo int(1) primary key,
  Prezzo int (5),
  Descrizione varchar(500)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

create table Acquisto (
  IDAcquisto int(30) primary key,
  Tipo varchar(30),
  IDSpazioporto int(1),
  RecapitoViaggiatore varchar(50),
  Prezzo int(8),
  CheckIn boolean,
  Assicurazione int(1),
  foreign key (IDSpazioporto) references Spazioporto (CodiceID),
  foreign key (Assicurazione) references Assicurazione(Tipo)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

create table Biglietto (
  IDBiglietto bigint(10) primary key,
  NomeViaggiatore varchar(30) not null,
  CognomeViaggiatore varchar(30) not null,
  DataB date not null,
  Tipo char(1) not null,
  Destinazione int(7),
  Acquisto int(30),
  foreign key (Acquisto) references Acquisto(IDAcquisto),
  foreign key (Destinazione) references Destinazione(IdDestinazione)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;



/* PROCEDURE */

DROP PROCEDURE IF EXISTS CheckIn;
DROP PROCEDURE IF EXISTS TipoAcquisto;
DROP PROCEDURE IF EXISTS ControlloPortali;
DROP PROCEDURE IF EXISTS MansioneDipendenti;
DROP PROCEDURE IF EXISTS DisponibilitaDestinazione;
DROP PROCEDURE IF EXISTS AziendeEsterne;
DROP PROCEDURE IF EXISTS AumentoStipendi;

/*Fornisce Nome e Cognome dei viaggiatori che vanno nella stessa destinazione lo stesso giorno e devono fare il check-in. Destinazione e giorno sono date in input*/

delimiter $$
create procedure CheckIn(IN Dest int(7), IN Giorno date)
	begin
		select Nome, Cognome
		from Biglietto join Acquisto on Acquisto=IDAcquisto
		where (Biglietto.Destinazione=Dest
				and Biglietto.Data=Giorno
				and Acquisto.CheckIn='Y');
	end $$
delimiter ;

/* seconda dell'input (acquisto In Struttura o Online) visualizza i nomi, cognomi, recapiti viaggiatori ed Id degli acquisti*/

delimiter $$
create procedure TipoAcquisto(in Tipologia varchar(30)) 
	begin
		case
        when(Tipologia = 'In Struttura')
		then
			select Nome, Cognome, RecapitoViaggiatore, IDAcquisto
			from Biglietto join Acquisto on Acquisto = IdAcquisto 
			where Tipo = 'In Struttura';
		when(Tipologia = 'Online')
		then
			select Nome, Cognome, RecapitoViaggiatore, IDAcquisto
			from Biglietto join Acquisto on Acquisto = IdAcquisto 
			where Tipo = 'Online';
            end case;
	end $$
delimiter ;


/*Controlla se è attivo un portale per una determinata destinazione, qual è/quali sono e in quale ala si trovano*/

delimiter $$
create procedure ControlloPortali(IN Dest int(7))
	begin
		select CodiceP, Ala
		from Portale
		where Destinazione=Dest
		order by CodiceID;
	end $$
delimiter ;

/*A seconda dellinput (mansione) fornisce identificativo, nome e cognome dei dipendenti che la svolgono*/

 delimiter $$
 create procedure MansioneDipendenti(IN Mans int(2))
 	begin
 		select IDNumber, Nome, Cognome 
 		from Dipendenti join Mansioni 
 			on Turno=CodiceID 
 		where Turno=Mans
 		order by Cognome;
 	end $$ 
 delimiter ;

/*Siccome non tutte le destinazioni possono essere raggiunte in qualsiasi momento perché il numero di portali fisici è limitato 
si vuole verificare l'eventuale presenza di destinazioni che devono essere raggiunte da viaggiatori non attualmente servite da alcun portale.
Si inserisce perciò da input la data oltre la quale si vuole verificare l'esistenza del portale che serva una particolare destinazione. 
La procedura seguente fornirà -se c'è- l'ID della destinazione, il pianeta ed il luogo di una destinazione che dev'essere raggiunta in una certa data ma che non è servita da alcun portale*/

 delimiter $$
 create procedure DisponibilitaDestinazione(IN Dest int(7), IN Giorno date)
 	begin
 		select IDDestinazione, Pianeta, Luogo
 		from Biglietto left join Destinazione 
 			on Biglietto.Destinazione=Destinazione.IDDestinazione
 			left join Portale 
 			on Destinazione=Portale.Destinazione
 		where (Destinazione=Dest
 				and DataB=Giorno
 				and Portale.CodiceID=NULL);
	end $$
delimiter ;

/*Mostra quali aziende esterne stanno lavorando per lo spazioporto che vengono pagate più di una certa somma data in input*/

delimiter $$
create procedure AziendeEsterne(in Costo int)
	begin
		select PartitaIVA, Nome 
		from AziendeEsterne 
		where AziendeEsterne.Costo>=Costo;
	end $$
delimiter ;

/*Aggiorna gli stipendi dei Dipendenti a seconda della loro Mansione*/

  delimiter $$
  create procedure AumentoStipendi()
  	update (Dipendenti join Mansioni
 			on Dipendenti.Turno=Mansioni.CodiceID)
  set Stipendio=
  		case
  			when(Tipologia='Check-in' or
  				Tipologia='Emissione Biglietti' or
  				Tipologia='Controllo Biglietti' or
  				Tipologia='Banco informazioni')
  				then Stipendio*1.1
  			when(Tipologia='Assistenza attraversamento portale' or
  				Tipologia='Addetti allo sportello assicurativo')
  				then Stipendio*1.2
  			when(Tipologia='Addetti al mantenimento portali' or
  				Tipologia='Responsabili ali')
  				then Stipendio*1.4
  			when(Tipologia='Addetti alla sicurezza' and Stipendio>=50000)
  				then Stipendio*1.5
  			when(Tipologia='Addetti alla sicurezza' and Stipendio<50000)
  				then Stipendio*1.4
  	end $$
  delimiter ;

/* TRIGGER */

DROP TRIGGER IF EXISTS ControlloAumenti;
DROP TRIGGER IF EXISTS GenereDestinazione;
DROP TRIGGER IF EXISTS Recapito;
DROP TRIGGER IF EXISTS ScontoViaggiatori;

/*Impedisce l'aumento di più di un certo tetto massimo a seconda della mansione*/

delimiter $$
create trigger ControlloAumenti
before update on Dipendenti
for each row
begin
	IF (Tipologia='Check-in' or
			Tipologia='Emissione Biglietti' or
			Tipologia='Controllo Biglietti' or
			Tipologia='Banco informazioni' and new.Stipendio >= 28000)
			then 
			SIGNAL SQLSTATE VALUE '45000'
			set MESSAGE_TEXT = 'Stipendio troppo alto per la mansione richiesta';
	  else if (Tipologia = 'Assistenza attraversamento portale' and new.Stipendio > 38000)
		then
				SIGNAL SQLSTATE VALUE '45000'
				set message_text = 'Stipendio troppo alto per la mansione richiesta';
	 else if (Tipologia='Addetti al mantenimento portali' and new.Stipendio > 38500)
  		then 
        	SIGNAL SQLSTATE VALUE '45000'
  			set message_text = 'Aumento stipendio troppo alto';
		else if (Tipologia='Responsabili ali' and new.Stipendio > 35000)
  		then 
        	SIGNAL SQLSTATE VALUE '45000'
  			set message_text = 'Aumento stipendio troppo alto';
		else if (Tipologia='Addetti alla sicurezza' and new.Stipendio>=65000)
  		then 
        	SIGNAL SQLSTATE VALUE '45000'
  			set message_text = 'Aumento stipendio troppo alto';
			end if;
            end if;
        end if;
	  end if;
  end if;
end; $$
delimiter ;
  				
/*Impedisce l'aggiunta di una destinazione con un genere non già presente nelle destinazioni*/

delimiter $$
create trigger GenereDestinazione 
	before insert on Destinazione 
	for each row
	BEGIN
		if (new.Genere <> 'Fantasy' and new.Genere <> 'Fantascienza')
			then
				SIGNAL SQLSTATE VALUE '45000'
				set message_text = 'Genere non disponibile nello Spazioporto';
		end if;
	end; $$
	delimiter ;

/*Controlla che il formato del recapito inserito nell'acquisto sia valido (mail)*/

delimiter $$
create trigger Recapito 
	after insert on Acquisto 
	for each row
	begin
		if (new.RecapitoViaggiatore not like '%@%.%')
		then
			SIGNAL SQLSTATE VALUE '45000'
			set message_text = 'Il formato del recapito non è corretto';
		end if;
	end; $$
delimiter ;

/* se un viaggiatore ha effettuato più di 10 acquisti gli verrà applicato un 10% di sconto */

delimiter $$
create trigger ScontoViaggiatori
	before insert on Acquisto
    for each row
    begin
		declare Contatore integer;
        select COUNT(RecapitoViaggiatore) into Contatore
        from Acquisto
        group by RecapitoViaggiatore
        having COUNT(RecapitoViaggiatore) > 10; 
        if (Contatore > 10) then
			set new.Prezzo =  0.9* new.Prezzo;
		end if;
	end; $$
delimiter ;

/* FUNZIONI */

DROP FUNCTION IF EXISTS DestinazionePortali;
DROP FUNCTION IF EXISTS PrezzoNetto;
DROP FUNCTION IF EXISTS AzEstCosto;
DROP FUNCTION IF EXISTS AzEstMansione;

/*Restituisce la data di tutti i portali (sia ordinari che speciali) che vanno in una determinata destinazione*/

delimiter $$
create function DestinazionePortali(IdDest int(7)) 
    returns date 
	begin
		declare DataDest date;
		select DataD into DataDest
		from Portale
		Where IdDestinazione=IdDest;
		return DataDest;
	end; $$
delimiter ;

/*Prendendo in input l'identificativo dell'acquisto e il tipo di assicurazione, restituisce il prezzo del biglietto meno il costo dell'assicurazione*/

delimiter $$
create function PrezzoNetto (IDAcq int(30), TipoAss int(1))
returns integer
	begin
        declare Costo integer;
        select Acquisto.Prezzo into Costo
        from Acquisto join Assicurazione on Assicurazione=Tipo
        where IDAcquisto=IDAcq and Assicurazione=TipoAss;
        if(Assicurazione=1)
                then return Costo - 50;
                end if;
			if(Assicurazione=2)
                then return Costo -150;
                end if;
			if(Assicurazione=3)
                then return Costo -250;
                end if;
	end; $$
delimiter ;

/*Dato in input il Nome di un'azienda esterna, fornisce infromazioni relative al costo annuale.  e alla mansione che svolge per lo Spazioporto*/

delimiter $$ 
create function AzEstCosto (NomeAzienda varchar(20))
returns integer 
    begin
		declare Costo integer;
        select AziendeEsterne.Costo into Costo
        from AziendeEsterne
        where Nome=NomeAzienda;
        return Costo;
	end; $$
delimiter ;

/*Dato in input il Nome di un'azienda esterna, fornisce infromazioni relative alla mansione che svolge per lo Spazioporto. */

 delimiter $$ 
create function AzEstMansione (NomeAzienda varchar(20))
returns varchar(30) 
    begin
		declare Lavoro varchar(30);
        select Tipologia into Lavoro
        from AziendeEsterne join Mansioni on Mansione=CodiceID
        where Nome=NomeAzienda;
        return Lavoro;
	end; $$
delimiter ; 


/* DATA ENTRY */

insert into Spazioporto (`CodiceID`, `Pianeta`) values 
	(1, 'Terra');

insert into Ali (`CodiceID`, `Spazioporto`) values 
	(1, 1), 
	(2, 1); 

insert into Mansioni (`CodiceID`, `Tipologia`, `Spazioporto`) values
	(1, 'Check-in', 1),
	(2, 'Emissione Biglietti', 1),
	(3, 'Controllo Biglietti', 1),
	(4, 'Assistenza attraversamento portale', 1),
	(5, 'Addetti allo sportello assicurativo', 1),
	(6, 'Addetti al mantenimento portali', 1),
	(7, 'Responsabili ali', 1),
	(8, 'Banco informazioni', 1),
	(9, 'Addetti alla sicurezza', 1),
	(10, 'Pulizie', 1),
	(11, 'Revisione contabile', 1),
	(12, 'Supporto alla Sicurezza', 1);


insert into Dipendenti (`IDNumber`, `Turno`, `Nome`, `Cognome`, `Stipendio`, `DataAssunzione`) values
	('WF25161568', 4 , 'Abramo', 'Piccio', 30000, '2010-04-15'),
	('ML41671797', 8 ,'Tranquillina', 'Mancini', 20000, '2011-06-23'),
	('WH26629240', 9 ,'Assunta', 'Trevisan', 50000, '2005-02-03'),
	('NR12409070', 2 ,'Massimiliano', 'Barese', 22000, '2007-11-05'),
	('VA13716711', 1 ,'Crispina', 'Lucciano', 22000, '2009-12-04'),
	('PH52740422', 7 ,'Lionello', 'Luciano', 25000, '2012-12-15'),
	('BT36386327', 5 ,'Luana', 'Conti', 23500, '2016-11-30'),
	('NR12409071', 3 ,'Principio', 'Schiavon', 19000, '2011-06-10'),
	('XV39846372', 6 ,'Viviana', 'Buccho', 26000, '2014-11-15'),
	('VO58734477', 1 ,'Annibale', 'Rossi', 22000, '2005-10-05'),
	('VT80967292', 6 ,'Matilde', 'Lucchese', 22000, '2017-05-05'),
	('OY62470762', 9 ,'Quintilia', 'Siciliano', 45000, '2007-11-05'),
	('ED87036131', 5, 'James Louis', 'Davidson', 23500, '2011-06.29'),
	('IV56526138', 1, 'Isabel', 'Lander', 22000, '2008-05-01'),
	('LB43733089', 9, 'Derek', 'Bedwell', 45000, '2014-1-20'),
	('DV51877329', 3, 'James', 'Sawyer', 19000, '2016-09-01'),
	('UK23075790', 4, 'Storm', 'Larsen', 31000, '2017-05-20'),
	('HR66022000', 8, 'Freja', 'Jacobsen', 20000, '2009-04-11'),
	('KD86161156', 6, 'Elise', 'Kay', 29000, '2006-02-24'),
	('BB89910922', 8, 'Jonathan', 'Gough', 20000, '2014-08-14'),
	('DI85269434', 5, 'Alice', 'Griffiths', 23700, '2007-11-05'),
	('UO20276913', 9, 'Sabrina', 'Junker', 50000, '2006-02-22'),
	('ER89256917', 9, 'Erik', 'Mauer', 50000, '2005-04-19'),
	('WY28507301', 9, 'Horvát', 'Vilmos', 45000, '2013-09-05'),
	('YW24034810', 4 ,'Lorna', 'Pisano', 31000, '2007-11-05'),
	('UH37019957', 1, 'Savine', 'Klopper', 22000, '2010-09-01'),
	('YG98958194', 1, 'Maclovio Orozco', 'Cintrón', 22000, '2013-06-24'),
	('YF72309552', 1, 'Radek', 'Řezníček', 22000, '2016-03-04'),
	('FI63113335', 2, 'Magda', 'Viktorinová', 22000, '2011-03-24'),
	('SS19010633', 2, 'James', 'Struth', 22000, '2008-01-05'),
	('CG41040602', 2, 'Lily', 'Schutt', 22000, '2018-02-16'),
	('LS22907809', 2, 'Birgitte', 'Forland', 22000, '2014-12-06'),
	('FR60141927', 2, 'Monika', 'Eiffel', 22000, '2010-10-10'),
	('SL37976359', 3, 'Tobias', 'Bieber', 19000, '2016-09-10'),
	('AI24318051', 3, 'Valeria', 'Mancini', 19000, '2011-06-01'),
	('TW17579448', 3, 'Clémence', 'Laramée', 19000, '2008-11-02'),
	('QY44593939', 3, 'Audric', 'Duhamel', 19000, '2011-12-01'),
	('SJ64466252', 3, 'Kinfe', 'Yohannes', 19000, '2017-01-11'),
	('SW68366722', 4, 'Helen', 'Efrem', 30000, '2011-04-05'),
	('FH66813613', 4, 'Milivoj', 'Mikulić', 31000, '2006-07-04'),
	('NB90800841', 4, 'Edward', 'Lane', 30000, '2016-07-17'),
	('SL57198852', 4, 'Jessica', 'Henry', 31000, '2009-10-10'),
	('NX90967499', 4, 'Iskander', 'Borodin', 30000, '2014-04-20'),
	('ED68962000', 4, 'Cerys', 'Grant', 30000, '2014-11-15'),
	('SA45599709', 5, 'Toby', 'Moore', 23700, '2008-09-15'),
	('UV27275114', 5, 'Gordon', 'Zamora Montano', 23500, '2014-09-22'),
	('IA10532084', 5, 'Vivienne', 'Berie', 23500, '2016-03-25'),
	('TL72131081', 5, 'Sebastian', 'Strand', 23700, '2008-11-25'),
	('YZ42381668', 5, 'Abelardo', 'Zetticci', 23700, '2006-01-20'),
	('QL72093110', 6, 'Georg', 'Johansson', 22000, '2015-10-23'),
	('TG36611678', 6, 'Thomas', 'Klug', 29000, '2009-03-27'),
	('XY58411595', 6, 'Nuraga', 'Molan', 26000, '2012-05-05'),
	('SK55691853', 6, 'Peter', 'Løvstrøm', 22000, '2017-06-22'),
	('IT28141792', 6, 'Marie', 'Jeremiassen', 26000, '2010-10-11'),
	('IR59473959', 7, 'Birthe', 'Fleischer', 25000, '2009-01-15'),
	('ZR23974206', 8, 'Cristina', 'Pugnesi', 20000, '2013-11-12'),
	('FA86435815', 8, 'Claudia', 'Ermakova', 20000, '2017-02-11'),
	('FR89086230', 8, 'Storm', 'Pedersen', 20000, '2010-06-04'),
	('FY97688575', 8, 'Josh', 'Wilkins', 20000, '2014-12-20'),
	('VS39554759', 8, 'Matthew', 'Cooper', 20000, '2008-05-28'),
	('CA14601667', 8, 'Silla', 'Guðjónsdóttir', 20000, '2018-01-15'),
	('UR47930877', 9, 'Ingþór', 'Matthíasson', 50000, '2008-09-17'),
	('OH22598536', 9, 'Amadeo', 'Velázquez Marín', 45000, '2015-04-19'),
	('OD24041892', 9, 'Alex', 'Patterson', 50000, '2010-10-09'),
	('XZ43423439', 9, 'Mia', 'Barnett', 45000, '2015-11-03'),
	('SK99932406', 9, 'Tilde', 'Björk', 50000, '2007-03-21'),
	('VL77936793', 9, 'Földi', 'Loránd', 50000, '2008-11-25'),
	('WS55712332', 9, 'Tomáš', 'Lukáš', 45000, '2014-07-03'),
	('YS46596221', 9, 'Agostina', 'Arenas Linares', 50000, '2009-08-04'),
	('OA99862276', 9, 'Bogdan', 'Aksenov', 50000, '2008-04-09'),
	('MZ12960394', 1, 'Robina', 'Tunnelly', 25000, '2018-01-06'),
	('AP15966748', 1, 'Gilly', 'Gawkroger', 25000, '2018-08-12'),
	('XR46325029', 2, 'Ferdinand', 'Gardner', 22000, '2018-04-20'),
	('FY41043627', 2, 'Rosa', 'Maggot', 19500, '2017-11-29'),
	('XA93718633', 3, 'Belinda', 'Goold', 48000, '2011-05-23'),
	('MQ48829951', 4, 'Reginald', 'Button', 29000, '2014-11-22'),
	('RQ3097771', 4, 'Prisca', 'Headstrong', 38000, '2012-03-02'),
	('HQ78262972', 3, 'Selina', 'Headstrong', 43000, '2011-01-20'),
	('KW58789980', 6, 'Maura', 'Sackville', 33000, '2016-10-31'),
	('EU1275358', 7, 'Myrtle', 'Bolger-Baggins', 21000, '2018-11-15'),
	('TK9138407', 7, 'Reginard', 'Baggins', 45000, '2006-02-17'),
	('PO57723698', 7, 'Conrad', 'Goodchild', 30000, '2011-03-25'),
	('MJ82937768', 9, 'Peregrin', 'Labingi', 28000, '2015-09-11');



insert into Destinazione (`IdDestinazione`, `Pianeta`, `Luogo`, `Genere`) values 
	(1, 'Terra', 'Hogwarts', 'Fantasy'),
	(2, 'Terra', 'Diagon Alley', 'Fantasy'),
	(3, 'Terra', 'Notturn Alley', 'Fantasy'),
	(4, 'Terra', 'Ministero della Magia', 'Fantasy'),
	(5, 'Terra', 'Azkaban', 'Fantasy'),
	(6, 'Terra', 'Hogsmeade', 'Fantasy'),
	(7, 'Terra', 'Binario 9/4', 'Fantasy'),
	(8, 'Terra di Mezzo', 'Gondor', 'Fantasy'),
	(9, 'Terra di Mezzo', 'Rohan', 'Fantasy'),
	(10, 'Terra di Mezzo', 'La Contea', 'Fantasy'),
	(11, 'Terra di Mezzo', 'Mordor', 'Fantasy'),
	(12, 'Terra di Mezzo', 'Bosco Atro', 'Fantasy'),
	(13, 'Terra di Mezzo', 'Gran Burrone', 'Fantasy'),
	(14, 'Terra di Mezzo', 'Lorien', 'Fantasy'),
	(15, 'Terra di Mezzo', 'Moria', 'Fantasy'),
	(16, 'Terra di Mezzo', 'Valinor', 'Fantasy'),
	(17, 'Terra di Mezzo', 'Notturn Alley', 'Fantasy'),
	(18, 'Westeros', 'Approdo Del Re', 'Fantasy'),
	(19, 'Westeros', 'Roccia Del Drago', 'Fantasy'),
	(20, 'Westeros', 'Approdo Del Re', 'Fantasy'),
	(21, 'Westeros', 'Grande Inverno', 'Fantasy'),
	(22, 'Westeros', 'Delta delle Acque', 'Fantasy'),
	(23, 'Westeros', 'Pyke', 'Fantasy'),
	(24, 'Westeros', 'Castelgranito', 'Fantasy'),
	(25, 'Westeros', 'Capo Tempesta', 'Fantasy'),
	(26, 'Westeros', 'Tarth', 'Fantasy'),
	(27, 'Westeros', 'Lancia del Sole', 'Fantasy'),
	(28, 'Westeros', 'Nido dell Aquila', 'Fantasy'),
	(29, 'Westeros', 'Alto Giardino', 'Fantasy'),
	(30, 'Westeros', 'La Barriera', 'Fantasy'),
	(31, 'Westeros', 'Pentos Braavos', 'Fantasy'),
	(32, 'Westeros', 'Volantis', 'Fantasy'),
	(33, 'Westeros', 'Vaes Dothrak', 'Fantasy'),
	(34, 'Fantasia', 'Acque della Vita', 'Fantasy'),
	(35, 'Fantasia', 'Amarganta', 'Fantasy'),
	(36, 'Fantasia', 'Casa Che Muta', 'Fantasy'),
	(37, 'Fantasia', 'Goab', 'Fantasy'),
	(38, 'Fantasia', 'Citta degli Imperatori', 'Fantasy'),
	(39, 'Fantasia', 'Minround', 'Fantasy'),
	(40, 'Fantasia', 'Oracolo Meridionale', 'Fantasy'),
	(41, 'Fantasia', 'Perelun', 'Fantasy'),
	(42, 'Fantasia', 'Il Bosco Notturno', 'Fantasy'),
	(43, 'Fantasia', 'Tempio dalle Mille Porte', 'Fantasy'),
	(44, 'Fantasia', 'Torre D Avorio', 'Fantasy'),
	(45, 'Fantasia', 'Citta dei Fantasmi', 'Fantasy'),
	(46, 'Andoria', ' ', 'Fantascienza'),
	(47, 'Kronos', ' ', 'Fantascienza'),
	(48, 'Genesis', ' ', 'Fantascienza'),
	(49, 'Vulcano', ' ', 'Fantascienza'),
	(50, 'Nibiru', ' ', 'Fantascienza'),
	(51, 'Romulus', ' ', 'Fantascienza'),
	(52, 'Denobula', ' ', 'Fantascienza'),
	(53, 'Alpha Centauri', ' ', 'Fantascienza'),
	(54, 'Cittadella Borg', ' ', 'Fantascienza'),
	(55, 'Veridiano 3', ' ', 'Fantascienza'),
	(56, 'Tattooine', ' ', 'Fantascienza'),
	(57, 'Utapau', ' ', 'Fantascienza'),
	(58, 'Morte Nera', ' ', 'Fantascienza'),
	(59, 'Base Starkiller', ' ', 'Fantascienza'),
	(60, 'Coruscant', ' ', 'Fantascienza'),
	(61, 'Dagobah', ' ', 'Fantascienza'),
	(62, 'Endor', ' ', 'Fantascienza'),
	(63, 'Hoth', ' ', 'Fantascienza'),
	(64, 'Naboo', ' ', 'Fantascienza'),
	(65, 'Mustafar', ' ', 'Fantascienza'),
	(66, 'Kamino', ' ', 'Fantascienza'),
	(67, 'Jakku', ' ', 'Fantascienza'),
	(68, 'Jedha', ' ', 'Fantascienza'),
	(69, 'Terra', 'Arkham', 'Fantascienza'),
	(70, 'Terra', 'Dunwich', 'Fantascienza'),
	(71, 'Terra', 'Citta senza Nome', 'Fantascienza'),
	(72, 'Terra', 'Lemuria', 'Fantascienza'),
	(73, 'Terra', 'Mu', 'Fantascienza'),
	(74, 'Terra', 'Citta senza Nome', 'Fantascienza'),
	(75, 'Terra', 'Rlyeh', 'Fantascienza'),
	(76, 'Terra', 'Yhanthlei', 'Fantascienza'),
	(77, 'Terra', 'Citta senza Nome', 'Fantascienza'),
	(78, 'Yuggoth', 'Nithon', 'Fantascienza'),
	(79, 'Yuggoth', 'Thog', 'Fantascienza'),
	(80, 'Yuggoth', 'Thok', 'Fantascienza'),
	(81, 'Centro dell Universo', 'Corte di Azatoth', 'Fantascienza');


insert into Assicurazione (`Tipo`, `Prezzo`, `Descrizione`) values
	(1, 100, 'al viaggiatore viene rimborsato un valore standard per la valigia in caso di perdita e/o danneggiamento dei suoi contenuti. Questo valore ammonta a 200€'),
	(2, 300, 'al viaggiatore viene rimborsato un valore standard per la valigia in caso di perdita e/o danneggiamento dei suoi contenuti. Questo valore ammonta a 450€'),
	(3, 500, 'al viaggiatore viene rimborsato un valore standard per la valigia in caso di perdita e/o danneggiamento dei suoi contenuti. Questo valore ammonta a 800€');


insert into AziendeEsterne (`PartitaIVA`, `Nome`, `Costo`, `Mansione`) values
	(78564738931, 'Barese SRL', 15000,  11),
	(12323454567, 'Freshclean SRL', 18000,  10),
	(56789098765, 'SecurityGo', 16000, 12);

insert into Acquisto (`IDAcquisto`, `Tipo`, `IDSpazioporto`, `RecapitoViaggiatore`, `Prezzo`, `CheckIn`, `Assicurazione`) values
	(01010101, 'In Struttura', 1, 'giannischiavon@gmail.com', 300, 'Y', 1),
	(02020202, 'Online', 1, 'lucianobucco@gmail.com', 400, 'N', 1),
	(03030303, 'In Struttura', 1, 'martapiatto@gmail.com', 250, 'N', 1),
	(04040404, 'In Struttura', 1, 'emmabarison@gmail.com', 800, 'Y', 2),
	(05050505, 'Online', 1, 'sofiapieretti@gmail.com', 980, 'Y', 3),
	(10101010, 'In Struttura', 1, 'giuliacontato@gmail.com', 500, 'N', 1),
	(05060505, 'Online', 1, 'marion_napier@dayrep.com', 920, 'Y', 3),
	(03026303, 'Online', 1, 'KennethNTrujillo@teleworm.us', 340, 'N', 1),
	(03026304, 'Online', 1, 'freyablackburn@armyspy.com', 420, 'N', 2),
	(35057545, 'In Struttura', 1, 'NoelPadronGarcia@rhyta.com', 500, 'Y', 2),
	(00016901, 'In Struttura', 1, 'eirinthomassen@armyspy.com', 300, 'N', 1),
	(12501434, 'Online', 1, 'zuzannatysse@dayrep.com', 520, 'Y', 2),
	(13226303, 'In Struttura', 1, 'NiklasBrandt@jourrapide.com', 950, 'Y', 3),
	(16843547, 'Online', 1, 'leonieschroder@dayrep.com', 600, 'N', 3),
	(17443547, 'Online', 1, 'lucabeyer@jourrapide.com', 750, 'Y', 3),
	(13426353, 'In Struttura', 1, 'radovan_horvat@teleworm.us', 900, 'Y', 3),
	(53230343, 'Online', 1, 'BozoGalic@jourrapide.com', 750, 'Y', 2),
	(00043593, 'In Struttura', 1, 'dragoslavkovacevic@rhyta.com', 300, 'N', 1),
	(34635258, 'Online', 1, 'evanturnbull@gmail.com', 550, 'Y', 2),
	(21194102, 'In Struttura', 1, 'TillyTomlinson@rhyta.com', 480, 'Y', 2),
	(33144153, 'Online', 1, 'eleanor-dawson@armyspy.com', 850, 'Y', 3),
	(13225356, 'In Struttura', 1, 'zmarsalkova@teleworm.us', 420, 'N', 2),
	(32571442, 'Online', 1, 'reindljakub@gmail.com', 900, 'Y', 3),
	(32526314, 'In Struttura', 1, 'ocalabrese@thotmail.it', 550, 'Y', 2),
	(17523203, 'Online', 1, 'greece_ennio@gmail.com', 600, 'Y', 2),
	(38420659, 'Online', 1, 'nellabaresi@hotmail.it', 850, 'Y', 3),
	(37232010, 'In Struttura', 1, 'protasio.bianchi@gmail.com', 950, 'Y', 3),
	(43223413, 'In Struttura', 1, 'folcardzara@hotmail.com', 400, 'Y', 2),
	(43212266, 'Online', 1, 'pearlbrock@alice.it', 470, 'N', 1),
	(19090940, 'Online', 1, 'theobald@gmail.com', 700, 'Y', 3),
	(12009392, 'Online', 1, 'robin20939@hotmail.com', 900, 'Y', 3),
	(56879889, 'Online', 1, 'reginagee@libero.it', 600, 'N', 1), 
	(56776543, 'Online', 1, 'MarrocBrown@armyspy.com', 920, 'Y', 2),
	(54324545, 'In Struttura', 1, 'GriffoLonghole@jourrapide.com', 690, 'Y', 1),
	(98918912, 'In Struttura', 1, 'BerthaPuddifoot@armyspy.com', 375, 'Y', 1),
	(52312111, 'In Struttura', 1, 'BildatBracegirdle@jourrapide.com', 300, 'N', 2),
	(21123433, 'Online', 1, 'RubyTuk@armyspy.com', 500, 'Y', 2),
	(95483922, 'Online', 1, 'PerSrensen@dayrep.com', 600, 'N', 2),
	(78987688, 'Online', 1, 'FrederikSrensen@jourrapide.com', 780, 'Y', 3),
	(56887788, 'Online', 1, 'ThomasGeisler@teleworm.us', 580, 'N', 2),
	(23423212, 'Online', 1, 'MinikKreutzmann@jourrapide.com', 700, 'Y', 2),
	(43435432, 'In Struttura', 1, 'EmilieMikaelsen@rhyta.com', 600, 'N', 1),
	(67976577, 'Online', 1, 'AndersKleist@armyspy.com', 460, 'N', 1),
	(56333122, 'Online', 1, 'TregokGordek@armyspy.com', 590, 'N', 1),
	(98778989, 'Online', 1, 'LinkasaTharaxes@jourrapide.com', 840, 'N', 1),
	(67980090, 'In Struttura', 1, 'SynaTichar@dayrep.com', 700, 'N', 3),
	(89977678, 'In Struttura', 1, 'ValkrisKoru@teleworm.us', 895, 'N', 2),
	(54321221, 'In Struttura', 1, 'GKolaIssarra@armyspy.com', 260, 'N', 1),
	(34543334, 'In Struttura', 1, 'AranKreth@armyspy.com', 500, 'Y', 1),
	(12321112, 'Online', 1, 'AktuhVarrin@teleworm.us', 460, 'Y', 1),
	(15431113, 'Online', 1, 'TSiraGIogh@teleworm.us', 360, 'Y', 1),
	(43434556, 'Online', 1, 'JKahlaMnemon@rhyta.com', 480, 'N', 1),
	(23425465, 'Online', 1, 'VixisMnetic@armyspy.com', 800, 'N', 1),
	(12435433, 'Online', 1, 'KoraxDjon@dayrep.com', 540, 'Y', 2),
	(76534313, 'Online', 1, 'DKoraKamarag@jourrapide.com', 600, 'N', 2),
	(56442325, 'Online', 1, 'AntaanMong@dayrep.com', 780, 'N', 2),
	(65768787, 'Online', 1, 'KaChoAvell@dayrep.com', 930, 'Y', 3),
	(43567657, 'Online', 1, 'GNaanaKardem@teleworm.us', 650, 'Y', 3), 
	(47336434, 'Online', 1, 'KarvanDjon@dayrep.com', 530, 'Y', 2),
	(43536467, 'Online', 1, 'BElikHurn@jourrapide.com', 480, 'N', 2),
	(21123234, 'In Struttura', 1, 'KamatoKommora@rhyta.com', 380, 'N', 1),
	(45768798, 'In Struttura', 1, 'LElijSubaiesh@jourrapide.com', 400, 'N', 1),
	(76567776, 'In Struttura', 1, 'KehleyrVarrin@teleworm.us', 430, 'N', 1),
	(65435544, 'Online', 1, 'TSiraMajjas@dayrep.com', 670, 'Y', 3),
	(77897899, 'Online', 1, 'MyleyMiller@dayrep.com', 540, 'N', 3),
	(86678876, 'Online', 1, 'EdwardMurphy@armyspy.com', 760, 'N', 2),
	(76547835, 'Online', 1, 'RileyMaclean@jourrapide.com', 500, 'Y', 1),
	(67688978, 'In Struttura', 1, 'NaomiJamieson@jourrapide.com', 570, 'Y', 1),
	(54455542, 'In Struttura', 1, 'KimberleyPaterson@rhyta.com', 580, 'Y', 1),
	(56788980, 'In Struttura', 1, 'HubertScott@teleworm.us', 760, 'N', 2),
	(68987679, 'Online', 1, 'QuinnDonaldson@rhyta.com', 650, 'Y', 3),
	(87432987, 'Online', 1, 'FraserCrawford@dayrep.com', 720, 'N', 3),
	(43254364, 'In Struttura', 1, 'PatrickSinclair@rhyta.com', 450, 'N', 2),
	(54253543, 'Online', 1, 'AronKennedy@rhyta.com', 370, 'Y', 1),
	(35243433, 'Online', 1, 'RuaraidhSinclair@teleworm.us', 400, 'N', 1),
	(54345322, 'Online', 1, 'RonnieGrant@dayrep.com', 720, 'N', 3),
	(35654321, 'Online', 1, 'EmmanuelGrant@jourrapide.com', 980, 'N', 3),
	(34256600, 'Online', 1, 'NatalieClark@teleworm.us', 920, 'N', 3),
	(43253459, 'In Struttura', 1, 'MillarBrown@dayrep.com', 820, 'N', 3),
	(67689098, 'Online', 1, 'MusaJamieson@armyspy.com', 760, 'Y', 3),
	(76932424, 'In Struttura', 1, 'LeighaCraig@teleworm.us', 650, 'Y', 2),
	(47382975, 'In Struttura', 1, 'EmaanRoss@dayrep.com', 600, 'Y', 3),
	(89068540, 'In Struttura', 1, 'BryceHay@jourrapide.com', 540, 'N', 1),
	(35243636, 'In Struttura', 1, 'AidenGibson@rhyta.com', 490, 'N', 1),
	(97854398, 'In Struttura', 1, 'KaitlynMillar@dayrep.com', 560, 'Y', 2);


insert into Biglietto (IDBiglietto, NomeViaggiatore, CognomeViaggiatore, DataB, Tipo, Destinazione, Acquisto) values
	(1234323498, 'Gianni', 'Schiavon', '2019-12-3', 'C', 3, 01010101),
	(4323453543, 'Luciano', 'Bucco', '2018-11-25', 'E', 35, 02020202),
	(3424324123, 'Marta', 'Piatto', '2019-03-12', 'C', 23, 03030303),
	(6544355343, 'Emma', 'Barison', '2019-04-30', 'C', 80, 04040404),
	(4325436576, 'Sofia', 'Pieretti', '2019-07-21', 'E', 81, 05050505),
	(3424324125, 'Marion', 'Napier', '2018-07-15', 'E', 80, 05060505),	
	(4323453544, 'Kenneth', 'Trujillo', '2019-01-11', 'E', 15, 03026303),
	(5673356754, 'Giulia', 'Contato', '2018-12-08', 'C', 69, 10101010),
	(3424324126, 'Freya', 'Blackburn', '2020-02-12', 'E', 42, 03026304),
	(5323453543, 'Noel', 'Padrón Garcia', '2016-05-10', 'C', 35, 35057545),
	(8684354757, 'Eirin', 'Thomassen', '2014-12-06', 'C', 66, 00016901),
	(7644355343, 'Zuzanna', 'Tysse', '2018-10-02', 'E', 66, 12501434),
	(2371960686, 'Niklas', 'Brandt', '2012-12-12', 'C', 1, 13226303),
	(1339937519, 'Leonie', 'Schroder', '2021-08-20', 'E', 2, 16843547),
	(8734725523, 'Luca', 'Beyer', '2014-01-29', 'E', 2, 17443547),
	(6776244404, 'Radovan', 'Horvat', '2012-03-25', 'C', 15, 13426353),
	(3335747517, 'Božo', 'Galić', '2021-05-02', 'E', 4, 53230343),
	(6776244453, 'Dragoslav', 'Kovačević', '2017-06-01', 'C', 5, 00043593),
	(2337421923, 'Evan', 'Turnbull', '2013-04-18', 'E', 5, 34635258),
	(1119410238, 'Tilly', 'Tomlinson', '2018-07-10', 'C', 6, 21194102),
	(9926543335, 'Eleanor', 'Dawson', '2010-05-14', 'E', 6, 33144153),
	(0177232010, 'Zdeňka', 'Maršálková', '2015-05-15', 'E', 6, 13225356),
	(1164570174, 'Jakub', 'Reindl', '2016-11-20', 'C', 7, 32571442),
	(2317980983, 'Ofelia', 'Calabrese', '2011-11-23', 'S', 7, 32526314),
	(9914206594, 'Ennio', 'Greece', '2013-01-14', 'E', 8, 17523203),
	(5228780400, 'Novella', 'Baresi', '2017-05-19', 'E', 9, 38420659),
	(5755276309, 'Protasio', 'Bianchi', '2013-07-10', 'C', 9, 37232010),
	(5435466545, 'Folcard', 'Zara', '2018-04-15', 'S', 15, 43223413),
	(3480284390, 'Pearl', 'Brock', '2014-03-12', 'E', 12, 43212266),
	(3424123214, 'Theo', 'Bald', '2010-12-09', 'E', 60, 19090940),
	(4449890805, 'Robin', 'Tyssar', '2016-11-13', 'E', 61, 12009392),
	(4378270980, 'Regina', 'Gee', '2015-08-13', 'E', 41, 56879889),
	(8974234545, 'Marroc', 'Brown', '2014-12-14', 'E', 42, 56776543),
	(8975438323, 'Griffo', 'Longhole', '2013-12-11', 'C', 43, 54324545), 
	(5837580654, 'Bertha', 'Puddifoot', '2015-04-03', 'C', 44, 98918912),
	(9605845783, 'Bilda', 'Bracegirdle', '2018-11-16', 'C', 45, 52312111),
	(5678594305, 'Ruby', 'Tuk', '2017-12-13', 'E', 46, 21123433),
	(9089043243, 'Per', 'Sernsen', '2019-04-04', 'E', 47, 95483922),
	(8347298347, 'Frederik', 'Srensen', '2007-02-12', 'E', 48, 78987688),
	(3948754832, 'Thomas', 'Geisler', '2013-02-05', 'E', 49, 56887788),
	(8974354313, 'Minik', 'Kreutzmann', '2018-03-14', 'E', 50, 23423212),
	(4387924732, 'Emilie', 'MIkaelsen', '2016-12-13', 'C', 51, 43435432),
	(0843729843, 'Anders', 'Kleist', '2011-02-04', 'E', 52, 67976577),
	(8394274322, 'Tregok', 'Gordek', '2013-08-12', 'E', 53, 56333122),
	(0489324222, 'Linaska', 'THarexes', '2016-08-19', 'E', 54, 98778989),
	(8543958049, 'Syna', 'Tichar', '2010-09-19', 'E', 55, 67980090),
	(0835430859, 'Valkris', 'Koru', '2010-09-19', 'E', 56, 89977678),
	(5439809809, 'G-Kola', 'Issarra', '2019-06-30', 'C', 57, 54321221),
	(3908594009, 'Aran', 'Kreth', '2016-05-20', 'E', 58, 34543334),
	(0958390489, 'Akuth', 'Varrin', '2018-01-29', 'C', 59, 12321112),
	(4932854398, 'T-Sira', 'G-Iogh', '2017-09-18', 'C', 60, 15431113),
	(4389098234, 'Myley', 'Miller', '2017-05-18', 'C', 61, 43434556),
	(5430890342, 'Vixis', 'Mnetic', '2017-08-20', 'C', 62, 23425465),
	(9084839209, 'Korax', 'Djon', '2017-09-22', 'C', 63, 12435433),
	(0984530984, 'D-Kora', 'Kamarag', '2017-08-05', 'C', 64, 76534313),
	(0985493089, 'Antaan', 'Mong', '2017-08-28', 'E', 65, 56442325),
	(0985439083, 'Ka-Cho', 'Avell', '2017-09-27', 'E', 66, 65768787),
	(8974302984, 'G-Naana', 'Kardem', '2016-07-23', 'C',60, 43567657),
	(0983443212, 'Karvan', 'Djon', '2016-06-30','C', 60, 47336434),
	(5984308594, 'B-Elik', 'Hurn', '2016-06-30', 'E', 60, 43536467),
	(0958439084, 'Kamato', 'Komora', '2017-05-30','E', 61, 21123234),
	(9084392080, 'L-Elij', 'Subaiesh', '2018-05-16','C', 80, 45768798),
	(0985430984, 'Kehleyr', 'Varrin', '2017-04-19','E', 81, 76567776),
	(0985438758, 'T-Sira', 'Majjas', '2017-06-29','C', 78, 65435544),
	(0584532984, 'Myley', 'Miller', '2018-04-23','E', 70, 77897899),
	(5978843543, 'Edward', 'Murphy', '2017-07-31', 'C', 70, 86678876),
	(9089849328, 'Riley', 'MacLean', '2019-06-05','E', 71, 76547835),
	(9084392843, 'Naomi', 'Jamienson', '2019-08-05', 'E', 71, 67688978),
	(8975439849, 'Kimberly', 'Paterson', '2020-08-20','C', 32, 54455542),
	(0985430985, 'Hubert', 'Scott', '2020-03-20', 'C', 33, 56788980),
	(0897432874, 'Quinn', 'Donaldson', '2020-01-12', 'C', 10, 68987679),
	(0983421433, 'Fraser', 'Crawford', '2020-03-04', 'C',  11, 87432987),
	(0234875894, 'Patrick', 'Sinclair', '2019-05-22', 'C', 12, 43254364),
	(0938492433, 'Aron', 'Kennedy', '2018-06-20', 'E', 10, 54253543),
	(3489349209, 'Ruaraidh', 'Sinclair', '2018-04-12', 'C', 10, 35243433),
	(0983424111, 'Ronnie', 'Grant', '2015-04-12', 'E', 11, 54345322),
	(0112387543, 'Emmanuel', 'Grant', '2018-07-11', 'C', 40, 35654321),
	(9847221321, 'Natalie', 'Clark', '2010-04-11', 'E', 45, 34256600),
	(3234832843, 'Millar', 'Brown', '2019-04-12', 'C', 44, 43253459),
	(3231112323, 'Musa', 'Jamienson', '2018-06-18', 'C', 45, 67689098),
	(5439000432, 'Leigha', 'Craig', '2020-09-04', 'E', 65, 76932424),
	(1123325555, 'Emaan', 'Ross', '2021-02-02', 'C', 66, 47382975),
	(4309284322, 'Bryce', 'Hay', '2021-03-12', 'E', 44, 89068540),
	(0983422112, 'Aiden', 'Gibson', '2021-09-03', 'E', 32, 35243636),
	(3321313288, 'Kaitlyn', 'Millar', '2019-03-04', 'E', 32, 97854398);

insert into Portale (`CodiceID`, `Tipo`, `Sovrapprezzo`, `FrequenzaApertura`, `Destinazione`, `DataP`, `Ora`, `Gate`, `Ala`) values
    (1, 'Ordinario', 0, 30, 1, '2018-05-20', '15:03:00', 1, 1),
	(2, 'Ordinario', 0, 25, 1, '2018-05-21', '07:00:00', 2, 1),
	(3, 'Ordinario', 0, 40, 2, '2018-05-22', '08:00:00', 3, 1),
	(4, 'Ordinario', 0, 50, 2, '2018-05-23', '09:00:00', 5, 1),
	(5, 'Ordinario', 0, 30, 3, '2018-04-22', '10:00:00', 7, 1),
	(6, 'Ordinario', 0, 35, 4, '2018-06-01', '09:30:00', 9, 1),
	(7, 'Ordinario', 0, 15, 5, '2017-12-04', '09:30:00', 10, 1),
	(8, 'Ordinario', 0, 20, 5, '2018-07-01', '09:00:00', 8, 1),
	(9, 'Ordinario', 0, 25, 5, '2019-09-16', '10:10:00', 34, 1),
	(10, 'Ordinario', 0, 30, 8, '2020-10-10', '09:00:00', 23, 1),
	(11, 'Ordinario', 0, 20, 8, '2020-11-21', '11:00:00', 54, 1),
	(12, 'Ordinario', 0, 25, 8, '2018-12-10', '10:00:00', 12, 1),
	(13, 'Ordinario', 0, 30, 10, '2019-04-18', '09:10:00', 34, 1),
	(14, 'Ordinario', 0, 15, 10, '2019-04-19', '09:00:00', 15, 1),
	(15, 'Ordinario', 0, 15, 10, '2018-03-20', '15:00:00', 17, 1),
	(16, 'Ordinario', 0, 40, 11, '2018-06-30', '16:00:00', 19, 1),
	(17, 'Ordinario', 0, 45, 13, '2017-10-11', '11:00:00', 27, 1),
	(18, 'Ordinario', 0, 30, 13, '2019-12-01', '12:00:00', 22, 1),
	(19, 'Ordinario', 0, 35, 13, '2018-10-11', '10:00:00', 24, 1),
	(20, 'Ordinario', 0, 15, 15, '2018-11-30', '09:00:00', 35, 1),
	(21, 'Ordinario', 0, 10, 20, '2017-05-05', '08:00:00', 33, 1),
	(22, 'Ordinario', 0, 20, 20, '2016-04-12', '08:00:00', 41, 1),
	(23, 'Ordinario', 0, 20, 20, '2016-04-13', '08:00:00', 15, 1),
	(24, 'Ordinario', 0, 25, 20, '2016-05-01', '08:00:00', 14, 1),
	(25, 'Ordinario', 0, 15, 22, '2020-04-12', '09:00:00', 4, 1),
	(26, 'Ordinario', 0, 20, 22, '2020-04-13', '09:00:00', 15, 1),
	(27, 'Ordinario', 0, 30, 23, '2018-04-12', '10:00:00', 18, 1),
	(28, 'Ordinario', 0, 25, 30, '2018-04-12', '11:00:00', 36, 1),
	(29, 'Ordinario', 0, 30, 31, '2018-04-12', '09:00:00', 39, 1),
	(30, 'Ordinario', 0, 40, 31, '2018-05-28', '08:00:00', 45, 1),
	(31, 'Ordinario', 0, 45, 31, '2019-05-29', '08:00:00', 35, 1),
	(32, 'Ordinario', 0, 50, 32, '2020-05-12', '09:00:00', 27, 1),
	(33, 'Ordinario', 0, 30, 32, '2019-03-15', '08:30:00', 42, 1),
	(34, 'Ordinario', 0, 35, 32, '2018-09-28', '08:00:00', 46, 1),
	(35, 'Ordinario', 0, 20, 38, '2019-09-23', '09:00:00', 48, 1),
	(36, 'Ordinario', 0, 25, 38, '2019-09-24', '09:00:00', 12, 1),
	(37, 'Ordinario', 0, 45, 40, '2016-04-24', '10:00:00', 15, 1),
	(38, 'Ordinario', 0, 40, 40, '2015-03-13', '10:00:00', 14, 1),
	(39, 'Ordinario', 0, 25, 41, '2015-03-14', '09:00:00', 12, 1),
	(40, 'Ordinario', 0, 15, 43, '2015-02-12', '10:00:00', 19, 1),
	(41, 'Ordinario', 0, 35, 43, '2015-03-10', '08:00:00', 29, 1),
	(42, 'Ordinario', 0, 35, 43, '2015-03-11', '08:30:00', 43, 1),
	(43, 'Ordinario', 0, 30, 44, '2015-02-20', '08:30:00', 27, 1),
	(44, 'Ordinario', 0, 40, 48, '2018-03-14', '07:00:00', 32, 2),
	(45, 'Ordinario', 0, 35, 48, '2018-03-15', '07:30:00', 30, 2),
	(46, 'Ordinario', 0, 20, 49, '2019-03-14', '08:00:00', 21, 2),
	(47, 'Ordinario', 0, 10, 50, '2019-02-11', '06:30:30', 33, 2),
	(48, 'Ordinario', 0, 20, 55, '2017-01-03', '04:00:00', 35, 2),
	(49, 'Ordinario', 0, 25, 14, '2018-05-02', '08:00:00', 3, 1),
	(50, 'Ordinario', 0, 40, 50, '2018-05-14', '04:45:00', 1, 2),
	(51, 'Ordinario', 0, 20, 51, '2019-02-02', '09:00:00', 32, 2),
	(52, 'Ordinario', 0, 25, 53, '2018-01-06', '10:00:00', 42, 2),
	(53, 'Ordinario', 0, 30, 53, '2018-04-04', '11:00:00', 51, 2),
	(54, 'Ordinario', 0, 10, 54, '2018-10-19', '15:00:00', 59, 2),
	(55, 'Ordinario', 0, 15, 55, '2016-10-23', '14:00:00', 30, 2),
	(56, 'Ordinario', 0, 25, 55, '2015-11-12', '13:30:00', 28, 2),
	(57, 'Ordinario', 0, 50, 56, '2015-07-29', '16:00:00', 29, 2),
	(58, 'Ordinario', 0, 45, 56, '2015-10-11', '10:00:00', 30, 2),
	(59, 'Ordinario', 0, 30, 57, '2015-11-09', '11:30:00', 20, 2),
	(60, 'Ordinario', 0, 10, 60, '2013-07-20', '12:30:00', 33, 2),
	(101, 'Straordinario', 200, 50, 30, '2018-10-10', '09:00:00', 55, 1),
	(102, 'Straordinario', 300, 50, 32, '2018-10-11', '08:30:00', 45, 1),
	(121, 'Straordinario', 150, 55, 40, '2018-10-10', '09:00:00', 30, 1),
	(103, 'Straordinario', 200, 50, 45, '2016-10-15', '11:00:00', 43, 1),
	(104, 'Straordinario', 400, 50, 30, '2018-10-11', '09:30:00', 46, 1),
	(105, 'Straordinario', 450, 60, 25, '2015-10-10', '10:30:00', 55, 1),
	(106, 'Straordinario', 360, 55, 23, '2018-10-10', '09:30:00', 60, 1),
	(107, 'Straordinario', 200, 65, 30, '2017-12-10', '10:00:00', 55, 1),
	(108, 'Straordinario', 600, 55, 60, '2014-10-10', '09:00:00', 10, 2),
	(109, 'Straordinario', 500, 75, 60, '2017-06-25', '10:00:00', 10, 2),
	(110, 'Straordinario', 390, 55, 66, '2018-10-10', '09:00:00', 11, 2),
	(111, 'Straordinario', 580, 65, 69, '2019-03-10', '10:00:00', 34, 2),
	(112, 'Straordinario', 400, 60, 70, '2018-08-15', '09:30:00', 43, 2),
	(113, 'Straordinario', 300, 55, 73, '2016-06-14', '10:30:00', 21, 2),
	(114, 'Straordinario', 500, 55, 60, '2017-07-15', '15:30:00', 10, 2),
	(115, 'Straordinario', 700, 55, 60, '2020-02-16', '10:30:00', 9, 2),
	(116, 'Straordinario', 550, 55, 75, '2020-11-20', '18:30:00', 2, 2),
	(117, 'Straordinario', 350, 55, 77, '2018-12-30', '09:30:00', 19, 2),
	(118, 'Straordinario', 300, 55, 73, '2019-06-22', '04:15:00', 45, 2),
	(119, 'Straordinario', 400, 55, 65, '2017-03-19', '12:00:00', 14, 2),
	(120, 'Straordinario', 650, 55, 81, '2018-02-11', '14:00:00', 12, 2);


/*QUERY SOTTO FORMA DI VISTE*/

/*Seleziona tutti i dipendenti che sono stati assunti dal 2014 e che prendono almeno 25000 all'anno*/
create view VistaDipendenti as 
	select Nome, Cognome, Tipologia
	from Dipendenti join Mansioni on Turno = CodiceID
	where DataAssunzione not in (select DataAssunzione 
								 from Dipendenti 
								 where DataAssunzione<='2013-12-31')
		  and Stipendio > all (select Stipendio
								from Dipendenti
								Where Stipendio <=24999)
	order by Tipologia;


/*Seleziona nome e cognome dei viaggiatori che devono fare checkin e vanno nella stessa destinazione*/
create view VistaViaggiatori as
	select NomeViaggiatore, CognomeViaggiatore, Pianeta, Luogo
	from Destinazione join Biglietto on IdDestinazione=Destinazione join Acquisto on IDAcquisto=Acquisto
	where CheckIn='Y' 
	group by Destinazione;

/*Conta il numero di volte in cui sono state visitate tutte le desinazioni, con output pianeta, luogo e numero di visite e le ordina dalla più alla meno visitata*/

create view VistaDestinazioni as
	select Pianeta, Luogo, count(*) as Totale
	from Destinazione join Biglietto on IdDestinazione=Destinazione
	group by IdDestinazione
	order by Totale desc;