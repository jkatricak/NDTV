#!/usr/bin/perl -w



#use strict;
use DBI;
use MP3::Info;
use MP3::Info qw(:all);
use File::Spec;


#read in filename from command line and assign to variable
$filename = $ARGV[0];
$filename = File::Spec->rel2abs( $filename ) ;



my $tag = get_mp3tag($filename) or die "No ID3 tag for file $filename";   # ID3v2, raw ID3v2 tags



#ID3 tag stuff


#YEAR 
#ARTIST 
#COMMENT 
#ALBUM
#TITLE 
#GENRE 
#TAGVERSION 
#TRACKNUM

my $info = get_mp3info($filename); 



#get_mp3info variables
#VERSION         MPEG audio version (1, 2, 2.5)
#       STEREO          boolean for audio is in stereo
#
#       VBR             boolean for variable bitrate
#      BITRATE         bitrate in kbps (average for VBR files)
#     FREQUENCY       frequency in kHz
#    SIZE            bytes in audio stream
#
#       SECS            total seconds
#      MM              minutes
#     SS              leftover seconds
#    MS              leftover milliseconds
#   TIME            time in MM:SS
#
#       COPYRIGHT       boolean for audio is copyrighted
#      PADDING         boolean for MP3 frames are padded
#     MODE            channel mode (0 = stereo, 1 = joint stereo,
				      #                    2 = dual channel, 3 = single channel)
#   FRAMES          approximate number of frames
#  FRAME_LENGTH    approximate length of a frame
# VBR_SCALE       VBR scale from VBR header





$dbh = DBI->connect ("DBI:mysql:ndtv",
                      "ndtv", "mysql",
                      { RaiseError => 1, PrintError => 0});
$query = "INSERT INTO audio SET
title =\'" . &dequote($tag->{TITLE}) . "\',"
. "artist =\'" . &dequote($tag->{ARTIST}) . "\',"
. "album =\'" . &dequote($tag->{ALBUM}) . "\',"
. "year =\'" . &dequote($tag->{YEAR}) . "\',"
. "track =\'" . &dequote($tag->{TRACKNUM}) . "\',"
. "filename =\'" . $filename . "\'," 
. "genre =\'" . &dequote($tag->{GENRE}) . "\',"
. "format =\'mp3\',"
. "length =\'" . &dequote($info->{TIME}) . "\',"
. "bitrate =\'" . &dequote($info->{BITRATE}) . "\',"
. "frequency =\'" . &dequote($info->{FREQUENCY}) . "\'," 
. "comment =\'" . &dequote($tag->{COMMENT}) . "\'";

$dbh->do($query);



sub dequote {
    my ($samp) = @_;
   # print "Samp $samp\n";
    $samp =~ s/\'/\'\'/g;
#print "Samp $samp\n";
    return $samp
}

