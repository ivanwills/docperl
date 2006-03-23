package DocPerl::Cached::API;

=head1 NAME

DocPerl::Cached::API - <One-line description of module's purpose>

=head1 VERSION

This documentation refers to DocPerl::Cached::API version 0.1.


=head1 SYNOPSIS

   use DocPerl::Cached::API;

   # Brief but working code example(s) here showing the most common usage(s)
   # This section will be as far as many users bother reading, so make it as
   # educational and exemplary as possible.


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
<Author name(s)>  (<contact address>)

=head1 LICENSE AND COPYRIGHT

Copyright (c) 2006 Ivan Wills (101 Miles St Bald Hills QLD Australia 4036).
All rights reserved.


This module is free software; you can redistribute it and/or modify it under
the same terms as Perl itself. See L<perlartistic>.  This program is
distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY;
without even the implied warranty of MERCHANTABILITY or FITNESS FOR A
PARTICULAR PURPOSE.

=cut

# Created on: 2006-03-19 20:32:12
# Create by:  ivan

use strict;
use warnings;
use Carp;
use Data::Dumper qw/Dumper/;

use Scalar::Util;
use base qw/DocPerl::Cached/;

our $VERSION = 0.0.1;
our @EXPORT = qw//;
our @EXPORT_OK = qw//;

=head3 C<display ( $var1, $var2,  )>

Param: C<$var1> - type (detail) - description

Param: C<$var2> - type (detail) - description

Return:  - 

Description: 

=cut

sub process {
	my $self	= shift;
	my $q		= $self->{cgi};
	my $conf	= $self->{conf};
	my $module	= $self->{module};
	my $file	= $self->{module_file} || '';
	my $source	= $self->{source} || '';
	
	my $api	= $self->get_api($source);
	return api => $api;
}

sub get_api {
	my $self	= shift;
	my $conf	= $self->{conf};
	my $location= $self->{current_location};
	my ($file)	= @_;

	# open the file
	open FILE, $file or warn "Cannot open $file: $!\n";
	my %api;
	my $i = 0;

	# loop through the file line by line
	while ( my $line = <FILE> ) {
		$i++;

		# ignore lines starting with a { or = or #
		next if $line =~ /^\s*(?:{|=|#)/;

		# check if we have reached the end of the file
		last if $line =~ /^__(END|DATA)__/;

		# if the line starts with the package directive
		if ( $line =~ /^\s*package ([\w:]+);/ ) {
			$api{package} = $1;
		}

		# check if the line starts with 'use base' to indicate inhereted packages
		elsif ( $line =~ m#^
							\s* use \s+ base \s+ qw
							( [\|/({\[] )
							\s*([\w:]+)\s*
							( [\|/)}\]] )
							#xm ) {
			my $parents = $2;
			my @parents = split /\s+/, $parents;
			$api{parents} = \@parents;
		}

		# check if the line starts with '@ISA' to indicate inhereted packages
		elsif ( $line =~ / \@ISA \s* = \s* \( ([^)]+) \)  /x ) {
			my $parents = $1;
			my @parents = split /,\s*/, $parents;
			$_ =~ s/'|\s//g for (@parents);    #'
			$api{parents} = \@parents;
		}
		elsif ( $line =~ m#^
							\s* \@ISA \s* = \s* qw
							( \| | \/ | \( | \{ | \[ )
							\s*(.*)\s*
							( \| | \/ | \) | \} | \] )
							#xm ) {
			warn "Untested!!!!!!!!!";
			my $parents = $1;
			my @parents = split /\s+/, $parents;
			$api{parents} = \@parents;
		}

		# check for generic module 'use'
		elsif ( my ($module) = $line =~ /^\s*use\s+([\w:]*)/ ) {
			$api{modules}{$module}++;
		}

		# check for generic module 'require'
		elsif ( my ($require) = $line =~ /^\s*require\s+([\w:]*)/ ) {

			#			my ($require) = $line =~ /require\s+([\w:]*)/;
			#			warn $line;
			$api{required}{$require}++;
		}

		# check for sub directives
		elsif ( my ($func) = $line =~ /^\s*sub\s+(\w+)/ ) {
			my $method     = 0;
			my $found_line = $i;
			my $line;
			for ( my $sub_line_no = 0 ; $sub_line_no < 10 and $line = <FILE> ; $sub_line_no++ ) {
				$i++;
				if ( my ($require) = $line =~ /require\s+([\w:]*)/ ) {
					$api{required}{$require}++;
				}

				# if the line is of the from $self = shift then assume sub is a method
				if ( $line =~ /}/ ) {
					$sub_line_no = 11;
				}

				# if the line is of the form $class = shift or $caller = shift assume sub is a class method
				elsif ( $line =~ /\$(class|caller)\s*=\s*shift;/ ) {
					$api{class}{$func} = $found_line;
					$method = 1;
				}

				# stop if we come accross a closing bracket
				elsif ( $line =~ /\$(self|this)\s*=\s*shift;/ ) {
					$api{object}{$func} = $found_line;
					$method = 1;
				}
				
				# alternate object opener $this = shift form
				elsif ( $line =~ /my\s*\(\s*\$(self|this)[^\)]*\)\s*=\s*\@_;/ ) {
					$api{object}{$func} = $found_line;
					$method = 1;
				}
				
			}

			# if no a class or object method add to functions
			$api{func}{$func} = $found_line unless $method;
		}
	}
	close FILE;
	
	my @paths = split /:/, $location eq 'local' ? $conf->{LocalFolders}{Path} : $conf->{IncFolders}{Path};
	push @INC, @paths;
	warn join "\n", @paths, "\n ";
	warn join "\n", @INC, "\n ";
	
	if ( $api{package} ) {
		$api{version} = eval("require $api{package};\$$api{package}\:\:VERSION");
		warn $@ if $@;
	}
	return \%api;
}

