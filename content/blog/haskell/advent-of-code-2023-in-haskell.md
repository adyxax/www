---
title: Advent of code 2023 in haskell
description: I improved in haskell this year and still love parsing
date: 2024-11-22
tags:
- haskell
---

## Introduction

I did the [advent of code 2023](https://adventofcode.com/2023) in haskell, it was a fun experience as always! Why writing about this now? Because I just finished the last puzzle as a warm up for the upcoming year's puzzles!

I did the first 11 puzzles on time last December but the "one puzzle a day" schedule is a bit much when life happens around you. I therefore took a break and did a few more puzzles in mid January. Upon reaching [the 17th puzzle](https://adventofcode.com/2023/day/17) (the shortest paths with weird constraints puzzle) I took another break until June were I pushed through until [Day 24th](https://adventofcode.com/2023/day/24) (the hailstorm that forces you to do math). I took another break only to pick it up this week. I just finished days 24 and 25, completing the set!

This article explains some patterns I used for solving the puzzles. I always use megaparsec to parse the input, even when it is overkill... just because I find it so fun to work with.

## Haskell for puzzles

### Parsing permutations

Relying on megaparsec payed off from day 2 where you need to parse this beauty:

```
Game 1: 3 blue, 4 red; 1 red, 2 green, 6 blue; 2 green
Game 2: 1 blue, 2 green; 3 green, 4 blue, 1 red; 1 green, 1 blue
Game 3: 8 green, 6 blue, 20 red; 5 blue, 4 red, 13 green; 5 green, 1 red
Game 4: 1 green, 3 red, 6 blue; 3 green, 6 red; 3 green, 15 blue, 14 red
Game 5: 6 red, 1 blue, 3 green; 2 blue, 1 red, 2 green
```

You got an ID, then some draws separated by `;`. A draw is a set of colors given out of order, which I see as a clear cut case of running permutations:

```haskell
data Draw = Draw Int Int Int deriving (Eq, Show)
data Game = Game Int [Draw] deriving Show
type Input = [Game]

type Parser = Parsec Void String

parseColor :: String -> Parser Int
parseColor color = read <$> try (some digitChar <* hspace <* string color <* optional (string ", "))

parseDraw :: Parser Draw
parseDraw = do
  (blue, green, red) <- runPermutation $
    (,,) <$> toPermutationWithDefault 0 (parseColor "blue")
         <*> toPermutationWithDefault 0 (parseColor "green")
         <*> toPermutationWithDefault 0 (parseColor "red")
  void . optional $ string "; "
  return $ Draw blue green red

parseGame :: Parser Game
parseGame = do
  id <- read <$> (string "Game " *> some digitChar <* optional (string ": "))
  Game id <$> someTill parseDraw eol

parseInput' :: Parser Input
parseInput' = some parseGame <* eof
```

### Functors and applicatives

I also got better at understanding functors and applicatives, using them to simplify mapping things to types. For example on day 12 you got a map that looks like:

```
???.### 1,1,3
.??..??...?##. 1,1,3
?#?#?#?#?#?#?#? 1,3,1,6
????.#...#... 4,1,1
????.######..#####. 1,6,5
?###???????? 3,2,1
```

Here is how I parsed it:

```haskell
data Tile = Broken | Operational | Unknown deriving Eq
instance Show Tile where
  show Broken = "#"
  show Operational = "."
  show Unknown = "?"
data Row = Row [Tile] [Int] deriving Show
type Input = [Row]

type Parser = Parsec Void String

parseNumber :: Parser Int
parseNumber = read <$> some digitChar <* optional (char ',')

parseTile :: Parser Tile
parseTile = char '#' $> Broken
        <|> char '.' $> Operational
        <|> char '?' $> Unknown

parseRow :: Parser Row
parseRow = Row <$> some parseTile <* space
               <*> some parseNumber <* eol

parseInput' :: Parser Input
parseInput' = some parseRow <* eof
```

The functor usage is very useful for parts where you want to parse one thing but return another thing like:

```haskell
char '#' $> Broken
```

I also used it to parse the integers from the digit characters without any intermediate step, which I find really clean and powerful:

```haskell
parseNumber = read <$> some digitChar <* optional (char ',')
```

The applicative (which is an extension of functors but for types instead of functions) allows this clever structure:

```haskell
parseRow :: Parser Row
parseRow = Row <$> some parseTile <* space
               <*> some parseNumber <* eol
```

### Playing poker

Parsing also did all the heavy lifting on day 7 where you need to rank poker like hands. Your input is a list of hands of five cards and a bid:

```
32T3K 765
T55J5 684
KK677 28
KTJJT 220
QQQJA 483
```

Here is the data structure I settled on:
```haskell
data Card = Two | Three | Four | Five | Six | Seven | Eight | Nine | T | J | Q | K | A deriving (Eq, Ord)

data Rank = HighCard
          | Pair
          | Pairs
          | Brelan
          | FullHouse
          | Quartet
          | Quintet
          deriving (Eq, Ord, Show)

data Hand = Hand Rank [Card] Int deriving (Eq, Show)
compareCards :: [Card] -> [Card] -> Ordering
compareCards (x:xs) (y:ys) | x == y = compareCards xs ys
                           | otherwise = x `compare` y
instance Ord Hand where
  (Hand a x _) `compare` (Hand b y _) | a == b = compareCards x y
                                      | otherwise = a `compare` b

type Input = [Hand]
```

The hard part of the puzzle is to rank hands, which I decided to compute while parsing because why not!
```haskell
parseCard :: Parser Card
parseCard = char '2' $> Two
        <|> char '3' $> Three
        <|> char '4' $> Four
        <|> char '5' $> Five
        <|> char '6' $> Six
        <|> char '7' $> Seven
        <|> char '8' $> Eight
        <|> char '9' $> Nine
        <|> char 'T' $> T
        <|> char 'J' $> J
        <|> char 'Q' $> Q
        <|> char 'K' $> K
        <|> char 'A' $> A

evalRank :: [Card] -> Rank
evalRank n@(a:b:c:d:e:_) | not (a<=b && b<=c && c<=d && d<=e) = evalRank $ L.sort n
                         | a==b && b==c && c==d && d==e = Quintet
                         | (a==b && b==c && c==d) || (b==c && c==d && d==e) = Quartet
                         | a==b && (b==c || c==d) && d==e = FullHouse
                         | (a==b && b==c) || (b==c && c==d) || (c==d && d==e) = Brelan
                         | (a==b && (c==d || d==e)) || (b==c && d==e) = Pairs
                         | a==b || b==c || c==d || d==e = Pair
                         | otherwise = HighCard

parseHand :: Parser Hand
parseHand = do
  cards <- some parseCard <* char ' '
  bid <- read <$> (some digitChar <* eol)
  return $ Hand (evalRank cards) cards bid

parseInput' :: Parser Input
parseInput' = some parseHand <* eof
```

With all the heavy lifting already done, computing the solution for part1 of the puzzle is simply:
```haskell
compute :: Input -> Int
compute = sum . zipWith (*) [1..] . map (\(Hand _ _ bid) -> bid) . L.sort
```

This was particularly interesting for part 2 where there is a twist: `J` cards are now jokers, so you need to handle this as a wildcard when ranking hands! After raking my brain for a while, I decided to make the type system bear the complexity by adjusting the data structure to this:

```haskell
data Card = J | Two | Three | Four | Five | Six | Seven | Eight | Nine | T | Q | K | A

instance Eq Card where
  J == _ = True
  _ == J = True
  a == b = show a == show b

instance Ord Card where
  a `compare` b = show a `compare` show b
  a <= b = show a <= show b
```

With this change, I could now rank the hands with:
```haskell
evalRank :: [Card] -> Rank
evalRank [J, J, J, J, _] = Quintet
evalRank [J, J, J, d, e] | d==e = Quintet
                         | otherwise = Quartet
evalRank [J, J, c, d, e] | c==d && d==e = Quintet
                         | c==d || d==e = Quartet
                         | otherwise = Brelan
evalRank [J, b, c, d, e] | b==c && c==d && d==e = Quintet
                         | (b==c || d==e) && c==d = Quartet
                         | b==c && d==e = FullHouse
                         | b==c || c==d || d==e = Brelan
                         | otherwise = Pair
evalRank [a, b, c, d, e] | a==b && a==c && a==d && a==e = Quintet
                         | (a==b && a==c && a==d) || (b==c && b==d && b==e) = Quartet
                         | a==b && (b==c || c==d) && d==e = FullHouse
                         | (a==b && b==c) || (b==c && c==d) || (c==d && d==e) = Brelan
                         | (a==b && (c==d || d==e)) || (b==c && d==e) = Pairs
                         | a==b || b==c || c==d || d==e = Pair
                         | otherwise = HighCard
```

## Conclusion

I love haskell, I wish I could use it daily and not just for seasonal puzzles.
