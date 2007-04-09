#!/usr/bin/perl -Tw

BEGIN { $ENV{TESTING} = 1 }
use strict;
use warnings;
use Test::More tests => 5;

my $module = 'DocPerl::View::CODE';
use_ok( $module );


my $obj = $module->new( conf => { General => { Data => '.' }, LocalFolders => { Path => '.' }, }, current_location => 'local', source => 'CODE.t', module => 'CODE' );

ok( defined $obj, "Check that the class method new returns something" );
ok( $obj->isa('DocPerl::View::CODE'), " and that it is a DocPerl::View::CODE" );

can_ok( $obj, 'process' );
ok( $obj->process(),      " check object method process()" );
#is( $obj->process(), '?', " check object method process()" );

