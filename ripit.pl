#!/usr/bin/perl
#
# ripit.pl - Rips CD Audio and creates MP3 files
#            Does the following:
#		Query CDDB data for Album/Artist/Track info
#		Rip the Audio wav files from the CD
#		Encode the MP3 files
#		id3 tag the MP3 files
#		Create an M3U file
#
# Options:
#	[start_track] 		- rips from this track to last track
#	--halt 			- powers off the machine when finished
#			  	  if your configuration supports it
#	--bitrate [rate] 	- Encode MP3 at this bitrate 
#	--year [year]		- Tag MP3 with this year (included as CDDB
#				  does not store this information)
#       --genre [genre]		- Overrides CDDB genre, e.g. rock,funk
#       --device [device]       - CDROM device to rip from
#	--encopt [options]	- Parameters to pass to encoder
#	--encoder [encoder]	- Encoder to use, see below
#	--cdripper [ripper]	- Cdripper to use, see below
#	--cdopt [options]	- Parameters to pass to cdripper
#	--outputdir [dir]	- Where MP3s should go
#
# Version 2.0 20/08/01 - Simon Quinn
#
# Usage: ripit.pl [--halt] [--bitrate rate] [--year year] [--genre genre]
#                 [--device cddevice] [--encopt options] [--encoder encoder]
#		  [--cdripper cdripper] [--cdopt options] [--outputdir dir] 
#	 	  [start_track]
####################################################################

use Expect; #JPK

#
# User configurable variables
#

$cddev 		= "/dev/cdrom";		# CD Audio device
$outputdir 	= "/ndtv/audio/";        # Where the MP3s should go, 
					# must have trailing /
$bitrate	= 160;			# Bitrate for MP3s
$encoder	= 0; 			# 0 - Lame, 1 - OggVorbis
$encopt		= "";			# options for mp3 encoder
$cdripper	= 0;			# 0 - dagrab,
					# 1 - cdparanoia, 2 - cdda2wav,
					# 3 - tosha, 4 - cdd
$cdopt		= "";			# options for cdaudio ripper

$CDDB_HOST	= "freedb.freedb.org";  # set cddb host
$CDDB_PORT	= 8880;                 # set cddb port
$CDDB_MODE	= "cddb";               # set cddb mode: cddb or http
$CDDB_INPUT	= 0;                    # 1 ask user if multiple CDs found, 
					# 0 no interaction - JPK

$mainpath        = "/home/ndtv/DBGroup"; #where musicin.pl is located
    
$use_underscore = 1;	# Use _ instead of spaces in filenames (1 yes, 0 no)

# Track template variable. Contains the format the track names will be
# written as. The '" and "' are important and must surround the template.
# Example variables to use are: $tracknum, $trackname, $album, $artist
# E.G. Default setting produces a trackname of "02 Alphabet Street"

#$tracktemplate  = '"$tracknum $trackname"';

$tracktemplate  = '"$artist - $trackname"';

#######################################################################
# No User configurable parameters below here
#######################################################################

require "flush.pl";
use Getopt::Long;
use CDDB_get qw ( get_cddb );
use DBI;

# Initialise global variables
#
$year		= "";	# Year of Audio CD - written to MP3 tag
$haltonfinish	= 0;	# Shutdown machine when finished?, default to no
$nocddbinfo	= 1;    # Assume no CDDB info exists
$trackselection = "";   # Passed from command line

####################################################
# Do the following:
#  1. Get command line parameters
#  2. Get CDDB data for CD  
#  3. Get CD information, i.e. Artist, Album etc
#  4. Create Directory where the MP3s will go
#  5. Rip the CD
#  6. Encode and id3 Tag the files in the background
#  7. Create the M3U file
####################################################

# Get the parameters from the command line
if ( ! &GetOptions("halt" => \$haltonfinish, 
                  "bitrate=i" => \$bitrate,
		  "year=i" => \$year,
		  "genre=s" => \$genre,
		  "device=s" => \$cddev,
		  "encopt=s" => \$encopt,
		  "encoder=i" => \$encoder,
		  "cdripper=i" => \$cdripper,
		  "cdopt=s" => \$cdopt,
		  "outputdir=s" => \$outputdir ) ) {
   print "Usage: ripit.pl [--halt] [--bitrate rate] [--year year]
                [--device cddevice] [--encopt options] [--encoder encoder]
		[--cdripper cdripper] [--cdopt options] [--outputdir dir] 
		[start_track]\n";
   exit 1;
}

