#!/usr/bin/perl -w

# Compares torecord with programme to check for time changes

use DBI;
use Date::Calc qw(:all);
print "Running Program Time Update\n";

$dbh = DBI->connect("DBI:mysql:ndtv:localhost",
		    "ndtv", "mysql");

#get each of the entries from the torecord table
$query = "select title,subtitle,description,starttime,endtime,channel,category from torecord";

$sth = $dbh->prepare($query);
$sth->execute;

$i = 0;

while (@row = $sth->fetchrow_array) {
    $tr_title[$i] = $row[0];
    $tr_subtitle[$i] = $row[1];
    $tr_description[$i] = $row[2];
    $tr_starttime[$i] = $row[3];
    $tr_endtime[$i] = $row[4];
    $tr_channel[$i] = $row[5];
    $tr_category[$i] = $row[6];
    $i++;
}

#find matches in programme (except for starttime, endtime, atjobno)
for ($j = 0; $j < $i; $j++) {
    $query = "select starttime,endtime from programme where title = \"$tr_title[$j]\" and subtitle = \"$tr_subtitle[$j]\" and description = \"$tr_description[$j]\" and channel = \"$tr_channel[$j]\" and category = \"$tr_category[$j]\"";
    $sth = $dbh->prepare($query);
    $sth->execute;
    
    #get new starttime/endtime, and number of answers returned
    while (@row2 = $sth->fetchrow_array) {
	$prog_starttime[$j] = $row2[0];
	$prog_endtime[$j] = $row2[1];
    }
}

#count number of occurences of each match
for ($k = 0; $k < $i; $k++) {
    $query = "select COUNT(*) from programme where title = \"$tr_title[$k]\" and subtitle = \"$tr_subtitle[$k]\" and description = \"$tr_description[$k]\" and channel = \"$tr_channel[$k]\" and category = \"$tr_category[$k]\"";
    $sth = $dbh->prepare($query);
    $sth->execute;
    
    #get new starttime/endtime, and number of answers returned
    while (@row3 = $sth->fetchrow_array) {
	$prog_count[$k] = $row3[0];
    }
}

#for ($l = 0; $l < $i; $l++) {
#    print ("$tr_starttime[$l], $prog_starttime[$l], $tr_endtime[$l], $prog_endtime[$l], $prog_count[$l]\n");
#}

#compare old and new starttime/endtimes
for ($l = 0; $l < $i; $l++) {
    if ((($tr_starttime[$l] == $prog_starttime[$l]) && ($tr_endtime[$l] == $prog_endtime[$l])) || $prog_count[$l] > 1) {
	#no change in time, do nothing
	#or, program was found more than once, so ignore
	#("The Price is Right Rule")
    } else {
	#cancel old torecord
	`perl /home/ndtv/DBGroup/cancel_rec.pl $tr_starttime[$l] $tr_channel[$l]`;
	print ("Canceling $tr_title[$l] on $tr_starttime[$l]\n");
	#create new torecord
	`perl /home/ndtv/DBGroup/record_tv_init.pl $prog_starttime[$l] $tr_channel[$l]`;
	print ("Replacing with new starttime $prog_starttime[$l]\n");
    }
}
