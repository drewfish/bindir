#!/usr/bin/env perl
#
# Setup tmux session in the right environment, or attach if it already exists.
#

use strict;
use warnings;
use Data::Dumper;
use File::Basename;
our %RUN;   # our runtime details


sub debug {
    #print @_, "\n";
}


sub usage {
    print "USAGE: t <dir>\n";
    exit(1);
}


sub tmuxListSessions {
    my %sessions;
    my @cmd = ('tmux');
    push @cmd, 'list-sessions';
    push @cmd, '-F', '"#{session_id} #{session_name}"';
    my $cmd = join(' ', @cmd);
    foreach my $line ( split "\n", `$cmd 2>/dev/null` ) {
        my ($id, $name) = split ' ', $line, 2;
        $sessions{$name} = $id;
    }
    return \%sessions;
}


sub getPidName {
    my $pid = shift or die;
    my @lines = split "\n", `ps -o command -p $pid`;
    return $lines[1];
}


sub makeRuntime {
    $RUN{'dir'} = shift @ARGV or usage();
    $RUN{'project'} = basename($RUN{'dir'});
    if ( $ENV{'TMUX'} ) {
        my($socket, $pid, $session) = split ',', $ENV{'TMUX'};
        $RUN{'socket'} = basename($socket);
        $RUN{'session'} = '$' . $session;
    }
}


sub changeTmux {
    debug "---------------------------------------------- changeTmux";
    my $sessions = tmuxListSessions();
    my @cmd;

    if ( $RUN{'session'} ) {
        if ( ($sessions->{$RUN{'project'}} || '') eq $RUN{'session'} ) {
            return;
        }
    }
    debug "---------------------------------------------- changeTmux";

    unless ( $sessions->{$RUN{'project'}} ) {
        # This'll let the new-session succeed. (It complains about nesting,
        # but we're making it detached so that shouldn't be an issue.)
        my $TMUX = $ENV{'TMUX'};
        delete $ENV{'TMUX'};

        @cmd = ( 'tmux' );
        push @cmd, 'new-session', '-d';
        push @cmd, '-s', $RUN{'project'};
        push @cmd, '-c', $RUN{'dir'},
        debug "---CMD--- ", join(' ', @cmd);
        system(@cmd)==0 or die("tmux new-session failed with $?");

        $ENV{'TMUX'} = $TMUX if $TMUX;
    }

    @cmd = ( 'tmux' );
    if ( $RUN{'session'} ) {
        push @cmd, 'switch-client';
    }
    else {
        push @cmd, 'attach-session', '-d';
    }
    push @cmd, '-t', $RUN{'project'};
    debug "---CMD--- ", join(' ', @cmd);
    exec(@cmd);
}


sub main {
    makeRuntime();
    changeTmux();
}
main();


