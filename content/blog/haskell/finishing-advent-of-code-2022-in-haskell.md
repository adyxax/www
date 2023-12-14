---
title: Finishing advent of code 2022 in Haskell
description: Last year I stopped on day 22, I finally took it up again
date: 2023-12-05
tags:
- haskell
---

## Introduction

I wrote about doing the [advent of code 2022 in zig]({{< ref "advent-of-code-2022-in-zig.md" >}}), but I did not complete the year. I stopped on using zig on day 15 when I hit a bug when using hashmaps that I could not solve in time and continued in JavaScript until [day 22](https://adventofcode.com/2022/day/22). On day 22 part 2, you need to fold a cube and move on it keeping track of your orientation... It was hard!

Last week I wanted to warm up for the current advent of code and therefore took it up again... it was (almost) easy with Haskell!

## Day 22 - Monkey Map

You get an input that looks like this:
```
        ...#
        .#..
        #...
        ....
...#.......#
........#...
..#....#....
..........#.
        ...#....
        .....#..
        .#......
        ......#.

10R5L5R10L4R5L5
```

The `.` are floor tiles, the `#` are impassable walls. You have a cursor starting on the leftmost tile on the first line. The cursor moves  and the empty spaces do not exist: if you step out you wrap around: easy enough... until part 2!

Here is how I parse the input:
```haskell
type Line = V.Vector Char
type Map = V.Vector Line
data Instruction = Move Int | L | R deriving Show
data Input = Input Map [Instruction] deriving Show
type Parser = Parsec Void String

parseMapLine :: Parser Line
parseMapLine = do
  line <- some (char '.' <|> char ' ' <|> char '#') <* eol
  return $ V.generate (length line) (line !!)

parseMap :: Parser Map
parseMap = do
  lines <- some parseMapLine <* eol
  return $ V.generate (length lines) (lines !!)

parseInstruction :: Parser Instruction
parseInstruction = (Move . read <$> some digitChar)
               <|> (char 'L' $> L)
               <|> (char 'R' $> R)

parseInput' :: Parser Input
parseInput' = Input <$> parseMap
                    <*> some parseInstruction <* eol <* eof
```

In part 2 you learn that your input pattern is in fact 6 squares that can be folded to form a cube. Now instead of simply wrapping the empty spaces, when stepping out you need to find out were you end up on the cube and with which orientation.

Here is a visualization I made in excalidraw to understand how folding the cube based on my input would work (this does not match the example above but matched the players' input):

![excalidraw cube folding](https://files.adyxax.org/www/aoc-2022-22-folding.excalidraw.svg)

The whole code is available [on my git server](https://git.adyxax.org/adyxax/advent-of-code/tree/2022/22-Monkey-Map/second.hs) but here is the core of my solver for this puzzle:
```haskell
stepOutside :: Map -> Int -> Int -> Int -> Heading -> Int -> Cursor
stepOutside m s x y h i | (t, h) == (a, N) = proceed fw (fn + rx) E
                        | (t, h) == (a, W) = proceed dw (ds - ry) E
                        | (t, h) == (b, N) = proceed (fw + rx) fs N
                        | (t, h) == (b, E) = proceed ee (es - ry) W
                        | (t, h) == (b, S) = proceed ce (cn + rx) W
                        | (t, h) == (c, W) = proceed (dw + ry) dn S
                        | (t, h) == (c, E) = proceed (bw + ry) bs N
                        | (t, h) == (d, N) = proceed cw (cn + rx) E
                        | (t, h) == (d, W) = proceed aw (as - ry) E
                        | (t, h) == (e, E) = proceed be (bs - ry) W
                        | (t, h) == (e, S) = proceed fe (fn + rx) W
                        | (t, h) == (f, W) = proceed (aw + ry) an S
                        | (t, h) == (f, S) = proceed (bw + rx) bn S
                        | (t, h) == (f, E) = proceed (ew + ry) es N
  where
    (tx, rx) = x `divMod` s
    (ty, ry) = y `divMod` s
    t = (tx, ty)
    proceed :: Int -> Int -> Heading -> Cursor
    proceed x' y' h' = case m V.! y' V.! x' of
      '.' -> step m s (Cursor x' y' h') (Move $ i - 1)
      '#' -> Cursor x y h
    (ax, ay) = (1, 0)
    (bx, by) = (2, 0)
    (cx, cy) = (1, 1)
    (dx, dy) = (0, 2)
    (ex, ey) = (1, 2)
    (fx, fy) = (0, 3)
    a = (ax, ay)
    b = (bx, by)
    c = (cx, cy)
    d = (dx, dy)
    e = (ex, ey)
    f = (fx, fy)
    (an, as, aw, ae) = (ay * s, (ay+1)*s-1, ax *s, (ax+1)*s-1)
    (bn, bs, bw, be) = (by * s, (by+1)*s-1, bx *s, (bx+1)*s-1)
    (cn, cs, cw, ce) = (cy * s, (cy+1)*s-1, cx *s, (cx+1)*s-1)
    (dn, ds, dw, de) = (dy * s, (dy+1)*s-1, dx *s, (dx+1)*s-1)
    (en, es, ew, ee) = (ey * s, (ey+1)*s-1, ex *s, (ex+1)*s-1)
    (fn, fs, fw, fe) = (fy * s, (fy+1)*s-1, fx *s, (fx+1)*s-1)
```

This `stepOutside` function takes in argument the map, its size, the cursor's `(x, y)` position and heading `h`, while i is the number of steps to perform. I first compute on which face the cursor is, and based on its heading where it should end up. I then use the faces coordinates to compute the final position, being careful to follow on the schematic how the transition is performed.

## Conclusion

The next days where quite a lot easier than this one. Haskell is really a great language for puzzle solving thanks to its excellent parsing capabilities and its incredible type system.

A great thing that should speak of Haskell's qualities is that it is the second year of advent of code that I completed all 25 days: both times it was thanks to Haskell! I think I should revisit the years 2021 that I did with Go next: I stopped on day 19 because it involved a three dimensional puzzle that was quite difficult.
