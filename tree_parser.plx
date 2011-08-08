#!/usr/bin/perl -w

use strict;

use HTML::TreeBuilder;

die "pass an HTML file\n"
  unless @ARGV && -s $ARGV[0];

my $html_file = $ARGV[0];



my $tree = HTML::TreeBuilder->new();

## syntax errors during parsing should generate warnings
$tree->warn(1);

$tree->parse_file($html_file);

## Jump to the relevant section of the HTML content
my @paper_details =
  $tree->address('0.1.0.5.1.0')->content_list;



## Parse the paper details

## This is a horrible mix of 'state' (position in the document) and
## logic (structure of the current position).

my %data;



## Initially, the document is well structured

$data{name} = get_name($paper_details[2]);
$data{accn} = get_accn($paper_details[4]);



## Now things become optional (but ordered)

for( my $i = 5; $i < @paper_details -2; $i++ ){
  my $node = $paper_details[$i];
  
  ## Ignore the random empty <BR />s
  if (!$node->content_list){
    #$node->dump;
    next;
  }
  
  if(!exists($data{url})){
    #$node->dump;
    $data{url} = get_url($node);
    next if @{$data{url}};
  }
  
  if(!exists($data{author})){
    #$node->dump;
    $data{author} = get_author($node);
    next if $data{author} ne 'missing';
  }
  
  if(!exists($data{address})){
    #$node->dump;
    $data{address} = get_address($node);
    next if $data{address} ne 'missing';
  }
  
  if(!exists($data{contact})){
    #$node->dump;
    $data{contact} = get_contact($node);
    next if @{$data{contact}};
  }
  
  
  
  ## More stable content from here!
  
  if ($node->find('h3')){
    #$node->dump;
    $data{h3}{$node->as_text} = $node->right->as_text;
    $i++; # SKIP RIGHT NODE NEXT TIME ROUND!
    next;
  }
  
  
  if ($node->look_down('class', qr/(sub)?category/)){
    #$node->dump;
    my ($key, $val) = get_category($node);
    $data{category}{$key} = $val;
    next;
  }
  
  
  if ($node->find('a')){
    #$node->dump;
    my ($key, $val) = get_abstract($node);
    $data{abstract}{$key} = $val;
    next;
  }
  
  
  warn $node->dump;
}

warn "OK\n\n";





print
  join("\n",
       "Name:   \t". $data{name},
       "Accn    \t". $data{accn},
       
       "URL     \t". join(', ', @{$data{url}}),
       
       "Author  \t". ($data{author} eq 'missing' ? 'missing' :
		      length($data{author}->as_text)),
       "Address \t". ($data{address} eq 'missing' ? 'missing' :
		      length($data{address}->as_text)),
       
       "Contact \t". join(', ', @{$data{contact}} || 'missing'),
       
       "H3      \t". scalar keys %{$data{H3}},
       "Category\t". scalar keys %{$data{category}},
       "Abstract\t". join(', ', keys %{$data{abstract}} || 'missing'),
      ), "\n";

#print "\t$_\t". length($data{h3}{$_}). "\n"
#  for keys %{$data{h3}};

warn "OK\n\n";



## Try the author mungie

#$data{author}->dump;
#$data{address}->dump;
#print $data{author}->as_HTML, "\n";

my %authors;
my @authors = $data{author}->content_list;

for(my $i=0; $i<@authors; $i+=2){
  
  
  $authors{} = 
  print $authors[$i+0], "\n";
  print $authors[$i+1]->as_text, "\n";
}




#print scalar @authors, "\n";

#print join("\n", @authors), "\n";
















$tree->delete;



## Parser helpers

sub get_name{
  my $node = shift;
  return $node->as_text;
}


sub get_accn{
  my $node = shift;
  
  ## Parse out the accn
  die $node->as_text, "\n"
    unless $node->as_text =~ /entry number (\d+) $/;
  return $1;
}


sub get_url{
  my $node = shift;
  
  ## Check for a 'contact'
  if($node->find('span')){
    return [];
  }
  return
    [map $_->as_text, $node->find('a')];
}


sub get_author{
  my $node = shift;
  
  my @author = $node->find('strong');
  die if @author > 1; # Sanity test
  
  return $author[0] || 'missing';
}


sub get_address{
  my $node = shift;
  
  ## Check for a 'contact'
  if($node->find('span')){
    return 'missing';
  }
  ## Check for an 'h3'
  if($node->find('h3')){
    return 'missing';
  }
  
  my @address = $node->look_down('class', 'bodytext');
  die if @address > 1; # Sanity test
  
  return $address[0] || 'missing';
}


sub get_contact{
  my $node = shift;
  
  ## Check for an 'h3'
  if($node->find('h3')){
    return [];
  }
  return
    [map $_->as_text, $node->find('a')];
}


sub get_category{
  my $node = shift;
  
  die unless # Sanity test
    my $a = $node->find('a');
  return
    $a->attr('href'), $a->as_text;
}


sub get_abstract{
  my $node = shift;
  
  if(    $node->as_text =~ /in the NAR (\d+) Database Issue/){
    return $1, $node->find('a')->attr('href');
  }
  elsif( $node->as_text =~ /DOI:/){
    return 'DOI', $node->find('a')->attr('href');
  }
  else{
    return 'missing', '', "\n";
  }
}
