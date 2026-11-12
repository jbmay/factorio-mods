GCKI.entered_file()
GCKI_lib.recipe = GCKI_lib.recipe or {}


-- Added by Pi-C
------------------------------------------------------------------------------------
--          Generate functions to change individual properties of recipes         --
------------------------------------------------------------------------------------
-- List of all recipe properties
-- (We must copy them when creating difficulties, we also need them to generate
--  the functions for setting individual properties!)
local recipe_properties = {
  -- Boolean values
  allow_as_intermediate = "boolean",
  allow_decomposition = "boolean",
  allow_inserter_overload = "boolean",
  allow_intermediates = "boolean",
  always_show_made_in = "boolean",
  always_show_products = "boolean",
  enabled = "boolean",
  hidden = "boolean",
  hide_from_player_crafting = "boolean",
  hide_from_stats = "boolean",
  show_amount_in_title = "boolean",
  unlock_results = "boolean",
  -- Numeric values
  emissions_multiplier = "double",
  energy_required = "double",
  overload_multiplier = "integer",
  requester_paste_multiplier = "integer",
  result_count = "integer",
  -- String values
  main_product = "string",
  result = "string",
  -- Table values!
  ingredients = "table",
  results = "table",
}

-- Added by Pi-C
------------------------------------------------------------------------------------
--                           Set properties of a recipe                           --
------------------------------------------------------------------------------------
local function recipe_set_difficulty_property_value(recipe_in, property, difficulty, value)
  GCKI.entered_function({recipe_in, property, difficulty, value})

  -- Sanitize arguments
  GCKI_lib.functions.check_difficulty(difficulty)
  local recipe = GCKI_lib.functions.check_recipe(recipe_in)

  if not recipe_properties[property] then
    error(string.format("%s is not a valid recipe property!", property))
  end
  if
    (recipe_properties[property] == "boolean" and type(value) ~= "boolean") or
    (recipe_properties[property] == "double" and type(value) ~= "number") or
    (recipe_properties[property] == "integer" and
      type(value) ~= "number" or
      (type(value) == "number" and value ~= math.floor(value))
    ) or
    (recipe_properties[property] == "string" and type(value) ~= "string") or
    (recipe_properties[property] == "table" and type(value) ~= "table")
  then
    error(string.format("%s is not a %s value!", value, recipe_properties[property]))
  end

  -- Set value
  if recipe then
    if difficulty == "" then
      recipe[property] = value
    else
      if not recipe[difficulty] then
        GCKI_lib.recipe.difficulty_split(recipe.name)
      end
      recipe[difficulty][property] = value
    end
  end

  GCKI.entered_function("leave")
end

-- Generate functions!
-- Set property for one difficulty ("" is the property in the recipe root):
-- GCKI_lib.recipe.recipe_set_difficulty_X(recipe, difficulty, item_in)
--
-- Set property for all difficulties, including no difficulty (directly in the recipe root):
-- GCKI_lib.recipe.set_X(recipe, value)
for property, p in pairs(recipe_properties) do
  if p == "boolean" then
    -- Usage: recipe -- name (string) or recipe data (table)
    GCKI_lib.recipe["set_difficulty_"..property] = function(recipe, difficulty, value)
      recipe_set_difficulty_property_value(recipe, property, difficulty, value)
    end

    -- Usage: recipe -- name (string) or recipe data (table)
    GCKI_lib.recipe["set_"..property] = function(recipe, value)
      GCKI_lib.recipe["set_difficulty_"..property](recipe, "", value)
      GCKI_lib.recipe["set_difficulty_"..property](recipe, "normal", value)
      GCKI_lib.recipe["set_difficulty_"..property](recipe, "expensive", value)
    end

  end
end


-- Modified by Pi-C
------------------------------------------------------------------------------------
--                           Create recipe difficulties                           --
------------------------------------------------------------------------------------
-- Copy recipe properties from recipe root to recipe difficulties
local function split_line(recipe_in, tag)
  --~ GCKI.entered_function({recipe_in, tag})

  -- Sanitize arguments
  local recipe = GCKI_lib.functions.check_recipe(recipe_in)

  if recipe then
    -- Checking for nil explicitely because Boolean properties set to "false" will
    -- mess things up!
    if recipe[tag] ~= nil then
      recipe.normal[tag] = recipe.normal[tag] ~= nil and recipe.normal[tag] or
                              table.deepcopy(recipe[tag])
      recipe.expensive[tag] = recipe.expensive[tag] ~= nil and recipe.expensive[tag] or
                              table.deepcopy(recipe[tag])
    -- Only recipe.normal exists
    elseif recipe.normal[tag] ~= nil and recipe.expensive[tag] == nil then
      recipe.expensive[tag] = table.deepcopy(recipe.normal[tag])
    -- Only recipe.expensive exists
    elseif recipe.expensive[tag] ~= nil and recipe.normal[tag] == nil then
      recipe.normal[tag] = table.deepcopy(recipe.expensive[tag])
    end
  end

  --~ GCKI.entered_function("leave")
end

-- Modified by Pi-C
-- Make sure the difficulties exist
function GCKI_lib.recipe.difficulty_split(recipe_in)
  GCKI.entered_function({recipe_in})

  local recipe = GCKI_lib.functions.check_recipe(recipe_in)

  if recipe then
    recipe.normal = recipe.normal or {}
    recipe.expensive = recipe.expensive or {}

    for property, p in pairs(recipe_properties) do
      split_line(recipe, property)
    end
  else
    GCKI.writeDebug("Recipe %s does not exist.", {recipe_in})
  end

  GCKI.entered_function("leave")
end


------------------------------------------------------------------------------------
------------------------------------------------------------------------------------
--                            Functions for ingredients                           --
------------------------------------------------------------------------------------
------------------------------------------------------------------------------------


------------------------------------------------------------------------------------
--                                 Add ingredients                                --
------------------------------------------------------------------------------------
-- Modified by Pi-C
-- Add new item to ingredients. If it already is an ingredient, add to its amount.
--~ function GCKI_lib.recipe.add_difficulty_ingredient(recipe_in, difficulty, item_in)
  --~ GCKI.entered_function({recipe_in, difficulty, item_in})

  --~ -- Sanitize arguments
  --~ GCKI_lib.functions.check_difficulty(difficulty)
  --~ local recipe = GCKI_lib.functions.check_recipe(recipe_in)
  --~ local item = GCKI_lib.item.item(item_in)
  --~ local ret

  --~ if recipe and item and GCKI_lib.item.get_type(item.name) then
    --~ if difficulty == "" then
      --~ recipe.ingredients = recipe.ingredients or {}
      --~ GCKI_lib.item.add(recipe.ingredients, item)
    --~ else
      --~ if not recipe[difficulty] then
        --~ GCKI_lib.recipe.difficulty_split(recipe)
      --~ end
      --~ recipe[difficulty].ingredients = recipe[difficulty].ingredients or {}
      --~ ret = GCKI_lib.item.add(recipe[difficulty].ingredients, item)
    --~ end

  --~ else
    --~ if not recipe then
      --~ GCKI.writeDebug("Recipe %s does not exist.", {recipe_in})
    --~ end
    --~ if not GCKI_lib.item.get_basic_type(item.name) then
      --~ GCKI.writeDebug("Ingredient %s does not exist.", {item_in})
    --~ end
  --~ end

  --~ GCKI.entered_function("leave")
  --~ return ret
