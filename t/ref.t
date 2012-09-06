use strict;
use warnings;
use Test::More tests => 22;
use constant EPS => 1e-2;

BEGIN { use_ok('Statistics::Sequences::Joins') };

my $seq = Statistics::Sequences::Joins->new();
isa_ok($seq, 'Statistics::Sequences::Joins');

my %refdat = (
    chimps => {
        observed  => 4, expected => 3.50, variance => 1.75, z_value => 0, p_value => 1.00000, data => [qw/ban ban che ban che ban ban ban/],
    },
    mice => {
        observed  => 1, expected => 3.50, variance => 1.75, z_value => -1.512, p_value => 0.13057, data => [qw/ban che che che che che che che/],
    },
);
my $val;
$val = $seq->observed(data => $refdat{'mice'}->{'data'});
ok(equal($val, $refdat{'mice'}->{'observed'}), "joinstat_observed  $val != $refdat{'mice'}->{'observed'}");

$val = $seq->jce(data => $refdat{'mice'}->{'data'}, prob => .5);
ok(equal($val, $refdat{'mice'}->{'expected'}), "joincount_expected  $val != $refdat{'mice'}->{'expected'}");

$val = $seq->jcv(data => $refdat{'mice'}->{'data'}, prob => .5);
ok(equal($val, $refdat{'mice'}->{'variance'}), "joincount_variance  $val != $refdat{'mice'}->{'variance'}");

$val = $seq->zscore(data => $refdat{'mice'}->{'data'}, prob => .5);
ok(equal($val, $refdat{'mice'}->{'z_value'}), "joincount_zscore  $val != $refdat{'mice'}->{'z_value'}");

$seq->load({chimps => $refdat{'chimps'}->{'data'}, mice => $refdat{'mice'}->{'data'},});
$seq->match(data => ['chimps', 'mice']);
$seq->test(data => 'chimps', precision_s => 3, tails => 2);
foreach (qw/observed expected z_value p_value/) {
   ok(defined $seq->{$_} );
   ok(equal($seq->{$_}, $refdat{'chimps'}->{$_}), "$_  $seq->{$_} = $refdat{'chimps'}->{$_}");
}
$seq->test(data => 'mice', precision_s => 3, tails => 2);
foreach (qw/observed expected z_value p_value/) {
   ok(defined $seq->{$_} );
   ok(equal($seq->{$_}, $refdat{'mice'}->{$_}), "$_  $seq->{$_} = $refdat{'mice'}->{$_}");
}

sub equal {
    return 1 if $_[0] + EPS > $_[1] and $_[0] - EPS < $_[1];
    return 0;
}
