
use strict;
use warnings;
use Test::More;

if ( not $ENV{TEST_AUTHOR} ) {
    my $msg = 'Author test.  Set TEST_AUTHOR environment variable to a true value to run.';
    plan( skip_all => $msg );
}

 check that Test::Spelling is installed
eval { require Test::Spelling; Test::Spelling->import() };

# now check that the spell command is installed
my $found;
for my $dir ( split /:/, $ENV{PATH} ) {
	next if !-d $dir;
	next if !-x "$dir/spell";

	$found = 1;
	last;
}

plan skip_all => "Test::Spelling required for testing POD spelling" if $@;
plan skip_all => "spell cmd required for testing POD spelling" if !$found;

add_stopwords(qw/
	html
	HTML
	QLD
	Param
	API
	ISA
	Arg
	DocPerl
	docperl
	pl
	pm
	ppm
	IIS
	tmpl
	CPAN
	LightHTTPD
	conf
	checksetup
	Readonly
	firefox
	cgi
	http
	DocPerl's
	clearcache
	eg
	hightlighted
	initialisation
	initialises
	inc
	ini
	IncFilders
	IncFolders
	LocalFolders
	url
	api
	GraphViz
	StyleSheet
	HideDefaultModule
	LocalOnly
	ShowTestStatus
	ShowText
	tyleSheet
	cpan
	org's
	javascript
	URLs
/);
all_pod_files_spelling_ok();
