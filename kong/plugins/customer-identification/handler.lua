local BasePlugin = require "kong.plugins.base_plugin"

local CustomerIdentificationHandler = BasePlugin:extend()

CustomerIdentificationHandler.PRIORITY = 903

function CustomerIdentificationHandler:new()
    CustomerIdentificationHandler.super.new(self, "customer-identification")
end

function CustomerIdentificationHandler:access(conf)
    CustomerIdentificationHandler.super.access(self)

    local headers = kong.request.get_headers()

    if headers[conf['target_header']] then
        return nil
    end

    for _, source_header in ipairs(conf['source_headers']) do
        if headers[source_header] then
            kong.service.request.set_header(conf['target_header'], headers[source_header])
            return nil
        end
    end

    local customer_id = kong.request.get_query()[conf['source_query_parameter']]
    if customer_id then
        kong.service.request.set_header(conf['target_header'], customer_id)
        return nil
    end

    for _, pattern in ipairs(conf['uri_matchers']) do
        local customer_id = string.match(ngx.var.request_uri, pattern)
        if customer_id then
            kong.service.request.set_header(conf['target_header'], customer_id)
            return nil
        end
    end

    return nil
end

return CustomerIdentificationHandler
