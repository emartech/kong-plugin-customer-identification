local helpers = require "spec.helpers"
local cjson = require "cjson"
local TestHelper = require "spec.test_helper"

local function get_response_body(response)
  local body = assert.res_status(201, response)
  return cjson.decode(body)
end

local function setup_test_env()
  helpers.dao:truncate_tables()

  local service = get_response_body(TestHelper.setup_service())
  local route_internal = get_response_body(TestHelper.setup_route_for_service(service.id, '/api/v2/internal'))
  local route_services = get_response_body(TestHelper.setup_route_for_service(service.id, '/api/services/customers'))
  local route_custom = get_response_body(TestHelper.setup_route_for_service(service.id, '/custom-service'))
  local plugin = get_response_body(TestHelper.setup_plugin_for_service(service.id, 'customer-identification'))
  local consumer = get_response_body(TestHelper.setup_consumer('TestUser'))
  return service, route_internal, route_services, route_custom, plugin, consumer
end

describe("Plugin: customer-identification (access) #e2e", function()

  setup(function()
    helpers.start_kong({ custom_plugins = 'customer-identification' })
  end)

  teardown(function()
    helpers.stop_kong(nil)
  end)

  describe("Customer Identification", function()
    local service, route_internal, route_services, route_custom, plugin, consumer

    before_each(function()
      service, route_internal, route_services, route_custom, plugin, consumer = setup_test_env()
    end)

    context("when X-Suite-CustomerId header is not present", function()
      it("should be set if customer id can be found in v2 internal request path", function()
        local res = assert(helpers.proxy_client():send {
          method = "GET",
          path = "/api/v2/internal/12345678/",
          headers = {
            ["Host"] = "test1.com"
          }
        })

        local response = assert.res_status(200, res)
        local body = cjson.decode(response)

        assert.is_equal('12345678', body.headers["x-suite-customerid"])
      end)

      it("should be set if customer id can be found in services request path", function()
        local res = assert(helpers.proxy_client():send {
          method = "GET",
          path = "/api/services/customers/12345678/",
          headers = {
            ["Host"] = "test1.com"
          }
        })

        local response = assert.res_status(200, res)
        local body = cjson.decode(response)

        assert.is_equal('12345678', body.headers["x-suite-customerid"])
      end)
    end)

    context("when X-Suite-CustomerId header is present", function()
      it("should not be set if customer id can be found in the headers", function()
        local res = assert(helpers.proxy_client():send {
          method = "GET",
          path = "/custom-service/",
          headers = {
            ["Host"] = "test1.com",
            ["X-Suite-CustomerId"] = "23456789"
          }
        })

        local response = assert.res_status(200, res)
        local body = cjson.decode(response)

        assert.is_equal('23456789', body.headers["x-suite-customerid"])
      end)
    end)

  end)

end)
