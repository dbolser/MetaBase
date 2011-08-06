#!/usr/local/bin/perl -w
#!/usr/bin/perl -w

## Given a NAR database (in HTML format), this script checks if the
## MetaBase entry for the given database can be 'safely' updated. User
## contributed text is saved, the update performed, and the user
## contributed text is then restored.

use strict;
use Getopt::Long;

## Import the helper functions
use NARDatabase
  ( "mwLogin",
    "parseNarDatabaseHtml",
    "tidyTitleForMediaWiki",
    "getPage",
    "makeTheFucker",
    "getPageRevisions",
    "updatePage",
  );

## Get a connection to the wiki...
my $mw = mwLogin;



## Check the command line for command line arguments

# For debugging
my $force = 0;
my $verbose = 0;

# To tag pages with a version number
my $pageVersion = "2.1.1";

GetOptions( "force" => \$force,
	    "verbose+" => \$verbose,
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
  
  #print "$mwTitle ($titleCode)\n";
  
  ## Historical fix up!!!!!
  my $rev = getPageRevisions($mwTitle, $mw)
    or die "ffffff\n";
  
  if($force ||
     #(scalar(@$rev) == 3 &&
     # $rev->[0]->{user} eq 'MaintainanceBot' &&
     # $rev->[1]->{user} eq 'NARDatabaseBot' &&
     # $rev->[2]->{user} eq 'NARDatabaseBot'
     #) ||
     #(scalar(@$rev) == 4 &&
     # $rev->[0]->{user} eq 'MaintainanceBot' &&
     # $rev->[1]->{user} eq 'MaintainanceBot' &&
     # $rev->[2]->{user} eq 'NARDatabaseBot' &&
     # $rev->[3]->{user} eq 'NARDatabaseBot'
     #) ||
     (scalar(@$rev) == 2 &&
      $rev->[0]->{user} eq 'NARDatabaseBot' &&
      $rev->[1]->{user} eq 'NARDatabaseBot'
     )# ||
     #(scalar(@$rev) == 1 &&
     # $rev->[0]->{user} eq 'MaintainanceBot'
     #)
    ){
    
    warn "updating!\n"
      if $verbose > 0;
    
    my $pageText = makeTheFucker($data)
      or die "fuckidy\n";
    
    updatePage($mwTitle, $mw, $pageText,
	       "Moving to template based system. $pageVersion"
	      );
  }
  else {
    warn "cuck knwos\n"
      if $verbose > 0;
  }
  # Process the next file
  warn "\n"
    if $verbose > 0;
  
  my $x = <>;
}

warn "OK\n";



__END__


    ## Try to grab the user contributed comments...
    
    my $mwTitle = tidyTitleForMediaWiki( $title );
    
    my $page = getPage( $mwTitle, $mw );
    my $pageText = $page->{'*'};
    
    
    if($pageText =~ /NARWebserver transclusion/){
	die "phui\n"
    }
    
    my $sps = index($page->{'*'}, '<!-- Add your text below -->');
    my $spe = index($page->{'*'}, '<!-- Add your text above -->');
    
    die "mcFucker\n" 
	unless $sps && $spe && $sps < $spe;
    
    my $userText =
	substr($page->{'*'}, $sps, $spe-$sps);
    
    print "'$userText'\n";


    
    #my $pageText = makeTheFucker($data, $sps, $spe)
#	or die "fuckidy\n";
 
    

   
    
    #updatePage($title, $mw, $pageText, 
#	       'Moving to template based mayhem! ;-)'
#	);
    
}

warn "OK\n";
