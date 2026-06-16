# PHP Framework Benchmark

A real-world HTTP benchmark comparing popular PHP frameworks under identical conditions.
Each framework runs inside its own Docker container with **Nginx + PHP-FPM**, default configuration, and no special optimizations enabled.

## Frameworks

| Framework | Version | Port | Template Engine |
|-----------|---------|------|----------------|
| [Webrium](https://github.com/webrium/webrium) | latest | 8001 | Webrium View |
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
- Hardware: Intel Core i5, 16GB RAM

## Results

> Tested on: June 2025
> All frameworks run with default configuration. No caching layers, no query optimizers, no custom FPM tuning.

### /bench/render

| Framework | Req/sec | Avg latency | p99 latency | Memory delta | CPU after |
|-----------|---------|-------------|-------------|--------------|-----------|
| Webrium | **12,157** | 8.3ms | 17.3ms | +7 MiB | 0.7% |
| Symfony | 3,632 | 28.2ms | 61.9ms | +7 MiB | 2.2% |
| CodeIgniter | 3,119 | 32.4ms | 64.6ms | +6 MiB | 9.0% |
| Laravel | 528 | 189.8ms | 422ms | +35 MiB | 63% |

### /bench/json

| Framework | Req/sec | Avg latency | p99 latency | Memory delta | CPU after |
|-----------|---------|-------------|-------------|--------------|-----------|
| Webrium | **14,024** | 7.2ms | 13.1ms | +5 MiB | 0.9% |
| Symfony | 4,222 | 23.7ms | 34.4ms | +5 MiB | 1.9% |
| CodeIgniter | 3,280 | 31.2ms | 62.6ms | +3 MiB | 9.2% |
| Laravel | 441 | 228ms | 549ms | +28 MiB | 149% |

### Latency distribution - /bench/render

| Percentile | Webrium | Symfony | CodeIgniter | Laravel |
|------------|---------|---------|-------------|---------|
| p50 | 7.9ms | 26.3ms | 30.7ms | 174ms |
| p75 | 8.2ms | 27.4ms | 32.0ms | 231ms |
| p90 | 8.7ms | 29.9ms | 34.2ms | 293ms |
| p99 | 17.3ms | 61.9ms | 64.6ms | 422ms |
| Max | 52ms | 254ms | 212ms | 804ms |

### Latency distribution - /bench/json

| Percentile | Webrium | Symfony | CodeIgniter | Laravel |
|------------|---------|---------|-------------|---------|
| p50 | 7.0ms | 23.3ms | 29.6ms | 207ms |
| p75 | 7.2ms | 24.2ms | 31.0ms | 283ms |
| p90 | 7.6ms | 25.2ms | 32.7ms | 357ms |
| p99 | 13.1ms | 34.4ms | 62.6ms | 549ms |
| Max | 49ms | 161ms | 273ms | 1130ms |

## Notable observations

**Webrium CPU usage stayed below 1% throughout both tests.** At 12,000+ req/s, the container showed 0.7% CPU after the test run - meaning the framework never saturated the server and wrk itself was the bottleneck, not PHP.

**Symfony outperformed CodeIgniter despite being a heavier framework.** In production mode, Symfony compiles its entire routing and service container into cached PHP files, reducing per-request overhead significantly. CodeIgniter does not apply this level of compilation caching.

**Laravel's JSON endpoint was slower than its render endpoint** (441 vs 528 req/s). This is because Laravel's `response()->json()` pipeline triggers additional service resolution layers compared to rendering a Blade view, resulting in higher CPU usage (up to 149%) and greater memory growth.

**All four frameworks showed clean, consistent latency distributions** with low standard deviation - confirming the test conditions were stable and results are reproducible.

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
- Memory is measured before and after each test using `docker stats`
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