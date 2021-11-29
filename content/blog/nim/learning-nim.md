---
title: "Learning the nim programming language"
description: "A statically typed compiled systems programming language that takes inspiration from Python and other languages"
date: 2021-11-29
---

## Introduction

Since learning go about three years ago I did not take the time for learning another language. I stumbled upon [nim](https://nim-lang.org/) on [Hacker News](https://news.ycombinator.com/) about a month and a half ago and decided to take a bite at it.

## Getting started

Learning nim itself is not that hard, there are well written materials starting from [the official tutorial](https://nim-lang.org/docs/tut1.html). The language is pleasant and simple to think about, it shows that there was a lot of thinking involved to keep it simple but powerful.

What I found not so simple to learn is the tooling. For example it is unclear what are the best practices regarding testing, and even though I ended up with something I find quite elegant I think a testing tutorial would be beneficial. Another example is `nimble`, nim package manager. It seems there are diverging opinions between the language developers and nimble's, which ends up confusing.

I am also missing a way to simply get a test coverage report. There are some unofficial ways to get that information but it is either not a perfect representation of the coverage with obvious errors, or would require you to adapt your code for it.

## Projects I wrote in nim

I took a lot of satisfaction writing code in nim. The language is really expressive, compilation is fast, debugging with gdb is simple... You can iterate on your code very quickly and it is such a breeze.

Having wrote a Funge-98 interpreter in go recently, I wrote one in nim to have an objective comparison of the two languages : https://git.adyxax.org/adyxax/nimfunge98. The code ends up shorter, more expressive and executes faster than its go counterpart.

Next I wanted a web project so I wrote a simple url shortener : https://git.adyxax.org/adyxax/short. I was a bit disappointed in the lack of releases for some dependencies. I guess the popularity of nim shows when you look at existing libraries and their various states of activity and maintainance.

## Conclusion

I recommend learning nim, it is a very refreshing language and you will quickly be productive with it. The tooling still has some ways to go but this language is a jewel waiting to be discovered by more developers.

It shows that it does not have a big corporation behind it like go with google or rust with mozilla, if it did it would be one of the top languages of the decade.
