#!/usr/bin/perl -w



#use strict;
use DBI;
use Date::Calc qw(:all);

my $sixzs;
$Daystoerase = 2;
$listingdays = 14;
$mainpath = '/home/ndtv/DBGroup/';
$listingpath =$mainpath; 
$xmltosqlpath = $mainpath;
$Dd = $Daystoerase * -1;
#However it doesn't check to see if listings change


# This gets the time

($year,$month,$day) = System_Clock();# $hour,$min,$sec) = System_Clock();



#print " Today = $year$month$day\n";

#use one of the Date::Calc functions to subtract days from the date... even works in leap years

($nyear,$nmonth,$nday) = Add_Delta_Days($year,$month,$day,$Dd);

#We want to have leading zeros so our date strings are consistent
#
if ( $nmonth < '10'){
    $nmonth = '0' . $nmonth;
}
if ( $nday < '10'){
    $nday = '0' . $nday;
}

if ( $month < '10'){
    $month = '0' . $month;
}
if ( $day < '10'){
    $day = '0' . $day;
}

$sixzs = '000000';
#This string determines the date before time using the calculated days plus a dummy string of 0's for midnight.
$delbefore = $nyear . $nmonth . $nday . $sixzs;# . $hour . $min . $sec;

$fileprefix = $year . $month . $day;

$tvgrabstr = 'tv_grab_na --days ' . $listingdays . ' > ' . $listingpath . $fileprefix . 'unsorted.xml'; # 

$unsortedfile = $fileprefix . 'unsorted.xml';
$sortedfile = $fileprefix . 'sorted.xml';
$sorttvstr = 'tv_sort < ' . $listingpath . $unsortedfile . ' > ' . $listingpath . $sortedfile; 




#print " New Day = $delbefore\n";


$dbh = DBI->connect ("DBI:mysql:ndtv",
                      "ndtv", "mysql",
                      { RaiseError => 1, PrintError => 0});
$query = "DELETE FROM programme WHERE starttime < $delbefore";

$dbh->do($query);


$dbh->disconnect ();

$pxstring = 'perl ' . $xmltosqlpath . 'xml2sql.pl ' . $listingpath . $sortedfile; 
$chanupstring = 'perl ' . $mainpath . 'chanlogo.pl ' . $listingpath . $sortedfile; 
$lp = $listingpath . $sortedfile;
$np = $listingpath . 'currentlistings.xml';
`cp $lp $np`;
$spass = 'perl ' . $mainpath . 'seasonpass.pl';
$pud = 'perl ' . $mainpath . 'progupdate.pl';

#print $tvgrabstr . "\n";
#print $sorttvstr . "\n";
#print $pxstring . "\n";

system($tvgrabstr);
system($sorttvstr);
system($pxstring);
system($chanupstring);
system($spass);
system($pud);
system('rm ' . $listingpath . $unsortedfile);




sub dequote {
    my ($samp) = @_;
    $samp =~ s/'/''/g;
    return $samp
}

