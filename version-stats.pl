#!/usr/bin/perl
use v5.36;
use YAML::PP;

my ($xml, $factory, $out) = @ARGV;

my %factory;
open my $fh, '<', $factory or die $!;
while (my $line = <$fh>) {
    next unless $line =~ m/name='(perl-.*?)'/;
    my $pkg = $1;
    $factory{ $pkg } = 1;
}
close $fh;

open $fh, '<', $xml or die $!;
my %types;
my $total = 0;
while (my $line = <$fh>) {
    unless ($line =~ m/name="(perl-.*?)".*version="(.*?)"/) {
        next;
    }
    my ($pkg, $v) = ($1, $2);
    next if $factory{ $pkg };
    $total++;
    if ($v =~ m/^\d+$/) {
        $types{integer}->{ $pkg } = $v;
        next;
    }
    if ($v =~ m/^\d+\.\d+(\.\d+)+$/) {
        $types{normal}->{ $pkg } = $v;
        next;
    }
    if ($v =~ m/\d+\.\d$/) {
        $types{dec1}->{ $pkg } = $v;
        next;
    }
    if ($v =~ m/\d+\.\d\d$/) {
        $types{dec2}->{ $pkg } = $v;
        next;
    }
    if ($v =~ m/\d+\.\d\d\d$/) {
        $types{dec3}->{ $pkg } = $v;
        next;
    }
    if ($v =~ m/\d+\.\d\d\d+$/) {
        $types{"dec4+"}->{ $pkg } = $v;
        next;
    }
    $types{other}->{ $pkg } = $v;
}
close $fh;

my @types = qw/ normal integer dec1 dec2 dec3 dec4+ /;
#warn __PACKAGE__.':'.__LINE__.$".Data::Dumper->Dump([\%types], ['types']);
for my $type (@types) {
    say sprintf "%-10s: %d", $type, scalar keys %{ $types{ $type } };
}
my @other = map { "$_:$types{other}->{ $_ }" } sort keys %{ $types{other} };
say sprintf "%-10s: %d (%s)", "Other", scalar @other, "@other";
say sprintf "%-10s: %d", "Total", $total;

if (defined $out) {
    YAML::PP::DumpFile($out, \%types);
}

__END__
obs api /status/project/devel:languages:perl >dlp-2023-07-27.xml
obs api "/search/package/id?match=devel/@project='devel:languages:perl'" >factory-dlp-2023-07-27.xml
