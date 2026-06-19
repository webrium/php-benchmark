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
COOLDOWN=30
SAMPLE_INTERVAL=0   # extra sleep between samples; `docker stats --no-stream`
                    # itself already takes ~1s, so 0 yields roughly 1 sample/sec.
                    # Increase this to sample less frequently.

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

# Continuously samples CPU% and MEM (MiB) of a container, one line per sample.
# Writes "<cpu> <mem_mib>" per line into $1. Runs until killed.
sample_stats() {
    local container=$1
    local outfile=$2

    # We poll `docker stats --no-stream` once per interval instead of using the
    # streaming form. The streaming form emits ANSI/cursor control characters
    # (it is meant for live terminal display), which corrupt the parsed values
    # when piped. Polling gives one clean single-line reading each iteration.
    while true; do
        local line cpu memusage memval num unit mem
        line=$(docker stats --no-stream "$container" \
            --format "{{.CPUPerc}};{{.MemUsage}}" 2>/dev/null)

        # line example: "12.34%;45.6MiB / 1.944GiB"
        cpu="${line%%;*}"
        cpu="${cpu%\%}"

        memusage="${line#*;}"
        memval="${memusage%% *}"          # e.g. "45.6MiB" or "1.2GiB"

        num="${memval//[A-Za-z]/}"        # numeric part
        unit="${memval//[0-9.]/}"         # unit part

        case "$unit" in
            GiB|GB) mem=$(awk "BEGIN{printf \"%.2f\", $num*1024}") ;;
            MiB|MB) mem=$(awk "BEGIN{printf \"%.2f\", $num}") ;;
            KiB|KB) mem=$(awk "BEGIN{printf \"%.4f\", $num/1024}") ;;
            B)      mem=$(awk "BEGIN{printf \"%.6f\", $num/1048576}") ;;
            *)      mem="$num" ;;
        esac

        # only record clean numeric samples
        if [[ "$cpu" =~ ^[0-9.]+$ ]] && [[ "$mem" =~ ^[0-9.]+$ ]]; then
            echo "$cpu $mem" >> "$outfile"
        fi

        sleep "$SAMPLE_INTERVAL"
    done
}

run_bench() {
    local label=$1
    local container=$2
    local url=$3

    echo ""
    echo "--- $label ---"

    local samples_file
    samples_file="$(mktemp)"

    # Start sampling in the background BEFORE load starts.
    sample_stats "$container" "$samples_file" &
    local sampler_pid=$!

    echo "  Running load test (sampling CPU/MEM ~1x per second during the run)..."
    echo ""
    wrk -t$THREADS -c$CONNECTIONS -d$DURATION \
        --latency \
        -s "$LUA_SCRIPT" \
        "$url"

    # Stop the sampler loop and any child it spawned (docker stats / sleep).
    pkill -P "$sampler_pid" 2>/dev/null
    kill "$sampler_pid" 2>/dev/null
    wait "$sampler_pid" 2>/dev/null

    echo ""
    echo "  Resource usage DURING the test (container: $container):"

    if [ -s "$samples_file" ]; then
        awk '
        {
            cpu=$1; mem=$2;
            cpu_sum+=cpu; mem_sum+=mem; n++;
            if (n==1 || cpu>cpu_max) cpu_max=cpu;
            if (n==1 || mem>mem_max) mem_max=mem;
            if (n==1 || cpu<cpu_min) cpu_min=cpu;
            if (n==1 || mem<mem_min) mem_min=mem;
        }
        END {
            if (n>0) {
                printf "    Samples collected : %d\n", n;
                printf "    CPU  avg / max / min : %.2f%% / %.2f%% / %.2f%%\n", cpu_sum/n, cpu_max, cpu_min;
                printf "    MEM  avg / max / min : %.2f MiB / %.2f MiB / %.2f MiB\n", mem_sum/n, mem_max, mem_min;
            } else {
                print "    No samples collected.";
            }
        }' "$samples_file"
    else
        echo "    No samples collected (is the container running?)."
    fi

    rm -f "$samples_file"

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
