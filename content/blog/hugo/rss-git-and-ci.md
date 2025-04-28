---
title: Hugo RSS feed generation issue when running in CI
description: Normal services resume after disruption
date: 2025-04-28
tags:
- Forgejo
- Hugo
---

## Introduction

I just fixed an RSS feed generation that first started a month ago after
migrating the CI job that builds my blog from a git hook in Gitolite to a
workflow in Forgejo actions.

## The issue

I only realized this issue after not seeing yesterday's article pop in my
[miniflux](https://miniflux.app/). It puzzled me when I realized that the [XML
index file](https://www.adyxax.org/index.xml) was empty of any articles on the
hosting server. I immediately checked the Forgejo actions workflow logs, but
they did not show any error nor warning. Whatever was failing just failed
silently.

## Solving the issue

I worked around the issue quickly by building the website locally on my
workstation and seeing the XML index file properly populated. I redeployed this
version of the website and refreshed my miniflux feed: it worked.

I first theorized that I might be missing a build dependency on my Forgejo
runners. It was disproved when connecting over SSH to the runner that ran the
last build: cloning and building the website there produced a valid XML index
file once again.

I then added a `sleep` statement before the deployment step in the workflow file
and pushed a commit so that I could inspect a CI run in progress. I manged to
SSH on the runner, find my way to the temporary build directory and reproduce
the issue there: whatever was happening was not intermittent.

I therefore squinted my eyes a bit at the workflow and saw the
`actions/checkout` step that innocuously starts all GitHub or Forgejo actions
workflow. Having been bitten by this in the past, I knew it performed a shallow
git clone by default so I followed my instinct to try a deep clone instead: this
fixed the issue.

With this information, I checked Hugo's documentation and figured I had to set
`enableGitInfo = false` in my `config.toml` file. When enabled, Hugo uses git to
figure out the last modification date of a file and this breaks the RSS feeds.

Though I did not use git information anywhere in my templates, this still
affected the logic that filters which articles show up in the feed. This
particular configuration flag was a remnant from before [I wrote my own Hugo
theme]({{< ref "ditching-the-heavy-hugo-theme.md" >}}): The theme I used once
upon a time required this flag.

## Conclusion

I was disappointed that Hugo could fail silently on such trivial thing, but alas
it was easy to solve.
