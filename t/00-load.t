#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'Stilts' ) || print "Bail out!\n";
}

diag( "Testing Stilts $Stilts::VERSION, Perl $], $^X" );
