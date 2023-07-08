#!/usr/bin/perl
use v5.26;
use experimental 'signatures';
use warnings;
use version;
use YAML::PP qw/ LoadFile DumpFile /;
use List::Util qw/ first /;

my ($yaml, $task, @args) = @ARGV;
my $all = {};
if (-f $yaml) {
    $all = LoadFile $yaml;
}
if ($task eq 'stats') {
    for my $key (sort keys %$all) {
        say sprintf "%-10s: %d", $key, scalar keys %{ $all->{ $key } }
    }
    exit;
}

my $tsv = shift @args;
my %modules;
open my $fh, '<', $tsv or die $!;
while (my $line = <$fh>) {
    chomp $line;
    my ($name, $version) = split m/\t/, $line;
    $modules{ $name } = $version;
}
close $fh;

if ($task eq 'next') {
    my ($module, $next) = @args;
    my $v = next_version(@args);
    $v =~ s/^v//;
    warn __PACKAGE__.':'.__LINE__.": ======= $v\n";
    exit;
}
sub next_version ($module, $next) {
    my $current = $modules{ $module };
    warn __PACKAGE__.':'.__LINE__.$".Data::Dumper->Dump([\$current], ['current']);
    my $nextv = version->parse($next);
    my $normal = $nextv->normal;
    my $currentv = version->parse($current);
    if ($current =~ m/^\d+\.\d+\./) { # already proper format for rpm
        return $nextv > $currentv ? $normal : $next;
    }
    unless ($current =~ m/\./) { # integer
        return $nextv > $currentv ? $normal : $next;
    }
    # up to 3 decimals
    if ($current =~ m/^\d+\.\d{1,3}$/) {
        return $nextv > $currentv ? $normal : $next;
    }
    # four or more decimals, must keep format until major version increases
    if ($current =~ m/^(\d)\.(\d{4,})$/) {
        my ($cmajor, $cminor) = ($1, $2);
        my $decimals = length $cminor;
        my ($nmajor, $nminor) = split m/\./, $next;
        if (defined $nminor) {
            $next = sprintf "%.*f", $decimals, $next;
        }
        if ($nextv <= $currentv) {
            return $next;
        }
        if ($next =~ m/^$cmajor(?:\.|$)/) {
            return $next;
        }
        return $normal;
    }
}


if ($task eq 'rpm') {
    my $rpm = rpm(\%modules);
    $all->{rpm} = $rpm;
}
elsif ($task eq 'three') {
    my $three = three(\%modules);
    $all->{three} = $three;
}
elsif ($task eq 'decimal') {
    my $decimal = decimal(\%modules);
    $all->{decimal} = $decimal;
}
elsif ($task eq 'integer') {
    my $integer = integer(\%modules);
    $all->{integer} = $integer;
}
DumpFile $yaml, $all;

sub normal($dec) {
    my $v = version->parse($dec);
    my $n = $v->normal;
    $n =~ s/^v//r;
}

sub rpm ($modules) {
    my %rpm;
    for my $name (sort keys %$modules) {
        my $current = $modules->{ $name };
        if ($current =~ m/^\d+\.\d+(\.\d+)+$/) {
            $rpm{ $name }->{current} = $current;
            $rpm{ $name }->{normal} = normal $current;
        }
        else {
            say "$name\t$current";
        }
    }
    return \%rpm;
}

# up to 3 decimals
sub three ($modules) {
    my %three;
    for my $name (sort keys %$modules) {
        my $current = $modules->{ $name };
        if ($current =~ m/^\d+\.\d{1,3}$/) {
            $three{ $name }->{current} = $current;
            $three{ $name }->{normal} = normal $current;
        }
        else {
            say "$name\t$current";
        }
    }
    return \%three;
}

sub decimal ($modules) {
    my %decimal;
    for my $name (sort keys %$modules) {
        my $current = $modules->{ $name };
        if ($current =~ m/^\d+\.\d{4,}$/) {
            $decimal{ $name }->{current} = $current;
#            $decimal{ $name }->{normal} = normal $current;
        }
        else {
            say "$name\t$current";
        }
    }
    return \%decimal;
}

sub integer ($modules) {
    my %integer;
    for my $name (sort keys %$modules) {
        my $current = $modules->{ $name };
        if ($current =~ m/^\d+$/) {
            $integer{ $name }->{current} = $current;
            $integer{ $name }->{normal} = normal $current;
        }
        else {
            say "$name\t$current";
        }
    }
    return \%integer;
}
