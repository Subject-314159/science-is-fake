-- Declare global variables
suffix = "-siftool"
item_map = {}
fluid_map = {}
lab_map = {}
all_sciences = {}
science_cost = {}

-- Convert all available recipes to technology and disable
-- require("data-final-fixes.disable-starting-recipes")

-- Add all entry tech as successor to our bootstrap tech
-- require("data-final-fixes.update-entry-tech")

-- Create barrelling items and recipes for all opted-out fluids and create the fluid mapping
require("data-final-fixes.make-barrel")

-- Convert all items to tools and creat the item mapping
require("data-final-fixes.item-to-tool")

-- make a list of all current sciences and related mappings
require("data-final-fixes.get-current-sciences")

-- Change all research unit ingredients of all technology to the new tools
require("data-final-fixes.update-technology-sciences")

-- Update all labs to accept our new tool items as research and remove initial sciences
require("data-final-fixes.update-lab-inputs")

-- Clean up initial sciences
require("data-final-fixes.clean-up-sciences")

