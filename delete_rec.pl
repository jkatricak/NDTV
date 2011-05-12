#!/usr/bin/perl -w

use DBI;

#open(LOG, ">>record.log") || die "Can't open log!\n";

#FI
$starttime = $ARGV[0];
$channel = $ARGV[1];
for ($i=2;$i<=$#ARGV;$i++) {
    $channel = $channel . " " . $ARGV[$i];
}
print qq{ Channel = $channel and starttime = $starttime \n};
$dbh = DBI->connect("DBI:mysql:ndtv:localhost",
		    "ndtv", "mysql");
$query = "select filename from recordedtv where channel=\"$channel\" and starttime=\"$starttime\"";

$sth = $dbh->prepare($query);
$sth->execute;

$filename = $sth->fetchrow_array;
$output = `rm -f $filename`;
print $output;
#FI
#FI
$query = "delete from recordedtv where channel=\"$channel\" and starttime=\"$starttime\"";

$dbh->do($query);

