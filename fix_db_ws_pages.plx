#!/usr/local/bin/perl -w
#!/usr/bin/perl -w

## Given a NAR database (in HTML format), this script checks if the
## MetaBase entry for the given database can be 'safely' updated. User
## contributed text is saved, the update performed, and the user
## contributed text is then restored.


use Data::Dumper;

use Getopt::Long;

use MediaWiki::API;

use HTML::WikiConverter;

use strict;


## This will be moved into .pm
my $wc =
  new HTML::WikiConverter( dialect => 'MediaWiki' );



## Set this to tag pages

my $version = "2.1.1";


## Set this to help debugging

my $verbose = 0;



## Import the helper functions

use NARDatabase
  qw( mwLogin
      parseNarDatabaseHtml
      getPage
      printPageRevisions
      tidyHtmlForMediaWiki
      updatePage
   );



## Check that we have been passed an appropriate HTML file

die "pass me a NAR datbase HTML page!\n"
  unless @ARGV;

my $file = $ARGV[0];

die "file not recognised: $file\n"
  unless $file =~ /db_accn_(\d{4})\.html$/;

my $id = $1;





## OK

warn "doing $file\n";



## Get a connection to the wiki...

my $mw = mwLogin();

warn "logged in\n";



## parse the given NAR database HTML

my $fh;

open $fh, $file
  or die "cant open $file : $! \n";

my $data = parseNarDatabaseHtml( $fh, $verbose )
  or die "failed to parse $file\n";

warn "parsed $file\n";



## Unwrap the resulting data (for didactic purposes)

my ($title,		# The database Title.
    $no,		# The database No.
    $url,		# The database URL(s).
    $author,		# The database authors (one line).
    $authorAdr,		# The author address (one line).
    $contact,		# The database contact(s).
    $H3,		# The H3 data.
    #
    $cat,		# The category data.
    $subCat,		# The sub-category data.
    #
    $abstract,		# Abstract URL.
    $abstractYear	# Abstract year
   ) = @$data;

&freakOut()
  unless $id == $no;

## Move this check into the parser?
unless (keys %{$H3}){
  die "no sections?\n"
}

for(keys %{$H3}){
  warn "\tFound Section:$_\n";
}



printPageRevisions($title, $mw);

warn "\nUpdate?\n";
print "Press Enter to Continue . . .\n";
my $dummy = <STDIN>;



## Start building the template
my $text = <<EO;
{{Database entry
|name = $title
|nar id = $no
EO

##
my %sections =
("Database Description" => "10 nar description",
 "Recent Developments"  => "20 nar developments",
 "Acknowledgements"     => "30 nar acknowledgements",
 "References"           => "40 nar references",
);

for (keys %{$H3}){
  next if $sections{$_};
  die "unknown section -$_-\n"
}

for my $section (sort {$sections{$a} cmp
			 $sections{$b} } keys %sections){
  if (defined($H3->{$section})){
    my $paramName = substr($sections{$section},3);
    
    $text .= "|$paramName = ";
    my $t  = $wc->html2wiki( $H3->{$section} ). "\n";
    
    ## Sad but true...
    $t = tidyHtmlForMediaWiki( $t );
    
    $text .= "$t\n"
  }
}

if($author){
  $text .= "|authors = $author\n";
}
if ($authorAdr){
  $text .= "|author addresses = $authorAdr\n"
}

$text .= "|homepage = ". join(",", @$url). "\n";

$text .= <<EO;
|abstracts = $abstract
|nar years = $abstractYear
EO

$text .= "|emails = ". join(",", @$contact). "\n";

$text .= "|nar categories = ".
  join(",", values(%$cat),
       (map {values(%$_)}  values(%$subCat))
      ). "\n";

$text .= "|version = $version\n";

$text .= "}}\n";

$text .= <<EO;

<!-- Add your text below -->




<!-- Add your text above -->

{{Page data|term=$title}}
EO



updatePage($title, $mw, $text, 'Moving to template based mayhem! ;-)');



warn "OK\n";
