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
    my $nextv = version->parse($next); # version object
    my $normal = $nextv->normal;       # normalized version string with more than one dot
    my $currentv = version->parse($current);

    # If the requested version is lower than/equal to the saved one, we just
    # use the given format like we did before
    if ($nextv <= $currentv) {
        return $next;
    }
    # requested version is higher
    if ($current =~ m/^\d+\.\d+\./) {
        # is already proper format for rpm, e.g. 3.14.159
        return $normal;
    }
    unless ($current =~ m/\./) {
        # integer
        return $normal;
    }
    # up to 3 decimals, safe to use normalized version
    if ($current =~ m/^\d+\.\d{1,3}$/) {
        return $normal;
    }
    # four or more decimals, must keep format until major version increases
    # otherwise e.g. 1.2023 would be normalized to 1.202.3 which is lower
    if ($current =~ m/^(\d)\.(\d{4,})$/) {
        my ($cmajor, $cminor) = ($1, $2);
        # format with the number of decimals of the saved version
        my $decimals = length $cminor;
        my ($nmajor, $nminor) = split m/\./, $next;
        if (defined $nminor) {
            $next = sprintf "%.*f", $decimals, $next;
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
