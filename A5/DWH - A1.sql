-- drop all tables
drop table temp_bestellung;
drop table fact_bestellung;
drop table dim_kunde; 
drop table dim_verkaeufer;
drop table dim_artikel; 
drop table dim_artgrp;
drop table dim_datum;

-- create Kunde dimension
create table dim_kunde (
    dim_kunde_key integer generated always as identity,
    kundennummer integer,
    vorname varchar2(50 char),
    nachname varchar2(50 char),
    adresse varchar2(50 char),
    plz varchar2(5 char),
    ort varchar2(50 char),
    
    constraint dim_kunde_pk primary key(dim_kunde_key)
)

-- create Verkaeufer dimension
create table dim_verkaeufer (
    dim_verkaeufer_key integer generated always as identity, 
    verkaeufer_vorname varchar2(50 char),
    filiale_name varchar2 (50 char),
    geburtstag date,
    wohnort varchar2(50 char),
    
    constraint dim_verkaeufer_pk primary key(dim_verkaeufer_key)
)

-- create Artikel dimension 
create table dim_artikel (
    dim_artikel_key integer generated always as identity, 
    artnr integer, 
    artname varchar2 (100 char), 
    artgrp varchar2 (10 char),
    
    constraint dim_artikel_pk primary key(dim_artikel_key)
)

-- create Artikelgruppe dimention 
create table dim_artgrp (
    dim_artgrp_key integer generated always as identity, 
    artgrp varchar2(10 char), 
    grpname varchar2(50 char),
    
    constraint dim_artgrp_pk primary key(dim_artgrp_key)
) 

-- create Datum dimension 
create table dim_datum (
    dim_datum_key integer generated always as identity,
    
    datum date,
    datum_tag number(2, 0),
    datum_monat number(2, 0),
    datum_jahr number(4, 0),
    
    constraint dim_datum_pk primary key(dim_datum_key)
)

-- create Bestellung fact table 
create table fact_bestellung (
    anzahl integer, 
    preis number(6, 2), 
    
    dim_kunde_key integer, 
    dim_verkaeufer_key integer not null, 
    dim_artikel_key integer not null, 
    dim_artgrp_key integer not null, 
    dim_datum_key integer not null,
    
    constraint dim_kunde_fk foreign key(dim_kunde_key) references dim_kunde(dim_kunde_key),
    constraint dim_verkaeufer_fk foreign key(dim_verkaeufer_key) references dim_verkaeufer(dim_verkaeufer_key),
    constraint dim_artikel_fk foreign key(dim_artikel_key) references dim_artikel(dim_artikel_key),
    constraint dim_artgrp_fk foreign key(dim_artgrp_key) references dim_artgrp(dim_artgrp_key), 
    constraint dim_datum_fk foreign key(dim_datum_key) references dim_datum(dim_datum_key)
)

-- create temporary Bestellung (Bondatei) table 
create table temp_bestellung (
    filiale_name varchar2 (50 char),
    datum date,
    artnr integer,
    anzahl integer, 
    preis number(6, 2),
    verkaeufer_vorname varchar2(50 char),
    kundennummer integer
)

-- Artikel table
--select * from gerken.artikel;

--------------------------------------------------- populate tables ----------------------------------------------------------
-- populate dim_artikel
insert into dim_artikel (artnr, artname, artgrp) 
select artnr, artname, artgrp from gerken.artikel;

-- populate dim_artgrp
insert into dim_artgrp (artgrp, grpname)
select distinct artgrp, grpname from gerken.artikel;

-- populate dim_kunde, dim_verkaeufer with GUI 
-- populate temp_bestellung with GUI

--------------------------------------------- fix error in Bondatei.txt ------------------------------------------------------
-- remove null rows in the data
delete from temp_bestellung 
where filiale_name is null; 

-- replace crazy price (2099.49) at line 24 with 1.49, which is more usual with item 2001
select preis from temp_bestellung 
where artnr = 2001;

update temp_bestellung 
set preis = 1.49
where preis > 1000;

---------------------------- check for non-existent parent keys, possibly input error ----------------------------------------
-- check filiale_name
select filiale_name from temp_bestellung
where filiale_name not in (select distinct filiale_name from dim_verkaeufer);

-- check artnr (=> 2148)
select artnr from temp_bestellung 
where artnr not in (select distinct artnr from dim_artikel);

-- replace unknown item code 2148 with the more common 2147
select artnr from dim_artikel;

