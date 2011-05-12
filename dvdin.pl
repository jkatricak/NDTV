#!/usr/bin/perl -w

#use strict;
use DBI;
#use File::Spec;


#read in filename from command line and assign to variable
$filename = $ARGV[0];
#$filename = File::Spec->rel2abs( $filename ) ;

#NOTE: assumes all movies saved to /ndtv/movies
$filename =~ /(\/ndtv\/movies\/)(\w+)(.)(\w+)/;
$title = $2;
$format = $4;

$dbh = DBI->connect ("DBI:mysql:ndtv",
                      "ndtv", "mysql",
                      { RaiseError => 1, PrintError => 0});
$query = ("INSERT INTO video (title, filename, format) values (\"$title\", \"$filename\", \"$format\")");

$dbh->do($query);



sub dequote {
    my ($samp) = @_;
   # print "Samp $samp\n";
    $samp =~ s/\'/\'\'/g;
#print "Samp $samp\n";
    return $samp
}

