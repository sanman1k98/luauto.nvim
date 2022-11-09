describe("The `luauto.event` module", function()
  local auto = {
    event = require "luauto.event",
  }

  it("can be indexed by event names", function()
    assert.has_no.errors(function()
      local value = auto.event.BufEnter
    end)
    assert.has_no.errors(function()
      local value = auto.event.bufenter
    end)
    assert.has_no.errors(function()
      local value = auto.event["BufEnter"]
    end)
    assert.has_no.errors(function()
      local value = auto.event["bufenter"]
    end)
  end)

  describe("when indexed, returns a table", function()
    it("with a field `_event` containing the key used to retrieve it", function()
      local key = "BufEnter"
      local tbl = auto.event[key]
      assert.is_truthy(tbl._event)
      assert.is_equal(tbl._event, key)
    end)

    it("which can also be indexed", function()
      assert.has_no.errors(function()
        local value = auto.event.user.testing
      end)
    end)
  end)

  it("can be indexed like a 2D array with first and second keys being an event and pattern respectively", function()
    assert.has_no.errors(function()
      local value = auto.event.User.custom_event
    end)
    assert.has_no.errors(function()
      local value = auto.event["User"]["custom_event"]
    end)
  end)

  describe("", function()
  end)

  describe("", function()
  end)

end)
