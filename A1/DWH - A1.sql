-- drop all tables
drop table temp_bestellung;
drop table fact_bestellung;
drop table dim_kunde; 
drop table dim_verkaeufer;
drop table dim_artikel; 
drop table dim_artgrp;
drop table dim_date;

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
CREATE TABLE dim_datum (
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

-- create tempoparary Bestellung table 
create table temp_bestellung (
    filiale_name varchar2 (50 char),
    datum date,
    artnr integer,
    anzahl integer, 
    preis number(6, 2),
    verkaeufer_vorname varchar2(50 char),
    kundennummer integer
)

-- populate dim_artikel
insert into dim_artikel (artnr, artname, artgrp) 
select artnr, artname, artgrp from gerken.artikel;

-- populate dim_artgrp
insert into dim_artgrp (artgrp, grpname)
select distinct artgrp, grpname from gerken.artikel;

-- populate dim_kunde, dim_verkauefer with GUI 
-- populate temp_bestellung with GUI

-- fix error in Bondatei.txt
-- remove null rows in the data
delete from temp_bestellung 
where filiale_name is null; 

-- replace crazy price at line 24 with 1.49, which is more usual with item 2001
select preis from temp_bestellung 
where artnr = 2001;

update temp_bestellung 
set preis = 1.49
where preis > 1000;

-- check for non-existent parent keys, possibly input error
-- check filiale_name
select filiale_name from temp_bestellung
where filiale_name not in (select distinct filiale_name from dim_verkaeufer);

-- check artnr
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

-- check kundennummer
select distinct kundennummer from temp_bestellung
where kundennummer not in (select distinct kundennummer from dim_kunde);

-- replace non-existent customers with null
update temp_bestellung  
set kundennummer = null
where kundennummer not in (select distinct kundennummer from dim_kunde);

-- populate dim_datum
insert into dim_datum (datum, datum_tag, datum_monat, datum_jahr)
select distinct datum, extract(day FROM datum), extract(month FROM datum), extract(year FROM datum) 
from temp_bestellung;

-- populate fact_bestellung
insert into fact_bestellung(dim_kunde_key, dim_verkaeufer_key, dim_artikel_key, dim_artgrp_key, dim_datum_key, anzahl, preis)
select dim_kunde_key, dim_verkaeufer_key, dim_artikel_key, dim_artgrp_key, dim_datum_key, anzahl, preis 
from temp_bestellung 
left join dim_verkaeufer using(verkaeufer_vorname, filiale_name)
left join dim_artikel using(artnr)
left join dim_artgrp using(artgrp)
left join dim_datum using(datum)
left join dim_kunde using(kundennummer);
















