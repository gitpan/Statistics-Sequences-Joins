use strict;
use warnings;
use Test::More tests => 20;
use constant EPS => 1e-2;

use Statistics::Sequences::Joins 0.10;

my $seq = Statistics::Sequences::Joins->new();
isa_ok($seq, 'Statistics::Sequences::Joins');

my %refdat = (
    chimps => {
        observed  => 4, expected => 3.50, variance => 1.75, z_value => 0, p_value => 1.00000, data => [qw/ban ban che ban che ban ban ban/],
    },
    mice => {
        observed  => 1, expected => 3.50, variance => 1.75, z_value => -1.512, p_value => 0.13057, data => [qw/ban che che che che che che che/],
    },
    matched => {
        observed  => 5, expected => 3.50, variance => 1.75, z_value => 0.7559, p_value => .44970,
        data => [qw/1 0 1 0 1 0 0 0/],
    },
    esp60 => { # from ESP-60 App. 8 p 381
        observed => 70, expected => 99.5, variance => 49.75, prob => 1/2, z_value => 4.17, trials => 200
    },
);
my $val;
$val = $seq->observed(data => $refdat{'mice'}->{'data'});
ok(equal($val, $refdat{'mice'}->{'observed'}), "joinstat_observed  observed  $val != $refdat{'mice'}->{'observed'}");

$val = $seq->jce(data => $refdat{'mice'}->{'data'}, prob => .5);
ok(equal($val, $refdat{'mice'}->{'expected'}), "joincount_expected  observed  $val != $refdat{'mice'}->{'expected'}");

$val = $seq->jcv(data => $refdat{'mice'}->{'data'}, prob => .5);
ok(equal($val, $refdat{'mice'}->{'variance'}), "joincount_variance  observed  $val != $refdat{'mice'}->{'variance'}");

my $stdev = sqrt($val);
$val = $seq->stdev(data => $refdat{'mice'}->{'data'}, prob => .5);
ok(equal($val, $stdev), "joincount stdev observed  $val != $stdev");

my $obsdev = $refdat{'mice'}->{'observed'} - $refdat{'mice'}->{'expected'}; 
$val = $seq->obsdev(data => $refdat{'mice'}->{'data'}, prob => .5);
ok(equal($val, $obsdev), "joincount obsdev observed  $val != $obsdev");

$val = $seq->zscore(data => $refdat{'mice'}->{'data'}, prob => .5);
ok(equal($val, $refdat{'mice'}->{'z_value'}), "joincount_zscore  observed  $val != $refdat{'mice'}->{'z_value'}");

# Using raw data already loaded, but not transformed in any way:
eval { $seq->load(@{$refdat{'chimps'}->{'data'}});};
ok(!$@, do {chomp $@; "Data load failed: $@";});
$val = $seq->observed();
ok(equal($val, $refdat{'chimps'}->{'observed'}), "joincount_observed  observed  $val != $refdat{'chimps'}->{'observed'}");
$val = $seq->expected();
ok(equal($val, $refdat{'chimps'}->{'expected'}), "joincount_expected  observed  $val != $refdat{'chimps'}->{'expected'}");

$val = $seq->variance();
ok(equal($val, $refdat{'chimps'}->{'variance'}), "joincount_variance  observed  $val != $refdat{'chimps'}->{'variance'}");

# Using transformed (matched) data - direct calls to descriptives
use Statistics::Data::Dichotomize;
my $seqd = Statistics::Data::Dichotomize->new();
my $matched = $seqd->match(data => [$refdat{'chimps'}->{'data'}, $refdat{'mice'}->{'data'}]);
eval {$seq->load(data => $matched);};
ok(!$@, do {chomp $@; "Data load failed: $@";});

$val = $seq->observed();
ok(equal($val, $refdat{'matched'}->{'observed'}), "joincount_observed  observed  $val != $refdat{'matched'}->{'observed'}");
$val = $seq->expected();
ok(equal($val, $refdat{'matched'}->{'expected'}), "joincount_expected  observed  $val != $refdat{'matched'}->{'expected'}");
$val = $seq->variance();
ok(equal($val, $refdat{'matched'}->{'variance'}), "joincount_variance  observed  $val != $refdat{'matched'}->{'variance'}");
$val = $seq->zscore(prob => .5);
ok(equal($val, $refdat{'matched'}->{'z_value'}), "joincount_zscore  observed  $val != $refdat{'matched'}->{'z_value'}");
$val = $seq->zscore(data => $refdat{'matched'}->{'data'}, prob => .5);
ok(equal($val, $refdat{'matched'}->{'z_value'}), "joincount_zscore  observed  $val != $refdat{'matched'}->{'z_value'}");

$val = $seq->test(data => $refdat{'matched'}->{'data'}, prob => .5);
ok(equal($val, $refdat{'matched'}->{'p_value'}), "joincount_pvalue observed  $val != $refdat{'matched'}->{'p_value'}");

$val = $seq->jce(trials => $refdat{'esp60'}->{'trials'}, prob => $refdat{'esp60'}->{'prob'});
ok(equal($val, $refdat{'esp60'}->{'expected'}), "expected count  $val = $refdat{'esp60'}->{'expected'}");

$val = $seq->jcv(trials => $refdat{'esp60'}->{'trials'}, prob => $refdat{'esp60'}->{'prob'});
ok(equal($val, $refdat{'esp60'}->{'variance'}), "expected count  $val = $refdat{'esp60'}->{'variance'}");

sub equal {
    return 1 if $_[0] + EPS > $_[1] and $_[0] - EPS < $_[1];
    return 0;
}
