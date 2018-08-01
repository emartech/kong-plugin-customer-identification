local BasePlugin = require "kong.plugins.base_plugin"

local CustomerIdentifyHandler = BasePlugin:extend()

CustomerIdentifyHandler.PRIORITY = 903

function CustomerIdentifyHandler:new()
  CustomerIdentifyHandler.super.new(self, "customer-identify")
end

function CustomerIdentifyHandler:access(conf)
  CustomerIdentifyHandler.super.access(self)

  return nil
end

return CustomerIdentifyHandler
