---
title: Advent of code 2020 in haskell
description: My patterns for solving advent of code puzzles
date: 2023-06-22
tags:
- haskell
---

## Introduction

I did the [advent of code 2020](https://adventofcode.com/2020/) in haskell, I had a great time! I did it following [advent of code 2022 in zig]({{< ref "advent-of-code-2022-in-zig.md" >}}), while reading [Haskell Programming From First Principles]({{< ref "haskell-programming-from-first-principles.md" >}}) a few months ago.

## Haskell for puzzles

### Parsing

I used megaparsec extensively, it felt like a cheat code to be able to process the input so easily! This holds especially true for day 4 where you need to parse something like:
```
ecl:gry pid:860033327 eyr:2020 hcl:#fffffd
byr:1937 iyr:2017 cid:147 hgt:183cm

iyr:2013 ecl:amb cid:350 eyr:2023 pid:028048884
hcl:#cfa07d byr:1929

hcl:#ae17e1 iyr:2013
eyr:2024
ecl:brn pid:760753108 byr:1931
hgt:179cm

hcl:#cfa07d eyr:2025 pid:166559648
iyr:2011 ecl:brn hgt:59in
```

The keys can be in any order so you need to account for permutations. Furthermore, entries each have their own set of rules in order to be valid. For example a height needs to have a unit in cm on inches and be in a certain range, while colors need to start with a hash sign and be composed of 6 hexadecimal digits.

All this could be done at parsing time, haskell made this almost easy: I kid you not!

### The type system

I used and abused the type system in order to have straightforward algorithms where if it compile then it works. A very notable example comes from day 25 where I used the `Data.Mod` library to have modulus integers enforced by the type system. That's right, in haskell that is possible!

### Performance

Only one puzzle had me reach for optimizations in order to run in less than a second. All the others ran successfully with a simple `runghc <solution>.hs`! For this slow one, I sped it up by reaching for:
```sh
ghc --make -O3 first.hs && time ./first
```

### Memory

I had no memory problems and laziness was not an issue either. Haskell really is a fantastic language.

## Solution Templates

### Simple parsing

Not all days called for advanced parsing. Some just made me look for a concise way of doing things. Here is (spoiler alert) my solution for the first part of day 6 as an example:
```haskell
-- requires cabal install --lib split Unique
module Main (main) where
import Control.Monad (void, when)
import Data.List.Split (splitOn)
import Data.List.Unique (sortUniq)
import Data.Monoid (mconcat)
import System.Exit (die)

exampleExpectedOutput = 11

parseInput :: String -> IO [String]
parseInput filename = do
  input <- readFile filename
  return $ map (sortUniq . mconcat . lines) $ splitOn "\n\n" input

compute :: [String] -> Int
compute = sum . map length

main :: IO ()
main = do
  example <- parseInput "example"
  let exampleOutput = compute example
  when  (exampleOutput /= exampleExpectedOutput)  (die $ "example failed: got " ++ show exampleOutput ++ " instead of " ++ show exampleExpectedOutput)
  input <- parseInput "input"
  print $ compute input
```

### Advanced parsing

Here is (spoiler alert) my solution for the first part of day 24 as an example:
```haskell
-- requires cabal install --lib megaparsec parser-combinators
module Main (main) where
import Control.Monad (void, when)
import Data.List qualified as L
import Data.Map qualified as M
import Data.Maybe (fromJust)
import Data.Set qualified as S
import Data.Void (Void)
import Text.Megaparsec
import Text.Megaparsec.Char
import System.Exit (die)

exampleExpectedOutput = 10

data Direction = E | W | NE | NW | SE | SW
type Directions = [Direction]
type Coordinates = (Int, Int, Int)
type Floor = M.Map Coordinates Bool
type Input = [Directions]
type Parser = Parsec Void String

parseDirection :: Parser Direction
parseDirection = (string "se" *> return SE)
  <|> (string "sw" *> return SW)
  <|> (string "ne" *> return NE)
  <|> (string "nw" *> return NW)
  <|> (char 'e' *> return E)
  <|> (char 'w' *> return W)

parseInput' :: Parser Input
parseInput' = some (some parseDirection <* optional (char '\n')) <* eof

parseInput :: String -> IO Input
parseInput filename = do
  input <- readFile filename
  case runParser parseInput' filename input of
    Left bundle -> die $ errorBundlePretty bundle
    Right input' -> return input'

compute :: Input -> Int
compute input = M.size . M.filter id $ L.foldl' compute' M.empty input
  where
    compute' :: Floor -> Directions -> Floor
    compute' floor directions = case M.lookup destination floor of
      Just f -> M.insert destination (not f) floor
      Nothing -> M.insert destination True floor
      where
        destination :: Coordinates
        destination = L.foldl' run (0, 0, 0) directions
    run :: Coordinates -> Direction -> Coordinates
    run (x, y, z) E = (x+1,y-1,z)
    run (x, y, z) W = (x-1,y+1,z)
    run (x, y, z) NE = (x+1,y,z-1)
    run (x, y, z) SW = (x-1,y,z+1)
    run (x, y, z) NW = (x,y+1,z-1)
    run (x, y, z) SE = (x,y-1,z+1)

main :: IO ()
main = do
  example <- parseInput "example"
  let exampleOutput = compute example
  when  (exampleOutput /= exampleExpectedOutput)  (die $ "example failed: got " ++ show exampleOutput ++ " instead of " ++ show exampleExpectedOutput)
  input <- parseInput "input"
  print $ compute input
```

## Conclusion

Learning haskell is worthwhile, it is really a great language with so many qualities. Puzzle solving is a use case where it shines so bright, thanks to its excellent parsing capabilities and its incredible type system.

A great thing that should speak of haskell's qualities is that it is the first year of advent of code that I completed all 25 days. I should revisit the years 2021 and 2022 that I did with golang and zig respectively and maybe finish those!
