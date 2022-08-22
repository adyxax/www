---
title: "Learning the zig programming language"
description: "a general-purpose programming language and toolchain for maintaining robust, optimal and reusable software"
date: 2022-08-22
---

## Introduction

Since learning nim last years I had a renewed interest for learning yet another language. I liked nim but I wanted to try something else, a simpler language. I had my eye on [zig](https://ziglang.org/) and spend the last five or six months learning it.

## Getting started

Learning zig is relatively easy, there are well written materials starting from [these great tutorials](https://ziglearn.org/). The language is pleasant and simple to think about, it shows that there was a lot of thinking involved to keep it simple but powerful. The tooling is fantastic and well thought out, zig build is so smartly done! Testing is a breeze, debugging straightforward.

What i found not so simple to learn is the idioms regarding the usage of `anytype`. I encountered this when trying to feed a reader or a writer as argument when instantiating an object. Once I understood it was quite logical, but the lack of resources made me stumble a little.

## Projects I wrote in zig

I took a lot of satisfaction writing code in zig. The language is really great, compilation is on the slow side compared to nim and go but faster than c or c++ (and should improve a lot in the next release), debugging with gdb is so simple... You can iterate on your code very quickly and it is such a breeze.

Having wrote a Funge-98 interpreter in go then in nim recently, I did the logical thing and wrote one in zig to have an objective comparison of the three languages : https://git.adyxax.org/adyxax/zigfunge98. The code ends up shorter and executes faster than its go and nim counterparts. IT is a little less expressive than nim, but being a simpler language I find it all more elegant and easier to find my way again in the code in a few years.

I have also tested the C integration which is absolutely stellar. I wrote a little tool around the libssh for a non trivial test and was very impressed. I might pick this up and start writing the configuration management tool I have been dreaming about for the last decade : https://git.adyxax.org/adyxax/zigod/

Next I wanted to write something I had not attempted before and settle on a little game. It is a game played in the terminal with ascii graphics, a pong like thing that could remind you of volleyball : https://git.adyxax.org/adyxax/grenade-brothers/

I have not dabble yet into a web project but it is next on my todo list.

## Conclusion

I recommend learning zig, it is a very refreshing language and you will quickly be productive with it. The tooling is great and I find this language is a jewel waiting to be discovered by more developers.

It shows that it does not have a big corporation behind it like go with google or rust with mozilla, if it did it would already be one of the top languages of the decade.
