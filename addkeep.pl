#!/usr/bin/perl -w

use DBI;

#open(LOG, ">>record.log") || die "Can't open log!\n";

#FI
$starttime = $ARGV[0];
$channel = $ARGV[1];
for ($i=2;$i<=$#ARGV;$i++) {
    $channel = $channel . " " . $ARGV[$i];
}
$dbh = DBI->connect("DBI:mysql:ndtv:localhost",
		    "ndtv", "mysql");


$query = "update recordedtv set keep=1 where channel=\"$channel\" and starttime=\"$starttime\"";

#$query = "delete from torecord where title=\"$title\"";
$dbh->do($query);

