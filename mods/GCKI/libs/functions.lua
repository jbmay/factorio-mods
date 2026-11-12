GCKI_lib.functions = GCKI_lib.functions or {}

-- Make sure we've got a valid difficulty name!
GCKI_lib.functions.check_difficulty = function(difficulty)
  if difficulty ~= "" and difficulty ~= "normal" and difficulty ~= "expensive" then
    error(string.format("%s is not a valid difficulty!", difficulty))
  end
end

-- Get actual recipe data
GCKI_lib.functions.check_recipe = function(recipe)
  return (type(recipe) == "table" and recipe.type == "recipe" and recipe) or
          (recipe and data.raw.recipe[recipe])
end
