local lqc = require 'src.quickcheck'
local p = require 'src.property'
local property = p.property

local function clear_properties()
  lqc.properties = {}
end


describe('quickcheck', function()
  before_each(clear_properties)

  describe('check function', function()
    it('should check every successful property X amount of times', function()
      local x, prop_amount = 0, 5
      for _ = 1, prop_amount do
        property 'test property' {
          generators = {},
          check = function()
            x = x + 1
            return true
          end
        }
      end

      lqc.check()
      local expected = prop_amount * 100
      assert.equal(expected, x)
    end)

    it('should continue to check if a constraint of property is not met', function()
      local x = 0
      property 'test property' {
        generators = {},
        check = function() return true end,
        implies = function()
          x = x + 1
          return false
        end
      }

      lqc.check()
      local expected = lqc.iteration_amount
      assert.equal(expected, x)
    end)

    it('should stop checking a property after a failure', function()
      local x, iterations = 0, 10
      property 'test property' {
        generators = {},
        check = function()
          x = x + 1
          return x < iterations
        end
      }
      lqc.check()
      local expected = iterations
      assert.equal(expected, x)
    end)
  end)
end)

