local cjson = require "cjson"
local helpers = require "spec.helpers"
local TestHelper = require "spec.test_helper"

local function get_response_body(response)
    local body = assert.res_status(201, response)
    return cjson.decode(body)
end

local function setup_test_env(conf)
    helpers.db:truncate()

    local service = get_response_body(TestHelper.setup_service())
    local route = get_response_body(TestHelper.setup_route_for_service(service.id, "/anything"))
    local plugin = get_response_body(TestHelper.setup_plugin_for_service(service.id, "customer-identification", conf))
    local consumer = get_response_body(TestHelper.setup_consumer("TestUser"))

    return service, route, plugin, consumer
end

describe("Plugin: customer-identification (access) #e2e", function()

    setup(function()
        helpers.start_kong({ plugins = "customer-identification" })
    end)

    teardown(function()
        helpers.stop_kong()
    end)

    describe("Customer Identification", function()

        context("plugin config", function()

            it("should not allow empty source_headers and uri_matchers", function()
                local res = assert(helpers.admin_client():send({
                    method = "POST",
                    path = "/plugins",
                    headers = {
                        ["Content-Type"] = "application/json"
                    },
                    body = {
                        name = "customer-identification",
                        config = {}
                    }
                }))

                local response = assert.res_status(400, res)

                assert.is_same({
                    ["config.target_header"] = "target_header is required"
                }, cjson.decode(response))
            end)

        end)

        context("when the target header and none of the source headers are present", function()
            local service, route, plugin, consumer
            local local_conf = {
                source_headers = { "x-suite-customerid" },
                uri_matchers = { "/anything/(.-)/" },
                target_header = "x-suite-customerid"
            }

            before_each(function()
                service, route, plugin, consumer = setup_test_env(local_conf)
            end)

            it("should match the target header value from the uri", function()
                local res = assert(helpers.proxy_client():send({
                    method = "GET",
                    path = "/anything/12345678/",
                    headers = {
                        ["Host"] = "test1.com"
                    }
                }))

                local response = assert.res_status(200, res)
                local body = cjson.decode(response)

                assert.is_equal("12345678", body.headers["x-suite-customerid"])
            end)

        end)

        context("when the target header is present", function()
            local service, route, plugin, consumer
            local local_conf = {
                source_headers = { "x-suite-customerid" },
                uri_matchers = { "/anything/(.-)/" },
                target_header = "anything"
            }

            before_each(function()
                service, route, plugin, consumer = setup_test_env(local_conf)
            end)

            it("should leave anything as is", function()
                local res = assert(helpers.proxy_client():send({
                    method = "GET",
                    path = "/anything/etc/",
                    headers = {
                        ["Host"] = "test1.com",
                        ["anything"] = "12345678"
                    }
                }))

                local response = assert.res_status(200, res)
                local body = cjson.decode(response)

                assert.is_equal("12345678", body.headers["anything"])
            end)

        end)

        context("when source_headers and uri_matchers both set", function()
            local service, route, plugin, consumer
            local local_conf = {
                source_headers = { "other-anything" },
                uri_matchers = { "/anything/(.-)/" },
                target_header = "anything"
            }

            before_each(function()
                service, route, plugin, consumer = setup_test_env(local_conf)
            end)

            context("and source header exists", function()

                it("should map value to the target header", function()
                    local res = assert(helpers.proxy_client():send({
                        method = "GET",
                        path = "/anything/something/",
                        headers = {
                            ["Host"] = "test1.com",
                            ["other-anything"] = "23456789"
                        }
                    }))

                    local response = assert.res_status(200, res)
                    local body = cjson.decode(response)

                    assert.is_equal("23456789", body.headers["other-anything"])
                    assert.is_equal("23456789", body.headers["anything"])
                end)

            end)

        end)

        context("when the target header is not present on request but source_query_parameter can be found in query string", function()
            local service, route, plugin, consumer
            local local_conf = {
                source_headers = { "other-header" },
                uri_matchers = {},
                target_header = "anything",
                source_query_parameter = "other_query_param"
            }

            before_each(function()
                service, route, plugin, consumer = setup_test_env(local_conf)
            end)

            context("and query parameter is present", function()

                it("should set the target header from query string", function()
                    local res = assert(helpers.proxy_client():send({
                        method = "GET",
                        path = "/anything/something?other_query_param=23456789",
                        headers = {
                            ["Host"] = "test1.com"
                        }
                    }))

                    local response = assert.res_status(200, res)
                    local body = cjson.decode(response)

                    assert.is_equal("23456789", body.headers["anything"])
                end)

            end)

        end)

        context("when log_header_mismatch_with is configured", function()
            local service, route, plugin, consumer
            local local_conf = {
                source_headers = { "other-anything" },
                uri_matchers = { "/anything/(.-)/" },
                target_header = "anything",
                log_header_mismatch_with = "anything2"
            }

            before_each(function()
                service, route, plugin, consumer = setup_test_env(local_conf)
            end)

            it("should work fine", function()
                local res = assert(helpers.proxy_client():send({
                    method = "GET",
                    path = "/anything/something/",
                    headers = {
                        ["Host"] = "test1.com",
                        ["other-anything"] = "23456789",
                        ["anything2"] = "444555666"
                    }
                }))

                assert.res_status(200, res)
            end)

        end)

    end)

end)
