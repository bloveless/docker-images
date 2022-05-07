#!/usr/bin/perl
use warnings;
use strict;

my @nameservers = ();

while(<>){
  my @tokens = split /[ ,]/, $_;

  # If we found the DNS key
  if ($tokens[0] eq 'DNS') {
    # Take each of the tokens and split the first two "DNS" and "="
    # the rest of the tokens are the nameservers
    foreach my $i (0 .. $#tokens) {
      if ($i gt 1 && $tokens[$i] ne '') {
        push(@nameservers, $tokens[$i]);
      }
    }

    last;
  }
}

print join ' ', @nameservers
