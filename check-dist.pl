#!/usr/bin/perl
use v5.36;
use autodie;
use Data::Dumper;
$Data::Dumper::Sortkeys = 1;

my $dist = "dlp.tsv";
my $modules = "dlp-cpan.tsv";

my $rows = read_tsv($dist);
my %dlpdist;
for my $row (@$rows) {
    my ($dist, $distv) = @$row;
    $dist =~ s/^perl-//;
    $dist = 'perl-ldap' if $dist eq 'ldap';
    $dlpdist{$dist} = $distv;
}

$rows = read_tsv($modules);
my %cpandist;
for my $row (@$rows) {
    my ($dist, $distv, $module, $version) = @$row;
    $distv =~ s/^v//;
    $cpandist{ $dist } = [$distv, $module, $version];
}
for my $name (sort keys %dlpdist) {
    unless (exists $cpandist{ $name }) {
        warn __PACKAGE__.':'.__LINE__.$".Data::Dumper->Dump([\$name], ['name']);
        next;
    }
    my $cpan = $cpandist{ $name };
    my $dlp = $dlpdist{ $name };
    unless (defined $dlp) {
        warn __PACKAGE__.':'.__LINE__.": ============== $name\n";
        warn __PACKAGE__.':'.__LINE__.$".Data::Dumper->Dump([\$name], ['name']);
        next;
    }
    if ($dlp ne $cpan->[0]) {
        warn __PACKAGE__.':'.__LINE__.": ============== $name\n";
        warn __PACKAGE__.':'.__LINE__.$".Data::Dumper->Dump([\$cpan], ['cpan']);
        warn __PACKAGE__.':'.__LINE__.$".Data::Dumper->Dump([\$dlp], ['dlp']);
    }
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

