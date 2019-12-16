<h1 align="center">
  <img src="https://raw.githubusercontent.com/isomorfeus/opal-devtools/master/opal_devtools.png" 
  align="center" title="Opal logo by Elia Schito combined with Tools" width="111" height="125" />
  <br/>
  Opal Developer Tools<br/>
  <img src="https://img.shields.io/badge/Opal-Ruby%20💛%20JavaScript%20💛%20Firefox%20💛%20Chrome%20💛%20Edge%20Canary%20💛%20Opera%20💛%20Vivaldi-yellow.svg?logo=ruby&style=social&logoColor=777"/>
</h1>

Currently provides a console to execute ruby in the webpage context.
Works on Chrome, Firefox and Edge Canary.

Screenshots:

Console:

![Screenshot](https://raw.githubusercontent.com/isomorfeus/opal-devtools/master/screenshot_console_firefox.png)

Object Browser:

![Screenshot](https://raw.githubusercontent.com/isomorfeus/opal-devtools/master/screenshot_object_browser_firefox.png)

### Community and Support
At the [Isomorfeus Framework Project](http://isomorfeus.com) 

### Installation

#### Firefox:
[Opal Developer Tools from Mozilla AddOns](https://addons.mozilla.org/addon/opaldevtools/)

#### Chromium Browsers (Chrome and other Browsers that can use the Webstore):
[OpalDeveloperTools from Chrome Webstore](https://chrome.google.com/webstore/detail/opaldevelopertools/lbodjejiiaanfdajbegggpomgogfhahj)

#### From the Repository
- clone
- `yarn install`
- `bundle install`
- `yarn run production_build` for a minified build

or
- `yarn run debug_build` to include source maps for debugging, webpack will continue running and rebuild on file changes.
 
For Chrome, Edge (Canary, the one based on Chromium, >= V79), Opera, Vivaldi:
- in Extensions, turn on developer mode
- load the `chrome_extension` directory.

For Firefox:
- in Firefox, Add-ons, the gear, select "Debug Add-on"
- then "Load temporary Add-on"
- select `manifest.json` in the `firefox_extension` directory.

### Usage

#### Console
`help` shows available commands.

Commands can by default only be executed if Opal is loaded on the page.

If Opal is not loaded on the page it can be injected with `inject_opal`,
on any page. Afterwards Opal Ruby can be used to manipulate the DOM. Everything from opal-browser is available, eg:
```
my_div = $document['div']
```
However, `inject_opal` puts the console in "inject" mode. In this mode the Javascript context of the page is not available,
only access to the DOM is possible.
To go out of "inject" mode use `go_iso`, it loads the Isomorfeus website with Opal loaded, execution of Opal Ruby commands in page context
is then possible again. Afterwards any other page with Opal loaded can be visited and Opal Ruby commands be executed.

Command execution works with Opal 0.11.x and 1.x.
Tab completion only works with Opal 1.x.
Opal Versions < 0.11 are not supported.

#### Object Browser

The Object Browser requires the inspected app to be build with the es6_modules_1_1 branch and a variable to be injected in the build, to enable the
object registry. Please see: [es6_modules_1_1](https://github.com/opal/opal/pull/1976#issuecomment-538459551).
Include in your Gemfile:
```
gem 'opal', github: 'janbiedermann/opal', branch: 'es6_modules_1_1'
```
Opal projects are very fast and easy to build with [opal_webpack_loader](https://github.com/isomorfeus/opal-webpack-loader), enabling hot relaoding,
the object registry for Opal Developer Tools and other features.

### Based on 
- [opal](http://opalrb.com)
- [opal-browser](https://github.com/opal/opal-browser)
- [opal-webpack-loader](https://github.com/isomorfeus/opal-webpack-loader)
- [isomorfeus-redux](https://github.com/isomorfeus/isomorfeus-redux/tree/master/ruby)
- [isomorfeus-react](https://github.com/isomorfeus/isomorfeus-react/tree/master/ruby)
- [OpalConsole, integrated.](https://github.com/isomorfeus/opal-devtools/tree/master/isomorfeus/components)

### Credits
- Tab completion engine originally taken from @fkchang [opal-irb](https://github.com/fkchang/opal-irb)

### Development

You are welcome! And your improvements to opal-devtools ...

- clone repo
- `yarn install`
- `bundle install`
- `yarn run debug`
- load extension from firefox_extension or chrome_extension directory

Its written in ruby using isomorfeus-react, see link above for docs.

#### Console
Files are in isomorfeus/components/*Console*.rb.
- opal_console.rb: For console commands and general functionality.
- console.rb: For keyboard support, etc.

#### ObjectBrowser
See isomorfeus/components/object_browser.rb

#### In General
There is a panel page, isomorfeus/components/isomorfeus_devtools_app.rb, it renders the opal_devtools_app_bar.rb and below it the console or
object browser.

The panel page executes directly on the page using `chrome.devtools.inspectedWindow.eval`, or on firefox in inject mode, it sends a message.
Ruby code can be executed using `execute_in_page` in the opal_console.rb, it will be compiled to js.

Framework detection happens via events and messaging, see `*_extension/devtools/devtools.js` -> `check_page_for_opal`, message is received by
isomorfeus/components/isomorfeus_devtools_app.rb and put into app_store. isomorfeus/components/opal_devtools_app_bar.rb then renders accordingly.
