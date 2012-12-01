QA Simulator 2012
==================

A not so loose interpretation of the theme. Branch and merge to fix bugs!

![Screenshot](http://doowttam.com/game-off-2012/opener-anno.png)

How to Play
------------------

The stream moves from the top left and wraps onto each line. Black circles represent bugs you needed to fix. The stream is made up of a random pattern, by looking at the pattern you can infer what the black circle should be.

**To fix a bug:**

 * Select the section with the bug
 * Branch what you have selected
 * Press space to jump into "branch mode"
 * Select the bug in your branch
 * Press up or down to cycle through possible fixes
 * Jump back into "stream mode" (with space)
 * Merge your branch, placing it on top of whatever is selected

Merge correctly to fix bugs! Merge incorrectly and you'll create all new ones!

**Goal:** Fix all 30 bugs (without causing any new ones) to get a perfect score!

**Scoring:** Commits are scored when they roll off of the stream at the bottom right.

 * Gain one point for every bug you fix (that you didn't cause!)
 * Lose one point for every bug you cause that makes it to the end

Controls
-------------------


 * **Space:** Switches between branch mode and stream mode
 * **Left/Right:** Moves your selector

In branch mode:

 * **Up/Down:** Cycle through possible fixes

In stream mode:

 * **Down:** Branches what you have selected, overwriting any branch you already have
 * **Up:** Puts your branch on top of whatever is currently selected

Built with
--------------

* [CoffeeScript](https://github.com/jashkenas/coffee-script)
* [HTML5 Boilerplate](https://github.com/h5bp/html5-boilerplate)
