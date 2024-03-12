#!/usr/bin/perl
use strict;
use warnings;
use 5.010;

use XML::LibXML;

my ($file) = @ARGV;

#my $dom = XML::LibXML->load_xml(location => $file);
my $dom = XML::LibXML->new->parse_file($file);

my $xpc = XML::LibXML::XPathContext->new($dom);
$xpc->registerNs('rpm',  'http://linux.duke.edu/metadata/rpm');
$xpc->registerNs('default',  'http://linux.duke.edu/metadata/common');

#my $root = $dom->documentElement();

#my @packages = $root->findnodes(q{/metadata/package[@type="rpm"]});
#my @packages = $root->findnodes(q{//metadata/package});
my @packages = $xpc->findnodes(q{//default:package[@type='rpm']});
say scalar @packages;

my %dists;
my %req;

local $Data::Dumper::Sortkeys = 1;
my $i = 0;
for my $p (@packages) {
    my $name = $xpc->findvalue(q{default:name}, $p);
    next if $name !~ m/^perl-/;
    next if $name =~ m/^perl-\d+bit/;
    my $arch = $xpc->findvalue(q{default:arch}, $p);
    next if $arch ne 'noarch';
    my ($v) = $xpc->findnodes(q{default:version}, $p);
    my $ver = $v->getAttribute('ver');
    my $rel = $v->getAttribute('rel');
    warn __PACKAGE__.':'.__LINE__.$".Data::Dumper->Dump([\$name], ['name']);
    warn __PACKAGE__.':'.__LINE__.$".Data::Dumper->Dump([\$ver], ['ver']);
    warn __PACKAGE__.':'.__LINE__.$".Data::Dumper->Dump([\$rel], ['rel']);
    my ($format) = $xpc->findnodes(q{default:format}, $p);
    my @prov = $xpc->findnodes(q{rpm:provides/rpm:entry}, $format);
    my @provides;
    for my $pr (@prov) {
        my $mod = $pr->getAttribute('name');
        next unless $mod =~ m/^perl\((.*)\)$/;
        $mod = $1;
        my $pver = $pr->getAttribute('ver') // '';
#        warn __PACKAGE__.':'.__LINE__.": !!!!!!!! $mod $pver\n";
        push @provides, { module => $mod, ver => $pver };
    }
    my $info = {
        ver => $ver,
        rel => $rel,
        provides => \@provides,
    };
    my $ex = $dists{ $name };
    warn __PACKAGE__.':'.__LINE__.": =========== $i\n";
    if ($ex and $ex->{ver} >= $ver and $ex->{rel} >= $rel) {
        next;
    }
    $dists{ $name } = $info;
    $i++;
    last if $i > 5;
}
warn __PACKAGE__.':'.__LINE__.$".Data::Dumper->Dump([\%dists], ['dists']);
