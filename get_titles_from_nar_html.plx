#!/usr/local/bin/perl -w

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
	    "verbose"  => \$verbose
	   )
  or die "problem with command line arguments\n";



## First things first...
die "pass me a list of NAR database webpages\n"
  unless @ARGV;


for my $file (@ARGV){
  warn "$file\n"
    if $verbose > 2;
  
  unless ($file =~ /db_accn_(\d{4})\.html$/){
    warn "file not recognised: $file\n";
    exit;
  }
  
  my $id = $1;
  
  warn "doing $file ($id)\n"
    if $verbose > 1;
  
  
  
  ## parse the HTML
  
  my $fh;
  
  open $fh, $file
    or die "cant open $file : $! \n";
  
  my $data = parseNarDatabaseHtml($fh)
    or die "failed to parse $file\n";
  
  warn "parsed $file\n"
    if $verbose > 1;
  
  
  
  ## Unwrap the resulting data (for didactic purposes)
  
  my ($title,		# The database Title.
      $accn_no,		# The database Accession No.
      $url,		# The database URL(s).
      $author,		# The database authors (one line).
      $authorAdr,	# The author address (one line).
      $contact,		# The database contact(s).
      $H3,		# The H3 data.
      #
      $cat,		# The category data.
      $subCat,		# The sub-category data.
      #
      $abstract,	# Abstract URL.
      $abstractYear	# Abstract year
     ) = @$data;
  
  ## basic sanity check; does the file name match its contents...
  &freakOut()
    unless $id == $accn_no;
  
  ## Move this check into the parser?
  unless (keys %{$H3}){
    die "no sections?\n"
  }
  
  
  
  ## OK
  
  my $mwTitle = tidyTitleForMediaWiki( $title );
  
  warn "changed '$title' to '$mwTitle'\n"
    if $title ne $mwTitle
      and $verbose > 0;
  
  ## But specifically...
  my $firstChar = substr($title, 0, 1);
  
  warn "TITLE CAPS: $mwTitle\n"
    if $firstChar ne uc($firstChar);

  print "$id\t$mwTitle\n";
}

warn "OK\n";
