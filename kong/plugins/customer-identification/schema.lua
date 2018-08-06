return {
    no_consumer = true,
    fields = {
        source_headers = { type = "array", required = true },
        uri_matchers = { type = "array", required = true },
        target_header = { type = "string", required = true },
    }
}