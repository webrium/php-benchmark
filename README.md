# PHP Framework Benchmark

![PHP Framework Benchmark](assets/php-framework-benchmark-2026-jun.png)

A real-world HTTP benchmark comparing popular PHP frameworks under identical conditions.
Each framework runs inside its own Docker container with **Nginx + PHP-FPM**, default configuration, and no special optimizations enabled.

## Frameworks

| Framework | Version | Port | Template Engine |
|-----------|---------|------|----------------|
| [Webrium](https://github.com/webrium/webrium) | 5 | 8001 | Webrium View |
| [Laravel](https://laravel.com) | 11.x | 8002 | Blade |
| [CodeIgniter](https://codeigniter.com) | 4.x | 8003 | PHP native |
| [Symfony](https://symfony.com) | 7.x | 8004 | Twig |

## Test Endpoints

| Endpoint | What it measures |
|----------|-----------------|
| `GET /bench/render` | Framework boot + view rendering with a static dataset |
| `GET /bench/json` | Framework boot + JSON response serialization |

Each endpoint returns the same 10-user dataset. No database queries are involved in these tests. All responses are validated as HTTP 200.

## Environment

- OS: Ubuntu 22.04 (Docker)
- PHP: 8.2
- Server: Nginx + PHP-FPM (default worker settings)
- OPcache: enabled (default configuration)
- Benchmark tool: [wrk](https://github.com/wg/wrk) - 4 threads, 100 connections, 30 seconds
- Hardware: 16 CPU cores, 16GB RAM

## Results

> Tested on: June 19, 2026
> All frameworks run with default configuration. No caching layers, no query optimizers, no custom FPM tuning.
> CPU and memory are sampled roughly once per second **throughout** each run (not just before/after), and reported as average / peak across the test.

### /bench/render

| Framework | Req/sec | Avg latency | p99 latency | CPU avg | CPU peak | Mem avg | Mem peak |
|-----------|---------|-------------|-------------|---------|----------|---------|----------|
| Webrium | **11,865** | 8.5ms | 14.6ms | 540% | 565% | 37 MiB | 38 MiB |
| Symfony | 3,679 | 27.5ms | 56.3ms | 513% | 540% | 43 MiB | 44 MiB |
| CodeIgniter | 3,105 | 32.5ms | 62.6ms | 500% | 525% | 41 MiB | 42 MiB |
| Laravel | 465 | 219.8ms | 592.7ms | 480% | 506% | 70 MiB | 81 MiB |

### /bench/json

| Framework | Req/sec | Avg latency | p99 latency | CPU avg | CPU peak | Mem avg | Mem peak |
|-----------|---------|-------------|-------------|---------|----------|---------|----------|
| Webrium | **13,526** | 7.5ms | 11.7ms | 567% | 583% | 38 MiB | 40 MiB |
| Symfony | 4,267 | 23.4ms | 32.9ms | 527% | 543% | 44 MiB | 45 MiB |
| CodeIgniter | 3,362 | 29.7ms | 43.0ms | 515% | 528% | 40 MiB | 41 MiB |
| Laravel | 392 | 257.1ms | 638.6ms | 492% | 509% | 90 MiB | 99 MiB |

### Latency distribution - /bench/render

| Percentile | Webrium | Symfony | CodeIgniter | Laravel |
|------------|---------|---------|-------------|---------|
| p50 | 8.2ms | 26.2ms | 31.0ms | 186.3ms |
| p75 | 8.5ms | 27.2ms | 32.2ms | 267.3ms |
| p90 | 8.9ms | 28.9ms | 34.2ms | 364.2ms |
| p99 | 14.6ms | 56.3ms | 62.6ms | 592.7ms |
| Max | 57.3ms | 194.6ms | 216.3ms | 996.2ms |

### Latency distribution - /bench/json

| Percentile | Webrium | Symfony | CodeIgniter | Laravel |
|------------|---------|---------|-------------|---------|
| p50 | 7.3ms | 23.1ms | 29.3ms | 222.5ms |
| p75 | 7.6ms | 24.2ms | 30.6ms | 341.9ms |
| p90 | 7.9ms | 25.4ms | 32.3ms | 442.4ms |
| p99 | 11.7ms | 32.9ms | 43.0ms | 638.6ms |
| Max | 47.8ms | 61.1ms | 56.3ms | 1150ms |

## Notable observations

**All four frameworks left CPU headroom on this 16-core machine.** With CPU sampled throughout the run, every framework sat in the ~480-580% range - i.e. each used between 5 and 6 cores' worth of CPU out of 16 available, so none of them came close to saturating the host. This means CPU was not the bottleneck for any framework; the limit was per-request overhead and the fixed wrk client load (4 threads, 100 connections), not raw CPU capacity. The real differentiator is how many requests each framework delivered for that similar CPU spend: Webrium turned ~5-6 cores into ~11,900 req/s on `/bench/render`, while Laravel produced ~465 req/s from a comparable CPU load. This throughput-per-core gap is what the old idle before/after snapshots completely hid.

**Memory is where the frameworks separate cleanly.** Webrium, CodeIgniter, and Symfony all held steady between ~37 and ~45 MiB across both endpoints, with very little spread between average and peak. Laravel used noticeably more - ~70 MiB average (81 MiB peak) on render and ~90 MiB average (99 MiB peak) on JSON - and showed a wider gap between average and peak, indicating more memory churn per request.

**Laravel's JSON endpoint was slower than its render endpoint** (392 vs 465 req/s). Laravel's `response()->json()` pipeline triggers additional service-resolution layers compared to rendering a Blade view, and this shows up as both lower throughput and higher memory use (90 MiB average on JSON vs 70 MiB on render).

**Symfony outperformed CodeIgniter despite being a heavier framework.** In production mode, Symfony compiles its routing and service container into cached PHP files, reducing per-request overhead. CodeIgniter does not apply this level of compilation caching.

**Latency distributions stayed tight for the three faster frameworks.** Webrium, Symfony, and CodeIgniter all showed low standard deviation and a small p50-to-p99 spread, confirming stable test conditions. Laravel's distribution was much wider (e.g. 222ms p50 rising to 639ms p99 on JSON), consistent with a framework operating close to its throughput ceiling under this load.

> Note on sampling: because each `docker stats` reading takes roughly one second, a 30-second run yields about 15 samples per framework. The averages and peaks above are computed from those samples. Increasing the run duration or lowering the sample interval would tighten these figures further.

## How to run

### Requirements

- Docker and Docker Compose
- [wrk](https://github.com/wg/wrk)

```bash
# Install wrk on Ubuntu/Debian
sudo apt update && sudo apt install -y wrk
```

### Clone and start

```bash
git clone https://github.com/webrium/php-benchmark.git
cd php-benchmark
```

Place your framework source files in the corresponding volume directories:

```
laravel-app/      <- Laravel application files
webrium-app/      <- Webrium application files
codeigniter-app/  <- CodeIgniter application files
symfony-app/      <- Symfony application files
```

Build and start all containers:

```bash
docker compose up -d --build
```

The first run takes a few minutes as Composer installs each framework. Check progress with:

```bash
docker compose logs -f
```

### Verify endpoints

```bash
curl -s -o /dev/null -w "%{http_code}" http://localhost:8001/bench/render  # Webrium
curl -s -o /dev/null -w "%{http_code}" http://localhost:8002/bench/render  # Laravel
curl -s -o /dev/null -w "%{http_code}" http://localhost:8003/bench/render  # CodeIgniter
curl -s -o /dev/null -w "%{http_code}" http://localhost:8004/bench/render  # Symfony
```

All should return `200`.

### Run the benchmark

```bash
chmod +x benchmark.sh
./benchmark.sh 2>&1 | tee results.txt
```

Results are saved to `results.txt`. The script runs each framework sequentially with a 30-second cooldown between tests and validates that all responses return HTTP 200.

### Stop containers

```bash
docker compose down
```

## Project structure

```
php-benchmark/
|-- docker-compose.yml
|-- benchmark.sh
|-- check_status.lua
|-- database.sql
|-- docker/
|   |-- Dockerfile.laravel
|   |-- Dockerfile.webrium
|   |-- Dockerfile.codeigniter
|   |-- Dockerfile.symfony
|   |-- nginx-laravel.conf
|   |-- nginx-webrium.conf
|   |-- nginx-codeigniter.conf
|   |-- nginx-symfony.conf
|   |-- entrypoint-laravel.sh
|   |-- entrypoint-webrium.sh
|   |-- entrypoint-codeigniter.sh
|   `-- entrypoint-symfony.sh
|-- laravel-app/
|-- webrium-app/
|-- codeigniter-app/
`-- symfony-app/
```

## Methodology

- Each framework runs in an isolated Docker container on Ubuntu 22.04
- PHP 8.2 with OPcache enabled at default settings
- Nginx + PHP-FPM with default worker configuration - no tuning applied
- A 30-second cooldown period between each test run allows CPU and memory to return to idle
- CPU and memory are sampled with `docker stats` roughly once per second **while the load test is running**, and reported as average and peak across all samples - not just a single before/after snapshot
- All responses are validated via a Lua script - only HTTP 200 responses are counted
- Frameworks are tested in the same order each run

## Challenging the results

If you believe these results do not reflect fair or accurate conditions for a specific framework, you are welcome to open an [issue](https://github.com/webrium/php-benchmark/issues).

Please include:

- The framework and version you are questioning
- The specific configuration change you believe would make the comparison fairer
- A technical explanation of why the current setup disadvantages that framework

Our goal is to produce results that are accurate, reproducible, and conducted under equal conditions for all frameworks. If a configuration error is found, we will re-run the benchmark and update the results.

> All frameworks in this benchmark run with their standard default configuration. No special optimizations, custom OPcache tuning, JIT settings, or FPM worker counts have been applied beyond what ships out of the box.

## License

MIT