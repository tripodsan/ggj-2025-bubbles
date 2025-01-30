# BÖBL

Böbl is a top-down puzzle game where the player manipulates colored bubbles to solve environmental puzzles. The core mechanics revolve around collecting, shooting, nesting, and bursting bubbles to activate switches, open paths, and achieve level objectives.

![cover](https://github.com/user-attachments/assets/a0a7d409-1892-4688-8c1e-18d2fbd36cd2)


## Game Mechanics

Böble is played on a grid with equally sized, square tiles. The grid can contain empty tiles, which represent air and cannot be stepped on by the player. The game is at its core step based, i.e. for each "move" the states of object can change or move from one tile to another. In order to achieve a more fluid game experience, the step-by-step aspect of the game is hidden in "normal" mode and the transitions from one step to the next are animated fluid.

### objects


- player: solid, movable, heavy
- wall: solid, static
- bubble: fragile, movable, light
- door: static, states(solid, ephemeral)
- rock: solid, movable, heavy
- kelp: soft, static
- spike: solid, static, pointy
- corner: ephemeral, static
- presssure plate: ephemeral, static
- bubble sensor: ephemeral, static

### general rules
- static objects cannot be moved
- ephemeral objects can occupy the same tile as other objects
- movable objects can be pushed into tiles that don't contain a solid object
- pointy objects will harm fragile objects


### player rules
- the player can move to any tiles that is not solid.
- player has a single "bubble" slot
- if the player occupies the same a bubble, it will pick it up unless his bubble slot is full. in that case the player is view as solid by the bubble. (bounce)
- the player can release a bubble from his slot in the direction he is facing. the released bubble will span in the tile in fron of the player with an initial state of "MOVING"
- the player can push movable objects in the direction of travel, but only if the object can be moved. there is no chain move (i.e. the player cannot move a row of rocks at once)


### bubble rules
- bubbles can be "STATIC" or "MOVING"
- when moving, they advance to the next tile for each game step.
- if the next tile is solid, the bubble will enter the "BOUNCE" state and switch direction. after the "BOUNCE" state, they will resume the "MOVING" state.
- if the next tile is pointy, the bubble will burst (see below)
- if the next tile is a bubble, the bubbles will merge or bounce, depending on the merge rules (see below)
- if the next tile is soft, the bubble will become "STATIC"
- if the next tile is movable, the bubble will try to push the object. if the object can be pushed, the bubble will become "STATIC", otherwise is will "BOUNCE"

### bubble merge rules
- static wins
- less children wins
- "smaler" direction wins


### bubble burst rules
- release inner bubble.

### sensors
- trigger doors


