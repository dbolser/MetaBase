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

my @paper_details =
  $tree->address('0.1.0.5.1.0')->content_list;





## Parse the paper details

my %data;

## This is a horrible mix of 'state' (position in the document) and
## logic (structure of the current position).

## Initially, the document is well structured

$data{name} = get_name($paper_details[2]);
$data{accn} = get_accn($paper_details[4]);



## Now things become optional (but ordered)

for( my $i = 5; $i < @paper_details -2; $i++ ){
  
  my $node = $paper_details[$i];
  
  #$node->dump;
  
  
  
  ## Ignore the random empty <BR />s
  if (!$node->content_list){
    #$node->dump;
    next;
  }
  
  if(!exists($data{url})){
    #$node->dump;
    $data{url} = get_url($node);
    next if $data{url} ne 'missing';
  }
  
  if(!exists($data{author})){
    $data{author} = get_author($node);
    next if $data{author} ne 'missing';
  }
  
  if(!exists($data{address})){
    $data{address} = get_address($node);
    next if $data{address} ne 'missing';
  }
  
  if(!exists($data{contact})){
    $data{contact} = get_contact($node);
    next if $data{contact} ne 'missing';
  }
  
  
  
  ## More stable content from here!
  
  if ($node->find('h3')){
    $data{h3}{$node->as_text} =
      $node->right->as_text;
    $i++;
    next;
  }
  
  
  if ($node->look_down('class', 'category')){
    my $subcat = $node->right;
    
    if ($subcat->look_down('class', 'subcategory')){
      $i++;
    }
    next;
  }
  
  
  if ($node->find('input')){
    die "wibble\n";
    next;
  }
  
  
  if ($node->find('a')){
    $data{abstract} = get_abstract($node);
    next;
  }
  
  $node->dump;
}

warn "OK\n\n";



print
  join("\n",
       $data{name},
       $data{accn},
       $data{url},
       $data{author},
       $data{address},
       $data{contact},
       $data{h3},
      ), "\n";

print "$_\n" for keys %{$data{h3}};

$tree->delete;





## Parser helpers

sub get_name{
  my $node = shift;
  return $node->as_text;
}

sub get_accn{
  my $node = shift;
  return $node->as_text;
}

sub get_url{
  my $node = shift;
  return
    [map $_->as_text, $node->find('a')]
      or 'missing';
}

sub get_author{
  my $node = shift;
  
  my @author = $node->find('strong');
  
  ## Sanity test
  die if @author > 1;
  
  if(@author == 1){
    return $author[0];
  }
  return 'missing';
}

sub get_address{
  my $node = shift;
  
  if($node->find('span')){
    ## We found a contact!
    return 'missing';
  }
  
  if($node->find('h3')){
    ## We found an h3!
    return 'missing';
  }
  
  my @address = $node->look_down('class', 'bodytext');
  
  ## Sanity test
  die if @address > 1;
  
  if(@address == 1){
    return $address[0];
  }
  return 'missing';
}

sub get_contact{
  my $node = shift;
  
  if($node->find('h3')){
    ## We found an h3!
    return 'missing';
  }
  
  return
    [map $_->as_text, $node->find('a')]
      or 'missing';
}

sub get_category{
  my $node = shift;
}

sub get_abstract{
  my $node = shift;
}
