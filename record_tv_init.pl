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

#FI

$starttime = $ARGV[0];
$channum = $ARGV[1];
#Hopefully this should work as long as XMLTV keeps the 2 string channel IDs
#for ($i=2;$i<=$#ARGV;$i++) {
    $channel = $channum . " " . $ARGV[2];
#}


#open(ATDAT, ">at$starttime.txt") || die "Can't open at.txt $!";
#print ("$channel\n");

$dbh = DBI->connect("DBI:mysql:ndtv:localhost",
		    "ndtv", "mysql");

$query = "select endtime from programme where starttime=\"$starttime\" and channel=\"$channel\"";
$sth = $dbh->prepare($query);
$sth->execute;
$endtime = $sth->fetchrow_array;

#check if torecord already has a record with this starttime
$query = "select channel,starttime,endtime from torecord where (starttime=$starttime) or ($starttime < starttime and $endtime < endtime and $endtime> starttime) or ($starttime > starttime and $endtime > endtime and $starttime < endtime) or ($starttime < starttime and $endtime > endtime) or ( $starttime > starttime and $endtime < endtime)  ";

$sth = $dbh->prepare($query);
$sth->execute;

@row = $sth->fetchrow_array;

if (@row > 0) 
{
# We have found a scheduling conflict... 
    
    if ($#ARGV < 3)
    {
	#First Run, no preference.
	print "error\n";
	print "Scheduled to be recorded: @row\n";
	print "New Recording Requested:  $channel $starttime $endtime\n";
	exit;
    }  
    else
     {
       #Preference is given - 1 for new, 0 for old
	 if ($ARGV[3] == 1){
	     #remove old show
	     `./cancel_rec.pl $row[1] $row[0]`;
	 }
	 else {
	     exit;
	 }

     }}
else 
{
#No scheduling Conflict
    print "success\n";
}



$query = "select title from programme where starttime=\"$starttime\" and channel=\"$channel\"";

$sth = $dbh->prepare($query);
$sth->execute;

$title = $sth->fetchrow_array;
print "This show has been set up to be recorded -> " . $title . "\n";


$starttime =~ /(\d\d\d\d)(\d\d)(\d\d)(\d\d\d\d)(\d\d)/;
$year = $1; $month = $2; $day = $3;
$stime = $4;
#FI

######################################

if (($starttime <= $currenttime) && ($endtime > $currenttime)) {
    #record now!
    print ("Recording now!\n");
    
    #move to torecord for program guide
    $query = "insert into torecord select title,subtitle,description,starttime,endtime,channel,category,NULL from programme where starttime=\"$starttime\" and channel=\"$channel\"";
    $dbh->do($query);

    $currenttime =~ /(\d\d\d\d)(\d\d)(\d\d)(\d\d)(\d\d)(\d\d)/;
    $year = $1; $month = $2; $day = $3; $hour = $4;
    $minute = $5; $second = $6;
    $msec = 60;$hsec = 60*60;$dsec = 24*60*60;$ysec = 365*24*60*60;
    $doy = Day_of_Year($year,$month,$day);
    $cytime = $ysec * ( $year - 2000);
    $ctsec = $cytime + $second+($minute*$msec)+($hour*$hsec)+($doy*$dsec);
    $endtime =~ /(\d\d\d\d)(\d\d)(\d\d)(\d\d)(\d\d)(\d\d)/;
    $year = $1; $month = $2; $day = $3; $hour = $4;
    $minute = $5; $second = $6;
    $doy = Day_of_Year($year,$month,$day);
    $eytime = $ysec * ( $year - 2000);
    $etsec = $eytime +$second+($minute*$msec)+($hour*$hsec)+($doy*$dsec);
    $elapsed = $etsec - $ctsec;
    $endpos = $elapsed;
    #substitute for spaces in title
    $title =~ s/ /_/g;
#run mencoder script
    print qq{ Hmm, here is $channum -1 $endpos -2 /ndtv/movies/$title$starttime.avi -s \n};
    print qq{/ndtv/scripts/ndtv_tv_rec $channum $endpos /ndtv/movies/$title$starttime.avi};
    system ("/ndtv/scripts/ndtv_tv_rec $channum $endpos /ndtv/movies/$title$starttime.avi > /dev/null");
    
#FI
#move info to recordedtv
    $query = "insert into recordedtv select title,subtitle,description,starttime,endtime,channel,category,NULL,0 from torecord where starttime=\"$starttime\" and channel=\"$channel\"";
    $dbh->do($query);

#remove from torecord
    $query = "delete from torecord where starttime=\"$starttime\" and channel=\"$channel\"";
    $dbh->do($query);
    
#FI
#$query = "update recordedtv set filename=\"/ndtv/movies/$title$starttime.avi\" where channel=\"$channel\" and starttime=\"$starttime\"";
    
    
#add filename to recordedtv
    $query = "update recordedtv set filename=\"/ndtv/movies/$title$starttime.avi\" where channel=\"$channel\" and starttime=\"$starttime\"";
    $dbh->do($query);

} elsif ($endtime < $currenttime) {
    #Do nothing, program is in the past
    print ("Stop living in the past!\n");
} elsif ($starttime > $currenttime) {
    print("atjob!\n");
    open(ATDAT, ">at$starttime.txt") || die "Can't open at.txt $!";
    print ATDAT "/home/ndtv/DBGroup/record_tv_execute.pl $starttime \"$channel\"";
    
#print ATDAT "/home/ndtv/DBGroup/record_tv_execute.pl \"$title\"";
    $pstring = `at $stime $month/$day/$year < at$starttime.txt 2>&1`;
    $atjob = `echo \"$pstring\" | grep job | awk '{print \$2}'`;
    $query = "insert into torecord select title,subtitle,description,starttime,endtime,channel,category,NULL from programme where starttime=\"$starttime\" and channel=\"$channel\"";
    $dbh->do($query);
    $query = "update torecord set atjobno=$atjob where starttime=\"$starttime\" and channel=\"$channel\"";
    $dbh->do($query);
    `rm at$starttime.txt` 
    }
