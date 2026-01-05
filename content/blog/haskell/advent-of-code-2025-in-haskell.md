---
title: Advent of code 2025 in Haskell
description: I sharpened my Haskell skills again this year
date: 2026-01-06
tags:
- Haskell
---

## Introduction

I participated in [Advent of Code 2025](https://adventofcode.com/2025) in
Haskell. It was a fun experience as always! Why write about this now? Because I
finished the last puzzle last Saturday!

I did all the puzzles each day on time last December except for day 10: part 2
was harder than all the rest combined! Life happened around Christmas, and I
took the usual long break away from the puzzles before finishing.

## Haskell for puzzles

 The puzzles were all interesting without overstaying their welcome. Well except
for day 10 part 2, but you need one of those for things to stay interesting! In
this section I will present some of the days I enjoyed the most.

One of my favourite puzzles was day 3 where you need to find number patterns in
the input. I found [my
solution](https://git.adyxax.org/adyxax/advent-of-code/src/branch/master/2025/03-Lobby/second.hs)
elegant:

``` haskell
type Input = [String]

maxWithIndex :: String -> (Int, Char)
maxWithIndex (x:xs) = let (_, i, m) = L.foldl' step (1, 0, x) xs in (i, m)
  where
    step :: (Int, Int, Char) -> Char -> (Int, Int, Char)
    step (index, maxIndex, max) c | max < c   = (index + 1, index, c)
                                  | otherwise = (index + 1, maxIndex, max)

compute :: Input -> Int
compute = sum . map compute'
  where
    compute' :: String -> Int
    compute' n = read . fst $ L.foldl' compute'' ("", 0) $ drop (length n - 11) $ L.inits n
    compute'' :: (String, Int) -> String -> (String, Int)
    compute'' (acc, i) s = let (ai, a) = maxWithIndex (drop i s)
                           in (acc ++ [a], i + ai + 1)
```

I found [Day
5](https://git.adyxax.org/adyxax/advent-of-code/src/branch/master/2025/05-Cafeteria/second.hs)
particularly satisfying to write. The puzzle is about merging intervals:

``` haskell
type Interval = (Int, Int)
data Input = Input [Interval] [Int]

compute :: Input -> Int
compute (Input intervals _) = sum $ map ilen intervals'
  where
    ilen :: Interval -> Int
    ilen (a, b) = b - a + 1
    (i:is) = L.sortOn fst intervals
    intervals' = L.foldl' step [i] is
    step :: [Interval] -> Interval -> [Interval]
    step acc@((c, d):xs) i@(a, b) | a > d = i:acc
                                  | otherwise = (c, max b d):xs
```

[Day
6](https://git.adyxax.org/adyxax/advent-of-code/src/branch/master/2025/06-Trash_Compactor/second.hs)
was all about parsing operations with a twist (we transpose the input to parse
column wise), and I always enjoy these problems:

``` haskell
data Op = Add | Mul deriving (Eq, Show)
type Input = [Int]
type Parser = Parsec Void String

parseNumber :: Parser Int
parseNumber = read <$> (some digitChar <* optional hspace)

parseOp' :: Parser Op
parseOp' = char '+' $> Add
       <|> char '*' $> Mul

parseOp :: Parser Int
parseOp = do
  n <- optional hspace *> parseNumber
  op <- parseOp' <* eol
  ns <- some (optional hspace *> parseNumber <* eol <* optional hspace)
  pure $ case op of
    Add -> sum $ n:ns
    Mul -> product $ n:ns

parseInput' :: Parser Input
parseInput' = some (parseOp <* optional eol) <* eof

parseInput :: String -> IO Input
parseInput filename = do
  input <- lines <$> readFile filename
  let len = maximum $ map length input
      input' = map complete input
      complete s = s ++ take (len - length s) (repeat ' ')
      input'' = unlines $ L.transpose input'
  case runParser parseInput' filename input'' of
    Left bundle  -> error $ errorBundlePretty bundle
    Right input' -> return input'

compute :: Input -> Int
compute = sum
```

[Day
7](https://git.adyxax.org/adyxax/advent-of-code/src/branch/master/2025/07-Laboratories/second.hs)
was a fun set-management puzzle, at least that's how I approached it. I also had
fun using Parsec's `getSourcePos` escape hatch to get the abscissa of the
element being parsed:

``` haskell
type Input = [S.Set Int]
type Parser = Parsec Void String

parseTile :: Parser (Maybe Int)
parseTile = do
  SourcePos _ _ x <- getSourcePos
  char '.' $> Nothing <|> (char '^' <|> char 'S') $> Just (unPos x)

parseLine :: Parser (S.Set Int)
parseLine = S.fromList . catMaybes <$> some parseTile

parseInput' :: Parser Input
parseInput' = some (parseLine <* eol) <* eof

parseInput :: String -> IO Input
parseInput filename = do
  input <- readFile filename
  case runParser parseInput' filename input of
    Left bundle  -> error $ errorBundlePretty bundle
    Right input' -> return input'

compute :: Input -> Int
compute (s:ls) = total $ foldl' compute' (M.fromList $ zip (S.toList s) [1]) ls
  where
    total :: M.Map Int Int -> Int
    total = M.foldl' (+) 0
    compute' :: M.Map Int Int -> S.Set Int -> M.Map Int Int
    compute' acc splitters = let splits = S.intersection (S.fromList $ M.keys acc) splitters
                                 continuingBeams = M.difference acc $ M.fromList $ zip (S.toList splits) $ repeat 0
                             in S.foldl' (split acc) continuingBeams splits
    split :: M.Map Int Int -> M.Map Int Int -> Int -> M.Map Int Int
    split origin acc i = let v = origin M.! i
                             acc' = case M.lookup (i+1) acc of
                                      Just n -> M.insert (i+1) (n+v) acc
                                      Nothing -> M.insert (i+1) v acc
                         in case M.lookup (i-1) acc of
                              Just n -> M.insert (i-1) (n+v) acc'
                              Nothing -> M.insert (i-1) v acc'
```

I solved [day
10](https://git.adyxax.org/adyxax/advent-of-code/src/branch/master/2025/10-Factory/second.hs)
by very stubbornly writing a solver for underconstrained systems of linear
equations, and it was a lot of fun!

[Day
11](https://git.adyxax.org/adyxax/advent-of-code/src/branch/master/2025/11-Reactor/second.hs)
might have been my favourite this year. It is about memoization and graph
exploration:

``` haskell
type Label = String
type Device = (Label, [Label])
type Input = M.Map Label [Label]

type Memo = M.Map (Bool, Bool, Label) Int

compute :: Input -> Int
compute input = (\(a, b) -> trace (show a) b) $ L.foldl' step (M.empty, 0) [(False, False, "svr")]
  where
    step :: (Memo, Int) -> (Bool, Bool, Label) -> (Memo, Int)
    step (m, a) (True, True, "out") = (m, a+1)
    step acc (_, _, "out") = acc
    step acc@(m, a) e@(d, f, l) = case M.lookup e m of
      Just v -> (m, a+v)
      Nothing -> let (m', a') = L.foldl' step (m, 0) $ zip3 (repeat $ if l == "dac" then True else d) (repeat $ if l == "fft" then True else f) (input M.! l)
                 in (M.insert e a' m', a + a')
```

## Some Befunge fun

I only did day 1 in
[befunge](https://github.com/catseye/Funge-98/blob/master/doc/funge98.markdown),
but it was fun. I would love to do more puzzles in befunge but I really lack the
time commitment.

Part1 is about simple parsing and keeping track of counters and modulos:

``` befunge
000p5a*>6j@.g000~&~$\'L-|
       ^       _v#:%d'<-<
       ^p00+1g00<     ^+<
```

Part2 is a bit more complex because you need some math, but not too bad:

``` befunge
p5a*10p>6j@.g000~&~$\'L-|
                      v >:10g\-'d%'d+'d%\10g\:0w
      ;^p01p00+g00/d'+<              <;# <     >\:!#;_aa*\-
       ^                >:10g+'d%\10g^         <
```

## Conclusion

I will always recommend tackling this kind of challenge: it is good to maintain
or develop proficiency in a programming language. Also I love Haskell! I wish I
could use it daily and not just for seasonal puzzles.