if ( length($year) > 0 && length($year) != 4 ) {
        print STDERR "Warning: year is not Y2K compliant - $year\n";
}

if ($haltonfinish == 1) {print "Will halt machine when finished.\n";}

# Get starting track parameter if it has been given
if ($ARGV[0] ne '') {
  $trackselection = $ARGV[0];
}              

# All logging information goes into this file
$logfile = "/tmp/ripitlog.".substr($cddev, rindex($cddev,"/") + 1);
open(RIPLOG, ">$logfile") || die "Cannot create $logfile: $!";

# All mp3 encoder messages go here
$enclog = "/tmp/encoderlog.".substr($cddev, rindex($cddev,"/") + 1);

# Tidy up from previous session
system("rm /tmp/id3ren.log $enclog >/dev/null 2>&1");

&get_cdinfo();				# Extract CD info from CDDB toc
&create_seltrack($trackselection);	# Create track selection 
#We don't want to create a subdirectory - JPK
#&create_dirs();				# Create directories MP3 files
&rip_cd();				# Rip, Encode & Tag

print "Waiting for MP3 Encoder to finish...\n";
wait; 

&create_m3u();			# Create the M3U file for the MP3 files

print "\nAll Complete.\n";
&printflush(RIPLOG,"\nAll Complete.\n");

# Delete logs and temporary files
system("rm /tmp/id3ren.log $enclog >/dev/null 2>&1");

# Uncomment to eject CD when finished
#system("/usr/bin/eject");

# Shutdown and poweroff when finished only if flag is set
if ($haltonfinish == 1) {
  &printflush(RIPLOG,"Shutdown PC...\n");
  close(RIPLOG);
  system("/sbin/poweroff");
}

close(RIPLOG);

exit;

