[% FOREACH mod = keys module -%]
[% IF mod eq '*' -%]
[% NEXT -%]
[% END -%]
[% mod %]: { '*': new Array([% IF module.mod.'*' -%]
[% files = module.mod.'*' -%]
[% FOREACH file = files -%]

[% END -%]), 
[% END -%]

[% PERL %]
for my $module ( keys %module ) {
	next if $module eq '*';
	
	print "$module: { '*': ";
	
	if ( $module{$module}{'*'} ) {
		print 'new Array("', join( '","', @{ $module{$module}{'*'} } ), '"),';
	}
	else {
		print 'new Array()';
	}
	
	if ( ref $module{$module} ) {
		for my
		#include list.js module = 
	}
	
	print " },";
}
[% END %]
