#!/usr/local/bin/perl -w
#!/usr/bin/perl -w

## This is a 'cleanup' script, written as part of the migration
## process from the old MetaBase to the latest version. 

use strict;
use Getopt::Long;
use MediaWiki::API;

## Import the helper functions
use NARDatabase
    ( "mwLogin",
      "getPageStatus",
      "getPageRevisions"
    );

## Get a connection to the wiki...
my $mw = mwLogin;



## Check the command line for command line arguments

# For debugging
my $force = 0;
my $verbose = 0;

GetOptions( "force" => \$force,
	    "verbose+" => \$verbose,
	  )
  or die "problem with command line arguments\n";



## List based on template usage

my $list =
  $mw->list ( { action => 'query',
		list => 'embeddedin',
		eititle => 'Template:NARDatabase transclusion',
		eilimit => '250'
	      },
	      { max => 4 }
	    );

print "got ", scalar(@$list), "\n";



for my $page (@$list){
  
  my $title = $page->{title};
  
  ## Historical fix up!!!!!
  my $rev = getPageRevisions($title, $mw)
    or die "ffffff\n";
  
  if($force ||
     (scalar(@$rev) == 3 &&
      $rev->[0]->{user} eq 'MaintainanceBot' &&
      $rev->[1]->{user} eq 'NARDatabaseBot' &&
      $rev->[2]->{user} eq 'NARDatabaseBot'
     ) ||
     (scalar(@$rev) == 4 &&
      $rev->[0]->{user} eq 'MaintainanceBot' &&
      $rev->[1]->{user} eq 'MaintainanceBot' &&
      $rev->[2]->{user} eq 'NARDatabaseBot' &&
      $rev->[3]->{user} eq 'NARDatabaseBot'
     ) ||
     (scalar(@$rev) == 2 &&
      $rev->[0]->{user} eq 'NARDatabaseBot' &&
      $rev->[1]->{user} eq 'NARDatabaseBot'
     ) ||
     (scalar(@$rev) == 1 &&
      $rev->[0]->{user} eq 'MaintainanceBot'
     )
    ){
    
    print "$title\n"
  }
  else{
    #nop
  }
}