--~ end
function GCKI_lib.recipe.add_difficulty_ingredient(recipe_in, difficulty, item_in)
  GCKI.entered_function({recipe_in, difficulty, item_in})

  -- Sanitize arguments
  GCKI_lib.functions.check_difficulty(difficulty)
  local recipe = GCKI_lib.functions.check_recipe(recipe_in)
  local item = GCKI_lib.item.item(item_in)
  local ret
GCKI.show("recipe", GCKI.argprint(recipe))
GCKI.show("item", GCKI.argprint(item))

  if recipe and item and GCKI_lib.item.get_type(item.name) then
    if difficulty == "" and recipe.ingredients then
      GCKI_lib.item.add(recipe.ingredients, item)
    elseif recipe[difficulty] and recipe[difficulty].ingredients then
      ret = GCKI_lib.item.add(recipe[difficulty].ingredients, item)
    end

  else
    if not recipe then
      GCKI.writeDebug("Recipe %s does not exist.", {recipe_in})
    end
    if not GCKI_lib.item.get_basic_type(item.name) then
      GCKI.writeDebug("Ingredient %s does not exist.", {item_in})
    end
  end

  GCKI.entered_function("leave")
  return ret
end


-- Modified by Pi-C
function GCKI_lib.recipe.add_ingredient(recipe, item)
  GCKI.entered_function(recipe, item)

  if recipe and item  then
    GCKI_lib.recipe.add_difficulty_ingredient(recipe, "", item)
    GCKI_lib.recipe.add_difficulty_ingredient(recipe, "normal", item)
    GCKI_lib.recipe.add_difficulty_ingredient(recipe, "expensive", item)
  else
    if not recipe then
      GCKI.writeDebug("No recipe!")
    end
    if not item then
      GCKI.writeDebug("No ingredient!")
    end
  end

  GCKI.entered_function("leave")
end


-- Modified by Pi-C
-- Only add this item if it's not yet an ingredient in this recipe!
--~ function GCKI_lib.recipe.add_new_difficulty_ingredient(recipe_in, difficulty, item_in)
  --~ GCKI.entered_function({recipe_in, difficulty, item_in})

  --~ -- Sanitizing arguments
  --~ GCKI_lib.functions.check_difficulty(difficulty)
  --~ local recipe = GCKI_lib.functions.check_recipe(recipe_in)
  --~ local item = GCKI_lib.item.item(item_in)

  --~ local ret

  --~ if recipe and item and GCKI_lib.item.get_type(item.name) then
    --~ if difficulty == "" then
      --~ recipe.ingredients = recipe.ingredients or {}
      --~ ret = GCKI_lib.item.add_new(recipe.ingredients, item)
    --~ else
      --~ if not recipe[difficulty] then
        --~ GCKI_lib.recipe.difficulty_split(recipe)
      --~ end
      --~ recipe[difficulty].ingredients = recipe[difficulty].ingredients or {}
      --~ ret = GCKI_lib.item.add_new(recipe[difficulty].ingredients, item)
    --~ end

  --~ else
    --~ if not recipe then
      --~ GCKI.writeDebug("Recipe %s does not exist.", {recipe_in})
    --~ end
    --~ if not item then
      --~ GCKI.writeDebug("Ingredient %s does not exist.", {item_in})
    --~ end
  --~ end

  --~ GCKI.entered_function("leave")
  --~ return ret
--~ end
function GCKI_lib.recipe.add_new_difficulty_ingredient(recipe_in, difficulty, item_in)
  GCKI.entered_function({recipe_in, difficulty, item_in})

  -- Sanitizing arguments
  GCKI_lib.functions.check_difficulty(difficulty)
  local recipe = GCKI_lib.functions.check_recipe(recipe_in)
  local item = GCKI_lib.item.item(item_in)
GCKI.show("recipe", recipe)
GCKI.show("item", item)
  local ret

  if recipe and item and GCKI_lib.item.get_type(item.name) then
    if difficulty == "" and recipe.ingredients then
      ret = GCKI_lib.item.add_new(recipe.ingredients, item)
    elseif recipe[difficulty] and recipe[difficulty].ingredients then
      ret = GCKI_lib.item.add_new(recipe[difficulty].ingredients, item)
    end

  else
    if not recipe then
      GCKI.writeDebug("Recipe %s does not exist.", {recipe_in})
    end
    if not item then
      GCKI.writeDebug("Ingredient %s does not exist.", {item_in})
    end
  end

  GCKI.entered_function("leave")
  return ret
end


-- Modified by Pi-C
function GCKI_lib.recipe.add_new_ingredient(recipe, item)
  GCKI.entered_function({recipe, item})

  if recipe and item  then
    GCKI_lib.recipe.add_new_difficulty_ingredient(recipe, "", item)
    GCKI_lib.recipe.add_new_difficulty_ingredient(recipe, "normal", item)
    GCKI_lib.recipe.add_new_difficulty_ingredient(recipe, "expensive", item)
  else
    if not recipe then
      GCKI.writeDebug("No recipe!")
    end
    if not item then
      GCKI.writeDebug("No ingredient!")
    end
  end

  GCKI.entered_function("leave")
end


------------------------------------------------------------------------------------
--                               Remove ingredients                               --
------------------------------------------------------------------------------------
-- Modified by Pi-C
function GCKI_lib.recipe.remove_difficulty_ingredient(recipe_in, difficulty, item_name)
  GCKI.entered_function({recipe_in, difficulty, item_name})

  -- Sanitize arguments
  GCKI_lib.functions.check_difficulty(difficulty)
  local recipe = GCKI_lib.functions.check_recipe(recipe_in)

  item_name = type(item_name) == "string" and item_name or
              type(item_name) == "table" and item_name.name or
              GCKI.arg_err(item_name, "item name or item")

  local ret

  if recipe and item_name then
    if difficulty == "" then
      ret = GCKI_lib.item.remove(recipe.ingredients, item_name)
    else
      if not recipe[difficulty] then
        GCKI_lib.recipe.difficulty_split(recipe)
      end
      ret = GCKI_lib.item.remove(recipe[difficulty].ingredients, item_name)
    end
  else
    if not recipe then
      GCKI.writeDebug("Recipe %s does not exist.", {recipe_in})
    end
  end

  GCKI.entered_function("leave")
  return ret
end


