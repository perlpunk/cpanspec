#!/usr/bin/perl
use v5.26;
use experimental 'signatures';
use warnings;
use version;

my ($module, $next) = @ARGV;

my %modules;
my $tsv = "dlp.tsv";
open my $fh, '<', $tsv or die $!;
while (my $line = <$fh>) {
    chomp $line;
    my ($name, $version) = split m/\t/, $line;
    $modules{ $name } = $version;
}
close $fh;

my $v = next_version($module, $next);
$v =~ s/^v//;
say "new version: $v";

sub next_version ($module, $next) {
    my $current = $modules{ $module };
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

