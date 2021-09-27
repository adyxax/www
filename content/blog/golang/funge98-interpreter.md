---
title: Writing a Funge-98 interpreter in golang
description: A useless but non trivial exercise to sharpen my skills in go
date: 2021-09-27
---

## Introduction

[Funge-98](https://github.com/catseye/Funge-98/blob/master/doc/funge98.markdown) is an esoteric programming language that like most [esolangs](https://esolangs.org/) is designed to be fun, without any particular use, and in particular impossible to compile. I like Funge-98 for its indecipherable two-dimensional grid of instructions and data mixed together, where execution can proceed in any direction of that grid and wrap around if is would leave the grid.

I began implementing this interpreter about two weeks ago when trying to resurrect [my Funge-98 IRC bot](https://git.adyxax.org/adyxax/b98/src/branch/master/bot.b98). I had trouble compiling [Fungi](https://github.com/thomaseding/fungi) the haskell Funge-98 interpreter that I used at that time and while I managed to use [Cfunge](https://github.com/VorpalBlade/cfunge) to replace it that was too late : I was already tempted by the idea to write my own interpreter and could not resist.

## Some interesting challenges

The [spec](https://github.com/catseye/Funge-98/blob/master/doc/funge98.markdown) is well written but leaves some undefined behaviours. There also are some things that I did not understand before reading the code of other interpreters, especially that when using the meta programming p command to modify the funge space (aka the program itself), if you put a space character you might have to resize the funge space.

The space character is special in the sense that the funge space is supposed infinite and any "empty" cell contains a space. But while infinite the funge space as upper and lower boundaries that encompass all the non empty cells which contain instructions or data. Writing something other than a space character outside the funge space will make it grow, but writing a space character might make it shrink.

Resizing the funge space means reallocating things in order to properly handle the wrapping of the instruction pointer, which is one a the most fun things in Funge-98! This instruction pointer that can travel in any direction on the grid space? It can really travel in any directions, left right up down but also diagonals or any vector really. And if the instruction pointer would leave the grid because of its travel it wraps around. Wrapping aound is intuitive when talking about cardinal directions, but not so much for an arbitrary vector.

I was also trapped by the line feed character handling, which is only used in Trifunge to process the z coordinate. The spec was not clear but in order to pass the mycology test suite you need to ignore this character if found in the input file, much like you would handle a carriage return in Onefunge.

## Conclusion

It was refreshing to write some non trivial algorithms and constructs in order to achieve this feast and I am quite proud of my little interpreter. I guess the next step would be to write some fingerprints (official libraries from frunge programs to use) or a funge-98 debugger... I prepared the necessary hooks for it in the code, but no promises. It was a fun undertaking and I might just leave it at that ;-)
