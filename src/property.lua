local lqc = require 'src.quickcheck'

-- NOTE: property is limited to 1 implies, for_all, when_fail
-- more complex scenarios should be handled with state machine.

local lib = {}


-- List of possible results after executing property
lib.results = {
  SUCCESS = 1,  -- property succeeded
  FAILURE = 2,   -- property failed
  SKIPPED = 3   -- property skipped (implies predicate not met)
}


-- Adds a small wrapper around the check function indicating success or failure
local function add_check_wrapper(prop_table)
  local check_func = prop_table.check
  prop_table.check = function(...)
    if check_func(...) then
      return lib.results.SUCCESS
    else
      return lib.results.FAILURE
    end
  end
end


-- Adds an 'implies' wrapper to the check function
local function add_implies(prop_table)
  local check_func = prop_table.check
  prop_table.check = function(...)
    if prop_table.implies(...) == false then
      return lib.results.SKIPPED
    end

    return check_func(...)
  end
end


-- Adds a 'when_fail' wrapper to the check function
local function add_when_fail(prop_table)
  local check_func = prop_table.check
  prop_table.check = function(...)
    local result = check_func(...)
    
    if result == lib.results.FAILURE then
      prop_table.when_fail(...)
    end

    return result
  end
end


-- Creates a new property. 
local function new(descr, func, gens)
  local prop = {
    description = descr,
    prop_func = func,
    generators = gens
  }

  -- TODO setfenv on prop_func
  return setmetatable(prop, { 
    __call = function(self)
      return self.prop_func(self.generators)
    end 
  })
end


-- Inserts the property into the list of existing properties.
function lib.property(descr)
  local function prop_func(prop_table)
    if not prop_table.generators then
      error('Need to supply generators in property!')
    end
 
    if type(prop_table.check) ~= 'function' then
      error('Need to provide a check function to property!')
    end

    add_check_wrapper(prop_table)

    if type(prop_table.implies) == 'function' then
      add_implies(prop_table)
    end

    if type(prop_table.when_fail) == 'function' then
      add_when_fail(prop_table)
    end

    local new_prop = new(descr, prop_table.check, prop_table.generators)
    table.insert(lqc.properties, new_prop)
  end

  return prop_func
end


return lib

