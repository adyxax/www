---
title: Advent of code 2024 in Haskell
description: I sharpened my Haskell skills again this year
date: 2025-07-24
tags:
- Haskell
---

## Introduction

I participated in [advent of code 2024](https://adventofcode.com/2024) in
Haskell: it was a fun experience as always! Why writing about this now? Because
I just finished the last puzzle!

I did the first 12 puzzles each day last December but then life happened and I
could no longer complete one puzzle per day. I only finished the first 19
puzzles by Christmas then took the usual long break. I picked up this challenge
again about a month ago while waiting at the airport and have now completed the
last one.

## Haskell for puzzles

Usually this kind of article is an opportunity to explain some of the patterns I
used and things I learned. Solving these puzzles was a lot of fun as always.

The puzzles were interesting, my favorite one being day 24 in which you need to
debug a binary adder. It is made of logic gates with a few wires that have been
inverted and need to be fixed. It was the hardest challenge for me by far and I
only solved it when I realized that instead of needing to simulate wire
permutations I could try to build the adder from the pool of logic gates that
were available. When I could not find a gate I needed, it meant I had to look
for a wire to swap.

I also thoroughly enjoyed day 21 where you need to input codes via proxy robots
and need to compute a very convoluted shortest path algorithm where the key was
careful usage of memoization.

I will also make a special mention for day 13 where the problem can be reduced
to a system of linear equations. I love an excuse to whip out a matrix
triangularization to achieve this, but I doubly loved that I could use the
Rational type to deal with exact ratio numbers computations. Haskell really
shines in these situations!

## Conclusion

I recommend tackling this kind of challenge, it is good to maintain or develop
proficiency in a programming language. I love Haskell, I wish I could use it
daily and not just for seasonal puzzles.
