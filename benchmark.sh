#!/bin/bash

DURATION=30s
THREADS=4
CONNECTIONS=100
LARAVEL=http://localhost:8002
WEBRIUM=http://localhost:8001
CODEIGNITER=http://localhost:8003
SYMFONY=http://localhost:8004
ENDPOINTS=("bench/render" "bench/json")
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
LUA_SCRIPT="$SCRIPT_DIR/check_status.lua"
COOLDOWN=15

if [ ! -f "$LUA_SCRIPT" ]; then
    echo "[ERROR] check_status.lua not found at $LUA_SCRIPT"
    exit 1
fi

if ! command -v wrk &> /dev/null; then
    echo "[ERROR] wrk is not installed"
    exit 1
fi

check_endpoint() {
    local url=$1
    local code
    code=$(curl -s -o /dev/null -w "%{http_code}" \
        --max-time 5 \
        --http1.1 \
        -4 \
        "$url")
    if [ "$code" != "200" ]; then
        echo "  [ERROR] $url returned HTTP $code"
        return 1
    fi
    echo "  [OK] $url -> HTTP 200"
    return 0
}

run_bench() {
    local label=$1
    local container=$2
    local url=$3

    echo ""
    echo "--- $label ---"

    echo "  Memory and CPU snapshot (before):"
    docker stats --no-stream "$container" \
        --format "  CONTAINER: {{.Name}} | CPU: {{.CPUPerc}} | MEM: {{.MemUsage}}"

    echo ""
    wrk -t$THREADS -c$CONNECTIONS -d$DURATION \
        --latency \
        -s "$LUA_SCRIPT" \
        "$url"

    echo ""
    echo "  Memory and CPU snapshot (after):"
    docker stats --no-stream "$container" \
        --format "  CONTAINER: {{.Name}} | CPU: {{.CPUPerc}} | MEM: {{.MemUsage}}"

    echo ""
    echo "  Cooling down for ${COOLDOWN}s..."
    sleep $COOLDOWN
}

for EP in "${ENDPOINTS[@]}"; do
    echo ""
    echo "=============================="
    echo "ENDPOINT: /$EP"
    echo "=============================="

    echo "Checking endpoints..."
    LARAVEL_OK=true
    WEBRIUM_OK=true
    CODEIGNITER_OK=true
    SYMFONY_OK=true

    check_endpoint "$LARAVEL/$EP"      || LARAVEL_OK=false
    check_endpoint "$WEBRIUM/$EP"      || WEBRIUM_OK=false
    check_endpoint "$CODEIGNITER/$EP"  || CODEIGNITER_OK=false
    check_endpoint "$SYMFONY/$EP"      || SYMFONY_OK=false

    if [ "$LARAVEL_OK" = true ];      then run_bench "Laravel"      "benchmark-laravel"      "$LARAVEL/$EP";      else echo "  [SKIP] Laravel $EP";      fi
    if [ "$WEBRIUM_OK" = true ];      then run_bench "Webrium"      "benchmark-webrium"      "$WEBRIUM/$EP";      else echo "  [SKIP] Webrium $EP";      fi
    if [ "$CODEIGNITER_OK" = true ];  then run_bench "CodeIgniter"  "benchmark-codeigniter"  "$CODEIGNITER/$EP";  else echo "  [SKIP] CodeIgniter $EP";  fi
    if [ "$SYMFONY_OK" = true ];      then run_bench "Symfony"      "benchmark-symfony"      "$SYMFONY/$EP";      else echo "  [SKIP] Symfony $EP";      fi
done

echo ""
echo "=============================="
echo "BENCHMARK COMPLETE"
echo "=============================="
