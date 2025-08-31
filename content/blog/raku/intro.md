---
title: "The Raku programming language"
description: Try it if you want to have fun!
date: 2025-08-31
tags:
- Raku
---

## Introduction

I gave [Raku](https://raku.org/) several tries over the last 15 years. I was
initially a bit disappointed when it was first released as Perl6 as it was very
slow to start and a resource hog. I was disappointed again sometime in the late
2010s I tried the freshly renamed Raku. Still very slow to start up and
consumming too much memory for what I was attempting, but much better.

I tried again this summer and I am glad to see that Raku has become much more
usable! The language and its ecosystem have made strides of progress. Startup
time (critical for a scripting language imho) is now good. CPU and memory usage
remain on the high side, but have become more reasonable.

## The language

The language is clearly Perlish, with sigils and unusual syntax that seem alien
compared to other programming languages. Having liked Perl, I must say that I
very much like the subtle changes Raku brought to the overall syntax. One such
change is the array indexing: where you would have written `$a[0]` in Perl, you
now write `@a[0]` in Raku.

I love all the convenience features and all the syntax sugar Raku brings to the
table. For example, you can declare a list of string literals with `my @l = <one
two three>;` instead of the heavier `my @l = ("one", "two", "three");`. Note
that the parentheses are also optional here. Another related example is about
hash indexing when keys are string literals: `%h{'one'}` is equivalent to
`%h<one>`.

Raku has gradual typing, and its type system is really powerful. Two of my
favorite features are junctions and subsets. Junctions in particular are wild:

``` raku
my $j = 0|1|2|3;  # $j is a junction, a composite value
if 3 == $j + 1 {  # this matches because 2 is a possible value for $j
    say 'yes';
}
```

Note that junctions are not sets, they are only meant for boolean evaluation.
But they are very neat! Subsets are also fun, allowing you to write things like:

``` raku
subset MyBiggerInts of Int where * >= 42;
subset Three-letter of Str where .chars == 3;
subset Foo of List where (Int,Str); # Only a List where the first element is an
                            # Int and the second a Str will pass the type check.
```

Many scripts are very concise in Raku. One of the neatest things is the amount
of features, classes and functions that are built-in. This might seem trivial,
but not having 10 lines of imports at the top of every script is refreshing!
This is of course true for all the regex stuff, but also for some things like
argument parsing on the command line. Here is how you write it in Raku:

``` raku
sub MAIN(
  Str   $file where *.IO.f = 'file.dat',  #= an existing file to frobnicate
  Int  :$length = 24,                     #= length needed for frobnication
  Bool :$verbose,                         #= required verbosity
) {
    say $length if $length.defined;
    say $file   if $file.defined;
    say 'Verbosity ', ($verbose ?? 'on' !! 'off');
}
```

Calling a program with `--help` or invalid flags will produce the following for
you, free of charge:

``` shell
Usage:
  frobnicate.raku [--length=<Int>] [--verbose] [<file>]

    [<file>]          an existing file to frobnicate
    --length=<Int>    length needed for frobnication
    --verbose         required verbosity
```

With all that I did not say anything yet about the object system which is very
well thought out, the regexes and grammar which are a lot of fun, or all the
convenience added to the standard classes. For example you can open a file and
read its contents with:

``` raku
"some/file.txt".IO.lines
```

[The documentation](https://docs.raku.org/introduction) and the [language
reference](https://docs.raku.org/reference) seem complete and are full of useful
examples. Numeric maths are treated carefully: arithmetic is exact by default
(big integrers when values exceed 64 bits, and rational numbers for fractions).
How neat is that?

## Conclusion

Learning Raku has been a lot of fun and I recommend giving it a try. Installing
it is easy thanks to a tool called [rakubrew](https://rakubrew.org/). Packages
are managed with `zef` and finding libraries is easy by browsing
[raku.land](https://raku.land/).

Of course wanted to solve some puzzles in Raku, as I do when learning new
languages: https://git.adyxax.org/adyxax/advent-of-code/src/branch/master/2019