-- Modified by Pi-C
function GCKI_lib.recipe.remove_ingredient(recipe, item)
  GCKI.entered_function({recipe, item})

  if recipe and item  then
    GCKI_lib.recipe.remove_difficulty_ingredient(recipe, "", item)
    GCKI_lib.recipe.remove_difficulty_ingredient(recipe, "normal", item)
    GCKI_lib.recipe.remove_difficulty_ingredient(recipe, "expensive", item)
  else
    if not recipe then
      GCKI.writeDebug("No recipe!")
    end
    if not item then
      GCKI.writeDebug("No ingredient!")
    end
  end

  GCKI.entered_function("leave")
end


------------------------------------------------------------------------------------
--                               Replace ingredients                              --
------------------------------------------------------------------------------------
-- Added by Pi-C
-- If the old item is an ingredient, remove it and add the new item instead.
function GCKI_lib.recipe.replace_difficulty_ingredient(recipe_in, difficulty, old, new)
  GCKI.entered_function({recipe_in, difficulty, old, new})

  -- Sanitize arguments
  GCKI_lib.functions.check_difficulty(difficulty)
  local recipe = GCKI_lib.functions.check_recipe(recipe_in)

  if type(old) ~= "string" and (type(old) ~= "table" or not old.name and old.type) then
    error(string.format("\"%s\" is not a valid item name or item!", old))
  end
  if type(new) ~= "string" and (type(new) ~= "table" or not new.name and new.type) then
    error(string.format("\"%s\" is not a valid item name or item!", new))
  end

  local retval = false

  -- Recipe must exist
  local new_type

  if recipe then
    local ingredient, ingredients
    --~ local new_item, new_name, new_type, old_name, old_type
    local new_item, new_name, old_name, old_type

    old_name = type(old) == "string" and old or type(old) == "table" and old.name


    --~ ingredients = BI_Functions.lib.get_difficulty_recipe_ingredients(recipe, difficulty)
    ingredients = GCKI_lib.recipe.get_difficulty_recipe_ingredients(recipe, difficulty)

    -- We only need to do this if the old item is among the recipe ingredients
    if ingredients and ingredients[old_name] then

      ingredient = ingredients[old_name]
      new_name = type(new) == "string" and new or type(new) == "table" and new.name
      new_type = GCKI_lib.item.get_basic_type(new)
      old_type = ingredient.type

      -- "new" was just a name, use data from old item!
      if type(new) == "string" then
        new_item = {
          name = new_name,
          type = new_type,
          amount = ingredient.amount,
          catalyst_amount = ingredient.catalyst_amount
        }
        -- Add data for fluid ingredients, if necessary
        if new_type == "fluid" then
          new_item.temperature = ingredient.temperature
          new_item.minimum_temperature = ingredient.minimum_temperature
          new_item.maximum_temperature = ingredient.maximum_temperature
          new_item.fluidbox_index = ingredient.fluidbox_index
        end

        -- Switch from fluid to item?
        if old_type == "fluid" and new_type == "item" then
          new_item.amount = math.ceil(new_item.amount * 0.1)
          new_item.catalyst_amount = math.ceil(new_item.catalyst_amount * 0.1)
          new_item.minimum_temperature, new_item.maximum_temperature = nil, nil
        -- Switch from item to fluid
        elseif old_type == "item" and new_type == "fluid" then
          new_item.amount = new_item.amount * 10
          new_item.catalyst_amount = new_item.catalyst_amount * 10

        -- Same item
          -- luacheck: ignore
        else
        end

        new_item.catalyst_amount = new_item.catalyst_amount > 0 and new_item.catalyst_amount or nil

      -- "new" was an item specification, use that!
      else
        new_item = GCKI_lib.item.item(new)
      end

      -- Remove old ingredient
      GCKI_lib.recipe.remove_difficulty_ingredient(recipe, difficulty, old)
      -- Add new ingredient
      GCKI_lib.recipe.add_difficulty_ingredient(recipe, difficulty, new_item)

      retval = true
    end

  else
    if not recipe then
      GCKI.writeDebug("Recipe %s does not exist.", {recipe_in})
    end
    if not new_type then
      GCKI.writeDebug("Ingredient %s does not exist.", {new})
    end
  end

  GCKI.entered_function("leave")
  return retval
end


-- Modified by Pi-C
function GCKI_lib.recipe.replace_ingredient(recipe, old, new)
  GCKI.entered_function({recipe, old, new})

  if recipe and old and new then
    GCKI_lib.recipe.replace_difficulty_ingredient(recipe, "", old, new)
    GCKI_lib.recipe.replace_difficulty_ingredient(recipe, "normal", old, new)
    GCKI_lib.recipe.replace_difficulty_ingredient(recipe, "expensive", old, new)
  else
    if not recipe then
      GCKI.writeDebug("No recipe!")
    end
    if not old then
      GCKI.writeDebug("No old ingredient to replace!")
    end
    if not new then
      GCKI.writeDebug("No new ingredient!")
    end
  end

  GCKI.entered_function("leave")
end


-- Modified by Pi-C
function GCKI_lib.recipe.replace_ingredient_in_all(old, new)
  GCKI.entered_function({old, new})

  if new and GCKI_lib.item.get_basic_type(new) then
    for r, recipe in pairs(data.raw.recipe) do
      GCKI.writeDebug("Recipe \"%s\": Trying to replace ingredient \"%s\" with \"%s\"",
                      {r, old and old.name or old or "nil", new and new.name or new or "nil"})
      GCKI_lib.recipe.replace_ingredient(recipe.name, old, new)
    end
  else
    GCKI.writeDebug("%s is not a valid ingredient!", {new})
  end

  GCKI.entered_function("leave")
end


------------------------------------------------------------------------------------
--                                 Set ingredients                                --
------------------------------------------------------------------------------------
-- If the item is used in the recipe, it will be overwritten (new amount)
-- Added by Pi-C
function GCKI_lib.recipe.set_difficulty_ingredient(recipe_in, difficulty, item_in)
  GCKI.entered_function({recipe_in, difficulty, item_in})

  -- Sanitize arguments
  GCKI_lib.functions.check_difficulty(difficulty)
  local recipe = GCKI_lib.functions.check_recipe(recipe_in)
  local item = GCKI_lib.item.item(item_in)

  local ret

  if recipe and item and GCKI_lib.item.get_type(item.name) then
    if difficulty == "" then
      ret = GCKI_lib.item.set(recipe.ingredients, item)
    else
      if not recipe[difficulty] then
        GCKI_lib.recipe.difficulty_split(recipe.name)
      end
      ret = GCKI_lib.item.set(recipe[difficulty].ingredients, item)
    end

  else
    if not recipe then
      GCKI.writeDebug("Recipe %s does not exist.", {recipe_in})
    end
    if not GCKI_lib.item.get_basic_type(item.name) then
      GCKI.writeDebug("%s is not a valid ingredient.", {item_in})
    end
  end

  GCKI.entered_function("leave")
  return ret
end

