#!/usr/bin/perl -w

use DBI;
use Date::Calc qw(:all);
open(LOG, ">>record.log") || die "Can't open log!\n";

#FI
$starttime = $ARGV[0];
$channel = $ARGV[1];
for ($i=2;$i<=$#ARGV;$i++) {
    $channel = $channel . " " . $ARGV[$i];
}



#insert run date and time into log
$cdate = `date`;


#get the channel number, for use with mencoder
$dbh = DBI->connect("DBI:mysql:ndtv:localhost",
		    "ndtv", "mysql");
#FI
#this should technicaly not be necessary since we already get channel
$query = "select title from torecord where channel=\"$channel\" and starttime=\"$starttime\"";

#$query = "select channel from torecord where title=\"$title\"";

$sth = $dbh->prepare($query);
$sth->execute;

$title = $sth->fetchrow_array;
print LOG "$cdate";
print LOG "Now recording $title";
print LOG "\n \n";
$title =~ s/ /_/g;
$tchan = $channel;
$channel =~ /(\d+) (\w+)/;
$channum = $1;
$channel = $tchan;
#FI - for the st + channel  version we don't need the next query

#get starttime and endtime to calculate program length
#$query = "select starttime from torecord where title=\"$title\"";

#$sth = $dbh->prepare($query);
#$sth->execute;

#$starttime = $sth->fetchrow_array;


#FI
$query = "select endtime from torecord where channel=\"$channel\" and starttime=\"$starttime\"";


#$query = "select endtime from torecord where title=\"$title\"";

$sth = $dbh->prepare($query);
$sth->execute;

$endtime = $sth->fetchrow_array;
print qq{ starttime = $starttime and endtime == $endtime \n };
#$elapsed = $endtime - $starttime;
#if ($elapsed == "7000" || $elapsed == "3000") {
#    $endpos = "30:00";
#} elsif ($elapsed == "10000") {$endpos = "60:00";}
#else 
#{
#$endpos = "60:00";
#}
$starttime =~ /(\d\d\d\d)(\d\d)(\d\d)(\d\d)(\d\d)(\d\d)/;
$year = $1; $month = $2; $day = $3; $hour = $4;
$minute = $5; $second = $6;
$msec = 60;$hsec = 60*60;$dsec = 24*60*60;$ysec = 365*24*60*60;
$doy = Day_of_Year($year,$month,$day);
$sytime = $ysec * ( $year - 2000);
$stsec = $sytime + $second+($minute*$msec)+($hour*$hsec)+($doy*$dsec);
$endtime =~ /(\d\d\d\d)(\d\d)(\d\d)(\d\d)(\d\d)(\d\d)/;
$year = $1; $month = $2; $day = $3; $hour = $4;
$minute = $5; $second = $6;
$doy = Day_of_Year($year,$month,$day);
$eytime = $ysec * ( $year - 2000);
$etsec = $eytime +$second+($minute*$msec)+($hour*$hsec)+($doy*$dsec);
$elapsed = $etsec - $stsec;
$endpos = $elapsed;
#run mencoder script
print qq{ Hmm, here is $channum -1 $endpos -2 /ndtv/movies/$title$starttime.avi -s \n};
print qq{/ndtv/scripts/ndtv_tv_rec $channum $endpos /ndtv/movies/$title$starttime.avi};
system ("/ndtv/scripts/ndtv_tv_rec $channum $endpos /ndtv/movies/$title$starttime.avi > /dev/null");

#FI
#move info from torecord to recordedtv then remove torecord record
$query = "insert into recordedtv select title,subtitle,description,starttime,endtime,channel,category,NULL from torecord where channel=\"$channel\" and starttime=\"$starttime\"";$dbh->do($query);
$query = "delete from torecord where channel=\"$channel\" and starttime=\"$starttime\"";


#delete from torecord
#$query = "delete from torecord where title=\"$title\"";
$dbh->do($query);

#FI
#$query = "update recordedtv set filename=\"/ndtv/movies/$title$starttime.avi\" where channel=\"$channel\" and starttime=\"$starttime\"";


#add filename to recordedtv
$query = "update recordedtv set filename=\"/ndtv/movies/$title$starttime.avi\" where channel=\"$channel\" and starttime=\"$starttime\"";
$dbh->do($query);

