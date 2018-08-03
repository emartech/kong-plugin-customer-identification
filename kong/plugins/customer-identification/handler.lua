local BasePlugin = require "kong.plugins.base_plugin"

local CustomerIdentificationHandler = BasePlugin:extend()

CustomerIdentificationHandler.PRIORITY = 903

function CustomerIdentificationHandler:new()
    CustomerIdentificationHandler.super.new(self, "customer-identification")
end

local function match_customer_id_from_uri(pattern)
    local customer_id = string.match(ngx.var.request_uri, pattern)
    if customer_id then
        ngx.req.set_header('X-Suite-CustomerId', customer_id)
        return true
    end

    return false
end

function CustomerIdentificationHandler:access(conf)
    CustomerIdentificationHandler.super.access(self)

    if ngx.req.get_headers()['X-Suite-CustomerId'] then
        return nil
    end

    if match_customer_id_from_uri('/api/v2/internal/(.-)/') then
        return nil
    end

    if match_customer_id_from_uri('/api/services/customers/(.-)/') then
        return nil
    end

end

return CustomerIdentificationHandler
