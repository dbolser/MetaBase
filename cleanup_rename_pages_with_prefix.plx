#!/usr/local/bin/perl -w
#!/usr/bin/perl -w

## This is a 'cleanup' script, written as part of the migration
## process from the old MetaBase to the latest version. Here we are
## changing the way that the database short names (codes) are handled.

use strict;
use Getopt::Long;

## Import the helper functions
use NARDatabase
  ( "mwLogin",
    "parseNarDatabaseHtml",
    "tidyTitleForMediaWiki"
  );

## Set piping hot pipes
$| = 1;

## Get a connection to the wiki...
my $mw = mwLogin;



## Check the command line for command line arguments

# For debugging
my $force = 0;
my $verbose = 0;

# Really move pages
my $movePages = 0;

GetOptions( "force"	=> \$force,
	    "verbose|v"	=> \$verbose,
	    "move"	=> \$movePages,
	  )
  or die "problem with command line arguments\n";



## First things first...
die "pass me a list of NAR database web pages\n"
  unless @ARGV;


for my $file (@ARGV){
  warn "$file\n"
    if $verbose > 3;
  
  my $data = parseNarDatabaseHtml($file)
    or die "failed to parse $file\n";
  
  warn "parsed $file\n"
    if $verbose > 2;
  
  
  
  ## Unwrap the resulting data (for didactic purposes)
  
  my ($title,           # The database Title.
      $accn_no,         # The database Accession No.
      $url,             # The database URL(s).
      $author,          # The database authors (one line).
      $authorAdr,       # The author address (one line).
      $contact,         # The database contact(s).
      $H3,              # The H3 data.
      #
      $cat,             # The category data.
      $subCat,          # The sub-category data.
      #
      $abstract,        # Abstract URL.
      $abstractYear     # Abstract year
     ) = @$data;
  
  ## OK
  
  
  
  ## Check for three DB abbreviation styles...
  
  # Hash to check that the database codes are unique
  my %titleCodes;
  
  # The code and the new title
  my ($code, $newTitle);
  
  # Debugging
  print "$title\n" if $verbose > 0;
  print "$title\n" if $verbose > 0;
  
  if ( $title =~ /^(\S+) - (.*)$/ ||
       $title =~ /^(\S+): (.*)$/  ||
       $title =~ /^(.*) \((\S+)\)$/ ){
    
    # cludge...
    ($code, $newTitle) =
      sort {length($a) <=> length($b)} ($1, $2);
    
    print " GOT DB CODE '$code'\n"
      if $verbose > 0;
    
    die "$code is not unique!: $code\n"
      if $titleCodes{$code}++;
  }
  else{
    # Apparently nothing to do... The title does not appear to contain a
    # database code.
    next;
  }
  
  print "\n"
    if $verbose > 0;
  
  
  
  ## Remember! This is a historical clean up job!
  
  ## Put everything in MW friendly format
  my $mwTitle    = tidyTitleForMediaWiki( $title );
  my $mwNewTitle = tidyTitleForMediaWiki( $newTitle );
  my $mwCode     = tidyTitleForMediaWiki( $code );
  
  warn "changed '$title' to '$mwTitle'\n"
    if $title ne $mwTitle
      and $verbose > 2;
  
  warn "changed '$newTitle' to '$mwNewTitle'\n"
    if $newTitle ne $mwNewTitle
      and $verbose > 2;
  
  warn "changed '$code' to '$mwCode'\n"
    if $code ne $mwCode
      and $verbose > 2;
  
  
  
  
  
  ## Connect to the database and perform some checks!
  use NARDatabase
    qw(	getPageStatus
	movePage
	createRedirect
     );
  
  my $titleStatus = getPageStatus($mwTitle, $mw);
  print "$titleStatus\n";
  
  my $newTitleStatus = getPageStatus($mwNewTitle, $mw);
  print "$newTitleStatus\n";
  
  my $codeStatus = getPageStatus($mwCode, $mw);
  print "$codeStatus\n";
  
  
  
  if($titleStatus eq 'exists' &&
     $newTitleStatus eq 'missing' &&
     ($codeStatus eq 'missing' ||
      $codeStatus eq 'redirect')){
    
    warn "moving from '$mwTitle' to '$mwNewTitle'\n";
    
    movePage( $mw, $mwTitle, $mwNewTitle, $force,
	      "Automatic removal of database codes." )
      or warn "problem moving '$mwTitle' to '$mwNewTitle'\n";
    
    warn "creating a redirect from '$mwCode' to '$mwNewTitle'\n";
    
    createRedirect( $mw, $mwCode, $mwNewTitle, $force,
		  "Automatic redirects for database codes.")
      or warn "problem creating redirect '$mwCode' to '$mwNewTitle'\n";
  }
  else{
    print "Skippin\n";
  }
  print "done\n\n";
  
  #warn "waiting for keypress\n";
  #my $wait = <STDIN>;
}

warn "OK\n";
