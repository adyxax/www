---
title: "Grenade Brothers"
description: "A pong like retro game written in zig and compiled to webassembly"
date: 2022-10-03
---

## Introduction

Since [learning zig]({{< ref "learning-zig.md" >}}), I embarked on a project to write a simple game in zig. I took inspiration from the video game [A Way Out](https://www.ea.com/games/a-way-out) which I played with a friend. At some point your characters stumble on an arcade console featuring a game called [Grenade Brothers](https://www.youtube.com/watch?v=B-pbPRX19JA). We had some fun and I joked about never writing a proper game in the past. The idea made its way and I started coding.

## The wasm4 fantasy console

At first I wrote the game to run from a terminal, in order to play over ssh. It was awkward, the terminal is not meant for these kind of interactions. For example you can detect only when keys are pressed, not released, which made controling lateral movements awkward. I looked for alternatives and almost started down a path to make a game boy advance game since there are [zig resources](https://github.com/wendigojaeger/ZigGBA) for that, but then I stumbled upon [wasm4](https://wasm4.org/).

It is a fantasy console where your game cartridge is a [WebAssembly](https://wasm4.org/) file. There are several limitations meant to increase creativity and enforce simplicity of games, like a 160x160 pixels screen with only four colours. There is also a great feature : transparent netplay!

## The game

It is a simple pong like video game where two characters exchange a ball between two sides separated with a net. You score a point if your opponent lets the ball hit the floor on his side. When playing on a single computer, the left player is controler by the arrow keys (up to jump) and the right player with the ESDF keys. You can press r to reset the cartridge.

Jumping into a falling ball will accelerate it, not jumping will slow it. To direct the ball in the right direction, have the right hand of your character hit it. The farther from the center of the model, the more lateral speed you add to the ball. If you manage to hit it twice repeatedly you can perform some sick tricks!

If you hit enter you open a menu that allows you to activate netplay. Paste the generated url to a friend in order to play together remotely. WebAssembly only requires browser and will even work on mobile phones!

You can find the game [here](https://grenade-brothers.adyxax.org/), while the source code is [here](https://git.adyxax.org/adyxax/grenade-brothers).

## Conclusion

I had great fun writing this. It is very basic and the collision detection will bug out if the ball starts moving too fast, but I am proud I took the time. I learned a lot and if you never wrote a simple game I encourage you to do so. The wasm4 virtual console has [tutorials](https://wasm4.org/docs/getting-started/setup) for many languages, just pick one in the drop down menu on the right just above any code snippet.

Have fun!
