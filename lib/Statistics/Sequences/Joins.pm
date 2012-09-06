package Statistics::Sequences::Joins;

use 5.008008;
use strict;
use warnings;
use Carp 'croak';
use vars qw($VERSION @ISA);
use Statistics::Sequences 0.051;
@ISA = qw(Statistics::Sequences);
use List::AllUtils qw(true uniq);

$VERSION = '0.06';

=pod

=head1 NAME

Statistics::Sequences::Joins Wishart-Hirshfeld statistics for number of alternations between two elements of a dichotomous sequence 

=head1 SYNOPSIS

  use Statistics::Sequences::Joins;
  $joins = Statistics::Sequences::Joins->new();
  $joins->load(qw/0 0 1 0 0 0 1 0 0 0 0 1 1 0 0 0 1 1 1 1 0 0/);
  $joins->test()->dump();

=head1 DESCRIPTION

Joins are similar to L<runs|Statistics::Sequences::Runs> but are counted for every alternation between dichotomous events (state, element, letter ...) whereas runs are counted for each continuous segment between alternations.. Joins are marked out with asterisks for the following sequence:

 0 0 1 0 0 0 1 0 0 0 0 1 1 0 0 0 1 1 1 1 0 0
    * *     * *       *   *     *       *

So there's a join (of 0 and 1) at indices 1 and 2, then immediately another join (of 1 and 0) at indices 2 and 3, and then another join at 5 and 6 ... for a total count of eight joins.

There are methods to get the observed and expected joincounts, and the expected variance in joincount. Counting up the observed number of joins needs some data to count through, but getting the expectation and variance for the joincount - if not sent actual data in the call, or already cached via L<load|load> - can just be fed with the number of trials, and, optionally, the probability of one of the two events (default = 0.50). Note that this also differs from the way runs are counted: the expected joincount, and its variance, are worked out from the relative probabilities of the two events, unlike runs where these are counted off the given data (or as told). Alternatively, the probabilities can be counted up from the proportional frequencies in the data at hand.

See L<Statistics::Sequences|Statistics::Sequences> for ways to dichotomise a multinomial or continuous numerical sequence.
      
=head1 METHODS

Methods are those described in L<Statistics::Sequences>, but can be used directly from this module, as follows.

=head2 new

 $join = Statistics::Sequences::Joins->new();

Returns a new Joins object. Expects/accepts no arguments but the classname.

=head2 load

 $joins->load(@data);
 $joins->load(\@data);
 $joins->load('sample1' => \@data1, 'sample2' => \@data2)
 $joins->load({'sample1' => \@data1, 'sample2' => \@data2})

Optionally - pre-load some data: Load data anonymously or by name. See L<load|Statistics::Sequences/load> in the Statistics::Sequences manpage. These data be used for all the following methods.

Alternatively, skip this action, and send the data to the descriptive methods that follow. Counting up the observed number of joins needs some data to count through, but getting the expectation and variance for the joincount can just be fed with the number of trials, and, optionally, the probability of one of the two events.

=head2 observed, joincount_observed, jco

 $count = $joins->observed(); # assumes testdata have already been loaded
 $count = $joins->observed(data => [1, 0, 0, 0, 1, 0, 0, 1, 0, 1, 1]); # assumes window = 1

Returns the number of joins in a sequence - i.e., when, from trial 2 on, the event on trial I<i> doesn't equal the event on trial I<i> - 1. So the following sequence adds up to 7 joins like this:

 Sequence:  1 0 0 0 1 0 0 1 0 1 1 0 
 JoinCount: 0 1 1 1 2 3 3 4 5 6 6 7

The data to test can already have been L<load|load>ed, or you send it directly as a flat referenced array keyed as C<data>.

=cut

