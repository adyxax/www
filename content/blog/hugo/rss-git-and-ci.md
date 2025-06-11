---
title: Hugo RSS feed generation issue when running in CI
description: Normal services resume after disruption
date: 2025-04-28
tags:
- Forgejo
- Hugo
---

## Introduction

I just fixed an issue with RSS feed generation that began a month ago after
migrating the CI job that builds my blog from a git hook in Gitolite to a
workflow in Forgejo Actions.

## The issue

I only realized this issue after not seeing yesterday's article appear in my
[miniflux](https://miniflux.app/). I was puzzled when I noticed that the [XML
index file](https://www.adyxax.org/index.xml) did not contain any articles on
the hosting server. I immediately checked the Forgejo Actions workflow logs, but
there were no errors or warnings. Whatever was failing just failed silently.

## Solving the issue

I worked around the issue quickly by building the website locally on my
workstation and seeing the XML index file properly populated. I redeployed this
version of the website and refreshed my miniflux feed: it worked.

I first theorized that I might be missing a build dependency on my Forgejo
runners. It was disproved when connecting over SSH to the runner that ran the
last build: cloning and building the website there produced a valid XML index
file once again.

I then added a `sleep` statement before the deployment step in the workflow file
and pushed a commit so that I could inspect a CI run in progress. I managed to
SSH on the runner, navigate to the temporary build directory and reproduce the
issue there: whatever was happening was not intermittent.

I therefore examined the workflow closely and saw the `actions/checkout` step
that innocuously starts all GitHub or Forgejo Actions workflow. Having been
bitten by this in the past, I knew it performed a shallow git clone by default.
Therefore I followed my instinct to try a deep clone instead: this fixed the
issue.

With this new information, I checked Hugo's documentation and figured I had to
set `enableGitInfo = false` in my `config.toml` file. When enabled, Hugo uses
git to figure out the last modification date of a file and this breaks the RSS
feeds.

Though I did not use git information anywhere in my templates, this still
affected the logic that filters which articles show up in the feed. This
particular configuration flag was a remnant from before [I wrote my own Hugo
theme]({{< ref "ditching-the-heavy-hugo-theme.md" >}}): The theme I used once
upon a time required this flag.

## Conclusion

It was frustrating to encounter a silent failure in Hugo over something
seemingly trivial. Despite the silent failure, I was relieved my past
experiences made it straightforward to resolve.
