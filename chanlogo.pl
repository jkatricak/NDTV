#!/usr/bin/perl -w

use strict;
use DBI;
use XML::Twig;
use File::Spec;

my $file = $ARGV[0];
my $twig = new XML::Twig(TwigRoots => {channel => 1}); # so it only looks for <channel> elements
#my $twig = XML::Twig->new();
my $str; 
my $volume;
my $directories;
my $logofile;
my $wstr;
my $clogo;
my $lpath = "/home/ndtv/DBGroup/logos/";
my $channame;
my $chanid;
my $channum;
my $icon;
my @info;
my $dbh = DBI->connect ("DBI:mysql:ndtv",
                         "ndtv", "mysql",
                        { RaiseError => 1, PrintError => 0});

$twig->parsefile($file);


my $root = $twig->root;

foreach my $channel ($root->children('channel')){
  
   $icon = $channel->first_child('icon');
   $chanid = &dequote($channel->att('id'));
   $channame = &dequote( $channel->first_child_text('display-name'));
   @info = split / / , $chanid;
   $channum = &dequote($info[0]);
   
   $str = "chanid='" . $chanid . "'";
   $str = $str . ",channame='" . $channame . "'";
   $str = $str . ",channum='" . $channum . "'";

  # print "channame : " . $channame . "\n";
  # print "chanid : " . $chanid . "\n";
  # print "channum : " . $channum . "\n";



   if ( $icon ne '')
{
    $clogo = &dequote($icon->att('src'));
    
    ($volume,$directories,$logofile) = File::Spec->splitpath( $clogo );
    
    #print $logofile . "\n";
 
    $str = $str . ",logofile='" . $logofile . "'";
    $wstr = "wget " . $clogo . " -P " . $lpath . " -nv -N";
    
    system($wstr);


    
}    

$dbh->do ("REPLACE INTO channel SET $str");




}


$dbh->disconnect ();


sub dequote { # dequote replaces ' with '' so mysql doesn't puke
    my ($samp) = @_;
  
    $samp =~ s/'/''/g;
#print "Samp $samp\n";
    return $samp
}
