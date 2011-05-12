#!/usr/bin/perl -w

#runs accessdb and checks if files exist for filenames listed
#errors reported to file_DNE.err
#optional: removes record from db if file does not exist
#usage: ./fileexist.pl

use DBI;

#open error log for output
#WILL NEED TO CHANGE NAME OF FILE LATER!
open(ERR, ">>file_DNE.err") || die "Can't open error log!\n";

#insert run date and time into log
$datetime = `date`;
print ERR "$datetime";

$dbh = DBI->connect("DBI:mysql:ndtv:localhost",
		    "ndtv", "mysql");

#audio
$query = "select filename from audio";
$sth = $dbh->prepare($query);
$sth->execute;
while (@audio = $sth->fetchrow) {
    if( -e "$audio[0]" ) {
	#do nothing
    } else {
	print ERR "$audio[0] does not exist!\n";
	$query = "delete from audio where filename=\"$audio[0]\"";
	$dbh->do($query);
    }
}

#pictures
$query = "select filename from pictures";
$sth = $dbh->prepare($query);
$sth->execute;
while (@pictures = $sth->fetchrow) {
    if( -e "$pictures[0]" ) {
	#do nothing
    } else {
	print ERR "$pictures[0] does not exist!\n";
	$query = "delete from pictures where filename=\"$pictures[0]\"";
	$dbh->do($query);
    }
}

#video
$query = "select filename from video";
$sth = $dbh->prepare($query);
$sth->execute;
while (@video = $sth->fetchrow) {
    if( -e "$video[0]" ) {
	#do nothing
    } else {
	print ERR "$video[0] does not exist!\n";
	$query = "delete from video where filename=\"$video[0]\"";
	$dbh->do($query);
    }
}

#recordedtv
$query = "select filename from recordedtv";
$sth = $dbh->prepare($query);
$sth->execute;
while (@recordedtv = $sth->fetchrow) {
    if( -e "$recordedtv[0]" ) {
	#do nothing
    } else {
	print ERR "$recordedtv[0] does not exist!\n";
	$query = "delete from recordedtv where filename=\"$recordedtv[0]\"";
	$dbh->do($query);
    }
}
print ERR "\n \n";
