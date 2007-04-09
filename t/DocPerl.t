#!/usr/bin/perl -Tw

BEGIN { $ENV{TESTING} = 1 }
use strict;
use warnings;
use Test::More tests => 4;

my $module = 'DocPerl';
use_ok( $module );


my $obj = $module->new( conf => { General => { Data => '.' }, LocalFolders => { Path => '.' }, }, current_location => 'local', source => 'CODE.t', cgi => {}, );

ok( defined $obj, "Check that the class method new returns something" );
ok( $obj->isa('DocPerl'), " and that it is a DocPerl" );

can_ok( $obj, 'init' );
#ok( $obj->init(),      " check object method init()" );
#is( $obj->init(), '?', " check object method init()" );

