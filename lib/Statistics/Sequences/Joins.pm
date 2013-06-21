package Statistics::Sequences::Joins;

use 5.008008;
use strict;
use warnings;
use Carp qw(carp croak);
use vars qw($VERSION @ISA);
use Statistics::Sequences 0.10;
@ISA = qw(Statistics::Sequences);
use List::AllUtils qw(true uniq);
use Statistics::Zed 0.072;
our $zed = Statistics::Zed->new();

$VERSION = '0.10';

=pod

=head1 NAME

Statistics::Sequences::Joins Wishart-Hirshfeld statistics for number of alternations between two elements of a dichotomous sequence 

=head1 SYNOPSIS

 use strict;
 use Statistics::Sequences::Joins 0.10; # methods/args here are not compatible with earlier versions
 my $joins = Statistics::Sequences::Joins->new();
 $joins->load(qw/1 0 0 0 1 1 0 1 1 0 0 1 0 0 1 1 1 1 0 1/); # dichotomous sequence (any values); or send as "data => $aref" with each stat call
 my $val = $joins->observed(); # other methods include: expected(), variance(), obsdev() and stdev()
 $val = $joins->expected(trials => 20); # by-passing need for data; also works with other methods except observed()
 $val = $joins->z_value(tails => 1, ccorr => 1); # or want an array & get back both z- and p-value
 $val = $joins->z_value(trials => 20, observed => 10, tails => 1, ccorr => 1); # by-pass need for data; also works with p_value()
 $val = $joins->p_value(tails => 1); # assuming data are loaded; alias: test()
 my $href = $joins->stats_hash(values => {observed => 1, p_value => 1}); # include any other stat-method as needed
 $joins->dump(values => {observed => 1, expected => 1, p_value => 1}, format => 'line', flag => 1, precision_s => 3, precision_p => 7);
 # prints: observed = 10.000, expected = 9.500, p_value = 1.0000000

=head1 DESCRIPTION

Joins are similar to L<runs|Statistics::Sequences::Runs> but are counted for every alternation between dichotomous events (state, element, letter ...) whereas runs are counted for each continuous segment between alternations. For example, joins are marked out with asterisks for the following sequence:

 0 0 1 0 0 0 1 0 0 0 0 1 1 0 0 0 1 1 1 1 0 0
    * *     * *       *   *     *       *

So there's a join (of 0 and 1) at indices 1 and 2, then immediately another join (of 1 and 0) at indices 2 and 3, and then another join at 5 and 6 ... for a total count of eight joins.

There are methods to get the observed and expected joincounts, and the expected variance in joincount. Counting up the observed number of joins needs some data to count through, but getting the expectation and variance for the joincount - if not sent actual data in the call, or already cached via L<load|load> - can just be fed with the number of trials, and, optionally, the binomial event probability (of one of the two events occurring; default = 0.50). Note that this also differs from the way runs are counted: the expected joincount, and its variance, where the relative frequencies of the two events are counted off the given data (although this option is availabe for figuring out the binomial probability here, too).

Have non-dichotomous, continuous or multinomial data? See L<Statistics::Data::Dichotomize> for how to prepare non-dichotomous data, whether numerical or made up of categorical events, for test of joins.
      
=head1 METHODS

Methods are those described in L<Statistics::Sequences>, but can be used directly from this module, as follows.

=head2 new

 $joins = Statistics::Sequences::Joins->new();

Returns a new Joins object. Expects/accepts no arguments but the classname.

=head2 load

 $joins->load(@data); # anonymously
 $joins->load(\@data);
 $joins->load('sample1' => \@data); # labelled whatever

Loads data anonymously or by name - see L<load|Statistics::Data/load, load_data> in the Statistics::Data manpage for details on the various ways data can be loaded and then retrieved (more than shown here).

After the load, the data are L<read|Statistics::Data/read, read_data, get_data> to ensure that they contain only two unique elements - if not, carp occurs and 0 rather than 1 is returned. 

Alternatively, skip this action; data don't always have to be loaded to use the stats methods here. To get the observed number of joins, data of course have to be loaded, but other stats can be got if given the observed count - otherwise, they too depend on data having been loaded.

Every load unloads all previous loads and any additions to them.

=cut

sub load {
    my $self = shift;
    $self->SUPER::load(@_);
    my $data = $self->read(@_);
    my $nuniq = scalar(uniq(@{$data}));
    if ($nuniq > 2) {
        carp __PACKAGE__, ' More than two elements were found in the data: ' . join(' ', uniq(@$data));
        return 0;
    }
    else {
        return 1;
    }
}