sub api {
	my ( $module, $api, $file, $q ) = @_;
	my $out;

	$out .= $q->h1($module);
	$out .= $q->div(
		{ -style => "float: right; border-width:2px; border-style:solid;" },
		$q->h2(
			{
				-style =>
"border-width:0px 0px 2px 0px; border-style:solid; padding:0px 3px 0px 3px;margin:0px;background-color:transparent;-moz-border-radius:0px"
			},
			"Class Inheritance",
		),
		$q->ul(
			{ -style => "list-style-type:none;padding-left:5px;font-weight:bold" },
			$q->li( { -style => "font-weight:bold" }, getHirachy( $module, $q ) ),
		)
	);
	$out .= $q->start_table( { -border => 1 } );
	if ( $api->{package} ) {
		$out .= $q->Tr( $q->th('Package'), $q->td( { -colspan => "2" }, $api->{package} ) );
		my $v = eval("require $module;\$$module\:\:VERSION");
		#warn "$v = $module\:\:VERSION;\t$@";
		$out .= $q->Tr( $q->th('Version'), $q->td( { -colspan => "2" }, $v || 'Module has no $VERSION' ) );    # if $module::VERSION;
	}
	if ( $api->{modules} ) {
		my @modules = sort keys %{ $api->{modules} };
		$out .= $q->Tr(
			$q->th(
				{ -style => "vertical-align:top", -rowspan => int( ( scalar(@modules) + 1 ) / 2 ) + 1 }, "Modules"
			)
		);
		for ( my $i = 0 ; $i < @modules ; $i += 2 ) {
			if ( $i + 2 > @modules ) {
				$out .= $q->Tr(
					$q->td(
						{ -colspan => 2 },
						$q->a( { -href => "?type=module&module=" . $modules[$i] }, $modules[$i] )
					)
				);
				last;
			}
			$out .= $q->Tr(
				$q->td( $q->a( { -href => "?type=module&module=" . $modules[$i] }, $modules[$i] ) ),
				$q->td( $q->a( { -href => "?type=module&module=" . $modules[ $i + 1 ] }, $modules[ $i + 1 ] ) )
			);
		}
	}
	if ( $api->{required} ) {
		my @required = sort keys %{ $api->{required} };
		$out .= $q->Tr(
			$q->th(
				{ -style => "vertical-align:top", -rowspan => int( ( scalar(@required) + 1 ) / 2 ) + 1 },
				"Required Modules"
			)
		);
		for ( my $i = 0 ; $i < @required ; $i += 2 ) {
			if ( $i + 2 > @required ) {
				$out .= $q->Tr(
					$q->td(
						{ -colspan => 2 },
						$q->a( { -href => "?type=module&module=" . $required[$i] }, $required[$i] )
					)
				);
				last;
			}
			$out .= $q->Tr(
				$q->td( $q->a( { -href => "?type=module&module=" . $required[$i] }, $required[$i] ) ),
				$q->td( $q->a( { -href => "?type=module&module=" . $required[ $i + 1 ] }, $required[ $i + 1 ] ) )
			);
		}
	}
	if ( $api->{parents} ) {
		my @parents = sort @{ $api->{parents} };
		$out .= $q->Tr(
			$q->th(
				{ -style => "vertical-align:top", -rowspan => int( ( scalar(@parents) + 1 ) / 2 ) + 1 },
				"Inherited Modules"
			)
		);
		for ( my $i = 0 ; $i < @parents ; $i += 2 ) {
			if ( $i + 2 > @parents ) {
				$out .= $q->Tr(
					$q->td(
						{ -colspan => 2 },
						$q->a( { -href => "?type=module&module=" . $parents[$i] }, $parents[$i] )
					)
				);
				last;
			}
			$out .= $q->Tr(
				$q->td( $q->a( { -href => "?type=module&module=" . $parents[$i] }, $parents[$i] ) ),
				$q->td( $q->a( { -href => "?type=module&module=" . $parents[ $i + 1 ] }, $parents[ $i + 1 ] ) )
			);
		}
	}
	if ( $api->{class} ) {
		my @classes = sort keys %{ $api->{class} };
		$out .= $q->Tr(
			$q->th(
				{ -style => "vertical-align:top", -rowspan => int( ( scalar(@classes) + 1 ) / 2 ) + 1 },
				"Class Methods"
			)
		);
		for ( my $i = 0 ; $i < @classes ; $i += 2 ) {
			my $line1 = $api->{object}{ $classes[$i] };
			my $line2 = $api->{object}{ $classes[ $i + 1 ] };
			if ( $i + 2 > @classes ) {
				$out .= $q->Tr(
					$q->td(
						{ -colspan => 2 },
						$q->a(
							{ -href => "?type=module&module=$module&details=code&file=$file#line$line1" },
							$classes[$i]
						)
					)
				);
				last;
			}
			$out .= $q->Tr(
				$q->td(
					$q->a(
						{ -href => "?type=module&module=$module&details=code&file=$file#line$line1" }, $classes[$i]
					)
				),
				$q->td(
					$q->a(
						{ -href => "?type=module&module=$module&details=code&file=$file#line$line2" },
						$classes[ $i + 1 ]
					)
				)
			);
		}
	}
	if ( $api->{object} ) {
		my @objects = sort keys %{ $api->{object} };
		$out .= $q->Tr(
			$q->th(
				{ -style => "vertical-align:top", -rowspan => int( ( scalar(@objects) + 1 ) / 2 ) + 1 },
				"Object Methods"
			)
		);
		for ( my $i = 0 ; $i < @objects ; $i += 2 ) {
			my $line1 = $api->{object}{ $objects[$i] }		 if $objects[$i];
			my $line2 = $api->{object}{ $objects[ $i + 1 ] } if $objects[ $i + 1 ];
			if ( $i + 2 > @objects ) {
				$out .= $q->Tr(
					$q->td(
						{ -colspan => 2 },
						$q->a(
							{ -href => "?type=module&module=$module&details=code&file=$file#line$line1" },
							$objects[$i]
						)
					)
				);
				last;
			}
			$out .= $q->Tr(
				$q->td(
					$q->a(
						{ -href => "?type=module&module=$module&details=code&file=$file#line$line1" }, $objects[$i]
					)
				),
				$q->td(
					$q->a(
						{ -href => "?type=module&module=$module&details=code&file=$file#line$line2" },
						$objects[ $i + 1 ]
					)
				)
			);
		}
	}
	if ( keys %{ $api->{func} } ) {
		my @funcs = sort keys %{ $api->{func} };
		$out .= $q->Tr(
			$q->th(
				{ -style => "vertical-align:top", -rowspan => int( scalar(@funcs) / 2 ) + 2 },
				"General Soubroutines"
			)
		);
		for ( my $i = 0 ; $i < @funcs ; $i += 2 ) {
			my $line1 = $api->{object}{ $funcs[$i] }		if $funcs[$i];
			my $line2 = $api->{object}{ $funcs[ $i + 1 ] }	if $funcs[ $i + 1 ];
			if ( $i + 2 > @funcs ) {
				my $a;
				if ( $line1 ) {
					$a = $q->a(
						{ -href => "?type=module&module=$module&details=code&file=$file#line$line1" },
						$funcs[$i]
					);
				}
				else {
					$a = $q->span( { title => "Error lost line number" }, $funcs[$i], );
				}
				$out .= $q->Tr( $q->td( { -colspan => 2 }, $a ) );
				last;
			}
			$out .= $q->Tr(
				$q->td(
					$q->a( { -href => "?type=module&module=$module&details=code&file=$file#line$line1" }, $funcs[$i] )
				),
				$q->td(
					$q->a(
						{ -href => "?type=module&module=$module&details=code&file=$file#line$line2" },
						$funcs[ $i + 1 ]
					)
				)
			);
		}
	}
	$out .= $q->end_table();
	$out .= <<NOTICE;
<br />
<div style="clear:both;font-size:0.8em">
	<b>Note:</b> This API is just a guess on the meaning of the subroutines in the file.<br />
	<div style="clear:both;">
		<i>Class Methods</i> are assumed be in one of the following forms:
		<pre style="width:16em;float: left">
sub class_method {
	my \$class = shift;
	...
}</pre>
		<div style="float:left;padding:5px"><br />or</div>
		<pre style="width:16em;float: left">
sub class_method {
	my \$caller = shift;
	...
}</pre>
	</div>
	<div style="clear:both;">
		<i>Object Methods</i> are assumed to be in one of the following forms:
		<pre style="width:16em;float: left">
sub object_method {
	my \$self = shift;
	...
}</pre>
		<div style="float:left;padding:5px"><br />or</div>
		<pre style="width:16em;float: left">
sub object_method {
	my \$this = shift;
	...
}</pre>
		<div style="float:left;padding:5px"><br />or</div>
		<pre style="width:18em;float: left">
sub object_method {
	my ( \$self, ... ) = \@_;
	...
}</pre>
		<div style="float:left;padding:5px"><br />or</div>
		<pre style="width:18em;float: left">
sub object_method {
	my ( \$this, ... ) = \@_;
	...
}</pre>
	</div>
</div>
NOTICE
	return $out;
}

1;

__END__