#
# Create the track selection from the parameters passed
# on the command line
#
sub create_seltrack {

  my($i, $tempstr);

  ($tempstr) = @_;

  if ($tempstr =~ /-/) { die "Track selection invalid"; }

  if ($tempstr eq '') {
    for($i=1; $i <= ($#tracklist + 1); $i++) { $seltrack[$i - 1] = $i; }
  }
  elsif ($tempstr =~ /,/) { 
    @seltrack = split(/,/ , $tempstr); 
    if ($#seltrack == 0) {
      $x = 0;
      for ($i=$seltrack[0]; $i <= ($#tracklist + 1); $i++) { 
        $seltrack[$x++] = $i; 
      }
    }
  } 
  elsif ($tempstr =~ /^[0-9]*[0-9]$/) { $seltrack[0] = $tempstr; }
  else { die "Track selection invalid"; }

  # Sort the tracks in order, perl is so cool :-)
  @seltrack = sort {$a <=> $b} @seltrack;

  # Check the validaty of the track selection
  foreach (@seltrack) {
    if ($_ > ($#tracklist + 1)) {
      die "Track selection higher than number of tracks";
    }
  }

}

#
# Read the Album, Artist, DiscID and Track Titles
# from the CDDB generated TOC file
#
sub get_cdinfo {

  my %config;
 
  #Configure CDDB_get parameters
  $config{CDDB_HOST} = $CDDB_HOST;      
  $config{CDDB_PORT} = $CDDB_PORT;       
  $config{CDDB_MODE} = $CDDB_MODE; 
  $config{CD_DEVICE} = $cddev;
  $config{input} = $CDDB_INPUT;

  my %cd=get_cddb(\%config); 			# Get CD TOC from CDDB_get

  if(defined $cd{title}) {

    $artist = $cd{artist};
    $album = $cd{title};

    if( $genre eq "") {				# Only set if it wasn't
      $genre = $cd{cat};			# passed on command line
    }
    
    $artist =~ s/[:;*#?|><"\$!]//g; 		# Strip dodgey chars
    $artist =~ s/`/'/g;
    $album =~ s/[:;*#?|><"\$!]//g; 		# Strip dodgey chars
    $album =~ s/`/'/g;

    #Translate valid genres for id3 tagger
    $genre =~ s/misc//;
    $genre =~ s/data//;
    $genre =~ s/newage/New Age/;
  
    $nocddbinfo = 0;				# Got CDDB info OK
  }
  else {
    #No CDDB info found for this CD
    $artist = "Unknown";  
    $album = "Unknown";
  }

  if($genre ne "") {
    if(system("lame --genre-list | grep -i \"$genre\" >/dev/null 2>&1")) {
      die "Genre $genre is invalid!";
    }      
  }

  print "\nCD TOC\n";
  print "Artist: $artist\n";
  print "Album: $album\n";
  print "Genre: $genre\n";

  my $n=1;
  foreach my $i ( @{$cd{track}} ) {
    $i =~ s/`/'/g;            # Change ` to ' to avoid problems later  
    $i =~ s/\//-/g;           # Change / to - to avoid problems later  
    $i =~ s/[;:*#?|><"\$!]//g;
    push @tracklist, $i;
    printf("%02d: %s\n", $n,$i);
    $n++;
  }

  print "\n";
  
  if (($seltrack[0] - 1) > $#tracklist) {
    die "Starting track is higher than number of tracks on CD!";
  }

  if ($artist eq "") {
    &printflush(RIPLOG,"TOC ERROR: No Artist Found\n");
    die "TOC ERROR: No Artist Found";
  }

}


#We want all mp3s in same directory for now - JPK
#
# Create the directory where the mp3 files will go
# Fail if directory exists or can't be created
#
#sub create_dirs {
#  # Directory created will be: /outputdir/Artist - Album/
#  # The value must end in /
#
#  $mp3dir = $outputdir.$artist." - ".$album."/";
#
#  if ($use_underscore == 1) { $mp3dir =~ s/ /_/g; }
#
#  if (!opendir(TESTDIR, $mp3dir)) {
#    mkdir($mp3dir,0777) || die "Cannot create directory $mp3dir: $!";
#  }
#  else {
#    closedir(TESTDIR);
#  }
#}

#
# Create the track file name from the template variable
#
sub get_trackname {
    my($trnum, $trname, $riptrname);

    ($trnum, $trname) = @_;

    # Create the full file name from the track template, unless
    # the disk is unknown
    if ($nocddbinfo == 0) {
      $riptrname = $mp3dir.sprintf("%02d",$trnum).$trname;
      $tracknum = sprintf("%02d",$trnum);
      $trackname = $trname;
      if (! eval ("\$riptrname = \$mp3dir.$tracktemplate")) {
        die "Track Template is incorrect, caused eval to fail: $!" ;
      }       
    }
    else {
      $riptrname = $mp3dir.$trname;
    }

    # If using underscores then change spaces to _
    if ($use_underscore == 1) { $riptrname =~ s/ /_/g; }

    return $riptrname;

}

#
# Rip the CD 
#
sub rip_cd {

  my($startenc,$i);

  print "Ripping...\n";
  foreach (@seltrack) {

    $riptrackname = &get_trackname($_, $tracklist[$_ - 1]);
    $riptrackno = $_;

    &printflush(RIPLOG,"Ripping $tracklist[$_ - 1]...\n");

    # Choose the cdaudio ripper to use
    if ($cdripper == 0) {
      if (system("dagrab -d $cddev -v $cdopt -f \"$outputdir$riptrackname.rip\" $riptrackno")) {
	&printflush(RIPLOG,"cdparanoia failed on $tracklist[$_ - 1]\n");
         die "dagrab failed on $tracklist[$_ - 1]";
      }
    }
    elsif ($cdripper == 1) {
      if (system("cdparanoia -d $cddev $cdopt $riptrackno \"$outputdir$riptrackname.rip\"")) {
         &printflush(RIPLOG,"cdparanoia failed on $tracklist[$_ - 1]\n");
         die "cdparanoia failed on $tracklist[$_ - 1]";
      }
    }
    elsif ($cdripper == 2) {
      if (system("cdda2wav -D $cddev -Q -H $cdopt -t $riptrackno \"$outputdir$riptrackname.rip\"")) {
         &printflush(RIPLOG,"cdda2wav failed on $tracklist[$_ - 1]\n");
         die "cdda2wav failed on $tracklist[$_ - 1]";
      }
    }
    elsif ($cdripper == 3) {
      if (system("tosha -d $cddev -f wav -t $riptrackno -o \"$outputdir$riptrackname.rip\"")) {
       &printflush(RIPLOG,"tosha failed on $tracklist[$_ - 1]\n");
       die "tosha failed on $tracklist[$_ - 1]";
      }
    }
    elsif ($cdripper == 4) {
      $cdd_dev = $cddev;
      $cdd_dev =~ s/^\/dev\/r//;
      $cdd_dev =~ s/c$//;
      if (system("cdd -t $riptrackno -q -f $cdd_dev - 2>/dev/null | sox -t cdr -x - \"$outputdir$riptrackname.rip\"")) {
        &printflush(RIPLOG,"cdd failed on $tracklist[$_ - 1]\n");
        die "cdd failed on $tracklist[$_ - 1]";
      }
    }
    else {
      die "No CD Ripper defined";
    }

    # Rename rip file to a wav for encoder so that it will be picked
    # up by the encoder background process
    rename "$outputdir$riptrackname.rip","$outputdir$riptrackname.wav";

    &printflush(RIPLOG,"Rip complete $tracklist[$_ - 1]\n");

    # Start the Encoder in the background. but only once
    if ($startenc == 0) { 
      $startenc = 1;
      unless (fork) { &enc_cd(); }
    }

  }
}

#
# Encode the wav
# This runs as a separate process from the main program which 
# allows it to continuously encode as the ripping is being done
# The encoder will also wait for the ripped wav in-case the encoder
# is faster than the CDROM.
#
sub enc_cd {
  my($i,$x,$ncount,$enc,$riptrackno);

  foreach (@seltrack) {

    $riptrackname = &get_trackname($_, $tracklist[$_ - 1]);
    $riptrackno = $_;
    $ncount++;
 
    print "\nMP3 Encoding track ".$ncount." of ".($#seltrack + 1)."\n";
    &printflush(RIPLOG,"Encoding $tracklist[$_ - 1]...\n");

    # Keep looping until the file appears, ie wait for cdparanoia
    # timeout after 30 minutes
    $x=0;
    while( ! -r "$outputdir$riptrackname.wav" ){ 
      $x++; 
      if ($x > 179) { die "MP3 encoder waited 30 minutes before giving up"; } 
      sleep 10;
    }

    # Set the encoder we are going to use
    if ($encoder == 0) {
      $enc = "lame $encopt -S -b $bitrate --tt \"$tracklist[$_ - 1]\" --ta \"$artist\" --tl \"$album\" --ty \"$year\" --tg \"$genre\" --tn $riptrackno --add-id3v2 \"$outputdir$riptrackname.wav\" \"$outputdir$riptrackname.mp3\"";
    }
    elsif ($encoder == 1) {
      $enc = "oggenc $encopt -b $bitrate -t \"$tracklist[$_ - 1]\" -a \"$artist\" -l \"$album\" -d \"$year\" -N $riptrackno -o \"$outputdir$riptrackname.ogg\" \"$outputdir$riptrackname.wav\"";
    }

    if ( ! system("$enc >$enclog 2>&1 </dev/null")) {
 
      system("rm \"$outputdir$riptrackname.wav\" >/dev/null 2>&1");
      system("perl $mainpath/musicin.pl $outputdir$riptrackname.mp3");

      &printflush(RIPLOG,"Encoding complete $tracklist[$_ - 1]\n");

    }
    else {
      &printflush(RIPLOG,"MP3 Encoder Failed on $tracklist[$_ - 1]\n");
      die "MP3 Encoder Failed on $tracklist[$_ - 1]";
    }

  }
  exit ;
}

#
# Creates the M3U file used by players such as X11Amp
#
sub create_m3u {
  my ($file);

  $file="$artist.m3u";
  if ($use_underscore == 1) { $file =~ s/ /_/g; }

  if($encoder == 1) {
    system("cd \"$mp3dir\" ; ls -rt *.ogg >\"$file\"");
  }
  else {
    system("cd \"$mp3dir\" ; ls -rt *.mp3 >\"$file\"");
  }
}
