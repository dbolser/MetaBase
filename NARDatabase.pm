
package NARDatabase;

use strict;

use MediaWiki::API;
use HTML::WikiConverter;

use Data::Dumper;



warn "PARSE AUTHORS / REFERENCES!!!\n";
warn "\n\n";



## Set up the package

require Exporter;

our @ISA        = qw( Exporter ); # Inherit from Exporter
our @EXPORT     = qw( );          # Default symbols to export.
our @EXPORT_OK  =                 # Symbols on request.
  (
   ## Functions
   "parseNarDatabaseHtml",
   "tidyTitleForMediaWiki",
   "tidyHtmlForMediaWiki",
   "getNarDatabasePageText",
   "printNarDatabasePageData",
   #
   "makeTheFucker",
   "mwLogin",
   "getPage",
   "getPageData",
   "getPageStatus",
   "getPageRevisions",
   "printPageRevisions",
   "updatePage",
   "checkPageForAutomaticUpdate",
   "movePage",
   "createRedirect"
   ## Variables
  );

my $wc =
  new HTML::WikiConverter( dialect => 'MediaWiki' );


# Parse the HTML text of a 'NAR Database page'. The function expects a
# file handle and optionally a 'verbosity index' for debugging. It
# returns an array reference with various data elements taken from the
# page. It does as much error checking as I could stomach. Note that
# some pages fail the error checks!

