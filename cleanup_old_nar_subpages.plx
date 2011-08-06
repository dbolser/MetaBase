#!/usr/local/bin/perl -w
#!/usr/bin/perl -w

## This is a 'cleanup' script, written as part of the migration
## process from the old MetaBase to the latest version. Here we are
## removing all the old 'Database/NAR' pages where the corresponding
## Database Page has been updated.

use strict;
use Getopt::Long;
use MediaWiki::API;

## Import the helper functions
use NARDatabase
    ( "mwLogin",
      "getPageStatus"
    );

## Get a connection to the wiki...
my $mw = mwLogin;





## Delete based on category

my $list =
  $mw->list ( { action => 'query',
		list => 'categorymembers',
		cmtitle => 'Category:Database entry',
		cmlimit=>'250'
	      },
	      { max => 4 }
	    );

print "got ", scalar(@$list), "\n";



for my $title (@$list){
  
  my $page = $title->{title}. '/NAR';
  
  my $pageStatus =
    getPageStatus($page, $mw);
  
  if($pageStatus eq 'exists'){
    
    warn "deleting $page\n";
    
    $mw->edit( { action => 'delete',
		 title => $page,
		 reason => 'Tidying up',
		 bot => 'true',
	       } );
  }
  else{
    warn "'$page' : '$pageStatus'\n";
  }
}


__END__












my $list =
  $mw->list ( { action => 'query',
		list => 'embeddedin',
		eititle => 'Template:NAR redirect',
		eilimit => '250'
	      },
	      { max => 4 }
	    );

print "got ", scalar(@$list), "\n";



for my $title (@$list){
  
  my $page = $title->{title};
  
  my $basePage = $page;
  
  die unless $basePage =~ s/\/NAR$//;
  
  my $basePageStatus =
    getPageStatus($basePage, $mw);
  
  if($basePageStatus eq 'missing' ||
     $basePageStatus eq 'redirect'){
    
    warn "deleting $page\n";
    
    $mw->edit( { action => 'delete',
		 title => $page,
		 reason => 'Tidying up',
		 bot => 'true',
	       } );
  }
  else{
    warn "'$basePage' : $basePageStatus \n";
  }
}






__END__

