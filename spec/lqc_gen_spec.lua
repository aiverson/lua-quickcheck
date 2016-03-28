local random = require 'src.random'
local r = require 'src.report'
local p = require 'src.property'
local property = p.property
local lqc_gen = require 'src.lqc_gen'
local lqc = require 'src.quickcheck'

local function do_setup()
  random.seed()
  lqc.properties = {}
  r.report = function() end
end


describe('choose', function()
  before_each(do_setup)

  it('chooses a number between min and max', function()
    local min1, max1 = 569, 1387
    local spy_check_pos = spy.new(function(x) 
      return x >= min1 and x <= max1
    end)
    property 'chooses a number between min and max (positive integers)' {
      generators = { lqc_gen.choose(min1, max1) },
      check = spy_check_pos
    }

    local min2, max2 = -1337, -50
    local spy_check_neg = spy.new(function(x) 
      return x >= min2 and x <= max2
    end)
    property 'chooses a number between min and max (negative integers)' {
      generators = { lqc_gen.choose(min2, max2) },
      check = spy_check_neg
    }

    lqc.check()
    assert.spy(spy_check_pos).was.called(lqc.iteration_amount)
    assert.spy(spy_check_neg).was.called(lqc.iteration_amount)
  end)

  it('shrinks the generated value towards the value closest to 0', function()
    local min1, max1 = 5, 10
    local shrunk_value1 = nil
    r.report_failed = function(_, _, shrunk_vals)
      shrunk_value1 = shrunk_vals[1]
    end
    property 'shrinks the generated value towards min value (positive integers)' {
    generators = { lqc_gen.choose(min1, max1) },
      check = function(x)
        return x < min1  -- always false
      end
    }

    lqc.check()
    assert.same(min1, shrunk_value1)

    lqc.properties = {}
    local min2, max2 = -999, -333
    local shrunk_value2 = nil
    r.report_failed = function(_, _, shrunk_vals)
      shrunk_value2 = shrunk_vals[1]
    end
    property 'shrinks the generated value towards min value (negative integers)' {
      generators = { lqc_gen.choose(min2, max2) },
      check = function(x)
        return x < min2  -- always false
      end
    }

    lqc.check()
    assert.same(max2, shrunk_value2)
  end)
end)

describe('oneof', function()
  before_each(do_setup)

  it('chooses a generator from a list of generators', function()
    local min1, max1, min2, max2 = 1, 10, 11, 20
    local shrunk_value = nil
    r.report_failed = function(_, _, shrunk_vals)
      shrunk_value = shrunk_vals[1]
    end
    local spy_check = spy.new(function(x)
      return x <= max1  -- only succeeds for 1st generator
    end)
    property 'oneof chooses a generator from a list of generators' {
      generators = { 
        lqc_gen.oneof { 
          lqc_gen.choose(min1, max1), 
          lqc_gen.choose(min2, max2) 
        } 
      },
      check = spy_check
    }

    lqc.check()
    assert.is_same(min2, shrunk_value)
    assert.spy(spy_check).was.not_called(lqc.iteration_amount)
  end)

  it('chooses the same generator each time if only 1 is supplied.', function() 
    local min, max = 1, 10
    local spy_check = spy.new(function(x)
      return x <= max
    end)
    property 'oneof chooses a generator from a list of generators' {
      generators = { 
        lqc_gen.oneof { 
          lqc_gen.choose(min, max), 
        } 
      },
      check = spy_check
    }

    lqc.check()
    assert.spy(spy_check).was.called(lqc.iteration_amount)
  end)

  it('shrinks one of the generated values from the supplied list of generators', function()
    local which_gen, shrunk_value = nil, nil
    local spy_shrink1 = spy.new(function() return 1 end)
    local spy_shrink2 = spy.new(function() return 2 end)

    local function gen_1()
      local gen = {}
      function gen.pick(_) which_gen = 1; return 1 end
      gen.shrink = spy_shrink1
      return gen
    end
    local function gen_2()
      local gen = {}
      function gen.pick(_) which_gen = 2; return 2 end
      gen.shrink = spy_shrink2
      return gen
    end
    r.report_failed = function(_, _, shrunk_vals)
      shrunk_value = shrunk_vals[1]
    end
    
    property 'oneof shrinks generated value with correct generator' {
      generators = {
        lqc_gen.oneof {
          gen_1(),
          gen_2()
        }
      },
      check = function(_)
        return false
      end
    }

    for _ = 1, 10 do
      lqc.check()
      assert.not_equal(nil, which_gen)
      assert.not_equal(nil, shrunk_value)
      assert.equal(which_gen, shrunk_value)
    end

    assert.spy(spy_shrink1).was.called()
    assert.spy(spy_shrink2).was.called()
  end)
end)
