#!/usr/bin/perl -w

use DBI;
use Date::Calc qw(:all);

#open(LOG, ">>record.log") || die "Can't open log!\n";

$datelimit = 0;
$dirsize = `du /ndtv/movies/ | awk '{print \$1}'`;


$dbh = DBI->connect("DBI:mysql:ndtv",
		    "ndtv", "mysql");
$query = "select starttime,channel from recordedtv where keep=0 order by starttime";

$sth = $dbh->prepare($query);
$sth->execute;

print " Directory size = $dirsize \n";
while(`du /ndtv//movies | awk '{print \$1}'` >29000000){
@show = $sth->fetchrow_array;
$starttime = $show[0];
$channel = $show[1]; 
print "Deleting $starttime at $channel\n";
$dres = `/home/ndtv/DBGroup/delete_rec.pl $starttime $channel`;
print "Result: $dres \n";
}




#$output = `rm -f $filename`;
#print $output;
#FI
#FI
#$query = "delete from recordedtv where channel=\"$channel\" and starttime=\"$starttime\"";

#$dbh->do($query);

