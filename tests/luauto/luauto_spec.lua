describe("The `luauto` module", function()
  it("returns a table that can access its submodules", function()
    local luauto = require "luauto"
    assert.is_truthy(luauto.cmd)
    assert.is_truthy(luauto.group)
    assert.is_truthy(luauto.event)
  end)
end)
