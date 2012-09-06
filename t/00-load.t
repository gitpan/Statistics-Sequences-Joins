#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'Statistics::Sequences::Joins' ) || print "Bail out!\n";
}

diag( "Testing Statistics::Sequences::Joins $Statistics::Sequences::Joins::VERSION, Perl $], $^X" );
