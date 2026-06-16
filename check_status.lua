counts = {}

function response(status, headers, body)
    counts[status] = (counts[status] or 0) + 1
end

function done(summary, latency, requests)
    print("\n  Status code breakdown:")
    for code, count in pairs(counts) do
        local label = (code == 200) and "[OK]" or "[FAIL]"
        print(string.format("    %s HTTP %d : %d responses", label, code, count))
    end
    local non200 = 0
    for code, count in pairs(counts) do
        if code ~= 200 then non200 = non200 + count end
    end
    if non200 > 0 then
        print(string.format("\n  [WARNING] %d failed responses detected!", non200))
    else
        print("\n  [PASS] All responses were HTTP 200")
    end
end
