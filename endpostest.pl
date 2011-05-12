#!/usr/bin/perl -w
use Date::Calc qw(:all);
$starttime = '20031231233000';
$endtime = '20040101010100'; 

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
print qq{Fuck - $starttime - $elapsed \n};
