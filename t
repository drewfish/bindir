#!/usr/bin/env perl
# 
# Setup tmux session in the right environment, or attach if it already exists.
#

use strict;
use warnings;
use Data::Dumper;
use File::Basename;
our $CONFIG_FILE = "$ENV{HOME}/.t";
our %RUN;   # our runtime details
our %CFG;   # configuration for the chosen group


sub debug {
    #print @_, "\n";
}


sub usage {
    print "USAGE: t <group> <project>\n";
    exit(1);
}


sub tmuxListSessions {
    my %sessions;
    my @cmd = ('tmux');
    push(@cmd, '-L', $CFG{'socket'}) if $CFG{'socket'};
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
    $RUN{'group'}   = shift @ARGV or usage();
    $RUN{'project'} = shift @ARGV or usage();
    if ( $ENV{'TMUX'} ) {
        my($socket, $pid, $session) = split ',', $ENV{'TMUX'};
        $RUN{'socket'} = basename($socket);
        $RUN{'session'} = '$' . $session;
    }
}


sub makeConfig {
    open(F, "<$CONFIG_FILE") or die("FAILED to open $CONFIG_FILE");
    my $group = '';
    foreach my $line ( <F> ) {
        chomp $line;
        $line =~ s/#.*//;
        $line =~ s/^\s+//;
        $line =~ s/\s+$//;
        next unless $line;
        if ( $line =~ m/^\[group (\w+)\]$/ ) {
            $group = $1;
            next;
        }
        if ( $group eq $RUN{'group'} ) {
            my ($k, $v) = split m/\s*=\s*/, $line, 2;
            $CFG{$k} = $v;
        }
    }
    close(F) or die("FAILED to close $CONFIG_FILE");
}


sub changeHost {
    debug "---------------------------------------------- changeHost";
    return unless $CFG{'host'};
    die("TODO -- changeHost\n");
}


sub changeTmux {
    debug "---------------------------------------------- changeTmux";
    my $sessions = tmuxListSessions();
    my @cmd;

    if ( $RUN{'session'} ) {
        if ( $CFG{'socket'} and $RUN{'socket'} ne $CFG{'socket'} ) {
            print STDERR "ERROR: existing tmux client can't switch between sockets\n";
            exit(2);
        }
        if ( ($sessions->{$RUN{'project'}} || '') eq $RUN{'session'} ) {
            debug "-------------------- TMUX already there";
            return;
        }
    }

    unless ( $sessions->{$RUN{'project'}} ) {
        # This'll let the new-session succeed. (It complains about nesting,
        # but we're making it detached so that shouldn't be an issue.)
        my $TMUX = $ENV{'TMUX'};
        delete $ENV{'TMUX'};

        @cmd = ( 'tmux' );
        push(@cmd, '-L', $CFG{'socket'}) if $CFG{'socket'};
        push @cmd, 'new-session', '-d';
        push @cmd, '-s', $RUN{'project'};
        push @cmd, "t $RUN{group} $RUN{project}";
        debug "---CMD--- ", join(' ', @cmd);
        system(@cmd)==0 or die("tmux new-session failed with $?");

        $ENV{'TMUX'} = $TMUX if $TMUX;
    }

    @cmd = ( 'tmux' );
    push(@cmd, '-L', $CFG{'socket'}) if $CFG{'socket'};
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


sub changeYroot {
    debug "---------------------------------------------- changeYroot";
    return unless $CFG{'yroot'};
    die("TODO -- changeYroot\n");
}


sub changeDir {
    debug "---------------------------------------------- changeDir";
    my $dir = $CFG{'dir'} or return;
    $dir =~ s/^~/$ENV{'HOME'}/;
    chdir($dir) if -d $dir;
    chdir($RUN{'project'}) if -d $RUN{'project'};
}


sub login {
    debug "---------------------------------------------- login";
    my $shell = $ENV{'SHELL'};
    my $alias = '-' . basename($shell);
    my $parentName = getPidName(getppid());
    if ( $parentName eq $alias ) {
        debug "-------------------- LOGIN already there";
        return;
    }
    debug "---CMD--- $shell";
    exec {$shell} $alias;
}


sub main {
    makeRuntime();
    makeConfig();
    changeHost();
    changeTmux();
    changeYroot();
    changeDir();
    login();
}
main();


__DATA__
TODO -- document .t file systax



