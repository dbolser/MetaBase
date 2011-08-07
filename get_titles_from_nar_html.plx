#!/usr/bin/perl -w

use strict;
use Getopt::Long;

use NARDatabase
  qw( parseNarDatabaseHtml
      tidyTitleForMediaWiki
   );

## Set piping hot pipes
$| = 1;



## command line arguments
my $verbose = 0;


## Check the command line for command line arguments
GetOptions (
	    "verbose+" => \$verbose
	   )
  or die "problem with command line arguments\n";

warn "verbose : $verbose\n"
  if $verbose > 0;


## First things first...
die "pass me a list of NAR database webpages\n"
  unless @ARGV;


for my $file (@ARGV){
  warn "$file\n"
    if $verbose > 2;
  
  unless ($file =~ /db_accn_(\d{4})\.html$/){
    warn "file not recognised! : '$file'\n";
    exit;
  }
  
  
  
  my $id = $1;
  
  warn "doing $file ($id)\n"
    if $verbose > 1;
  
  
  
  ## parse the HTML
  
  my $fh;
  
  open $fh, $file
    or die "cant open $file : $! \n";
  
  my $data = parseNarDatabaseHtml( $fh, $verbose )
    or die "failed to parse $file\n";
  
  warn "parsed $file\n"
    if $verbose > 1;
  
  
  
  ## Unwrap the resulting data (for didactic purposes)
  
  my ($title,		# The database Title.
      $code,            # The database title code (if any).
      $accn_no,		# The database Accession No.
      $url,		# The database URL(s).
      $author,		# The database author(s) (one line).
      $authorAdr,	# The author address(es) (one line).
      $contact,		# The database contact email(s).
      $H3,		# The H3 data.
      #
      $cat,		# The category data.
      $subCat,		# The sub-category data.
      #
      $abstract,	# Abstract URL.
      $abstractYear	# Abstract year
     ) = @$data;
  
  ## basic sanity check; does the file name match its contents...
  &freakOut
    unless $id == $accn_no;
  
  
  
  ## Munge the title for MW

  my $changed = 0;
  my $mwTitle = tidyTitleForMediaWiki( $title );
  
  if($title ne $mwTitle){
    warn "changed '$title' to '$mwTitle'\n"
      if $verbose > 0;
    $changed = 1;
  }
  
  ## But specifically...
  my $caps = 0;
  my $firstChar = substr($title, 0, 1);
  
  if ($firstChar ne uc($firstChar)){
    warn "TITLE CAPS: $mwTitle\n"
      if $verbose > 1;
    $caps = 1;
  }
  
  print
    join("\t", $id, $changed, $caps, 
	 $code||'', $mwTitle), "\n";
}

warn "OK\n";
