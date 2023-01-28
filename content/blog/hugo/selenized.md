---
title: Website makeover
description: From Solarized to Selenized
date: 2023-01-28
tags:
- hugo
---

## Introduction

I have been a long time user of the [solarized](https://ethanschoonover.com/solarized/) theme in almost all my tools: terminals, text editors... For a decade maybe? I naturally decided to use it for my personal website when I redesigned it two years ago. I found it nice on the eyes and its low contrast did not bother me.

Fast forward to 2023: I stumbled upon [selenized](https://github.com/jan-warchol/selenized) and fell in love with it.

## CSS theme

When I [wrote my own hugo theme]({{< ref "ditching-the-heavy-hugo-theme.md" >}}) my main goal was minimalism. Therefore I had only one color theme in mind and I did not want to have any javascript on the website! Now, after some research and considerations I decided to add a tiny bit of optional javascript to allow for changing the color theme of the website. I found a hack to make it possible without javascript but I did not like that it broke accessibility, so a tiny bit of optional javascript it is.

There are too many ways to implement themes in html and css and many are convoluted or complicated. I do not want to discuss all these choices, so here is simply what I settled on:
- adding a class on the root `<html>` tag of the page like so:
  ```html
  <html class="black-theme" lang="en">
  ```
- implementing themes with css variables:
  ```css
  .black-theme {
  	--bg-0: #181818;
  	--bg-1: #252525;
  	--bg-2: #3b3b3b;
  	--dim: #777777;
  	--fg-0: #b9b9b9;
  	--fg-1: #dedede;
  	--red: #ed4a46;
  	--green: #70b433;
  	--yellow: #dbb32d;
  	--blue: #368aeb;
  	--magenta: #eb6eb7;
  	--cyan: #3fc5b7;
  	--orange: #e67f43;
  	--violet: #a580e2;
  	--br_red: #ff5e56;
  	--br_green: #83c746;
  	--br_yellow: #efc541;
  	--br_blue: #4f9cfe;
  	--br_magenta: #ff81ca;
  	--br_cyan: #56d8c9;
  	--br_orange: #fa9153;
  	--br_violet: #b891f5;
  }
  ```
- Everywhere in the css, invoke the colors with something like:
  ```css
  html {
  	background-color: var(--bg-0);
  	color: var(--fg-0);
  }
  ```

Changing colors was simple matter of updating my css, or was it? Changing every aspect of this website was simple except for the code blocks syntax highlighting!

## Hugo syntax highlighting

One thing that was not straight forward and required some googling was how to customize syntax highlighting with hugo. In my `config.toml` file I had:
```toml
[markup]
[markup.highlight]
noClasses = true
style = 'solarized-dark'
```

But where does the style data comes from? You can get it with:
```sh
hugo gen chromastyles --style=solarized-dark > assets/code.css
```

From there I removed the `style` entry in my `config.toml` and set `noClasses = false`, and added this code.css in my `layouts/_default/baseof.html` where I compile all my css files into one using go templating:
```html
{{ $base := resources.Get "base.css" -}}
{{- $code := resources.Get "code.css" -}}
{{- $footer := resources.Get "footer.css" -}}
{{- $header := resources.Get "header.css" -}}
{{- $home := resources.Get "home.css" -}}
{{- $pagination := resources.Get "pagination.css" -}}
{{- $responsive := resources.Get "responsive.css" -}}
{{- $allCss := slice $base $code $footer $header $home $pagination $responsive | resources.Concat "static/all.css" | fingerprint | minify -}}
```

From there I manually edited the `code.css` file and replaced all the color entries with the correct css `var()` invocation.

## Themes chooser

### HTML and CSS

The theme chooser box is a `select` tag in the html code of the navigation menu. The difficult part was to make it look right and aligned with the other menu entries which really was not easy! css is complicated and unpredictable! After a lot of trials and errors I settled on the following HTML code for the menu:
```html
<header>
	<nav>
		<ol>
			<li id="title"{{if .IsHome}} class="nav-menu-active"{{end}}>
				<a href="/">{{ .Site.Title }}</a>
			</li>
		</ol>
		<ol id="nav-menu">
			{{- $p := . -}}
			{{- range .Site.Menus.main.ByWeight -}}
			{{- $active := or ($p.IsMenuCurrent "main" .) ($p.HasMenuCurrent "main" .) -}}
			{{- with .Page -}}
			{{- $active = or $active ( $.IsDescendant .)  -}}
			{{- end -}}
			{{- $url := urls.Parse .URL -}}
			{{- $baseurl := urls.Parse $.Site.Params.Baseurl -}}
			<li{{if $active }} class="nav-menu-active"{{end}}>
				<a href="{{ with .Page }}{{ .RelPermalink }}{{ else }}{{ .URL | relLangURL }}{{ end }}"{{ if ne $url.Host $baseurl.Host }}target="_blank" {{ end }}>{{ .Name }}</a>
			</li>
			{{ end }}
			<li>
				<select id="themes" onchange="setTheme()">
					<option value="black-theme">Black</option>
					<option value="dark-theme">Dark</option>
					<option value="light-theme">Light</option>
				</select>
			</li>
		</ol>
	</nav>
</header>
```

The go templating bits can be ignored: They are only used to display the different sections of this website and to highlight the currently visited one. The first important bit is that I am using two `ol` lists to allow a separation of the title aligned to the left and the menu aligned to the right. It also conditions how the website handles small screen sizes by then wrapping the title on one line and the menu on a second line.

The theme selector is the `select` html tag with each option being a valid theme. All this goes hand in hand with the following css:
```css
header nav {
	align-items: center;
	display: flex;
	flex-wrap: wrap;
	justify-content: space-between;
}
#nav-menu {
	align-items: baseline;
	display: flex;
	flex-wrap: nowrap;
}
#nav-menu li {
	flex-direction: column;
}
```

[There is more css needed to style the menu](https://git.adyxax.org/adyxax/www/tree/assets/header.css). This code only shows the nested `flex` bits needed to align things properly:
- the first flex (in `header nav`) conditions the separation of the website title and the menu.
- the second flex (in `#nav-menu`) permits the proper vertical alignment of the `select` html tag. Without this it would not look right!

### CSS and Javascript

Since I want javascript to be optional, the theme selector starts hidden:
```css
#themes {
	display: none;
}
```

Here is the bit of javascript at the end of the page template:
```javascript
function setTheme() {
	const themeName = document.getElementById('themes').value;
	document.documentElement.className = themeName;
	localStorage.setItem('theme', themeName);
}
(function () {  // Set the theme on page load
	const elt = document.getElementById('themes');
	elt.style.display = 'block';
	const themeName = localStorage.getItem('theme');
	if (themeName) {
		document.documentElement.className = themeName;
		elt.value = themeName;
	}
})();
```

The first part is the `setTheme` function which is called when the active entry in the `select` changes. It gets the newly selected value, sets it in the local storage so that the browser remembers which theme the user selected, then sets the root html tag class.

The second part is a function which is immediately called so that it runs when the page loads. It begins by making the theme selector visible (because since this code executes then javascript is available, so we want it to work), then it tries to retrieve the local storage theme entry, and if it exists activates it by setting the root html tag class.

## Customize Content Security Policy header

This website is served by [a k3s kubernetes cluster]({{< ref "k3s-ipv6.md" >}}) running [ingress-nginx](https://docs.nginx.com/nginx-ingress-controller/). Since I am now serving pages that might need javascript, I need to serve a custom [Content Security Policy](https://developer.mozilla.org/en-US/docs/Web/HTTP/CSP) that allows this.

Here is how to annotate your `ingress` resources to achieve this:
```yaml
metadata:
  annotations:
    nginx.ingress.kubernetes.io/configuration-snippet: |
      more_set_headers "Content-Security-Policy: script-src 'unsafe-inline'";
```

The position of the semicolon is NOT a mistake! Try to put it inside the `"` and it will break the whole nginx configuration.

For references, [the whole ingress entry is here](https://git.adyxax.org/adyxax/www/tree/deploy/www.yaml).

## Conclusion

Today I am introducing three color themes: two are based on Selenized named `Black` (the default) and `Light`, and another one named `Dark` which is based on the previous color theme on this blog (Solarized dark) for posterity.

Changing theme is only possible if you enable javascript and through the little dropdown menu in the top right of this page. If you do not have javascript enabled, the default `Black` theme is used and the menu is hidden.