-- Modified by Pi-C
function GCKI_lib.recipe.set_ingredient(recipe, item)
  GCKI.entered_function({recipe, item})

  if recipe and item then
    GCKI_lib.recipe.set_difficulty_ingredient(recipe, "", item)
    GCKI_lib.recipe.set_difficulty_ingredient(recipe, "normal", item)
    GCKI_lib.recipe.set_difficulty_ingredient(recipe, "expensive", item)
  else
    if not recipe then
      GCKI.writeDebug("No recipe!")
    end
    if not item then
      GCKI.writeDebug("No ingredient!")
    end
  end

  GCKI.entered_function("leave")
end



------------------------------------------------------------------------------------
------------------------------------------------------------------------------------
--                              Functions for results                             --
------------------------------------------------------------------------------------
------------------------------------------------------------------------------------


------------------------------------------------------------------------------------
--                                   Add result                                   --
------------------------------------------------------------------------------------
-- Modified by Pi-C
-- TODO: Check whether main_product must be set (#results > 1 and no subgroup)
function GCKI_lib.recipe.add_difficulty_result(recipe_in, difficulty, item_in)
  GCKI.entered_function({recipe_in, difficulty, item_in})
  -- Sanitize arguments
  GCKI_lib.functions.check_difficulty(difficulty)
  local recipe = GCKI_lib.functions.check_recipe(recipe_in)
  local item = GCKI_lib.item.item(item_in)

  local ret

  if recipe and item and GCKI_lib.item.get_type(item.name) then
    if difficulty == "" then
      GCKI_lib.recipe.result_check(recipe)
      ret = GCKI_lib.item.add(recipe.results, item)
    else
      if not recipe[difficulty] then
        GCKI_lib.recipe.difficulty_split(recipe)
      end
      GCKI_lib.recipe.result_check(recipe[difficulty])
      ret = GCKI_lib.item.add(recipe[difficulty].results, item)
    end
  else
    if not recipe then
      GCKI.writeDebug("Recipe %s does not exist.", {recipe_in})
    end
    if not GCKI_lib.item.get_basic_type(item.name) then
      GCKI.writeDebug("Item %s does not exist.", {item_in})
    end
  end

  GCKI.entered_function("leave")
  return ret
end


-- Modified by Pi-C
function GCKI_lib.recipe.add_result(recipe, item)
  GCKI.entered_function({recipe, item})

  if recipe and item then
    GCKI_lib.recipe.add_difficulty_result(recipe, "", item)
    GCKI_lib.recipe.add_difficulty_result(recipe, "normal", item)
    GCKI_lib.recipe.add_difficulty_result(recipe, "expensive", item)
  else
    if not recipe then
      GCKI.writeDebug("No recipe!")
    end
    if not item then
      GCKI.writeDebug("No ingredient!")
    end
  end

  GCKI.entered_function("leave")
end


------------------------------------------------------------------------------------
--                                 Replace results                                --
------------------------------------------------------------------------------------
-- Added by Pi-C
-- If the old item is a result, remove it and add the new item instead.
function GCKI_lib.recipe.replace_difficulty_result(recipe_in, difficulty, old, new)
  GCKI.entered_function({recipe_in, difficulty, old, new})

  -- Sanitize arguments
  GCKI_lib.functions.check_difficulty(difficulty)
  local recipe = GCKI_lib.functions.check_recipe(recipe_in)

  local old_name = (type(old) == "string") and old or
                    (type(old) == "table") and old.name or
                    error(string.format("\"%s\" is not a valid value for old result!", old))
  local new_name = (type(new) == "string") and new or
                    (type(new) == "table") and new.name or
                    error(string.format("\"%s\" is not a valid value for new result!", old))

  -- Will be "item" or "fluid"
  local new_type = GCKI_lib.item.get_basic_type(new_name)
  local old_type

  --~ local result, results, main_product, diff_results
  local result, results
  local retval = false

  if recipe and old_name and new_name then
    --~ results = BI_Functions.lib.get_difficulty_recipe_results(recipe_in, difficulty)
    results = GCKI_lib.recipe.get_difficulty_recipe_results(recipe_in, difficulty)

    -- Check whether recipe has old result
    if results and results[old_name] then

      old_type = results[old_name].type

      -- Set main_product, if necessary
      if difficulty == "" and recipe.main_product == old_name then
        recipe.main_product = new_name
      elseif difficulty ~= "" and recipe[difficulty].main_product == old_name then
        recipe[difficulty].main_product = new_name
      end

      -- Remove old result
      GCKI_lib.recipe.remove_difficulty_result(recipe, difficulty, old_name)

      -- Add new result
      result = table.deepcopy(results[old_name])
      result.name = new_name
      result.type = new_type

      -- Result "new" is just a string, use data from old result!
      if (type(new) == "string") then
        -- Switch from "fluid" to "item"
        if old_type == "fluid" and new_type == "item" then
          result.amount = result.amount and math.ceil(result.amount * 0.1)
          result.amount_min = result.amount_min and math.ceil(result.amount_min * 0.1)
          result.amount_max = result.amount_max and math.ceil(result.amount_max * 0.1)
          result.catalyst_amount = result.catalyst_amount and math.ceil(result.catalyst_amount * 0.1)

          result.temperature = nil
          result.fluidbox_index = nil

        -- Switch from "item" to "fluid"
        elseif old_type == "item" and new_type == "fluid" then
          result.amount = result.amount and math.ceil(result.amount * 10)
          result.amount_min = result.amount_min and math.ceil(result.amount_min * 10)
          result.amount_max = result.amount_max and math.ceil(result.amount_max * 10)
          result.catalyst_amount = result.catalyst_amount and math.ceil(result.catalyst_amount * 10)
        end

      -- Result "new" is an item
      else
        result.type = new_type
        result.amount = new.amount
        result.amount_min = new.amount_min
        result.amount_max = new.amount_max
        result.catalyst_amount = new.catalyst_amount
        result.probability = new.probability
        result.temperature = new.temperature
        result.fluidbox_index = new.fluidbox_index
      end

      -- Add new result!
      GCKI_lib.recipe.add_difficulty_result(recipe, difficulty, result)
      retval = true
    end
  else
    if not recipe then
      GCKI.writeDebug("Recipe %s does not exist.", {recipe_in})
    end
    if not new_type then
      GCKI.writeDebug("Result %s does not exist.", {new})
    end
  end

  GCKI.entered_function("leave")
  return retval
end


-- Added by Pi-C
function GCKI_lib.recipe.replace_result(recipe, old, new)
  GCKI.entered_function({recipe, old, new})

  recipe = type(recipe) == "table" and recipe.type == "recipe" and recipe or data.raw.recipe[recipe]

  if recipe and old and new then
    GCKI_lib.recipe.replace_difficulty_result(recipe, "", old, new)
    GCKI_lib.recipe.replace_difficulty_result(recipe, "normal", old, new)
    GCKI_lib.recipe.replace_difficulty_result(recipe, "expensive", old, new)

  else
    if not recipe then
      GCKI.writeDebug("No recipe!")
    end
    if not old then
      GCKI.writeDebug("No old result to replace!")
    end
    if not new then
      GCKI.writeDebug("No new result!")
    end
  end

  GCKI.entered_function("leave")
end


-- Added by Pi-C
function GCKI_lib.recipe.replace_result_in_all(old, new)
  GCKI.entered_function({old, new})

  --~ if new and GCKI_lib.item.get_basic_type(new) then
  if old and new and GCKI_lib.item.get_basic_type(new) then
    for i, recipe in pairs(data.raw.recipe) do
      GCKI_lib.recipe.replace_result(recipe, old, new)
    end
  else
    GCKI.writeDebug("%s is not a valid result!", {new})
  end

  GCKI.entered_function("leave")
end



------------------------------------------------------------------------------------
--                                  Remove result                                 --
------------------------------------------------------------------------------------
-- Modified by Pi-C
-- TODO: Check whether a new main_product is needed!
function GCKI_lib.recipe.remove_difficulty_result(recipe_in, difficulty, item_name)
  GCKI.entered_function({recipe_in, difficulty, item_name})

  -- Sanitize arguments
  GCKI_lib.functions.check_difficulty(difficulty)
  local recipe = GCKI_lib.functions.check_recipe(recipe_in)

  local ret

  if recipe and item_name then
    if difficulty == "" then
      GCKI_lib.recipe.result_check(recipe)
      ret = GCKI_lib.item.remove(recipe.results, item_name)
    else
      if not recipe[difficulty] then
        GCKI_lib.recipe.difficulty_split(recipe)
      end
      GCKI_lib.recipe.result_check(recipe[difficulty])
      ret = GCKI_lib.item.remove(recipe[difficulty].results, item_name)
    end
  else
    if not recipe then
      GCKI.writeDebug("No recipe!")
    end
    if not item_name then
      GCKI.writeDebug("No item name!")
    end
  end

  GCKI.entered_function("leave")
  return ret
end

-- Modified by Pi-C
function GCKI_lib.recipe.remove_result(recipe, item)
  GCKI.entered_function({recipe, item})

  if recipe and item then
    GCKI_lib.recipe.remove_difficulty_result(recipe, "", item)
    GCKI_lib.recipe.remove_difficulty_result(recipe, "normal", item)
    GCKI_lib.recipe.remove_difficulty_result(recipe, "expensive", item)
  else
    if not recipe then
      GCKI.writeDebug("No recipe!")
    end
    if not item then
      GCKI.writeDebug("No item!")
    end
  end

  GCKI.entered_function("leave")
end


------------------------------------------------------------------------------------
--                                   Set result                                   --
------------------------------------------------------------------------------------
-- If the item is used in the recipe, it will be overwritten (new amount)
-- Added by Pi-C
function GCKI_lib.recipe.set_difficulty_result(recipe_in, difficulty, item_in)
  GCKI.entered_function({recipe_in, difficulty, item_in})

  -- Sanitize arguments
  GCKI_lib.functions.check_difficulty(difficulty)
  local recipe = GCKI_lib.functions.check_recipe(recipe_in)
  local item = GCKI_lib.item.item(item_in)

  local ret

  if recipe and item and GCKI_lib.item.get_type(item.name) then
    if difficulty == "" then
      GCKI_lib.recipe.result_check(recipe)
      ret = GCKI_lib.item.set(recipe.results, item)
    else
      if not recipe[difficulty] then
        GCKI_lib.recipe.difficulty_split(recipe.name)
      end
      GCKI_lib.recipe.result_check(recipe[difficulty])
      ret = GCKI_lib.item.set(recipe[difficulty].results, item)
    end

  else
    if not recipe then
      GCKI.writeDebug("Recipe %s does not exist.", {recipe_in})
    end
    if not GCKI_lib.item.get_basic_type(item.name) then
      GCKI.writeDebug("%s is not a valid result.", {item_in})
    end
  end

  GCKI.entered_function("leave")
  return ret
end


-- Modified by Pi-C
function GCKI_lib.recipe.set_result(recipe, item)
  GCKI.entered_function({recipe, item})

  if recipe and item then
    GCKI_lib.recipe.set_difficulty_result(recipe, "", item)
    GCKI_lib.recipe.set_difficulty_result(recipe, "normal", item)
    GCKI_lib.recipe.set_difficulty_result(recipe, "expensive", item)
  else
    if not recipe then
      GCKI.writeDebug("No recipe!")
    end
    if not item then
      GCKI.writeDebug("No item!")
    end
  end

  GCKI.entered_function("leave")
end


------------------------------------------------------------------------------------
--                                   Get result                                   --
------------------------------------------------------------------------------------
--~ -- Returns table with all results for a difficulty, or nil
--~ function GCKI_lib.recipe.get_difficulty_recipe_results(recipe_in, difficulty)
  --~ GCKI.entered_function({recipe_in, difficulty})

  --~ -- Sanitize arguments
  --~ GCKI_lib.functions.check_difficulty(difficulty)
  --~ local recipe = GCKI_lib.functions.check_recipe(recipe_in)
--~ GCKI.show("recipe", GCKI.argprint(recipe))
  --~ local ret = {}

  --~ if recipe then
    --~ local name, amount, amount_min, amount_max, catalyst_amount, probability
    --~ local results, crafting_time

    --~ -- Get results for difficulty
    --~ if difficulty == "" then
      --~ GCKI_lib.recipe.result_check(recipe)
      --~ results = recipe.results
      --~ crafting_time = recipe.energy_required or 0.5
    --~ else
      --~ if not recipe[difficulty] then
        --~ GCKI_lib.recipe.difficulty_split(recipe)
      --~ end
      --~ GCKI_lib.recipe.result_check(recipe[difficulty])
      --~ results = recipe[difficulty].results
      --~ crafting_time = recipe[difficulty].energy_required or 0.5
    --~ end

    --~ -- Cumulate results in case the same result is used several times
    --~ for r, result in ipairs(results or {}) do
      --~ name = result[1] or result.name
      --~ amount = result[2] or result.amount

      --~ if name then
        --~ ret[name] = ret[name] or {
          --~ name                          = name,
          --~ type                          = result.type or "item",
          --~ amount                        = 0,
          --~ amount_min                    = 0,
          --~ amount_max                    = 0,
          --~ catalyst_amount               = 0,
          --~ probability                   = 0,

          --~ -- We'll need this to calculate average values
          --~ cnt                   = 0,
          --~ min_max_cnt           = 0
        --~ }

        --~ -- amount has precedence over amount_min/amount_max!
        --~ if amount and amount > 0 then
          --~ ret[name].amount                = ret[name].amount + amount
        --~ -- amount_max must be >= amount_min!
        --~ else
          --~ amount_min = result.amount_min
          --~ amount_max = result.amount_max

          --~ if amount_min or amount_max then
            --~ ret[name].min_max_cnt = ret[name].min_max_cnt + 1

            --~ if (not amount_max or amount_max < amount_min) then
              --~ amount_max =  amount_min
            --~ elseif not amount_min then
              --~ amount_min = amount_max
            --~ end
--~ GCKI.writeDebug("Result: %s\nname: %s\tamount: %s\tamount_min: %s\tamount_max: %s",
                  --~ {result, name, amount or "nil", amount_min or "nil", amount_max or "nil"})

            --~ ret[name].amount_min      = amount_min and (ret[name].amount_min + amount_min) or
                                                        --~ ret[name].amount_min
            --~ ret[name].amount_max      = amount_max and ret[name].amount_max + amount_max or
                                                        --~ ret[name].amount_max
          --~ end
        --~ end
        --~ ret[name].catalyst_amount   = ret[name].catalyst_amount + (tonumber(result.catalyst_amount) or 0)
        --~ ret[name].probability       = ret[name].probability + (tonumber(result.probability) or 1)

        --~ -- We only need this if it differs from the default value
        --~ if result.show_details_in_recipe_tooltip == false then
          --~ ret[name].show_details_in_recipe_tooltip = false
        --~ end

        --~ ret[name].cnt               = ret[name].cnt + 1
      --~ end
    --~ end

    --~ -- Prepare the final list
    --~ for r, result in pairs(ret) do

      --~ -- Multiplication is faster than division!
      --~ result.cnt = result.cnt > 0 and 1/result.cnt or 1
      --~ result.min_max_cnt = result.min_max_cnt > 0 and 1/result.min_max_cnt

      --~ result.amount             = tonumber(result.amount) and (result.amount > 0) and
                                    --~ result.amount or nil
      --~ -- Round up to next full number for values with x > y.5
      --~ -- (Either both or none of amount_min and amount_max exist!)
      --~ result.amount_min         = result.min_max_cnt and
                                    --~ math.floor(0.5 + (result.amount_min * result.min_max_cnt)) or
                                    --~ nil
      --~ result.amount_max         = result.min_max_cnt and
                                    --~ math.floor(0.5 + (result.amount_max * result.min_max_cnt)) or
                                    --~ nil

      --~ result.catalyst_amount    = result.catalyst_amount > 0 and
                                    --~ math.floor(0.5 + (result.catalyst_amount * result.cnt)) or nil
      --~ result.probability        = result.probability > 0 and result.probability ~= 1 and
                                    --~ math.floor(0.5 + (result.probability * result.cnt)) or nil

      --~ result.min_max_cnt, result.cnt = nil

      --~ result.amount_per_sec = result.amount and (result.amount / crafting_time) or
                              --~ ((result.amount_min or 0) + (result.amount_max or 0)) * 0.5 / crafting_time
    --~ end
  --~ end
--~ GCKI.show("ret", ret)

  --~ GCKI.entered_function("leave")
  --~ return ret
--~ end
-- Returns table with all results for a difficulty, or nil
function GCKI_lib.recipe.get_difficulty_recipe_results(recipe_in, difficulty)
  GCKI.entered_function({recipe_in, difficulty})

  -- Sanitize arguments
  GCKI_lib.functions.check_difficulty(difficulty)
  local recipe = GCKI_lib.functions.check_recipe(recipe_in)
GCKI.show("recipe", GCKI.argprint(recipe))
  local ret = {}

  if recipe then
    --~ local name, amount, amount_min, amount_max, catalyst_amount, probability
    local name, amount, amount_min, amount_max
    local results, crafting_time

    -- Get results for difficulty
    if difficulty == "" then
      results = GCKI_lib.recipe.result_check(recipe)
      --~ results = recipe.results
      crafting_time = recipe.energy_required or 0.5
    else
      --~ if not recipe[difficulty] then
        --~ GCKI_lib.recipe.difficulty_split(recipe)
      --~ end
      results = GCKI_lib.recipe.result_check(recipe[difficulty])
      --~ results = recipe[difficulty].results
      crafting_time = recipe[difficulty].energy_required or 0.5
    end
GCKI.show("results", results)
GCKI.show("crafting_time", crafting_time)

    -- Cumulate results in case the same result is used several times
    for r, result in ipairs(results or {}) do
      name = result[1] or result.name
      amount = result[2] or result.amount

      if name then
        ret[name] = ret[name] or {
          name                          = name,
          type                          = result.type or "item",
          amount                        = 0,
          amount_min                    = 0,
          amount_max                    = 0,
          catalyst_amount               = 0,
          probability                   = 0,

          -- We'll need this to calculate average values
          cnt                   = 0,
          min_max_cnt           = 0
        }

        -- amount has precedence over amount_min/amount_max!
        if amount and amount > 0 then
          ret[name].amount               = ret[name].amount + amount
        -- amount_max must be >= amount_min!
        else
          amount_min = result.amount_min
          amount_max = result.amount_max

          if amount_min or amount_max then
            ret[name].min_max_cnt = ret[name].min_max_cnt + 1

            if (not amount_max or amount_max < amount_min) then
              amount_max =  amount_min
            elseif not amount_min then
              amount_min = amount_max
            end
GCKI.writeDebug("Result: %s\nname: %s\tamount: %s\tamount_min: %s\tamount_max: %s",
                  {result, name, amount or "nil", amount_min or "nil", amount_max or "nil"})

            ret[name].amount_min      = amount_min and (ret[name].amount_min + amount_min) or
                                                        ret[name].amount_min
            ret[name].amount_max      = amount_max and ret[name].amount_max + amount_max or
                                                        ret[name].amount_max
          end
        end
        ret[name].catalyst_amount   = ret[name].catalyst_amount + (tonumber(result.catalyst_amount) or 0)
        ret[name].probability       = ret[name].probability + (tonumber(result.probability) or 1)

        -- We only need this if it differs from the default value
        if result.show_details_in_recipe_tooltip == false then
          ret[name].show_details_in_recipe_tooltip = false
        end

        ret[name].cnt               = ret[name].cnt + 1
      end
    end

    -- Prepare the final list
    for r, result in pairs(ret) do

      -- Multiplication is faster than division!
      result.cnt = result.cnt > 0 and 1/result.cnt or 1
      result.min_max_cnt = result.min_max_cnt > 0 and 1/result.min_max_cnt

      result.amount             = tonumber(result.amount) and (result.amount > 0) and
                                    result.amount or nil
      -- Round up to next full number for values with x > y.5
      -- (Either both or none of amount_min and amount_max exist!)
      result.amount_min         = result.min_max_cnt and
                                    math.floor(0.5 + (result.amount_min * result.min_max_cnt)) or
                                    nil
      result.amount_max         = result.min_max_cnt and
                                    math.floor(0.5 + (result.amount_max * result.min_max_cnt)) or
                                    nil

      result.catalyst_amount    = result.catalyst_amount > 0 and
                                    math.floor(0.5 + (result.catalyst_amount * result.cnt)) or nil
      result.probability        = result.probability > 0 and result.probability ~= 1 and
                                    math.floor(0.5 + (result.probability * result.cnt)) or nil

      result.min_max_cnt, result.cnt = nil, nil

      result.amount_per_sec = result.amount and (result.amount / crafting_time) or
                              ((result.amount_min or 0) + (result.amount_max or 0)) * 0.5 / crafting_time
    end
  end
GCKI.show("ret", ret)

  GCKI.entered_function("leave")
  return ret
end


-- Returns table with all results for "normal", "expensive", or no difficulty
-- (in that order) or nil
--~ function GCKI_lib.recipe.get_recipe_results(recipe_in)
  --~ GCKI.entered_function({recipe_in})

  --~ local recipe = GCKI_lib.functions.check_recipe(recipe_in)

  --~ local ret
--~ GCKI.writeDebug("Get results for recipe %s", {recipe and recipe.name or "nil"})
  --~ if recipe then
    --~ -- If difficulty doesn't exist, it will be created from the raw recipe, so we don't
    --~ -- need to check recipe.results!
    --~ ret = GCKI_lib.recipe.get_difficulty_recipe_results(recipe, "normal") or
          --~ GCKI_lib.recipe.get_difficulty_recipe_results(recipe, "expensive")
  --~ end

  --~ GCKI.entered_function("leave")
  --~ return ret
--~ end
function GCKI_lib.recipe.get_recipe_results(recipe_in)
  GCKI.entered_function({recipe_in})

  local recipe = GCKI_lib.functions.check_recipe(recipe_in)
GCKI.show("recipe", GCKI.argprint(recipe))

  local ret = {}
  if recipe then
GCKI.writeDebug("Get results for %s", {GCKI.argprint(recipe)})
    ret[""]           = GCKI_lib.recipe.get_difficulty_recipe_results(recipe, "")
    ret["normal"]     = recipe.normal and
                        GCKI_lib.recipe.get_difficulty_recipe_results(recipe, "normal")
    ret["expensive"]  = recipe.expensive and
                        GCKI_lib.recipe.get_difficulty_recipe_results(recipe, "expensive")
  end

  GCKI.entered_function("leave")
  return ret
end


------------------------------------------------------------------------------------
--                        Check whether recipe has a result                       --
------------------------------------------------------------------------------------
-- Returns table with accumulated amount data for requested result or nil
function GCKI_lib.recipe.recipe_has_difficulty_result(recipe_in, difficulty, result_name)
  GCKI.entered_function({recipe_in, difficulty, result_name})

  -- Sanitize arguments
  GCKI_lib.functions.check_difficulty(difficulty)
  local recipe = GCKI_lib.functions.check_recipe(recipe_in)

  if type(result_name) ~= "string" then
    error(string.format("%s is not a valid result name!", result_name))
  end

  local ret

  if recipe then
    ret = GCKI_lib.recipe.get_difficulty_recipe_results(recipe, difficulty)
  end

  GCKI.entered_function("leave")
  return ret and ret[result_name]
end


-- Returns table with accumulated amount data for requested result or nil
function GCKI_lib.recipe.recipe_has_result(recipe_in, result_name)
  GCKI.entered_function({recipe_in, result_name})

  local recipe = GCKI_lib.functions.check_recipe(recipe_in)

  if type(result_name) ~= "string" then
    error(string.format("%s is not a valid result name!", result_name))
  end

  local ret

  if recipe then
    ret = GCKI_lib.recipe.get_recipe_results(recipe)
  end

  GCKI.entered_function("leave")
  return ret and ret[result_name]
end


------------------------------------------------------------------------------------
--                                 Get ingredients                                --
------------------------------------------------------------------------------------
function GCKI_lib.recipe.get_difficulty_recipe_ingredients(recipe_in, difficulty)
  GCKI.entered_function({recipe_in, difficulty})

  -- Sanitize arguments
  GCKI_lib.functions.check_difficulty(difficulty)
  local recipe = GCKI_lib.functions.check_recipe(recipe_in)

  local ret = {}
  local ingredients

  if recipe then
    if difficulty == "" then
      ingredients = recipe.ingredients
    else
      --~ if not recipe[difficulty] then
        --~ GCKI_lib.recipe.difficulty_split(recipe)
      --~ end
      ingredients = recipe[difficulty].ingredients
    end

    local name, amount, t_min, t_max
    for i, ingredient in ipairs(ingredients or {}) do

      name = ingredient.name or ingredient[1]
      amount = ingredient.amount or ingredient[2]
      if not (name and amount) then
        error(string.format("%s is not a valid recipe ingredient specification!",
                              serpent.line(ingredient)))
      end

      ret[name] = ret[name] or {
        name = name,
        type = ingredient.type or "item",
        amount = 0,
        catalyst_amount = 0,
        temperature = (ingredient.type == "fluid") and 0 or nil,
        minimum_temperature = (ingredient.type == "fluid") and 0 or nil,
        maximum_temperature = (ingredient.type == "fluid") and 0 or nil,
        cnt = 0,
        min_max_cnt = 0,
      }
      ret[name].amount = ret[name].amount + amount
      ret[name].catalyst_amount = ret[name].catalyst_amount + (ingredient.catalyst_amount or 0)
      ret[name].cnt = ret[name].cnt + 1

      -- Only for fluids!
      if ingredient.type == "fluid" then
        -- temperature will overwrite minimum_temperature/maximum_temperature
        if ingredient.temperature then
          ret[name].temperature = ret[name].temperature + ingredient.temperature

        -- No minimum temperature without maximum temperature (and vice versa)!
        elseif ingredient.minimum_temperature or ingredient.maximum_temperature then
          t_min = ingredient.minimum_temperature or ingredient.maximum_temperature
          t_max = ingredient.maximum_temperature or ingredient.minimum_temperature

          if t_min then
           if (t_max <= t_min) then
            ret[name].temperature = ret[name].temperature + t_min
            else
              ret[name].minimum_temperature = ret[name].minimum_temperature + t_min
              ret[name].maximum_temperature = ret[name].maximum_temperature + t_max
              ret[name].min_max_cnt = ret[name].min_max_cnt + 1
            end
          end
        end
        -- Use the first fluidbox_index we find!
        ret[name].fluidbox_index = ret[name].fluidbox_index or ingredient.fluidbox_index
      end
    end

    -- Prepare the final list
    for i_name, i_data in pairs(ret) do
      -- We only need to do this if there are any temperatures!
      if i_data.temperature or i_data.minimum_temperature then

        if (i_data.cnt > 0) then
          -- Average temperature
          i_data.temperature = i_data.temperature and i_data.temperature / i_data.cnt

          -- Only necessary if there are minimum/maximum temperatures
          if i_data.min_max_cnt > 0 then

            -- Average minimum/maximum temperatures
            i_data.min_max_cnt = (i_data.min_max_cnt > 0) and (1/i_data.min_max_cnt) or 1

            i_data.minimum_temperature = i_data.minimum_temperature * i_data.min_max_count
            i_data.maximum_temperature = i_data.maximum_temperature * i_data.min_max_count

            -- No temperature yet, keep minumum/maximum temperature?
            if not i_data.temperature then
              if i_data.maximum_temperature <= i_data.minimum_temperature then

                i_data.temperature = i_data.minimum_temperature
                i_data.minimum_temperature, i_data.maximum_temperature = nil, nil
              end
            -- Temperature already exists, add average of minimum/maximum temperature!
            elseif i_data.minimum_temperature then
              -- Account for unreasonable values
              if i_data.minimum_temperature and i_data.maximum_temperature and
                  i_data.maximum_temperature <= i_data.minimum_temperature then
                i_data.temperature = i_data.temperature + i_data.minimum_temperature
              -- Add average
              else
                i_data.temperature = (i_data.minimum_temperature + i_data.maximum_temperature) * 0.5
              end
              i_data.minimum_temperature, i_data.maximum_temperature = nil, nil
            end
          end
        end
      end

      -- Remove counters
      i_data.cnt, i_data.min_max_cnt = nil, nil
    end
  end
GCKI.show("ret", ret)

GCKI.entered_function("leave")
  return next(ret) and ret
end


function GCKI_lib.recipe.get_recipe_ingredients(recipe_in)
  GCKI.entered_function({recipe_in})

  local recipe = GCKI_lib.functions.check_recipe(recipe_in)

  --~ local ret
  --~ if recipe then
    --~ -- If difficulty doesn't exist, it will be created from the raw recipe, so we don't
    --~ -- need to check recipe.ingredients!
    --~ ret = GCKI_lib.recipe.get_difficulty_recipe_ingredients(recipe, "normal") or
          --~ GCKI_lib.recipe.get_difficulty_recipe_ingredients(recipe, "expensive")
  --~ end
  local ret = {}
  if recipe then
GCKI.writeDebug("Getting ingredients for %s", {GCKI.argprint(recipe)})
    ret[""]           = GCKI_lib.recipe.get_difficulty_recipe_ingredients(recipe, "")
    ret["normal"]     = recipe.normal and
                        GCKI_lib.recipe.get_difficulty_recipe_ingredients(recipe, "normal")
    ret["expensive"]  = recipe.expensive and
                        GCKI_lib.recipe.get_difficulty_recipe_ingredients(recipe, "expensive")
  end
GCKI.show("ret", ret)
  GCKI.entered_function("leave")
  return ret
end


------------------------------------------------------------------------------------
--               Check whether recipe is using a certain ingredient               --
------------------------------------------------------------------------------------
function GCKI_lib.recipe.recipe_has_difficulty_ingredient(recipe_in, difficulty, ingredient)
  GCKI.entered_function({recipe_in, difficulty, ingredient})

  -- Sanitize arguments
  GCKI_lib.functions.check_difficulty(difficulty)
  local recipe = GCKI_lib.functions.check_recipe(recipe_in)
  if type(ingredient) ~= "string" then
    error(string.format("%s is not a valid ingredient name!", ingredient))
  end

  local ret, ingredients
  if recipe then
    ingredients = GCKI_lib.recipe.get_difficulty_recipe_ingredients(recipe_in, difficulty)
    ret = ingredients and ingredients[ingredient]
  end

  GCKI.entered_function("leave")
  return ret
end


function GCKI_lib.recipe.recipe_has_ingredient(recipe_in, ingredient)
  GCKI.entered_function({recipe_in, ingredient})

  local recipe = GCKI_lib.functions.check_recipe(recipe_in)

  if type(ingredient) ~= "string" then
    error(string.format("%s is not a valid ingredient name!", ingredient))
  end

  local ret, ingredients

  if recipe then
    ingredients = GCKI_lib.recipe.get_recipe_ingredients(recipe.ingredients)
    ret = ingredients and ingredients[ingredient]
  end
--~ GCKI.show("Return", ret)

  GCKI.entered_function("leave")
  return ret
end


------------------------------------------------------------------------------------
--                    Convert recipe.result to recipe.results!                    --
------------------------------------------------------------------------------------
--~ function GCKI_lib.recipe.result_check(object)
  --~ GCKI.entered_function({object})

  --~ if object then
    --~ object.results = object.results or {}

    --~ if object.result then
      --~ local item = GCKI_lib.item.basic_item({name = object.result})

      --~ if object.result_count then
        --~ item.amount = object.result_count
        --~ object.result_count = nil
      --~ end

      --~ GCKI_lib.item.add_new(object.results, item)

      --~ if object.ingredients then  -- It's a recipe
        --~ if not object.main_product then
          --~ -- If we already have one, add the rest
          --~ if object.icon or object.subgroup or object.order or item.type ~= "item" then
            --~ if (not object.icon) and data.raw[item.type][item.name] and
                                      --~ data.raw[item.type][item.name].icon then
              --~ object.icon = data.raw[item.type][item.name].icon
              --~ object.icon_size = data.raw[item.type][item.name].icon_size

            --~ -- Make sure objects also have an icons definition
            --~ elseif not object.icons and data.raw[item.type][item.name] and
                                          --~ data.raw[item.type][item.name].icons and
                                          --~ -- Don't assume that an icon already exists,
                                          --~ -- it could be set later on!
                                          --~ data.raw[item.type][item.name].icon then
              --~ object.icons = {
                --~ {
                  --~ icon = data.raw[item.type][item.name].icon,
                  --~ icon_size = 64,
                  --~ icon_mipmaps = data.raw[item.type][item.name].icon_mipmaps
                --~ }
              --~ }
            --~ end
            --~ if not object.subgroup and data.raw[item.type][item.name] and
                                        --~ data.raw[item.type][item.name].subgroup then
              --~ object.subgroup = data.raw[item.type][item.name].subgroup
            --~ end
            --~ if not object.order and data.raw[item.type][item.name] and
                                      --~ data.raw[item.type][item.name].order then
              --~ object.order = data.raw[item.type][item.name].order
            --~ end

            --~ if data.raw[item.type][item.name] and
                --~ data.raw[item.type][item.name].main_product then
              --~ object.main_product = data.raw[item.type][item.name].main_product
            --~ end

          --~ -- Otherwise just use main_product as a cheap way to set them all.
          --~ else
            --~ object.main_product = object.result
          --~ end
        --~ end
      --~ end
      --~ object.result = nil
    --~ end

  --~ else
    --~ GCKI.writeDebug("%s does not exist.", {object})
  --~ end

  --~ GCKI.entered_function("leave")
--~ end
function GCKI_lib.recipe.result_check(object)
  GCKI.entered_function({object})

  if not object then
    GCKI.entered_function({}, "leave", "recipe or difficulty data")
    return
  end

  local ret

  -- If both result and results exist, the recipe will use results!
  if object.results then
GCKI.writeDebug("Using object.results!")
    ret = object.results

  elseif object.result then
GCKI.writeDebug("Using object.result!")
    local item = GCKI_lib.item.basic_item({name = object.result})
GCKI.show("item", item)
    if object.result_count then
      item.amount = object.result_count
    end
GCKI.show("item", item)
    ret = { item }

  else
GCKI.writeDebug("No result or results!")
    ret = {}
  end

  GCKI.entered_function("leave")
  return ret
end


------------------------------------------------------------------------------------
GCKI.entered_file("leave")
