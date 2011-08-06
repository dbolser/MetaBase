  ## However, the presence of the {{System:force update}} template
  ## causes all these checks to be skipped, potentially leading to the
  ## loss of user contributed data!
  
  warn "querying for system templates in '$title'\n";
  
  my $templates =
      $mwApi->api({ action => 'query',
		    prop   => 'templates',
		    titles  => $title,
		  });
  
  ## We 'parse' the returned data structure;
  $templates =
      $templates->{'query'}{'pages'}{ $pageId }{'templates'};
  
  #print Dumper($templates), "\n\n"; exit;
  
  ## Check for the "Template:System:force update" template
  for(my $i=0; $i<@$templates; $i++){
    #warn $templates->[$i]->{'title'}, "\n";
    if($templates->[$i]->{'title'} eq
       "Template:System:force update"){
      warn "forcing update of this page\n";
      return(1);
    }
  }
  
  
  
  ## Santiy check continues...
  