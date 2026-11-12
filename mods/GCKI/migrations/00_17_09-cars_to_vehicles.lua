-- Make sure that GCKI really exists! (If a tutorial from Tips and Tricks is started,
-- the migration will be applied to a mod named "level" and none of our global
-- variables will be defined.)
GCKI = GCKI or require('__gcki-continued__.common')()
GCKI.entered_file()

------------------------------------------------------------------------------------
-- Migrate storage.cars{} to storage.vehicles{} (table was renamed in GCKI 0.17.8).
------------------------------------------------------------------------------------

if storage.cars and not storage.vehicles then
  storage.vehicles = table.deepcopy(storage.cars)
  storage.cars = nil

  GCKI.writeDebug("Renamed variable \"storage.cars\" to \"storage.vehicles\".")
end


------------------------------------------------------------------------------------
GCKI.entered_file("leave")