=head2 add, read, unload

See L<Statistics::Data> for these additional operations on data that have been loaded.

=head2 observed, joincount_observed, jco

 $count = $joins->observed(); # assumes data have already been loaded
 $count = $joins->observed(data => [1, 0, 0, 0, 1, 0, 0, 1, 0, 1, 1]); # assumes window = 1

Returns the number of joins in a sequence - i.e., when, from trial 2 on, the event on trial I<i> doesn't equal the event on trial I<i> - 1. So the following sequence adds up to 7 joins like this:

 Sequence:  1 0 0 0 1 0 0 1 0 1 1 0 
 JoinCount: 0 1 1 1 2 3 3 4 5 6 6 7

The data to test can already have been L<load|Statistics::Sequences/load>ed, or you send it directly keyed as C<data>.

=cut

sub observed {
    my $self = shift;
    my $args = ref $_[0] ? shift : {@_};
    my $data = ref $args->{'data'} ? $args->{'data'} : $self->read($args);
    my $num = scalar(@$data);
    my ($jco, $i) = (0);
    foreach ($i = 1; $i < $num; $i++) {
        $jco++ if $data->[$i] ne $data->[$i - 1]; # increment count if event is not same as last
    }
    return $jco;
}
*joincount_observed = \&observed;
*jco = \&observed;

=head2 expected, joincount_expected, jce

 $val = $joins->expected(); # assumes data already loaded, uses default prob value (.5)
 $val = $joins->expected(data => [1, 0, 0, 0, 1, 0, 0, 1, 0, 1]); # count these data, use default prob value (.5)
 $val = $joins->expected(data => [1, 0, 0, 0, 1, 0, 0, 1, 0, 1], prob => .2); # count these data, use given prob value
 $val = $joins->expected(data => [1, 0, 0, 0, 1, 0, 0, 1, 0, 1], state => 1); # count off trial numbers and prob. of event
 $val = $joins->expected(prob => .2, trials => 10); # use this trial number and probability of one of the 2 events

Returns the expected number of joins between every element of the given data, or for data of the given attributes, using. 

=for html <p>&nbsp;&nbsp;<i>E[J]</i> = 2(<i>N</i> &ndash; 1)<i>p</i><i>q</i>

where I<N> is the number of observations/trials (width = 1 segments), 

I<p> is the expected probability of the joined event taking on its observed value, and

I<q> is (1 - I<p>), the expected probability of the joined event I<not> taking on its observed value.

The data to test can already have been L<load|Statistics::Sequences/load>ed, or you send it directly keyed as C<data>. The data are only needed to count off the number of trials, and the proportion of 1s (or other given state of the two), if the C<trials> and C<prob> attributes are not defined. If C<state> is defined, then C<prob> is worked out from the actual data (as long as there are some, or 1/2 is assumed). If C<state> is not defined, C<prob> takes the value you give to it, or, if it too is not defined, then 1/2. 

Counting up the observed number of joins needs some data to count through, but getting the expectation and variance for the joincount can just be fed with the number of C<trials>, and, optionally, the C<prob>ability of one of the two events.

=cut 

sub expected {
   my $self = shift;
   my $args = ref $_[0] ? shift : {@_};
   my ($num, $pex) = _get_trial_N($self, $args);
   return 2 * ($num - 1) * $pex * (1 - $pex);
}
*jce = \&expected;
*joincount_expected = \&expected;

=head2 variance, joincount_variance, jcv

 $val = $joins->variance(); # assume data already "loaded" for counting
 $val = $joins->variance(data => $aref); # use inplace array reference, will use default prob of 1/2
 $val = $joins->variance(data => [1, 0, 0, 0, 1, 0, 0, 1, 0, 1], state => 1); # count off trial numbers and prob. of event
 $val = $joins->variance(trials => number, prob => prob); # use this trial number and probability of one of the 2 events

Returns the expected variance in the number of joins for the given data.

=for html <p>&nbsp;&nbsp;<i>V[J]</i> = 4<i>N</i><i>p</i><i>q</i>(1 &ndash; 3<i>p</i><i>q</i>) &ndash; 2<i>p</i><i>q</i>(3 &ndash; 10<i>p</i><i>q</i>)

defined as above for L<joincount_expected|expected, joincount_expected, jce>.