sub observed {# Count the number of joins in the given data:
    my $self = shift;
    my $args = ref $_[0] ? shift : {@_};
    my $data_aref = ref $args->{'data'} ? $args->{'data'} : $self->{'testdata'};
    ref $data_aref or croak __PACKAGE__, '::Data for counting up joins are needed';
    my $num = scalar(@{$data_aref});
    return 0 if ! $num or $num < 2; 
    my $nuniq = scalar(uniq(@{$data_aref}));
    return 0 if $nuniq == 1;
    croak __PACKAGE__, '::test More than two states were found in the data: ' . join(' ', uniq(@$data_aref)) if $nuniq > 2;
    my ($count, $i) = ();
    foreach ($i = 1; $i < $num; $i++) {
        $count++ if $data_aref->[$i] ne $data_aref->[$i - 1]; # increment count if this event is not the same as the last event
    }
    return $count;
}
*joincount_observed = \&observed;
*jco = \&observed;

=head2 expected, joincount_expected, jce

 $val = $joins->expected(); # assumes testdata have already been loaded, uses default prob value (.5)
 $val = $joins->expected(data => [1, 0, 0, 0, 1, 0, 0, 1, 0, 1]); # count these data, use default prob value (.5)
 $val = $joins->expected(data => [1, 0, 0, 0, 1, 0, 0, 1, 0, 1], prob => .2); # count these data, use given prob value
 $val = $joins->expected(data => [1, 0, 0, 0, 1, 0, 0, 1, 0, 1], state => 1); # count off trial numbers and prob. of event
 $val = $joins->expected(prob => .2, trials => 10); # use this trial number and probability of one of the 2 events

Returns the expected number of joins between every element of the given data, or for data of the given attributes, using. 

=for html <p>&nbsp;&nbsp;<i>E[J]</i> = 2(<i>N</i> &ndash; 1)<i>p</i><i>q</i>

where I<N> is the number of observations/trials (width = 1 segments), 

I<p> is the expected probability of the joined event taking on its observed value, and

I<q> is (1 - I<p>), the expected probability of the joined event I<not> taking on its observed value.

The data to test can already have been L<load|load>ed, or you send it directly as a flat referenced array keyed as C<data>. The data are only needed to count off the number of trials, and the proportion of 1s (or other given state of the two), if the C<trials> and C<prob> attributes are not defined. If C<state> is defined, then C<prob> is worked out from the actual data (as long as there are some, or 1/2 is assumed). If C<state> is not defined, C<prob> takes the value you give to it, or, if it too is not defined, then 1/2. 

=cut 

sub expected {
   my $self = shift;
   my $args = ref $_[0] ? shift : {@_};
   my $num = defined $args->{'trials'} ? $args->{'trials'} : ref $args->{'data'} ? scalar @{$args->{'data'}} : scalar(@{$self->{'testdata'}});
   my $pex = defined $args->{'prob'} ? $args->{'prob'} : defined $args->{'state'} ? _count_pfrq($self, $args->{'data'}, $args->{'state'}) : .5;
   return 2 * ($num - 1) * $pex * (1 - $pex);
}
*jce = \&expected;
*joincount_expected = \&expected;

=head2 variance, joincount_variance, jcv

 $val = $joins->variance(); # assume the data are already "loaded" for counting
 $val = $joins->variance(data => $aref); # use inplace array reference, will use default prob of 1/2
 $val = $joins->variance(data => [1, 0, 0, 0, 1, 0, 0, 1, 0, 1], state => 1); # count off trial numbers and prob. of event
 $val = $joins->variance(trials => number, prob => prob); # use this trial number and probability of one of the 2 events

Returns the expected variance in the number of joins for the given data.

=for html <p>&nbsp;&nbsp;<i>V[J]</i> = 4<i>N</i><i>p</i><i>q</i>(1 &ndash; 3<i>p</i><i>q</i>) &ndash; 2<i>p</i><i>q</i>(3 &ndash; 10<i>p</i><i>q</i>)

defined as above for L<joincount_expected|expected, joincount_expected, jce>.

The data to test can already have been L<load|load>ed, or you send it directly as a flat referenced array keyed as C<data>. The data are only needed to count off the number of trials, and the proportion of 1s (or other given state of the two), if the C<trials> and C<prob> attributes aren't defined. If C<state> is defined, then C<prob> is worked out from the actual data (as long as there are some, or expect a C<croak>). If C<state> is not defined, C<prob> takes the value you give to it, or, if it too is not defined, then 1/2.

=cut 

