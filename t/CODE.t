#!/usr/bin/perl -Tw

BEGIN { $ENV{TESTING} = 1 }
use strict;
use warnings;
use Test::More tests => 10;

my $module = 'DocPerl::Cached::CODE';
use_ok( $module );


my $obj = $module->new();

ok( defined $obj, "Check that the class method new returns something" );
ok( $obj->isa('DocPerl::Cached::CODE'), " and that it is a DocPerl::Cached::CODE" );

can_ok( $obj, 'process',  " check object can execute process()" );
ok( $obj->process(),      " check object method process()" );
is( $obj->process(), '?', " check object method process()" );

