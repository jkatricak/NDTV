#!/usr/bin/perl -w

use DBI;


#$starttime = 20030226000000;
#$channel = "28 WSJV";

#FI

$starttime = $ARGV[0];
$channel = $ARGV[1];
$channel = $channel . " " . $ARGV[2];




$dbh = DBI->connect("DBI:mysql:ndtv:localhost",
		    "ndtv", "mysql");

$query = "select title from programme where starttime=\"$starttime\" and channel=\"$channel\"";
$sth = $dbh->prepare($query);
$sth->execute;
$title = $sth->fetchrow_array;

$starttime =~ /(\d\d\d\d)(\d\d)(\d\d)(\d\d\d\d)(\d\d)/;
$year = $1; $month = $2; $day = $3;
$stime = $4;$stime2 = $5;

$sptime = $stime . $stime2; 

$query = "insert into seasonpass set title=\"$title\",channel=\"$channel\",timeofday=\"$sptime\"";
$dbh->do($query);
print "\n $title added as a Season pass! \n";
`/home/ndtv/DBGroup/seasonpass.pl`
