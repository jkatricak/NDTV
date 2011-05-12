#!/usr/bin/perl -w

use DBI;
use Date::Calc qw(:all);

#open(LOG, ">>record.log") || die "Can't open log!\n";

#get current time
($year,$month,$day,$hour,$minute,$second) = System_Clock();
#We want to have leading zeros so our date strings are consistent
if ( $month < '10'){
    $month = '0' . $month;
}
if ( $day < '10'){
    $day = '0' . $day;
}
if ( $hour < '10'){
    $hour = '0' . $hour;
}
if ( $minute < '10'){
    $minute = '0' . $minute;
}
if ( $second < '10'){
    $second = '0' . $second;
}
$currenttime = $year . $month . $day . $hour . $minute . $second;

#FI
$starttime = $ARGV[0];
$channel = $ARGV[1];
for ($i=2;$i<=$#ARGV;$i++) {
    $channel = $channel . " " . $ARGV[$i];
}
print qq{ Channel = $channel and starttime = $starttime \n};
$dbh = DBI->connect("DBI:mysql:ndtv:localhost",
		    "ndtv", "mysql");

$query = "select endtime from torecord where channel=\"$channel\" and starttime=\"$starttime\"";

$sth = $dbh->prepare($query);
$sth->execute;

$endtime = $sth->fetchrow_array;

if (($starttime < $currenttime) && ($endtime > $currenttime)) {
    `killall mencoder`;
} else {
    
    $query = "select atjobno from torecord where channel=\"$channel\" and starttime=\"$starttime\"";
    
    $sth = $dbh->prepare($query);
    $sth->execute;
    
    $atjobno = $sth->fetchrow_array;
`atrm $atjobno`;
#FI
#FI
    $query = "delete from torecord where channel=\"$channel\" and starttime=\"$starttime\"";

#$query = "delete from torecord where title=\"$title\"";
    $dbh->do($query);

}
