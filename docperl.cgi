#!/usr/bin/perl

# Created on: 2006-01-20 07:10:57
# Create by:  ivanw

use strict;
use warnings;
use version;
use Scalar::Util;
use FindBin qw/$Bin/;
use CGI;
use Template;
use Config::Std;
use Readonly;
use DocPerl;

our $VERSION = version->new('0.1');

Readonly my $BASE		=> $Bin;
Readonly my $DATA		=> "$BASE/data";
Readonly my $CONFIG		=> "$DATA/docperl.conf";
#Readonly my $TEMPLATE	=> "$DATA/templates";
#Readonly my $TEMPLATES	=> "$TEMPLATE/local:$TEMPLATE/default";

#$SIG{__DIE__} = sub { error( "Internal error", $@ ) };

main();
exit(0);

sub main {
	my $cgi	 	 = CGI->new();
	my %cgi	 	 = $cgi->Vars();
	my $out;
	
	# get the configuration info
	read_config $CONFIG, my %config;
	$config{template} ||= {};
	
	# create a new doc perl object
	my $dp = DocPerl->new( cgi => \%cgi, conf => \%config );
	
	print $cgi->header( $dp->mime() );
	print $dp->process();
	
#	my $template = $dp->template()	? $dp->template()
#				 : $cgi{page} 		? "$cgi{page}.html"
#				 :					  'frames.html';
#	
#	# create a new template object
#	my $tmpl = Template->new( INCLUDE_PATH => $config{Templates}{Path}, EVAL_PERL => 1 );
#	my %params = $dp->process();
##	warn Dumper \%params;
##	warn join ", ", keys %params;
#	
#	# process the template
#	$tmpl->process( $template, { %cgi, %{ $config{template} }, %params }, \$out )
#		or error( $tmpl->error );
#	
#	my $mime = $dp->mime() ? $dp->mime() : 'text/html';
#	
#	print $cgi->header($mime);
#	print $out;
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

This documentation refers to docperl.cgi version 0.1.

=head1 SYNOPSIS



=head1 DESCRIPTION

A full description of the module and its features.

May include numerous subsections (i.e., =head2, =head3, etc.).

=head1 SUBROUTINES/METHODS

A separate section listing the public components of the module's interface.

These normally consist of either subroutines that may be exported, or methods
that may be called on objects belonging to the classes that the module
provides.

Name the section accordingly.

In an object-oriented module, this section should begin with a sentence (of the
form "An object of this class represents ...") to give the reader a high-level
context to help them understand the methods that are subsequently described.

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

A list of known problems with the module, together with some indication of
whether they are likely to be fixed in an upcoming release.

Also, a list of restrictions on the features the module does provide: data types
that cannot be handled, performance issues and the circumstances in which they
may arise, practical limitations on the size of data sets, special cases that
are not (yet) handled, etc.

The initial template usually just has:

There are no known bugs in this module.

Please report problems to Ivan Wills (ivan.wills@gmail.com).

Patches are welcome.

=head1 AUTHOR

Ivan Wills - (ivan.wills@gmail.com)

=head1 LICENSE AND COPYRIGHT

Copyright (c) 2006 Ivan Wills (101 Miles St Bald Hills QLD 4036 Australia).
All rights reserved.



=cut
