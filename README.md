# Science is Fake

“I have not failed. I’ve just found 10,000 ways that won’t work.”

- Thomas A. Edison

Isn't it peculiar that you mash together a copper plate and an iron gear, in order to make a mysterious potion, which magically gives you the insight to build new things?

Wouldn't it make more sense that in order to gain certain knowledge and build new things, you actually run experiments with available tools and items that will actually result in those new things?

---

# Incompatibility warning

- Incompatible with mods that add multiple recipes which produce the same science pack, resulting in possible deadlocks
- Incompatible with mods that require science packs as ingredients in recipes
- Incompatible with mods that add fluid which refuse to be barreled or fluids which are not properly defined
- Incompatible with mods that add/remove items/fluids/recipes/technology/labs in the data-final-fixes stage
- Incompatible with mods that edit affected recipe ingredients/results, technology costs or lab inputs in the data-final-fixes stage

_IMPORTANT:_ run command `/sif-test-deadlock` to test if all technology can be researched!

---

# How it works

Instead of researching by consuming science packs, research is done by consuming the ingredients of the recipes that are unlocked by that technology.

For example looking at the technology Logistics:

- Unlocks splitter, with ingredients: 5x green circuit + 5x iron plate + 4x yellow belt
- Unlocks underground belt, with ingredients: 10x iron plate + 5x yellow belt
- Total ingredients for recipes in this technology: 5x green circuit + 15x iron plate + 9x yellow belt
- Original science units required: 15s & (1x automation science pack) x 20
- New research units required: 15s & (5x green circuit + 15x iron plate + 9x yellow belt) x 20

The new ingredients are multiplied by the average number of original science packs required

- In vanilla all research cost an equal amount of science packs, but this is not a prerequisite
- There could be a situation where a tech requires (1x automation science + 3x logistic science)
- The average science packs in that scenario required would be 2 (rounded up)

Exceptions

- Technologies unlocked by a trigger are not affected
- Recipes that require fluid translate to fluid barrels in the related technology
- For technology that does not unlock a recipe, the cost will be calculated according to the ingredients of the original science pack cost
- Each non-recipe effect in a technology will multiply the base cost by +1

_What happens to science packs_
Science packs no longer exist, simple as that. This means:

- Recipes that produce science packs will get the science pack removed from the output
- If said recipe then does not produce any output, the recipe is removed
- Same goes for science packs in the recipe's ingredients
- Removed recipes will get removed from their unlocking technologies
- If said technology then does not have any research effects, the technology is removed
- If said technology is removed, it's pre-/postconditions are passed through so that the tech tree remains in tact
- Science packs are removed from lab inputs

---

# Known issues

- This mod has not been extensively stress-tested and there is no guarantee that the mod is deadlock free
- Not all locale is properly defined
- Not all "tool equivalent" item/recipe icons are properly defined
- There are "tool equivalent" items/recipes created for all non-tool items, but not all of them are used as lab input
- Science pack related items/recipes/technology are not actually removed but instead are hidden

# Roadmap

- Make this mod awesome
- Add a "research paper"-like item as the basis for all technology
- Recursive replace science packs in recipe ingredients
- Add a give-item modifier to each technology --> You'll get the first one free because you were successful
- Add a GUI to show which item is used how many times in remaining technology

# Collaborations welcome

- Start a discussion with your ideas
- Open a pull request on Github
- Report issues under discussions

# Acknowledgement

- Me, for being awesome
