#!/usr/bin/perl -Tw

BEGIN { $ENV{TESTING} = 1 }
use strict;
use warnings;
use Test::More tests => 10;

my $module = 'DocPerl::View';
use_ok( $module );


my $obj = $module->new();

ok( defined $obj, "Check that the class method new returns something" );
ok( $obj->isa('DocPerl::View'), " and that it is a DocPerl::View" );

can_ok( $obj, 'init',  " check object can execute init()" );
ok( $obj->init(),      " check object method init()" );
is( $obj->init(), '?', " check object method init()" );

