#!/usr/bin/perl 

# Created on: 2006-01-20 07:10:57
# Create by:  ivanw

use strict;
use warnings;
use version;
use FindBin qw/$Bin/;
use CGI;
use Config::Std;
use Readonly;
use lib qw/./;
use DocPerl;

our $VERSION = version->new('0.6.0');

Readonly my $BASE   => $Bin;
Readonly my $CONFIG => "$BASE/docperl.conf";

#$SIG{__DIE__} = sub { error( "Internal error", $@ ) };

# for taint saifty remove the environment's PATH;
delete $ENV{PATH};

main();
exit(0);

sub main {
	my $cgi = CGI->new();
	my %cgi = $cgi->Vars();
	my $out;
	
	# get the configuration info
	read_config $CONFIG, my %config;
	$config{template} ||= {};
	
	# create a new doc perl object
	my $docperl = DocPerl->new( cgi => \%cgi, conf => \%config, );
	
	print $cgi->header( $docperl->mime() );
	print $docperl->process();
}

# catastrofic error page
sub error {
	my ( $message, @hidden ) = @_;
	print "Content-Type: text/html; charset=ISO-8859-1\n\n";
	print "<html><head><title>Error</title></head><body>\n";
	print "<h1>Error</h1><p>$message</p>\n";
	for my $hidden ( @hidden ) {
		print "<div>\n$hidden\n</div>\n";
	}
	print "</body></html>";
	exit 1;
}

__DATA__

=head1 NAME

docperl.cgi - Displays the documentation/api/code of perl modules and other files perl programs

=head1 VERSION

This documentation refers to docperl.cgi version 0.6.0.

=head1 SYNOPSIS

 docperl.cgi?page={page_name}[&module={module_descriptor|module_name}[&location={perl|local|inc}][&file={relative_module_file}][&source={exact_module_file}]]

=head1 DESCRIPTION

docperl.cgi processes the cgi input and displays the out put of the DocPerl.pm
module. Setting the appropriate HTTP headders (mostly MIME type).

=head1 DIAGNOSTICS

A list of every error and warning message that the module can generate (even
the ones that will "never happen"), with a full explanation of each problem,
one or more likely causes, and any suggested remedies.

=head1 CONFIGURATION AND ENVIRONMENT

A full explanation of any configuration system(s) used by the module, including
the names and locations of any configuration files, and the meaning of any
environment variables or properties that can be set. These descriptions must
also include details of any configuration language used.

=head1 DEPENDENCIES

A list of all of the other modules that this module relies upon, including any
restrictions on versions, and an indication of whether these required modules
are part of the standard Perl distribution, part of the module's distribution,
or must be installed separately.

=head1 INCOMPATIBILITIES

A list of any modules that this module cannot be used in conjunction with.
This may be due to name conflicts in the interface, or competition for system
or program resources, or due to internal limitations of Perl (for example, many
modules that use source code filters are mutually incompatible).

=head1 BUGS AND LIMITATIONS

There are no known bugs in this module.

Please report problems to Ivan Wills (ivan.wills@gmail.com).

Patches are welcome.

=head1 AUTHOR

Ivan Wills - (ivan.wills@gmail.com)

=head1 LICENSE AND COPYRIGHT

Copyright (c) 2006 Ivan Wills (101 Miles St Bald Hills QLD 4036 Australia).
All rights reserved.

This module is free software; you can redistribute it and/or modify it under
the same terms as Perl itself. See L<perlartistic>.  This program is
distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY;
without even the implied warranty of MERCHANTABILITY or FITNESS FOR A
PARTICULAR PURPOSE.

=cut
