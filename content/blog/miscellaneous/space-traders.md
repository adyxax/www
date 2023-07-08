---
title: Space Traders
description: A programming game where you manage a space empire through an API
date: 2023-07-08
tags:
- JavaScript
- SpaceTraders
---

## Introduction

A few weeks ago, a friend stumbled upon [Space Traders](https://spacetraders.io/). He shared the link along with his enthusiasm knowing very well I would not resist its appeal.

## The game

SpaceTraders is an API-based game where you acquire and manage a fleet of ships to explore, trade, and one day fight your way across the galaxy. It is not finished and very much in alpha state. There have been a few bugs but nothing major so far.

You can use any programming language you want to query the API and control your ships, query market prices or shipyards stocks, explore systems, mine or survey asteroids. You run your code wherever you like, however you like.

One of the challenges is that you are rate limited to 2 requests per seconds, with a 10 requests burst over 10 seconds. Because of that, any competitive agent will need to be efficient in the commands it sends and the strategy it chooses!

## Getting started

My recent experiences with Haskell made me itch to get started in this language, but I finally decided against it. I was at a level of proficiency where I know it would have been too ambitious a task. I would have just ended up tinkering with data types and abstractions instead of learning the API and experimenting with the game.

Therefore I went with (vanilla) JavaScript. It is quite a nice language for prototyping despite its many pitfalls, and I quickly got an agent working its way through the first faction contract. This first contract is like a tutorial for the game and the documentation guides you through it. I refined my agent along the way and am proud to have something that can mine the requested good (selling anything else), then navigate and deliver goods. It loops like that until the contract is fulfilled.

It might be premature optimisation but I am caching a maximum of information in an SQLite database in order to reduce the amount of API calls my code needs to make. I am taking advantage of SQLite's JSON support to store the JSON data from the API calls, which is a lot easier than expressing all the information in SQL tables, columns and references. I add the necessary index on the JSON fields I query against.

The network requests are all handled by a queue processor which relies on a priority queue. When the agent needs to make an API call, it places it along with a promise into the priority queue, choosing the right priority depending on the action needed. For example ships actions that will gain credits will take priority over exploration tasks, or market refresh tasks. Centralizing the network requests in this manner allows me to strictly respect the rate limits and not hammer needlessly the game's servers.

## Going further

I started adding more complex behaviors to my ships. For example, a navigation request will check if the ship is docker or not, and undock it if that is the case. Upon arrival it will attempt to refuel. Another example is a navigation request which will check the ship's position for asteroids. If it is not a mining location, the ship will automatically navigate to where it can mine, and refuel if needed.

With all this implemented, I should begin tackling exploration. My navigation code currently only works in a single system and I need to handle FTL jumps or warp drives depending on the destination.

I also want to implement automatic ship purchasing depending on the current agent's goals, but I feel limited by JavaScript's dynamic nature when iterating on the code. I am tired of fighting with runtime error and exceptions, therefore I just started rewriting my agent in Haskell.

## Conclusion

I learned a lot about async in JavaScript with this project! I encourage anyone with a bit of free time to give it a try, be it to learn a new language or improve in one you already know. My code is available [on my git server](https://git.adyxax.org/adyxax/spacetraders/tree/) if you want to have a look. Do not hesitate to reach me on mastodon [@adyxax@adyxax.org](https://fedi.adyxax.org/@adyxax) if you want to discuss space traders!
