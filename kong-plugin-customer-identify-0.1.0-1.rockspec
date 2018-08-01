package = "kong-plugin-customer-identify"
version = "0.1.0-1"
supported_platforms = {"linux", "macosx"}
source = {
  url = "git+https://github.com/emartech/kong-plugin-customer-identify.git",
  tag = "0.1.0"
}
description = {
  summary = "Customer identifier plugin for Kong API gateway",
  homepage = "https://github.com/emartech/kong-plugin-customer-identify",
  license = "MIT"
}
dependencies = {
  "lua ~> 5.1",
  "classic 0.1.0-1",
  "kong-lib-logger >= 0.3.0-1"
}
build = {
  type = "builtin",
  modules = {
    ["kong.plugins.customer-identify.handler"] = "kong/plugins/customer-identify/handler.lua",
    ["kong.plugins.customer-identify.schema"] = "kong/plugins/customer-identify/schema.lua",
  }
}
