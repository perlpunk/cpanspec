#!/usr/bin/perl
use v5.36;
use autodie;
use Data::Dumper;
$Data::Dumper::Sortkeys = 1;
use Parse::CPAN::Packages;

my $prov = "dist-provides-module.tsv";
my $dist = "dlp.tsv";
my $pkgdetails = "02packages.details.txt";

my $rows = read_tsv($dist);
my %dist;
for my $row (@$rows) {
    my ($dist, $distv) = @$row;
    $dist =~ s/^perl-//;
    $dist{$dist} = $distv;
}
my $details = Parse::CPAN::Packages->new($pkgdetails);
my @packages = $details->packages;
for my $package (@packages) {
    my $dist = $package->distribution;
    my $name = $dist->dist;
    my $module = $package->package;
    unless (defined $name) {
        next;
    }
    my $distv = $dist->version // '??';
    next unless exists $dist{ $name };
    my $version = $package->version // '???';
    say "$name\t$distv\t$module\t$version";
}

sub read_tsv ($file) {
    open my $fh, "<", $file;
    my @rows;
    while (my $line = <$fh>) {
        chomp $line;
        push @rows, [split m/\t/, $line];
    }
    close $fh;
    return \@rows;
}

