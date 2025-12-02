# Performance Benchmark Suite

A comprehensive performance benchmarking suite for comparing Go and Java runtime performance across different systems and configurations.

## Features

- **Dual-language benchmarks**: Identical test cases implemented in both Go and Java
- **Comprehensive testing**: CPU, memory, concurrency, I/O, cryptography, and JSON benchmarks
- **Multiple configurations**: 
  - Go: Quick/Standard/Extended/Profiled runs with CPU/memory profiling
  - Java: Different GC collectors (Default/G1/ZGC/Parallel)
- **Automated reporting**: Generates detailed reports with system info and analysis guides

## Prerequisites

### For Go Benchmarks
- Go 1.x or higher
- Standard Go toolchain

### For Java Benchmarks
- **Java 21+** (required for ZGC support)
- Maven 3.6+
- Note: On macOS with Homebrew, ensure Java version matches Maven's version

## Quick Start

### Run Go Benchmarks
```bash
./run_go_benchmarks.sh [system_name]
```
Takes approximately 45-60 minutes. Results saved to `go_benchmark_<system_name>_<timestamp>/`

### Run Java Benchmarks
```bash
./run_java_benchmarks.sh [system_name]
```
Takes approximately 60-90 minutes. Results saved to `java_benchmark_<system_name>_<timestamp>/`

**System name is optional** - use it to identify different machines when comparing results (e.g., `./run_go_benchmarks.sh laptop` vs `./run_go_benchmarks.sh server`).

## Benchmark Categories

Both Go and Java implement identical test cases:

- **CPU-Intensive**: Fibonacci (20, 30), Prime generation (10K, 50K), Matrix multiplication (50x50, 100x100)
- **Memory**: Array sorting (100K, 1M elements), Memory allocation (1MB, 10MB), HashMap operations
- **String Operations**: Concatenation, StringBuilder
- **JSON**: Marshal/Unmarshal, Array serialization
- **Cryptography**: SHA256 (small data, 1MB data)
- **Concurrency**: Goroutines/Threads (10, 100, 1000), Channels/Queues, Mutex contention

## Result Analysis

### Go Results
```bash
# View standard benchmark results
cat go_benchmark_*/go_benchmark_standard.txt | grep Benchmark

# Analyze CPU profile (opens browser)
go tool pprof -http=:8080 go_benchmark_*/cpu.prof
```

### Java Results
```bash
# View throughput results
grep 'thrpt' java_benchmark_*/java_benchmark_default.txt | head -10

# Compare GC pause times
grep "Pause" java_benchmark_*/gc_*.log
```

### Comparing Systems
1. Run scripts with distinct system names on each machine
2. Compare `*_standard.txt` (Go) or `*_default.txt` (Java) files
3. Look for >10% differences (smaller differences may be measurement noise)

## Project Structure

```
.
├── run_go_benchmarks.sh              # Go benchmark orchestration script
├── run_java_benchmarks.sh            # Java benchmark orchestration script
├── go_benchmarks/
│   ├── benchmark_test.go             # Go benchmark implementations
│   └── go.mod                        # Go module definition
├── java_benchmarks/
│   ├── pom.xml                       # Maven project configuration
│   └── src/main/java/benchmark/
│       └── CompleteBenchmarks.java   # Java JMH benchmark implementations

# Generated directories (not committed):
go_benchmark_<system>_<timestamp>/    # Go results
java_benchmark_<system>_<timestamp>/  # Java results
```

## Platform-Specific Notes

### macOS
- System info commands (`lscpu`, `free`) may show errors - this is normal
- Java version management: Script auto-detects Homebrew OpenJDK
- Optional `sysbench` tool not available by default

### Linux
- Install optional tools: `sudo apt install sysbench` for additional system benchmarks
- All system info commands fully supported

## Troubleshooting

### Java: "Unable to find BenchmarkList" error
The JMH annotation processor didn't run. This is already fixed in `pom.xml`, but if you encounter it:
```bash
cd java_benchmarks
mvn clean package
# Verify: ls target/classes/META-INF/BenchmarkList
```

### Java: Version mismatch errors
Ensure runtime Java matches compile-time Java:
```bash
java -version  # Should be 21+
mvn -version   # Should also use Java 21+
```

### Go: Module errors
```bash
cd go_benchmarks
go mod tidy
```

## Contributing

When adding new benchmarks:
1. Implement in both `benchmark_test.go` and `CompleteBenchmarks.java`
2. Follow naming conventions: `BenchmarkName` (Go) vs `benchmarkName` (Java)
3. Use `b.ResetTimer()` (Go) or `@Setup(Level.Trial)` (Java) for data initialization
4. Test both implementations to ensure parity

## License

This project is for performance testing and comparison purposes.
