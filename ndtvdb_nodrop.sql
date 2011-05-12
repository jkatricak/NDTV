


create table audio (
	title varchar(50),
	filename varchar(70) NOT NULL,
        artist varchar(50),
        album varchar(50),		
        year int,
        genre varchar(25),
        track int, 
	bitrate int,
	frequency int,
        length varchar(6),
	comment varchar(100),
        format varchar(4),
         primary key (filename)

) 
;
create table pictures (
	description varchar(255),       
     	dimensions varchar(9), 
     	filename varchar(150) NOT NULL,        
     	format varchar(100),
        primary key (filename)
) 
;
create table programme (
		
   title varchar(128),         
   subtitle varchar(100),         
   description text,  
   starttime timestamp(14) NOT NULL,     
   endtime timestamp(14),     
   channel varchar(100) NOT NULL,
   category varchar(100),     
   record tinyint(1),
   primary key (channel, starttime)
   
) 
;
create table video (
      title varchar(75),
      year int,
      description text,
      genre varchar(25),
      rating varchar(4),
      length varchar(6),
      filename varchar(150) NOT NULL,
      format varchar(25),
      primary key (filename)
)
;

create table channel (
	chanid varchar(20) NOT NULL,
	logofile varchar(20),
	channame varchar(20),
	channum int,
	primary key (chanid)
)
;

create table torecord (
title varchar(128),
   subtitle varchar(100),
   description text,
   starttime timestamp(14) NOT NULL,
   endtime timestamp(14),
   channel varchar(100) NOT NULL,
   category varchar(100),
   record tinyint(1),
   primary key (channel, starttime)


)
;

create table recordedtv (

title varchar(128),         
   subtitle varchar(100),         
   description text,  
   starttime timestamp(14) NOT NULL,     
   endtime timestamp(14),     
   channel varchar(100) NOT NULL,
   category varchar(100),     
   record tinyint(1),
   primary key (starttime, channel)

)
;



