#!/usr/bin/perl

use strict;
use warnings;
use Test::More tests => 11 + 1;
use Test::NoWarnings;

BEGIN {
	use_ok( 'DocPerl'                 );
	use_ok( 'DocPerl::Search'         );
	use_ok( 'DocPerl::View'           );
	use_ok( 'DocPerl::POM::HTML'      );
	use_ok( 'DocPerl::Search::Grep'   );
	use_ok( 'DocPerl::Search::Perl'   );
	use_ok( 'DocPerl::View::API'      );
	use_ok( 'DocPerl::View::CODE'     );
	use_ok( 'DocPerl::View::FUNCTION' );
	use_ok( 'DocPerl::View::POD'      );
	use_ok( 'DocPerl::View::TEXT'     );
}

diag( "Testing module $DocPerl::VERSION, Perl $], $^X" );

