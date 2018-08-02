local BasePlugin = require "kong.plugins.base_plugin"

local CustomerIdentificationHandler = BasePlugin:extend()

CustomerIdentificationHandler.PRIORITY = 903

function CustomerIdentificationHandler:new()
  CustomerIdentificationHandler.super.new(self, "customer-identification")
end

function CustomerIdentificationHandler:access(conf)
  CustomerIdentificationHandler.super.access(self)

  return nil
end

return CustomerIdentificationHandler