The data to test can already have been L<load|Statistics::Sequences/load>ed, or you send it directly keyed as C<data>. The data are only needed to count off the number of trials, and the proportion of 1s (or other given state of the two), if the C<trials> and C<prob> attributes aren't defined. If C<state> is defined, then C<prob> is worked out from the actual data (as long as there are some, or expect a C<croak>). If C<state> is not defined, C<prob> takes the value you give to it, or, if it too is not defined, then 1/2.

=cut 

sub variance {
   my $self = shift;
   my $args = ref $_[0] ? shift : {@_};
   my ($num, $pex) = _get_trial_N($self, $args);
   my $pq = $pex * (1 - $pex);
   return ( 4 * $num * $pq ) * (1 - ( 3 * $pq ) ) - ( ( 2 * $pq ) * (3 - ( 10 * $pq ) ) ); 
}
*jcv = \&variance;
*joincount_variance = \&variance;

=head2 obsdev, observed_deviation

 $v = $joins->obsdev(); # use data already loaded - anonymously; or specify its "label" or "index" - see observed()
 $v = $joins->obsdev(data => [qw/blah bing blah blah blah/]); # use these data

Returns the deviation of (difference between) observed and expected joins for the loaded/given sequence (I<O> - I<E>). 

=cut

sub obsdev {
    return observed(@_) - expected(@_);
}
*observed_deviation = \&obsdev;

=head2 stdev, standard_deviation

 $v = $joins->stdev(); # use data already loaded - anonymously; or specify its "label" or "index" - see observed()
 $v = $joins->stdev(data => [qw/blah bing blah blah blah/]);

Returns square-root of the variance.

=cut

sub stdev {
    return sqrt(variance(@_));
}
*standard_deviation = \&stdev;

=head2 z_value, joincount_zscore, jzs, zscore

 $val = $joins->z_value(); # data already loaded, use default windows and prob
 $val = $joins->z_value(data => $aref, prob => .5, ccorr => 1);
 ($zvalue, $pvalue) =  $joins->z_value(data => $aref, prob => .5, ccorr => 1, tails => 2); # same but wanting an array, get the p-value too

Returns the zscore from a test of joincount deviation, taking the joincount expected away from that observed and dividing by the root expected joincount variance, by default with a continuity correction to expectation. Called wanting an array, returns the z-value with its p-value for the tails (1 or 2) given.

The data to test can already have been L<load|Statistics::Sequences/load>ed, or you send it directly keyed as C<data>.

Other options are C<precision_s> (for the z_value) and C<precision_p> (for the p_value).

=cut

sub z_value {
   my $self = shift;
   my $args = ref $_[0] ? shift : {@_};
   my $data = ref $args->{'data'} ? $args->{'data'} : $self->read($args);
   my $jco = defined $args->{'observed'} ? $args->{'observed'} : $self->jco($args);
   my $pex = defined $args->{'prob'} ? $args->{'prob'} : .5;
   my $num = defined $args->{'trials'} ? $args->{'trials'} : scalar(@{$data});
   my $ccorr = defined $args->{'ccorr'} ? $args->{'ccorr'} : 1;
   my $tails = $args->{'tails'} || 2;
   my ($zval, $pval) = $zed->zscore(
        observed => $jco,
        expected => $self->jce(prob => $pex, trials => $num),
        variance => $self->jcv(prob => $pex, trials => $num),
        ccorr => $ccorr,
        tails => $tails,
        precision_s => $args->{'precision_s'}, 
        precision_p => $args->{'precision_p'},
     );
    return wantarray ? ($zval, $pval) : $zval;
}
*jzs = \&z_value;
*joincount_zscore = \&z_value;
*zscore = \&z_value;

=head2 p_value, test, joins_test, jct

 $p = $joins->p_value(); # using loaded data and default args
 $p = $joins->p_value(ccorr => 0|1, tails => 1|2); # normal-approximation based on loaded data
 $p = $joins->p_value(data => [1, 0, 1, 1, 0], exact => 1); #  using given data (by-passing load and read)
 $p = $joins->p_value(trials => 20, observed => 10); # without using data, specifying its size and join-count

Test data for significance of the number of joins by deviation ratio (obsdev / stdev). Returns the Joins object, lumped with a C<z_value>, C<p_value>, and the descriptives C<observed>, C<expected> and C<variance>. Data are those already L<load|Statistics::Sequences/load>ed, or directly keyed as C<data>

=cut

sub p_value {
   return (z_value(@_))[1];
}
*test = \&p_value;
*joins_test = \&p_value;
*jct = \&p_value;

