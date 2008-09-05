#!/usr/bin/perl -Tw

BEGIN { $ENV{TESTING} = 1 }
use strict;
use warnings;
use Test::More tests => 4;

my $module = 'DocPerl::View';
use_ok( $module );


my $obj = $module->new( conf => { General => { Data => '.' }, LocalFolders => { Path => '.' }, }, current_location => 'local', source => 'CODE.t', module => 'CODE' );

ok( defined $obj, "Check that the class method new returns something" );
ok( $obj->isa('DocPerl::View'), " and that it is a DocPerl::View" );

can_ok( $obj, 'init', '_check_cache', '_save_cache', 'clear_cache' );
#ok( $obj->init(),      " check object method init()" );
#is( $obj->init(), '?', " check object method init()" );

