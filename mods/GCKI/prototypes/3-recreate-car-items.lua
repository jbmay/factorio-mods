GCKI.entered_file()

------------------------------------------------------------------------------------
------------------------------------------------------------------------------------
--             Compatibility with "DMV Directional Movement Vehicles"             --
------------------------------------------------------------------------------------
------------------------------------------------------------------------------------


------------------------------------------------------------------------------------
-- For some car prototypes, DMV will create a spider-vehicle version and change   --
-- the place_result of the corresponding item. If DMV is added to an existing     --
-- game where the entities based on the car prototypes have already been built,   --
-- selecting the car-based entities will show no icon. We therefore must make a   --
-- copy of the old item that will place the original car prototype.               --
------------------------------------------------------------------------------------
local cars = data.raw.car
local items = data.raw["item-with-entity-data"]
local car, placed_by, to_place, new_item


for c_name, c in pairs(GCKI.vehicle_prototypes_map.car) do
GCKI.show("c_name", c_name)
  car = cars[c_name]
GCKI.show("car.placeable_by", car.placeable_by)
GCKI.show("car.placeable_by.item", car.placeable_by and car.placeable_by.item)
GCKI.show("car.name", car.name)
  placed_by = car.placeable_by and car.placeable_by.item or car.name
  to_place = items[placed_by] and items[placed_by].place_result
GCKI.show("placed_by", placed_by)
GCKI.show("to_place", to_place)

  if to_place then
    if to_place ~= placed_by then
      new_item = table.deepcopy(items[placed_by])
      new_item.name = "AD-GCKI-dummy-item_"..new_item.name
GCKI.show("new_item", GCKI.argprint(new_item))
      -- If Autodrive is active, the dummy item could already have been created!
      if items[new_item.name] then
        GCKI.writeDebug("Dummy item has already been created by Autodrive!")

      -- We must create the dummy item!
      else
        --~ new_item.name = "AD-GCKI-dummy-item_"..new_item.name
        new_item.place_result = car.name
        --~ new_item.flags = {"hidden"}
        new_item.hidden = true
        new_item.hidden_in_factoriopedia = true
        data:extend({new_item})
        GCKI.created_msg(new_item)
      end
    else
      GCKI.writeDebug("Item for %s already exists!", {GCKI.argprint(car)})
    end

  end
end

------------------------------------------------------------------------------------
GCKI.entered_file("leave")
