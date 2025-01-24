# BÖBL

1. Introduction
Böbl is a top-down puzzle game where the player manipulates colored bubbles to solve environmental puzzles. The core mechanics revolve around collecting, shooting, nesting, and bursting bubbles to activate switches, open paths, and achieve level objectives.
2. Core Mechanics
* Movement: The player character moves on a grid-based environment using directional controls (e.g., WASD, arrow keys).
* Bubble Collection: The player can walk over bubbles scattered throughout the level to collect them. There is a limited inventory for how many bubbles the player can carry.
* Shooting: The player can shoot collected bubbles in any of the four cardinal directions. Bubbles travel in a straight line until they hit a wall or obstacle.
* Bubble Nesting: The player can shoot a bubble into another bubble (either stationary or in motion) to nest it. Multiple bubbles can be nested within each other, creating multi-bubble structures.
* Bursting:
    * Certain obstacles (e.g., spikes, sharp edges) cause bubbles to burst on contact.
    * If a multi-bubble structure bursts, all contained bubbles are released, continuing in their current trajectory (if any).
* Colored Bubbles: Bubbles come in different colors (e.g., Red, Blue, Green, Yellow).
* Switches:
    * Pressure Plates: Tiles that are activated when a bubble (or multiple bubbles) rests on them. Different colors might be required for different plates.
    * Colored Gates: Barriers that open only when a bubble of the corresponding color hits them.
3. Level Design
* Levels are designed on a grid.
* Levels incorporate various obstacles, switches, and bubble placement to create puzzles.
* Puzzle difficulty gradually increases by introducing new mechanics or combining existing ones in more complex ways.
* Examples of puzzle elements:
    * Using multi-bubbles to trigger multiple pressure plates simultaneously.
    * Using ricochets off walls to hit distant switches.
    * Strategic bursting of multi-bubbles to release inner bubbles in specific directions.
    * Sequences of colored gates that require precise bubble management.
4. Art Style
* Clean and simple top-down visuals.
* Bright and distinct colors for bubbles and level elements.
* Clear visual feedback for bubble movement, nesting, and bursting.
5. Sound Design
* Distinct sound effects for bubble collection, shooting, nesting, bursting, and switch activation.
* Background music that complements the puzzle-solving atmosphere.
6. User Interface
* Simple and intuitive UI.
* Clear display of the player's bubble inventory.
* In-game hints or tutorials (optional).
7. Example Puzzle
A pressure plate needs to be activated by a blue bubble. The blue bubble is located on the other side of a wall. The player can collect a red bubble and shoot it into the blue bubble. Then, the player shoots the multi bubble at a wall that has a sharp edge. The red bubble bursts on impact with the wall, and the blue bubble continues its trajectory to trigger the pressure plate.
8. Future Considerations
* Different bubble types with unique properties (e.g., bouncy bubbles, exploding bubbles).
* Moving obstacles or enemies.
* A level editor for user-generated content.
This document provides a basic framework for the game. Further details can be added as development progresses.


Okay, let's revise the merging and bursting rules with the changes you've specified:
Revised Merging Rules:
1. Empty Bubble + Empty Bubble: Results in a Single-Child Bubble. The shot bubble becomes the child bubble.
2. Empty Bubble + Single-Child Bubble: Results in a Double-Child Bubble. The shot bubble becomes the second child bubble.
3. Empty Bubble + Double-Child Bubble: This action is invalid. The shot bubble bounces off.
4. Single-Child Bubble + Empty Bubble: Results in a Double-Child Bubble. The shot bubble becomes the second child bubble.
5. Single-Child Bubble + Single-Child Bubble: Results in a Double-Child Bubble. The shot bubble becomes the second child bubble.
6. Single-Child Bubble + Double-Child Bubble: This action is invalid. The shot bubble bounces off.
7. Double-Child Bubble + Any Bubble: This action is invalid. The shot bubble bounces off.
Key Change: A Single-Child Bubble always accepts another bubble, becoming a Double-Child Bubble. The order of nesting still matters for bursting.
Revised Bursting Rules:
When a multi-bubble bursts:
* The parent bubble is destroyed.
* The child bubbles are released in directions orthogonal (perpendicular) to the parent bubble's direction of travel at the moment of the burst.
* In a Double-Child Bubble, the first child bubble is released first, followed immediately by the second child bubble.
Determining Orthogonal Directions:
Since this is a top-down game on a grid, there are only two orthogonal directions for each direction of travel:
* Traveling Up: Orthogonal directions are Left and Right.
* Traveling Down: Orthogonal directions are Left and Right.
* Traveling Left: Orthogonal directions are Up and Down.
* Traveling Right: Orthogonal directions are Up and Down.
Distributing Orthogonal Directions for Double-Child Bubbles:
To ensure predictable behavior, we need a consistent rule for which orthogonal direction each child bubble takes:
* First Child Bubble: Released to the left of the parent bubble's travel direction (relative to the parent's perspective).
* Second Child Bubble: Released to the right of the parent bubble's travel direction (relative to the parent's perspective).
Example:
A Double-Child Bubble R(B, G) is traveling up. It bursts.
* B (the first child) is released to the left.
* G (the second child) is released to the right.
If the same R(B, G) were traveling right:
* B would be released up.
* G would be released down.
Visual Example:
Imagine a Double-Child Bubble traveling right (→). Upon bursting:
```
    ↑ B
→ R(B,G)
    ↓ G
```    
Implications for Puzzle Design:
This orthogonal bursting mechanic adds a significant layer of strategic depth. Players will need to consider not only where to burst a bubble but also which direction it is traveling when it bursts to control the trajectory of the released child bubbles. This allows for puzzles that require precise timing and positioning to hit multiple targets or navigate complex level layouts.
These revised rules provide a more interesting and challenging gameplay experience.
