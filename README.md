# Shuttle Train Lite

Complete from-the-ground remake of Simwirs excellent [Shuttle Train](https://mods.factorio.com/mods/simwir/ShuttleTrain), because it wasn't really working with 0.15. He has approved of me publishing a remake (I asked him, even though the MIT license would not actually require me to do so).

This fork changes the original in a few ways.

Personally, I use the mod along with [Just GO!](https://mods.factorio.com/mods/folk/folk-justgo) and [Automated Fuel & Ammo](https://mods.factorio.com/mods/folk/folk-fill), and have one train with this module in my quickbar, and slam it on the rails when I need to.

## How it works

After researching the technology, two things happen; (1) the mod adds a new green button to the main bottom UI with a train icon on it, and (2) you can now construct Shuttle Trains.

Construct a Shuttle Train (or several) and place it somewhere in your rail network.

Left-click the green button - or use the keybinding, default Ctrl+J - to call the nearest (to your characters position) available shuttle to the nearest station. Remember shuttles will respect rail signals just like any other train.

A shuttle is considered available if:

1. It has no passenger already (or you're the only passenger)
2. It can move
3. Noone else on your team has called it to them (i.e. it's busy)

Once you hop into a shuttle, the station interface presents itself.

## The station interface

The interface has 2 elements;

1. A filter textfield
2. A list buttons

The filter textfield works quite different from the old Shuttle Train; it filters per word. Examples

-   "acid main" matches "Main Sulfuric Acid #1"
-   "sulf main" matches "Main Sulfuric Acid #1"
-   "oil 1" matches "Oil-Load-#1"
-   "old coal" matches "Old Base Coal Unload"
-   "cop 1" matches "Copper #1"
    and so forth.
    Also, typing a dot (.) in the box is a special case; it will trigger the top-most station button.
    So, once you've typed enough that the top button matches, just input a . as the next character, like "copper 1.", and the topmost button will be triggered.

A station button instantly changes your shuttles destination to the clicked station.

## Advanced

When using the keybinding or green button, there's a prioritized order of potential destinations for the called shuttle;

1. If your mouse is hovered over any rail (just like when you want to deconstruct/mine it), the shuttle will attempt to drive to that specific rail and stop.
2. If your mouse is hovered over a train station, the shuttle will use that.
3. If you have the station interface window open, the shuttle will use the current station.
4. Finally, if neither of the above occur, the shuttle will attempt to drive to the nearest station it can path to.

If the shuttle fails to find a usable path to a station, it will attempt to find another nearby station. If the shuttle fails to find a path to a specific rail destination, it will just stop.

## Settings

The most confusing setting is probably the Hidden Names one. It refers to [Lua patterns](http://www.lua.org/manual/5.2/manual.html#6.4.1) and [string.find](http://www.lua.org/manual/5.2/manual.html#pdf-string.find).
It's quite simple, really. in 95% of cases, this is what you want:

-   ^Test: matches any station name that starts with "Test"
-   %d$: matches any station name that ends with a number
-   %s: matches any station name that has a space in it
-   %S: matches any station name that does not have a space in it
-   Test: matches anything that has "Test" in it
-   [Tt]est: matches "test" and "Test"

So if you set the Hidden Names option to (without the quotes): "^Test,%d$", it will hide any stations that start with "Test" or end in a number.

## Keybinding

The mod adds a new keybinding; "Call nearest shuttle" that defaults to Ctrl+J.

Pressing this keybind will call the nearest (to your characters position) shuttle to the nearest station; or the station you have selected (hover your mouse over), or the station you have open (station interface), or the rail you have selected (hovered).

This also works from the map view.

## "Lite"?

Yes, I don't know what that means either. I had to call it something, and my brain didn't work.

## Item requirements/"balancing"

The shuttle locomotive and tech might be a bit cheap as it is now. I welcome feedback on that or anything else about the mod. If anyone has thoughts on adding a version of the recipes for the "expensive" game mode, please comment.

## Contribute

I welcome contributions. Anyone who knows even slightly how to code, make graphics, or whatever, is welcome to get write access to the source code repository.

## Changelog

Please see changelog.txt or the changelog tab at https://mods.factorio.com/mod/folk-shuttle
