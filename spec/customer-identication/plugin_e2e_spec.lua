local helpers = require "spec.helpers"
local cjson = require "cjson"
local TestHelper = require "spec.test_helper"

local function get_response_body(response)
    local body = assert.res_status(201, response)
    return cjson.decode(body)
end

local function setup_test_env(conf)
    helpers.dao:truncate_tables()

    local service = get_response_body(TestHelper.setup_service())
    local route_anything = get_response_body(TestHelper.setup_route_for_service(service.id, '/anything'))
    local route_internal = get_response_body(TestHelper.setup_route_for_service(service.id, '/api/v2/internal'))
    local route_services = get_response_body(TestHelper.setup_route_for_service(service.id, '/api/services/customers'))
    local route_custom = get_response_body(TestHelper.setup_route_for_service(service.id, '/custom-service'))
    local plugin = get_response_body(TestHelper.setup_plugin_for_service(service.id, 'customer-identification', conf))
    local consumer = get_response_body(TestHelper.setup_consumer('TestUser'))
    return service, route_anything, route_internal, route_services, route_custom, plugin, consumer
end

describe("Plugin: customer-identification (access) #e2e", function()
    local default_conf = {
        source_headers = { "x-suite-customerid" },
        uri_matchers = { "/api/v2/internal/(.-)/", "/api/services/customers/(.-)/" },
        target_header = "x-suite-customerid",
    }

    setup(function()
        helpers.start_kong({ custom_plugins = 'customer-identification' })
    end)

    teardown(function()
        helpers.stop_kong(nil)
    end)

    describe("Customer Identification", function()

        context("when X-Suite-CustomerId header is not present", function()
            local service, route_anything, route_internal, route_services, route_custom, plugin, consumer

            before_each(function()
                service, route_anything, route_internal, route_services, route_custom, plugin, consumer = setup_test_env(default_conf)
            end)

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
            local service, route_anything, route_internal, route_services, route_custom, plugin, consumer

            before_each(function()
                service, route_anything, route_internal, route_services, route_custom, plugin, consumer = setup_test_env(default_conf)
            end)

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

        context("when uri matchers are configured", function()
            local service, route_anything, route_internal, route_services, route_custom, plugin, consumer
            local local_conf = {
                source_headers = { "x-suite-customerid" },
                uri_matchers = { "/anything/(.-)/" },
                target_header = "x-suite-customerid",
            }

            before_each(function()
                service, route_anything, route_internal, route_services, route_custom, plugin, consumer = setup_test_env(local_conf)
            end)

            it("should match the header value from the uri", function()
                local res = assert(helpers.proxy_client():send {
                    method = "GET",
                    path = "/anything/12345678/",
                    headers = {
                        ["Host"] = "test1.com"
                    }
                })

                local response = assert.res_status(200, res)
                local body = cjson.decode(response)

                assert.is_equal('12345678', body.headers["x-suite-customerid"])
            end)

        end)

        context("when target header is configured", function()
            local service, route_anything, route_internal, route_services, route_custom, plugin, consumer
            local local_conf = {
                source_headers = { "x-suite-customerid" },
                uri_matchers = { "/anything/(.-)/" },
                target_header = "anything",
            }

            before_each(function()
                service, route_anything, route_internal, route_services, route_custom, plugin, consumer = setup_test_env(local_conf)
            end)

            it("should set the target header value if any of the uri matcher's pattern matched", function()
                local res = assert(helpers.proxy_client():send {
                    method = "GET",
                    path = "/anything/12345678/",
                    headers = {
                        ["Host"] = "test1.com"
                    }
                })

                local response = assert.res_status(200, res)
                local body = cjson.decode(response)

                assert.is_equal('12345678', body.headers["anything"])
            end)

        end)

        context("when source headers are configured", function()
            local service, route_anything, route_internal, route_services, route_custom, plugin, consumer
            local local_conf = {
                source_headers = { "other-anything" },
                uri_matchers = { "/anything/(.-)/" },
                target_header = "anything",
            }

            before_each(function()
                service, route_anything, route_internal, route_services, route_custom, plugin, consumer = setup_test_env(local_conf)
            end)

            it("should not set the target header and leave the source header as is", function()
                local res = assert(helpers.proxy_client():send {
                    method = "GET",
                    path = "/anything/something/",
                    headers = {
                        ["Host"] = "test1.com",
                        ["other-anything"] = '23456789'
                    }
                })

                local response = assert.res_status(200, res)
                local body = cjson.decode(response)

                assert.is_equal('23456789', body.headers["other-anything"])
                assert.is_equal(nil, body.headers["anything"])
            end)

        end)

    end)

end)