=head2 stats_hash

 $href = $joins->stats_hash(values => {observed => 1, expected => 1, variance => 1, z_value => 1, p_value => 1}, prob => .5, ccorr => 1);

Returns a hashref for the counts and stats as specified in its "values" argument, and with any options for calculating them (e.g., exact for p_value). See L<Statistics::Sequences/stats_hash> for details. If calling via a "joins" object, the option "stat => 'joins'" is not needed (unlike when using the parent "sequences" object).

=head2 dump

 $joins->dump(values => { observed => 1, variance => 1, p_value => 1}, exact => 1, flag => 1,  precision_s => 3); # among other options

Print Joins-test results to STDOUT. See L<dump|Statistics::Sequences/dump> in the Statistics::Sequences manpage for details.

=cut

sub dump {
    my $self = shift;
    my $args = ref $_[0] ? $_[0] : {@_};
    $args->{'stat'} = 'joins';
    $self->SUPER::dump($args);
}

sub _get_trial_N {
   my ($self, $args, $n, $data) = @_;
   if (defined $args->{'trials'}) {
       $n = $args->{'trials'};
   }
   else {
       $data = ref $args->{'data'} ? $args->{'data'} : $self->read($args);
       $n = scalar(@$data);
   }
   my $p = defined $args->{'prob'} ? $args->{'prob'} : (defined $args->{'state'} and defined $data) ? _count_pfrq($self, $data, $args->{'state'}) : .5;
   return ($n, $p);
}

sub _count_pfrq {
    my ($self, $aref, $state, $count) = @_;
    return .5 if ! ref $aref or ! scalar(@$aref);
    $count++ if true { $_ eq $state } @{$aref};
    return $count / scalar(@{$aref});
}

1;

__END__

=head1 EXAMPLE

Here the problem is to assess the degree of consistency of in number of matches between target and response obtained in each of 200 runs of 25 trials each. The number of matches expected on the basis of chance is 5 per run. To test for sustained high or low scoring sequences, a join is defined as the point at which a score on one side of this value (4, 3, 2, etc.) is followed by a score on the other side (6, 7, 8, etc.). Ignoring scores equalling the expectation value (5), the probability of a join is 1/2, or 0.5 (the default value to L<test|test>), assuming that, say, a score of 4 is as likely as a score of 6, and anything greater than a deviation of I<5> (from 5) is improbable/impossible.

 use Statistics::Sequences;

 # Conduct pseudo identification 5 x 5 runs:
 my ($i, $hits, $stimulus, $response, @scores);
 foreach ($i = 0; $i < 200; $i++) {
    $scores[$i] = 0;
    for (0 .. 24) {
        $stimulus = (qw/circ plus rect star wave/)[int(rand(5))];
        $response = (qw/circ plus rect star wave/)[int(rand(5))];
        $scores[$i]++ if $stimulus eq $response;
    }
  }
  
  my $seq = Statistics::Sequences->new();
  $seq->load(@scores);
  $seq->cut(value => 5, equal => 0); # value is the expected number of matches (Np); ignoring values equal to this
  $seq->test(stat => 'joins', tails => 1, ccorr => 1)->dump(text => 1, flag => 1);
  # prints, e.g., Joins: expected = 79.00, observed = 67.00, Z = -1.91, 1p = 0.028109*

=head1 REFERENCES

Wishart, J. & Hirshfeld, H. O. (1936). A theorem concerning the distribution of joins between line segments. I<Journal of the London Mathematical Society>, I<11>, 227.

=head1 SEE ALSO

L<Statistics::Sequences::Runs|lib::Statistics::Sequences::Runs> : Analogous test. 

L<Statistics::Sequences::Pot|lib::Statistics::Sequences::Pot> : Another concept of sequential structure.

=head1 BUGS/LIMITATIONS

No computational bugs as yet identfied. Hopefully this will change, given time.

=head1 REVISION HISTORY

See CHANGES in installation dist for revisions.

=head1 AUTHOR/LICENSE

=over 4

=item Copyright (c) 2006-2013 Roderick Garton

rgarton AT cpan DOT org

This program is free software. It may be used, redistributed and/or modified under the same terms as Perl-5.6.1 (or later) (see L<http://www.perl.com/perl/misc/Artistic.html>).

=item Disclaimer

To the maximum extent permitted by applicable law, the author of this module disclaims all warranties, either express or implied, including but not limited to implied warranties of merchantability and fitness for a particular purpose, with regard to the software and the accompanying documentation.

=back

=cut
