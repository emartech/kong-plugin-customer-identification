local BasePlugin = require "kong.plugins.base_plugin"

local CustomerIdentificationHandler = BasePlugin:extend()

CustomerIdentificationHandler.PRIORITY = 903

function CustomerIdentificationHandler:new()
  CustomerIdentificationHandler.super.new(self, "customer-identification")
end

function CustomerIdentificationHandler:access(conf)
  CustomerIdentificationHandler.super.access(self)

  if ngx.req.get_headers()['X-Suite-CustomerId'] then
    return nil
  end

  local customer_id = string.match(ngx.var.request_uri, '/api/v2/internal/(.-)/')
  if customer_id then
    ngx.req.set_header('X-Suite-CustomerId', customer_id)
    return nil
  end

  local customer_id = string.match(ngx.var.request_uri, '/api/services/customers/(.-)/')
  if customer_id then
    ngx.req.set_header('X-Suite-CustomerId', customer_id)
    return nil
  end

end

return CustomerIdentificationHandler
