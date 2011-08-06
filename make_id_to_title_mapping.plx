#!/usr/local/bin/perl -w
#!/usr/bin/perl -w

## Given a NAR database (in HTML format), this script outputs the id,
## code and title of the database

use strict;
use Getopt::Long;

## Import the helper functions
use NARDatabase
  ( "parseNarDatabaseHtml",
    "tidyTitleForMediaWiki"
  );



## Check the command line for command line arguments

# For debugging
my $verbose = 0;


GetOptions( "verbose" => \$verbose,
	  )
  or die "problem with command line arguments\n";



## First things first...
die "pass me a list of NAR database web pages\n"
  unless @ARGV;


for my $file (@ARGV){
  warn "$file\n"
    if $verbose > 1;
  
  my $data = parseNarDatabaseHtml($file)
    or die "failed to parse $file\n";
  
  warn "parsed $file\n"
    if $verbose > 1;
  
  
  
  ## Unwrap the resulting data (for didactic purposes)
  
  my ($title,           # The database title.
      $titleCode,	# The database title code (if any).
      $accn_no,         # The database accession No.
      $url,             # The database URL(s).
      $author,          # The database author(s) (one line).
      $authorAdr,       # The author address(es) (one line).
      $contact,         # The database contact email(s).
      $H3,              # The H3 data.
      #
      $cat,             # The database category data.
      $subCat,          # The database sub-category data.
      #
      $abstract,        # Abstract URL.
      $abstractYear     # Abstract year
     ) = @$data;
  
  ## OK
  
  
  
  ## Take care with the database titles, as they may not be mappable
  ## onto MW page names!
  my $mwTitle = tidyTitleForMediaWiki( $title );
  
  ## Done!
  
  print
    join("\t",
	 $accn_no,
	 $titleCode || '',
	 $mwTitle,
	), "\n";
}