sub parseNarDatabaseHtml {
  my $file = shift;
  my $verbose = shift || 0;
  
  unless ($file =~ /db_accn_(\d{4})\.html$/){
    warn "file not recognised: $file\n";
    exit;
  }
  
  my $id = $1;
  
  warn "doing $file ($id)\n"
    if $verbose > 2;
  
  
  
  ## parse the NAR Database HTML
  
  my $fh;
  
  open $fh, $file
    or die "cant open $file : $! \n";
  
  
  
  ## Watch out for logic!
  
  my ($bodyFlag,	# Are we in the body of the page?
      #
      $titleFlag,	# Do we have the database title?
      $dbTitle,		# The database title.
      $dbTitleCode,	# The database title 'code' (if any)
      #
      $noFlag,		# Do we have the database No.?
      $accnNo,		# The database No.
      #
      $urlFlag,		# Do we have the database URL(s)?
      @url,		# The database URL(s).
      #
      $authorFlag,	# Do we have the authors?
      $author,		# The database authors (one line).
      #
      $authorAdrFlag,	# Do we have the author address?
      $authorAdr,	# The author address (one line).
      #
      $contactFlag,	# Do we have the database contact(s)?
      @contact,		# The database contact(s).
      #
      $H3Flag,		# Are we in a H3 section?
      $H3,		# The H3 section we are in.
      %H3,		# The H3 data.
      #
      %cat,		# The database category number / id.
      %subCat,		# The database sub-category number / id.
      #
      $abstractFlag,	# Does the database have an abstract?
      $abstract,	# Abstract URL.
      $abstractYear	# Abstract year.
     );
  
  # Used for sanity checking (in theory)
  my $divCounter = 0;
  
  while(<$fh>){
    chomp;
    
    next if /^$/;
    
    # Look for the body of the page
    if(!$bodyFlag){
      if (/^\<!-- start body --\>$/){
	$bodyFlag = 1;
	warn "body starting at $.\n"
	  if $verbose > 0;
      }
      else{
	warn "IGNORING (1): -$_-\n"
	  if $verbose > 2;
      }
      next; # We won't continue until we find this!
    }
    
    
    ## Now we are in the body of the page
    
    # Keep track of div's (for debugging, in theory)
    $divCounter++
      if /\<div /;
    
    
    # Look for the database title
    
    if (!$titleFlag){
      if (/^\<h1 class=\"summary\"\>(.*)\<\/h1\>$/){
	$titleFlag = 1;
	($dbTitle, $dbTitleCode) = parseTitle($1);
	warn join("\t", "Title", $., $divCounter, $dbTitle), "\n"
	  if $verbose > 0;
      }
      else{
	warn "IGNORING (2): -$_-\n"
	  if $verbose > 2;
      }
      next; # We won't continue until we find this element!
    }
    
    
    # Look for the database number
    
    if (!$noFlag){
      if (/^NAR Molecular Biology Database Collection entry number (\d+)$/){
	$noFlag = 1;
	$accnNo = $1;
	warn join("\t", "No.", $., $divCounter, $accnNo), "\n"
	  if $verbose > 0;
      }
      else{
	warn "IGNORING (3): -$_-\n"
	  if $verbose > 2;
      }
      next; # We won't continue until we find this element!
    }
    
    
    # Look for the database URL(s) line
    
    if (!$urlFlag){
      # Note: there can be more than one URL (separated by ' or ')!
      if (/^(?:\<a href=\".*?\"\>.*?\<\/a\>(?: or )?)+$/){
	$urlFlag = 1;
	
	for (split(/ or /, $_)){
	  if (/\<a href=\"(.*?)\"\>(.*?)\<\/a\>/){
	    die "WHAT1? : \"$_\"\n"
	      if $1 ne $2;
	    push @url, $1;
	    warn join("\t", "URL", $., $divCounter, $1), "\n"
	      if $verbose > 0;
	  }
	  else{
	    die "WHAT2? : \"$_\"\n";
	  }
	}
      }
      else{
	warn "IGNORING (4): -$_-\n"
	  if $verbose > 2;
      }
      next; # We won't continue until we find this element!
    }
    
    
    # Look for the database author(s) line (optional)
    
    if (!$authorFlag){
      if (/^  \<strong\>(.*)\<\/strong\>$/){
	$authorFlag = 1;
	$author = $1;
	warn join("\t", "Auth", $., $divCounter, $author), "\n"
	  if $verbose > 0;
	
	next; # Done!
      }
      else{
	# We should set the $authorFlag later when we are sure that it
	# is missing.
	warn "IGNORING (5): -$_-\n"
	  if $verbose > 2;
      }
    }
    
    
    # Grab author address(es) line (one line)
    
    if ($authorFlag && !$authorAdrFlag){
      # It should be the next line after the author that isn't one of
      # these four...
      if (!/^  \<h3 / &&
	  !/^  \<div / &&
	  !/^  \<span / &&
	  !/^  \<\/div\>$/ &&
	  /^  (.+)$/){
	$authorAdrFlag = 1;
	$authorAdr = $1;
	warn join("\t", "Address", $., $divCounter, $authorAdr), "\n"
 	  if $verbose > 0;
      }
      else{
	warn "IGNORING (6): -$_-\n"
	  if $verbose > 2;
      }
      next; # Given we have an author, we won't continue until we find
	    # this element!
    }
    
    
    # Look for contact email address(es) line (optional)
    
    if (!$contactFlag){
      # Note: there can be more than one contact (separated by ' or ')!
      if (/^  \<span class=\"subhead\"\>Contact\<\/span\> (?:\<a href=\"MAILTO:.*?\"\>.*?\<\/a\>(?: or )?)+$/){
	$contactFlag = 1;
	
 	for (split(/ or /, $_)){
 	  if (/\<a href=\"MAILTO:(.*?)\"\>(.*?)\<\/a\>/){
 	    die "WHAT3? : \"$_\"\n"
 	      if $1 ne $2;
 	    push @contact, $1;
	    warn join("\t", "Cont", $., $divCounter, $1), "\n"
 	      if $verbose > 0;
	  }
	  else{
 	    die "WHAT4? : \"$_\"\n";
	  }
 	}
	next; # Done
      }
      else{
	# We should set the $contactFlag later when we are sure that
	# it is missing.
	warn "IGNORING (7): -$_-\n"
	  if $verbose > 2;
      }
    }
    
    
    # Grab the (standard?) 'H3' sections.
    if(/^  \<h3 class=\"summary\"\>(.*)\<\/h3\>$/){
      $H3Flag = 1;
      $H3 = $1;
      warn join("\t", "H3", $., $divCounter, $H3 ), "\n"
	if $verbose > 0;
      next; # Flag set... We could apply some logic here (and above).
    }
    elsif ($H3Flag){
      ## Leave the section
      if (/^  \<\/div\>$/){
	$H3Flag = 0;
      }
      # Or grab data (its a single line).
      elsif (!/  \<div / && /^  (.*)$/){
	$H3{$H3} = $1;
      }
      else{
	warn "IGNORING (8): -$_-\n"
	  if $verbose > 2;
      }
      next; # Given we have a H3, we won't continue until we find this
            # element!
    }
    
    # Grab category data
    
    # My error checking (and logic) ran out of steam...
    
    if(/^   Category\: \<a href\=\"\/nar\/database\/cat\/(\d+)\"\>(.*)\<\/a\>$/){
      my $catNo = $1;
      my $catId = $2;
      warn join("\t", "Cat", $., $divCounter, $catNo, $catId ), "\n"
	if $verbose > 0;
      
      #die "double cat!\n" if defined($cat{$catNo});
      
      $cat{$catNo} = $catId;
      
      next; # Done
    }
    
    if(/^      Subcategory\: \<a href\=\"\/nar\/database\/subcat\/(\d+)\/(\d+)\"\>(.*)\<\/a\>$/){
      my $catNo = $1;
      my $subCatNo = $2;
      my $subCatId = $3;
      warn join("\t", "SubCat", $., $divCounter, $subCatNo, $subCatId ), "\n"
	if $verbose > 0;
      
      die "sucks!\n" unless defined($cat{$catNo});
      
      die "double sub-cat!\n" if defined($subCat{$subCatNo});
      
      $subCat{$catNo}{$subCatNo} = $subCatId;
      
      next; # Done
    }
    
    ## Grab abstract link (optional)
    if (!$abstractFlag){
      if (/^\<div class\=\"bodytext\">Go to the \<a href\=\"(.*)\"\>abstract\<\/a\> in the NAR (\d\d\d\d) Database Issue\.$/){
	$abstractFlag = 1;
	$abstract = $1;
	$abstractYear = $2;
	warn join("\t", "Abst", $., $divCounter, $abstractYear, $abstract), "\n"
	  if $verbose > 0;
	next; # Done
      }
    }
    
    
    # Are we done here?
    if(/\<!-- end body --\>/){
      last;
    }
  }
  
  
  
  ## basic sanity check; does the file name match its contents...
  &freakOut()
    unless $id == $accnNo;
  
  ## Move this check into the parser?
  unless (keys %H3){
    die "no sections?\n"
  }
  
  
  
  return [$dbTitle,	# The database title.
	  $dbTitleCode, # The database title code (if any).
	  $accnNo,	# The database accession No.
	  \@url,	# The database URL(s).
	  $author,	# The database author(s) (one line).
	  $authorAdr,	# The author address(es) (one line).
	  \@contact,	# The database contact email(s).
	  \%H3,		# The H3 data.
	  #
	  \%cat,	# The database category data.
	  \%subCat,	# The database sub-category data.
	  #
	  $abstract,	# Abstract URL.
	  $abstractYear	# Abstract year.
	 ];

}

sub parseTitle {
  my $title = shift;
  
  if($title =~ /^(.*) \((\S+)\)$/ ){
    return($1, $2);
  }
  elsif($title =~ /^(\S+) - (.*)$/ ||
	$title =~ /^(\S+): (.*)$/ ){
    return($2, $1);
  }
  # The title does not appear to contain a database code.
  return($title)
}
  








sub tidyHtmlForMediaWiki {
  my $text = shift;
  
  $text =~ s/<br \/>/\n\n/;
  
  #$text =~ s/&reg;/®/g; # Feh!
  $text =~ s/&reg;//g; # Feh!!

  $text =~ s/&gt;/>/g;
  $text =~ s/&lt;/</g;
  $text =~ s/&amp;/&/g;
  $text =~ s/&apos;/'/g;
  $text =~ s/&eacute;/é/;
  
  die "Found an un-handled HTML character code?\n$text\n"
    if $text =~ m/&\S+;/;
  
  return $text;
}



sub tidyTitleForMediaWiki {
  my $text = shift;
  
  # Remove HTML that we can't wikify in the title...
  $text =~ s/<sup>(.*)<\/sup>/$1/;
  $text =~ s/<\/?[iI]>//g;
  
  #$text =~ s/&reg;/®/g; # Feh!
  $text =~ s/&reg;//g; # Feh!!
  $text =~ s/&eacute;/é/g;
  
  die "WTF?\n$text\n"
    if
      $text =~ m/&\S+;/ ||
	$text =~ m/<|>/;
  
  return $text;
}





### MediaWiki Subroutines

sub mwLogin {
  my $mw = MediaWiki::API->new();
  
  $mw->{config}->{api_url} = 'http://metadatabase.org/api.php';
  
  # log in
  $mw->login( { lgname     => '<user>',
		lgpassword => '<pass>' } )
    || die $mw->{error}->{code} . ': ' . $mw->{error}->{details};
  
  ## Make the above error code a bit more convenient...
  
  $mw->{config}->{on_error} = sub {
    print "Error code: ". $mw->{error}->{code}. "\n";
    print "Details: ". $mw->{error}->{details}. "\n\n";
    print $mw->{error}->{stacktrace}."\n";
    die;
  };
  
  warn "logged in\n";
  
  return $mw;
}




sub getPage {
  my $title = shift;
  my $mwApi = shift;
  
  warn "getting '$title'\n";

  return $mwApi->get_page({ title => $title });
}



## Query the MediaWiki page meta data and set a page status code

sub getPageData {
  my $title = shift;
  my $mwApi = shift;
  
  my $result;
  
  my $pageInfo =
    $mwApi->api({ action => 'query',
		  titles => $title,
		  prop   => 'info',
		});
  
  #print Dumper($pageInfo), "\n\n";
  
  ## We 'parse' the returned data structure using some Perl-ology
  $pageInfo =
      (values %{$pageInfo->{query}->{pages}})[0];
  
  #print Dumper($pageInfo), "\n\n";
  
  
  ## Now we explicitly set a status code using several status
  ## flags. This ad-hock step simplifies lots of subsequent code.
  
  if    ( exists($pageInfo->{missing}) ){
    $pageInfo->{status} = 'missing'
  }
  elsif ( exists($pageInfo->{redirect}) ){
    $pageInfo->{status} = 'redirect'
  }
  elsif ( exists($pageInfo->{invalid}) ){
    $pageInfo->{status} = 'invalid'
  }
  else{
    $pageInfo->{status} = 'exists'
  }
  
  return $pageInfo
}



# The purpose of this function is to check if a given Page exists, is
# a redirect, or is invalid (the page title is not a valid MediaWiki
# page title).
#
# Returns: a 'status code' which is 'exists', 'redirect', 'invalid' or
# 'missing'.

sub getPageStatus {
  my $title = shift;
  my $mwApi = shift;
  
  my $result;
  
  ## The real work is done here
  my $pageInfo =
    getPageData( $title, $mwApi );
  
  return $pageInfo->{status};
}



## Print the revision history of a given page

sub printPageRevisions {
  my $title = shift;
  my $mwApi = shift;
  
  my $revisions =
    getPageRevisions($title, $mwApi);
  
  ## Print the revisions
  print "revisions for $title\n";
  
  for(my $i=0; $i<@$revisions; $i++){
    print
      "\t", $revisions->[$i]->{timestamp},
      "\t", $revisions->[$i]->{user},
      "\t", $revisions->[$i]->{comment} || 'no comment',
      "\n";
  }
}

sub getPageRevisions {
  my $title = shift;
  my $mwApi = shift;
  
  my $pageStatus = getPageStatus($title, $mwApi);
  
  ## If the page has any status other than 'exists', we quit
  
  if( $pageStatus ne 'exists' ){
    warn " error : page '$title' is *$pageStatus*!\n\n";
    return [];
  }
  
  my $revisions =
    $mwApi->api({ action => 'query',
		  prop => 'revisions',
		  titles  => $title,
		  rvlimit => 'max',
		});
  
  ## Debugging
  #print Dumper $revisions, "\n";
  
  ## We 'parse' the returned data structure using some Perl-ology
  $revisions =
      (values %{$revisions->{query}->{pages}})[0]->{revisions};
  
  return $revisions;
}



 

## Sets to contents of the given page to the given text.

sub updatePage {
  my $title = shift;
  my $mwApi = shift;
  my $text  = shift;
  my $summary = shift;
  
  warn "updating '$title' with new text\n";
  
  my $page = $mwApi->get_page( { title => $title } );
  
  # to avoid edit conflicts
  my $timestamp = $page->{timestamp};
  
  $mwApi->edit({ action => 'edit',
		 title  => $title,
		 basetimestamp => $timestamp,
		 text => $text,
		 bot => 'true',
		 summary => $summary || 'Set "summary"'
	       });
}

sub movePage {
  my $mw = shift;
  my $title = shift;
  my $newTitle = shift;
  my $force = shift || 0;
  my $summary = shift;
  
  my $titleStatus = getPageStatus($title, $mw);
  my $newTitleStatus = getPageStatus($newTitle, $mw);
  
  if ($titleStatus ne 'exists'){
    warn "$title does not exist\n";
    return 0;
  }
  if ($newTitleStatus ne 'missing'){
    warn "$newTitle $newTitleStatus\n";
    return 0
      unless $force;
  }
  
  # move a page
  $mw->edit( {
	      action => 'move',
	      from => $title,
	      to => $newTitle,
	      bot => 'true',
	      reason => $summary || 'Set "summary"'
	     } );
  
  return 1;
}

sub createRedirect {
  my $mwApi = shift;
  my $fromTitle = shift;
  my $toTitle = shift;
  my $force = shift || 0;
  my $summary = shift;
  
  my $page =
    $mwApi->get_page( { title => $fromTitle } );
  
  # to avoid edit conflicts
  my $timestamp = $page->{timestamp};
  
  $mwApi->edit({ action => 'edit',
		 title  => $fromTitle,
		 basetimestamp => $timestamp,
		 text => "#REDIRECT [[$toTitle]]",
		 bot => 'true',
		 summary => $summary || 'Set "summary"'
	       });
  
  return 1;
}




# Using the data produced by "parseNarDatabaseHtml", we format the
# text for the 'NAR Database' component of the wiki. The function
# expects the output of "parseNarDatabaseHtml" and returns a string.

sub makeTheFucker {
  my $data = shift;
  my $text;
  
  ## Unwrap the data
  
  my ($title,		# The database title.
      $titleCode,	# The database title code (if any).
      $accn_no,		# The database accession No.
      $url,		# The database URL(s).
      $author,		# The database author(s) (one line).
      $authorAdr,	# The author address(es) (one line).
      $contact,		# The database contact email(s).
      $H3,		# The H3 data.
      #
      $cat,		# The database category data.
      $subCat,		# The database sub-category data.
      #
      $abstract,	# Abstract URL.
      $abstractYear	# Abstract year
      ) = @$data;
  
  ## Start building the template
  $text = "{{Database entry\n";
  $text .= "|name=$title\n";
  $text .= "|code=". ($titleCode || ''). "\n";
  $text .= "|nar id=$accn_no\n";
  
  
  
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
    
    my $paramName = substr($sections{$section}, 3);
    $text .= "|$paramName=";
    
    if (defined($H3->{$section})){
      
      my $t  = $wc->html2wiki( $H3->{$section} );
      
      ## Sad but true...
      $t = tidyHtmlForMediaWiki( $t );
      
      $text .= "$t"
    }
    $text .= "\n";
  }
  
  $text .= "|nar authors=". ($author || ''). "\n";
  $text .= "|nar author addresses=". ($authorAdr || ''). "\n";
  
  $text .= "|homepage urls=". join(", ", @$url). "\n";

  $text .= "|nar abstract urls=". ($abstract || ''). "\n";
  $text .= "|nar abstract years=". ($abstractYear || ''). "\n";

  $text .= "|contact emails=". join(", ", @$contact). "\n";
  
  $text .= "|nar categories=".
    join(", ", values(%$cat),
	 (map {values(%$_)}  values(%$subCat))
	). "\n";
  
  $text .= "|metabase version=2.1.1\n";
  
  $text .= "}}\n";

$text .= <<EO;
<!-- Add your text below -->




<!-- Add your text above -->

{{Page links}}
EO


    }

1;
