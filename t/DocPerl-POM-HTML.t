#!/usr/bin/perl -Tw

BEGIN { $ENV{TESTING} = 1 }
use strict;
use warnings;
use Test::More tests => 3;

my $module = 'DocPerl::POM::HTML';
use_ok( $module );


my $obj = $module->new( conf => { General => { Data => '.' }, LocalFolders => { Path => '.' }, }, current_location => 'local', source => 'CODE.t', module => 'CODE' );

ok( defined $obj, "Check that the class method new returns something" );
ok( $obj->isa('DocPerl::POM::HTML'), " and that it is a DocPerl::POM::HTML" );

#can_ok( $obj, 'process' );
#ok( $obj->process(),      " check object method process()" );
#is( $obj->process(), '?', " check object method process()" );

