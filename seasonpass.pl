#!/usr/bin/perl -w

use DBI;
use Date::Calc qw(:all);
print " Running Season Pass";
#get current time, so we don't try to record anything in the past
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

$dbh = DBI->connect("DBI:mysql:ndtv:localhost",
		    "ndtv", "mysql");

#get each of the entries from the seasonpass table
$query = "select * from seasonpass";

$sth = $dbh->prepare($query);
$sth->execute;

$i = 0;

while (@row = $sth->fetchrow_array) {
    $title[$i] = $row[0];
    $channel[$i] = $row[1];
    $timeofday[$i] = $row[2];
    $i++;
}

$k = 0;

#find instances of the seasonpass programs in programme
for ($j = 0; $j < $i; $j++) {
    $query = "select starttime,channel,title from programme where title = \"$title[$j]\" and channel = \"$channel[$j]\" and starttime like \"\%$timeofday[$j]\"";
    $sth = $dbh->prepare($query);
    $sth->execute;
    
    #get starttime and channel of each program
    while (@row2 = $sth->fetchrow_array) {
	$starttime[$k] = $row2[0];
	$channel2[$k] = $row2[1];
	$title2[$k] = $row2[2];
	$k++;
    }
}

#check if program is already in torecord
for ($l = 0; $l < $k; $l++) {
    #find atjobno
    $query = "select atjobno from torecord where starttime=$starttime[$l] and channel=\"$channel2[$l]\" and title=\"$title2[$l]\"";
    $sth = $dbh->prepare($query);
    $sth->execute;

    #run atrm for that at job
    while (@row3 = $sth->fetchrow_array) {
	`atrm $row3[0]`;
    }

    #delete from torecord to avoid conflict
    $query = "delete from torecord where starttime=$starttime[$l] and channel=\"$channel2[$l]\" and title=\"$title2[$l]\"";
    $dbh->do($query);
    
}

#run record_tv_init for each starttime/channel
for ($m = 0; $m < $k; $m++) {
    if ($starttime[$m] < $currenttime) {
	#starttime is in the past, do nothing
	#print "$starttime[$m] $channel2[$m] PAST!\n";
    } else {
	#print "$starttime[$m] $channel2[$m] Future\n";
	`/home/ndtv/DBGroup/record_tv_init.pl $starttime[$m] $channel2[$m] `;

print qq{Running record_tv_init on $starttime[$m] on channel $channel2[$m]\n};
	#run record_tv_init, deleting existing torecord request
	#if necessary
	#`./record_tv_init.pl $starttime[$m] \"$channel2[$m]\" 1`;
    }
}
