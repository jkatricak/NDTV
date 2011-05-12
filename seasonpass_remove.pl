#!/usr/bin/perl -w

use DBI;


#$starttime = 20030226000000;
#$channel = "28 WSJV";

#FI

$timeofday = $ARGV[0];
$channel = $ARGV[1];
$channel = $channel . " " . $ARGV[2];
$title = $ARGV[3];



$dbh = DBI->connect("DBI:mysql:ndtv:localhost",
		    "ndtv", "mysql");

$query = "delete from seasonpass where timeofday=\"$timeofday\" and title=\"$title\" and channel=\"$channel\"";
$sth = $dbh->prepare($query);
$sth->execute;

$query = "select starttime,channel from torecord where channel=\"$channel\" and title=\"$title\" and starttime like \"%$timeofday\"";
$sth = $dbh->prepare($query);
$sth->execute;


$i = 0;
while( @row = $sth->fetchrow_array) {
print "Fuck me - $row[0] - $row[1] \n";
$tempstime[$i] = $row[0];
$tempchannel[$i] = $row[1];	
$i++;
}

$j = 0;
while ($j < $i){
print "Tester -> $tempstime[$j] - $tempchannel[$j]";
`/home/ndtv/DBGroup/cancel_rec.pl $tempstime[$j] $tempchannel[$j]`;
$j++;
}

print "\n $title $timeofday removed from Season pass! \n";
