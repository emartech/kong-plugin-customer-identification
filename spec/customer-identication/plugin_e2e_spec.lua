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
    local route = get_response_body(TestHelper.setup_route_for_service(service.id, '/anything'))
    local plugin = get_response_body(TestHelper.setup_plugin_for_service(service.id, 'customer-identification', conf))
    local consumer = get_response_body(TestHelper.setup_consumer('TestUser'))
    return service, route, plugin, consumer
end

describe("Plugin: customer-identification (access) #e2e", function()

    setup(function()
        helpers.start_kong({ custom_plugins = 'customer-identification' })
    end)

    teardown(function()
        helpers.stop_kong(nil)
    end)

    describe("Customer Identification", function()

        context("when the target header and none of the source headers are present", function()
            local service, route, plugin, consumer
            local local_conf = {
                source_headers = { "x-suite-customerid" },
                uri_matchers = { "/anything/(.-)/" },
                target_header = "x-suite-customerid",
            }

            before_each(function()
                service, route, plugin, consumer = setup_test_env(local_conf)
            end)

            it("should match the target header value from the uri", function()
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

        context("when the target header is present", function()
            local service, route, plugin, consumer
            local local_conf = {
                source_headers = { "x-suite-customerid" },
                uri_matchers = { "/anything/(.-)/" },
                target_header = "anything",
            }

            before_each(function()
                service, route, plugin, consumer = setup_test_env(local_conf)
            end)

            it("should leave anything as is", function()
                local res = assert(helpers.proxy_client():send {
                    method = "GET",
                    path = "/anything/etc/",
                    headers = {
                        ["Host"] = "test1.com",
                        ["anything"] = "12345678"
                    }
                })

                local response = assert.res_status(200, res)
                local body = cjson.decode(response)

                assert.is_equal('12345678', body.headers["anything"])
            end)

        end)

        context("when the target header is not but one of the source headers is present", function()
            local service, route, plugin, consumer
            local local_conf = {
                source_headers = { "other-anything" },
                uri_matchers = { "/anything/(.-)/" },
                target_header = "anything",
            }

            before_each(function()
                service, route, plugin, consumer = setup_test_env(local_conf)
            end)

            it("should map the source header value to the target header", function()
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
                assert.is_equal('23456789', body.headers["anything"])
            end)

        end)

    end)

end)
