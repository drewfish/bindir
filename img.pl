#!/usr/bin/perl
# wrapper around imagemagick
# COMMON COMMANDS:
#   -rotate X       rotate X degrees clockwise
#   -enhance        apply digital filter to enhance a noisy image
#   -flip           create a mirror image
#   -flop           create a mirror image
#   +profile "*"    remove profiles from image
#   -resize WxH     TODO
#   
#
#   profile iptc = ?
#   profile APP1 = Exif
#

use strict;
use warnings;
use Data::Dumper;
use File::Basename;


my $CONVERTER = '/opt/local/bin/convert';


sub main {
    my @args;
    my @files;
    foreach my $a ( @ARGV ) {
        if ( -f $a ) {
            push @files, $a;
        }
        else {
            push @args, $a;
        }
    }

    my $mod = join '-', @args;
    foreach my $source ( @files ) {
        my ($name,$path,$suffix) = fileparse($source,'\\.[^.]+$');
        my $dest = $path . $name . $mod . $suffix;
        my @command = ($CONVERTER, @args, $source, $dest);
        print "-- @command\n";
        (0==system(@command)) or die "$? : $!";
    }
}
main();