sub variance {
   my $self = shift;
   my $args = ref $_[0] ? shift : {@_};
   my $num = defined $args->{'trials'} ? $args->{'trials'} : ref $args->{'data'} ? scalar @{$args->{'data'}} : scalar(@{$self->{'testdata'}});
   my $pex = defined $args->{'prob'} ? $args->{'prob'} : defined $args->{'state'} ? _count_pfrq($self, $args->{'data'}, $args->{'state'}) : .5;
   my $pq = $pex * (1 - $pex);
   return ( 4 * $num * $pq ) * (1 - ( 3 * $pq ) ) - ( ( 2 * $pq ) * (3 - ( 10 * $pq ) ) ); 
}
*jcv = \&variance;
*joincount_variance = \&variance;

=head2 zscore, joincount_zscore, jzs, z_value

 $val = $join->zscore(); # data already loaded, use default windows and prob
 $val = $join->zscore(data => $aref, prob => .5, ccorr => 1);

Returns the zscore from a test of joincount deviation, taking the joincount expected away from that observed and dividing the root of the expected joincount variance, by default with a continuity correction in the numerator. 

The data to test can already have been L<load|load>ed, or you send it directly as a flat referenced array keyed as C<data>.

=cut

sub zscore {
   my $self = shift;
   my $args = ref $_[0] ? shift : {@_};
   my $jco = defined $args->{'observed'} ? $args->{'observed'} : $self->jco($args);
   my $pex = defined $args->{'prob'} ? $args->{'prob'} : .5;
   my $num = defined $args->{'trials'} ? $args->{'trials'} : ref $args->{'data'} ? scalar @{$args->{'data'}} : scalar(@{$self->{'testdata'}});
   my $ccorr = defined $args->{'ccorr'} ? delete $args->{'ccorr'} : 1;
   my $zval = $self->{'zed'}->zscore(
        observed => $jco,
        expected => $self->jce(prob => $pex, trials => $num),
        variance => $self->jcv(prob => $pex, trials => $num),
        ccorr => $ccorr,
     );
    return $zval;
}
*jzs = \&zscore;
*joincount_zscore = \&zscore;
*z_value = \&zscore;

=head2 test, joins_test, jnt

 $joins->test();

Test the currently loaded data for significance of the number of joins. Returns the Joins object.

=cut

sub test {
   my $seq = shift;
   my $args = ref $_[0] ? $_[0] : {@_};
   $seq->_testdata_aref($args);
   my $pex = defined $args->{'prob'} ? $args->{'prob'} : .5;
   my $jco = defined $args->{'observed'} ? $args->{'observed'} : $seq->jco($args);
   my $jce = $seq->joincount_expected();
   my $jve = $seq->joincount_variance();

   if ($jve) {
       $seq->_expound($jco, $jce, $jve, $args);
   }
   else {
       $seq->_expire($jco, $jce, $args);
   }

   return $seq;
}
*joins_test = \&test;
*jnt = \&test;

=head2 dump

 $joins->dump(flag => '1|0', text => '0|1|2');

Print Joins-test results to STDOUT. See L<dump|Statistics::Sequences/dump> in the Statistics::Sequences manpage for details.

=cut

sub dump {
    my $seq = shift;
    my $args = ref $_[0] ? $_[0] : {@_};
    $args->{'testname'} = 'Joins';
    if ($args->{'text'} and $args->{'text'} > 1) {
        $args->{'title'} = "Joins test results:";
        $seq->SUPER::_dump_verbose($args);
    }
     else {
        $seq->SUPER::_dump_sparse($args);
    }
    return $seq;
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

=item Copyright (c) 2006-2012 Roderick Garton

rgarton AT cpan DOT org

This program is free software. It may be used, redistributed and/or modified under the same terms as Perl-5.6.1 (or later) (see L<http://www.perl.com/perl/misc/Artistic.html>).

=item Disclaimer

To the maximum extent permitted by applicable law, the author of this module disclaims all warranties, either express or implied, including but not limited to implied warranties of merchantability and fitness for a particular purpose, with regard to the software and the accompanying documentation.

=back

=head1 END

This ends documentation of a Perl implementation of the Wishart-Hirshfeld Joins test for randomness and group differences within a sequence.

=cut
