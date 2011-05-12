#!/usr/bin/perl -w
use strict;
use DBI;
use XML::Twig;
use Date::Calc qw(:all);
my $file = $ARGV[0];
my $twig = XML::Twig->new();
my $str;
my $hst; my $het;
my $hch;
my $hstring;
my $smin; my $emin;
my $shrs; my $ehrs;
my $year; my $eyear;
my $month; my $emonth;
my $day; my $eday;
my $hour; my $ehour;
my $second; my $esecond;
my $minute; my $eminute;
my $doy; my $edoy;
my $query;
my $dbh = DBI->connect ("DBI:mysql:ndtv",
                           "ndtv", "mysql",
                           { RaiseError => 1, PrintError => 0});

$twig->parsefile($file);


my $root = $twig->root;

foreach my $show ($root->children('programme')){
    
    $str = "title='" . &dequote($show->first_child_text('title')) . "'";
    $str .= ",starttime='" . $show->att('start') . "'";
    $str .= ",endtime='" . $show->att('stop') . "'";
    $str .= ",category='" . &dequote($show->first_child_text('category')) . "'";
    $str .= ",description='" . &dequote($show->first_child_text('desc')) . "'";
    $str .= ",subtitle='" . &dequote($show->first_child_text('sub-title')) . "'";
    $str .= ",channel='" . $show->att('channel') . "'";


    #print $str;
    
    $dbh->do ("REPLACE INTO programme SET $str");

    $hch = $show->att('channel');
    $hst = $show->att('start');
    $het = $show->att('stop');

#if ($hst eq "20030328033000 EST"){
#print "hst - - - $hst het - - - $het \n";
#}


$hst =~ /(\d\d\d\d)(\d\d)(\d\d)(\d\d)(\d\d)(\d\d)/;
$year = $1; $month = $2; $day = $3; $hour = $4;
$minute = $5; $second = $6;
$doy = Day_of_Year($year,$month,$day);


$shrs = ($doy * 24) + $hour;
$smin = ($doy * 24*60) + ($hour * 60) + $minute;

#if ($hst eq "20030328033000 EST"){
#$doy = $hour*2;
#print "doy $doy hour $hour minute $minute shrs $shrs smin $smin \n";
#}

$het =~ /(\d\d\d\d)(\d\d)(\d\d)(\d\d)(\d\d)(\d\d)/;
$eyear = $1; $emonth = $2; $eday = $3; $ehour = $4;
$eminute = $5;$esecond= $6; 
$edoy = Day_of_Year($eyear,$emonth,$eday);
$ehrs = ($edoy * 24) + $ehour;
$emin = ($edoy * 24*60) + ($ehour * 60) + $eminute;
#if ($hst eq "20030328033000 EST"){
#$edoy = ($edoy*24*60);
#print "edoy $edoy ehour $ehour eminute $eminute - ehrs $ehrs emin $emin\n";
#print "\n";
#}

$hst =~ /(\d\d\d\d)(\d\d)(\d\d)(\d\d)(\d\d)(\d\d)/;
$hst = $1 . $2 . $3 . $4 . $5 . $6;
#$hstring = "starttime=\'$hst\', channel=\'$hch\',hours=\'$hhrs\',minutes=\'$hmin\'";
$hstring = "shours=\'$shrs\',sminutes=\'$smin\',ehours=\'$ehrs\',eminutes=\'$emin\'";
    $query = qq{UPDATE programme SET $hstring where starttime=\'$hst\' and channel=\'$hch\'};
$dbh->do ($query);

}


$dbh->disconnect ();


sub dequote {
    my ($samp) = @_;
   # print "Samp $samp\n";
    $samp =~ s/'/''/g;
#print "Samp $samp\n";
    return $samp
}
