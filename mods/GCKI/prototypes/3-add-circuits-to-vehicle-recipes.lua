GCKI.entered_file()

--~ ------------------------------------------------------------------------------------
--~ -- In Nullius, cars are available before electronics. If we add green circuits to --
--~ -- car recipes, players won't be able to build cars after researching them. (See  --
--~ -- <https://mods.factorio.com/mod/nullius/discussion/64daae983c0efa4b8d067cef>!)
--~ if mods["nullius"] then
  --~ GCKI.entered_file({}, "leave", "Nullius is active")
  --~ return
--~ end

------------------------------------------------------------------------------------
--                            NOTE TO FELLOW MODDERS                              --
--  GCKI will add an "electronic-circuit" (a.k.a. "green circuit") to any recipe  --
--  producing a "car" or "spider-vehicle" prototype if that prototype doesn't     --
--  require that or a better circuit ("red circuit" or "blue circuit") already.   --
--  If that breaks your mod, you can tell GCKI to ignore your recipe by adding    --
--  "GCKI_ignore = true" to your recipe in data.lua.                              --
------------------------------------------------------------------------------------

GCKI_lib = {}
require('libs/functions')
require('libs/item-functions')
require('libs/recipe-functions')

------------------------------------------------------------------------------------
------------------------------------------------------------------------------------
--                   ADD ELECTRONIC CIRCUITS TO VEHICLE RECIPES                   --
------------------------------------------------------------------------------------
------------------------------------------------------------------------------------

-- Look for recipes producing these vehicles
--~ local vehicles = GCKI.get_vehicle_prototypes_map()
local vehicles = GCKI.vehicle_prototypes_map
GCKI.show("vehicles", vehicles)

-- Add this ingredient unless the recipe already uses the it!
local ingredient = "electronic-circuit"
local amount = 3

if mods["Satisfactorio"] then
  ingredient = "crystal-oscillator"
  amount = 5

-- Nullius rebrands the programmable-speaker as "antenna"!
elseif mods["nullius"] then
  ingredient = "programmable-speaker"
  amount = 1
end
GCKI.show("ingredient", ingredient)
GCKI.show("amount", amount)

local add_this = {type = "item", name = ingredient, amount = amount}
GCKI.show("add_this", add_this)

------------------------------------------------------------------------------------
-- We don't have a "car-key" item anymore, so there's no recipe we could use!
------------------------------------------------------------------------------------
--~ -- Determine amount of ingredient used in car-key recipe
--~ local ingredient_amount = {}
--~ local x
--~ for d, difficulty in ipairs({"normal", "expensive"}) do
  --~ -- This will create the difficulty if it doesn't exist yet.
  --~ -- (Our recipe should have no difficulty, but other mods may have changed that!)
  --~ x = GCKI_lib.recipe.recipe_has_difficulty_ingredient("car-key", difficulty, ingredient)
  --~ ingredient_amount[difficulty] = x and x.amount
--~ end
--~ GCKI.show("Ingredient amount for "..ingredient, ingredient_amount)


------------------------------------------------------------------------------------
-- Ignore these recipes
local ignore_recipe_patterns = {}
if mods["aai-programmable-vehicles"] then
  table.insert(ignore_recipe_patterns, "^.+%-reverse")
end

if mods["kj_40kbunker"] then
  table.insert(ignore_recipe_patterns, "^kj_40kbunker.*")
end


if mods["nullius"] then
  --~ table.insert(ignore_recipe_patterns, "^nullius%-car%-.+")
  --~ table.insert(ignore_recipe_patterns, "^nullius%-truck%-.+")
  --~ table.insert(ignore_recipe_patterns, "^nullius%-mecha.*")
  table.insert(ignore_recipe_patterns, "^nullius%-.+")
end


if mods["IndustrialRevolution3"] then
  table.insert(ignore_recipe_patterns, "monowheel")
end

-- Never ignore these recipes
local whitelist_recipe_names = {}
if mods["nullius"] then
  whitelist_recipe_names["nullius-car-1"] = true
end

GCKI.show("ignore_recipe_patterns", ignore_recipe_patterns)
GCKI.show("whitelist_recipe_names", whitelist_recipe_names)


-- Ignore recipes that require any of these ingredients
local ignore_ingredients = {
  ["electronic-circuit"] = true,
  ["advanced-circuit"] = true,
  ["processing-unit"] = true,
  ["rocket-control-unit"] = true,
}
GCKI.show("ignore_ingredients", ignore_ingredients)


-- Look up keys from the shorter list in the longer one to save loop iterations!
local function list_match(short, long)
  -- Make sure we have at least empty lists!
  short = short or {}
  long = long or {}

  if (table_size(short) > table_size(long)) then
    short, long = long, short
  end

  for k, v in pairs(short) do
    if long[k] then
      return true
    end
  end
end


local results, ingredients, skip
for r, recipe in pairs(data.raw.recipe) do
GCKI.show(r, recipe)
  -- Other mods: Set custom flag "recipe.GCKI_ignore = true" to prevent GCKI from
  --             changing your recipe!
  if recipe.GCKI_ignore then
    GCKI.writeDebug("Ignoring %s!", {GCKI.argprint(recipe)})

  -- No mod forbids us to change this recipe
  else
    -- Recipe could be blacklisted (matches a pattern)
    skip = false

    -- Only run the pattern match if the recipe name is not whitelisted!
    if not whitelist_recipe_names[r] then
      for p, pattern in pairs(ignore_recipe_patterns) do
        if r:match(pattern) then
    GCKI.show("Ignoring recipe", r)
          skip = true
          break
        end
      end
    else
      GCKI.writeDebug("Found whitelisted recipe \"%s\"!", {r})
    end
GCKI.show("skip", skip)

    -- Recipe name is not whitelisted, but could be on the ignore list
    if not skip then
      results = GCKI_lib.recipe.get_recipe_results(recipe)
GCKI.show("Results of available difficulties", results)
      for d, difficulty in ipairs({"", "normal", "expensive"}) do
        -- A recipe result is one of the vehicles we care about
        if results[difficulty] and list_match(results[difficulty], vehicles.car) then
          GCKI.writeDebug("Result is a vehicle!")
          ingredients = ingredients or
                        GCKI_lib.recipe.get_recipe_ingredients(recipe, difficulty)
          -- Mark recipe as changed by GCKI if it doesn't use any of the forbidden
          -- ingredients and if the ingredient we want to add isn't used already
          if ingredients[difficulty] and
              (not list_match(ingredients[difficulty], ignore_ingredients)) and
              GCKI_lib.recipe.add_new_difficulty_ingredient(recipe, difficulty, add_this) then

            recipe.GCKI_added_ingredient = recipe.GCKI_added_ingredient or {}
            recipe.GCKI_added_ingredient[difficulty] = add_this
            GCKI.writeDebug("Added %s to difficulty \"%s\" of recipe \"%s\".",
                            {add_this.name, difficulty, recipe.name})
          end
        end
      end
    else
      GCKI.writeDebug("Skipping recipe \"%s\"!", {r})
    end
  end
end


------------------------------------------------------------------------------------
GCKI.entered_file("leave")
