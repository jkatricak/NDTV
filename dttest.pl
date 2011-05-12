#!/usr/bin/perl -w

use DBI;
use Date::Calc qw(:all);

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
print ("$currenttime\n");

$starttime = $ARGV[0];
$endtime = $ARGV[1];

if (($starttime < $currenttime) && ($endtime > $currenttime)) {
    print ("Recording Now!\n");
} elsif ($endtime < $currenttime) {
    print ("Stop living in the past!\n");
} elsif ($starttime > $currenttime) {
    print("atjob!\n");
}