update temp_bestellung 
set artnr = 2147 
where artnr = 2148; 

-- check verkaeufer_vorname
select verkaeufer_vorname from temp_bestellung
where verkaeufer_vorname not in (select distinct verkaeufer_vorname from dim_verkaeufer);

-- check kundennummer (=> 0,1)
select distinct kundennummer from temp_bestellung
where kundennummer not in (select distinct kundennummer from dim_kunde);

-- replace "fake" customers with null
update temp_bestellung  
set kundennummer = null
where kundennummer not in (select distinct kundennummer from dim_kunde);

-------------------------------------populate dim_datum and fact_bestellung----------------------------------------------------
-- populate dim_datum
insert into dim_datum (datum, datum_tag, datum_monat, datum_jahr)
select distinct datum, extract(day FROM datum), extract(month FROM datum), extract(year FROM datum) 
from temp_bestellung;

-- replace unusual year 2112 with 2012 
update dim_datum
set datum_jahr = 2012
where datum_jahr = 2112;

update dim_datum
set datum = TO_DATE('09/02/2012', 'MM/DD/YYYY')
where datum = TO_DATE('09/02/2112', 'MM/DD/YYYY');

-- populate fact_bestellung
insert into fact_bestellung(dim_kunde_key, dim_verkaeufer_key, dim_artikel_key, dim_artgrp_key, dim_datum_key, anzahl, preis)
select dim_kunde_key, dim_verkaeufer_key, dim_artikel_key, dim_artgrp_key, dim_datum_key, anzahl, preis 
from temp_bestellung 
left join dim_verkaeufer using(verkaeufer_vorname, filiale_name)
left join dim_artikel using(artnr)
left join dim_artgrp using(artgrp)
left join dim_datum using(datum)
left join dim_kunde using(kundennummer);

------------------------------------------------------ Queries ---------------------------------------------------------------
-- Umsatz pro Filiale und Monat (group by)
select filiale_name, datum_monat, sum(anzahl * preis) as umsatz from fact_bestellung
right join dim_verkaeufer using(dim_verkaeufer_key)
right join dim_datum using(dim_datum_key)
group by (filiale_name, datum_monat)
order by filiale_name, datum_monat;

-- Umsatz pro Filiale und Monat (group by cube)
select nvl(filiale_name,' '), datum_monat, sum(anzahl * preis) as umsatz from fact_bestellung
right join dim_verkaeufer using(dim_verkaeufer_key)
right join dim_datum using(dim_datum_key)
group by cube(filiale_name, datum_monat)
order by filiale_name, datum_monat;

-- Welche Filiale hat vom 1.9-3.9.2012 die höchste Anzahl von Handcremes verkauft?
select filiale_name, sum(anzahl) as anzahl from fact_bestellung
right join dim_verkaeufer using(dim_verkaeufer_key)
right join dim_datum using(dim_datum_key)
right join dim_artikel using(dim_artikel_key)
where artname = 'Handcreme'
and datum between to_date('01.09.2012', 'DD.MM.YYYY') and to_date('03.09.2012', 'DD.MM.YYYY')
group by(filiale_name)
order by filiale_name
fetch first row only;   -- A instead of A and B

-- Umsatz pro Artikelgruppe
select artgrp, sum(anzahl * preis) as umsatz from fact_bestellung
right join dim_artgrp using(dim_artgrp_key)
group by(artgrp)
order by umsatz;

-- Prozentualler Absatz der Artikelgruppe Körperpflege in den einzelnen Filialen
select filiale_name, artgrp, 
round(sum(anzahl)/ cast(sum(sum(anzahl)) over (partition by filiale_name) as float), 3) as prozentualer_absatz from fact_bestellung
right join dim_verkaeufer using(dim_verkaeufer_key) 
right join dim_artgrp using(dim_artgrp_key)
group by(filiale_name, artgrp)
order by filiale_name, artgrp;

-- Umsatz pro Kunden
select kundennummer, sum(anzahl * preis) as umsatz from fact_bestellung
full outer join dim_kunde using(dim_kunde_key)
group by(kundennummer)
order by kundennummer;

-- Buchungen pro Verkäufer und Tag
select kundennummer, datum, sum(anzahl * preis) as beitrag from fact_bestellung
left join dim_kunde using(dim_kunde_key)
right join dim_datum using(dim_datum_key)
group by (kundennummer, datum)
order by kundennummer, datum;

commit