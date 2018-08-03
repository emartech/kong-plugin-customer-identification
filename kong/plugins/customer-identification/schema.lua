return {
    no_consumer = true,
    fields = {
        source_headers = { type = "table", required = true },
        uri_matchers = { type = "table", required = true },
        target_header = { type = "string", required = true },
    }
}