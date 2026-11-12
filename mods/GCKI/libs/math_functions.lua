  GCKI.entered_file()


local calc = {}

------------------------------------------------------------------------------------
------------------------------------------------------------------------------------
--                        CALCULATIONS FOR PATHING/DRIVING                        --
------------------------------------------------------------------------------------
------------------------------------------------------------------------------------

calc.angle = function(posA, posB)
  GCKI.entered_function({posA, posB})

  local x1, y1 = posA.x, posA.y
  local x2, y2 = posB.x, posB.y
  -- +90 for factorio orientation
  local angle = (math.atan2(y2 - y1, x2 - x1) * 180/math.pi) + 90
  GCKI.show("angle", angle)

  return angle
end


calc.box_size = function(box)
  GCKI.entered_function({box})

  local lt = GCKI.normalize_position(box.left_top or box[1])
  local rb = GCKI.normalize_position(box.right_bottom or box[2])
  local w = rb.x - lt.x
  local h = rb.y - lt.y
--~ GCKI.show("w", w)
--~ GCKI.show("h", h)
--~ GCKI.show("max(w, h)", max(w, h))

  return math.max(w, h)
end
calc.box_width = function(box)
  GCKI.entered_function({box})

  local lt = GCKI.normalize_position(box.left_top or box[1])
  local rb = GCKI.normalize_position(box.right_bottom or box[2])
  local w = rb.x - lt.x
  local h = rb.y - lt.y
--~ GCKI.show("w", w)
--~ GCKI.show("h", h)
--~ GCKI.show("min(w, h)", min(w, h))

  return math.min(w, h)
end




------------------------------------------------------------------------------------
-- Function to measure distance between two positions
calc.get_distance = function(pos_a, pos_b)
  GCKI.entered_function({pos_a, pos_b})

  pos_a = GCKI.normalize_position(pos_a)
  pos_b = GCKI.normalize_position(pos_b)

  local x, y = pos_a.x - pos_b.x, pos_a.y - pos_b.y
  local distance = math.sqrt(x*x + y*y)
  GCKI.show("Distance", distance)

  --~ return sqrt(x*x + y*y)
  GCKI.entered_function("leave")
  return distance
end


------------------------------------------------------------------------------------
-- Return true if the distance between pos_a and pos_b is greater than max_distance
calc.distance_exceeds = function(pos_a, pos_b, max_distance)
  GCKI.entered_function({pos_a, pos_b, max_distance})

  return calc.get_distance(pos_a, pos_b) > max_distance
end


------------------------------------------------------------------------------------
GCKI.entered_file("leave")

return calc
