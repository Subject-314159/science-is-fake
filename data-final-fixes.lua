-- make a list of all current sciences
require("data-final-fixes.get-current-sciences")

-- Convert all available recipes to technology and disable
require("data-final-fixes.disable-starting-recipes")

-- Add all entry tech as successor to our bootstrap tech
require("data-final-fixes.update-entry-tech")

-- Convert all items to tools
require("data-final-fixes.item-to-tool")

-- Change all research unit ingredients of all technology to the new tools
require("data-final-fixes.update-research-sciences")

-- Update all labs to accept our new tool items as research and remove initial sciences
require("data-final-fixes.update-lab-inputs")

-- Clean up initial sciences
require("data-final-fixes.clean-up-sciences")