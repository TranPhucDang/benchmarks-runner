#!/bin/bash

# ============================================================
# Go Benchmark Runner Script
# Runs comprehensive Go benchmarks and collects results
# ============================================================

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m' # No Color

echo -e "${BLUE}${BOLD}"
cat << "EOF"
╔═══════════════════════════════════════════════════════════════╗
║                                                               ║
║           GO BENCHMARK RUNNER                                 ║
║           Performance Testing Suite                           ║
║                                                               ║
╚═══════════════════════════════════════════════════════════════╝
EOF
echo -e "${NC}"

# Create results directory
SYSTEM_NAME="${1:-go_system}"
RESULTS_DIR="go_benchmark_${SYSTEM_NAME}_$(date +%Y%m%d_%H%M%S)"
mkdir -p "$RESULTS_DIR"

echo -e "${CYAN}System name: ${BOLD}$SYSTEM_NAME${NC}"
echo -e "${CYAN}Results will be saved to: ${BOLD}$RESULTS_DIR${NC}\n"

# ============================================================
# System Information
# ============================================================
echo -e "${GREEN}[1/5] Collecting system information...${NC}"
{
    echo "=========================================="
    echo "System Information - $SYSTEM_NAME"
    echo "=========================================="
    echo "Date: $(date)"
    echo "Hostname: $(hostname)"
    echo ""
    
    echo "--- Operating System ---"
    if [ -f /etc/os-release ]; then
        cat /etc/os-release
    else
        echo "OS info not available"
    fi
    echo ""
    echo "Kernel: $(uname -r)"
    echo "Architecture: $(uname -m)"
    echo ""
    
    echo "--- CPU Information ---"
    lscpu | grep -E "Model name|CPU\(s\)|Thread|Core|Socket|MHz"
    echo ""
    
    echo "--- Memory Information ---"
    free -h
    echo ""
    
    echo "--- Disk Information ---"
    df -h / /home 2>/dev/null || df -h /
    echo ""
    
    echo "--- Go Version ---"
    go version
    echo ""
    
    echo "--- Current System Load ---"
    uptime
    echo ""
    
} | tee "$RESULTS_DIR/system_info.txt"

echo -e "${GREEN}✓ System information collected${NC}\n"

# ============================================================
# Create Go Benchmark File
# ============================================================
echo -e "${GREEN}[2/5] Creating Go benchmark files...${NC}"

mkdir -p go_benchmarks
cd go_benchmarks


# Initialize Go module
if [ ! -f "go.mod" ]; then
    go mod init benchmark
fi

echo -e "${GREEN}✓ Go benchmark files created${NC}\n"

# ============================================================
# Run Go Benchmarks
# ============================================================
echo -e "${CYAN}========================================${NC}"
echo -e "${CYAN}[3/5] Running Go Benchmarks${NC}"
echo -e "${CYAN}========================================${NC}\n"

echo -e "${YELLOW}Running quick benchmark (2s each)...${NC}"
go test -bench=. -benchmem -benchtime=2s -timeout=30m \
    > "../$RESULTS_DIR/go_benchmark_quick.txt" 2>&1
echo -e "${GREEN}✓ Quick benchmark completed${NC}\n"

echo -e "${YELLOW}Running standard benchmark (5s each)...${NC}"
go test -bench=. -benchmem -benchtime=5s -timeout=60m \
    > "../$RESULTS_DIR/go_benchmark_standard.txt" 2>&1
echo -e "${GREEN}✓ Standard benchmark completed${NC}\n"

echo -e "${YELLOW}Running extended benchmark (10s, 3 runs)...${NC}"
go test -bench=. -benchmem -benchtime=10s -count=3 -timeout=120m \
    > "../$RESULTS_DIR/go_benchmark_extended.txt" 2>&1
echo -e "${GREEN}✓ Extended benchmark completed${NC}\n"

echo -e "${YELLOW}Running benchmark with CPU profiling...${NC}"
go test -bench=. -cpuprofile="../$RESULTS_DIR/cpu.prof" \
    -memprofile="../$RESULTS_DIR/mem.prof" \
    -benchtime=5s -timeout=60m \
    > "../$RESULTS_DIR/go_benchmark_profiled.txt" 2>&1
echo -e "${GREEN}✓ Profiled benchmark completed${NC}\n"

cd ..

# ============================================================
# System Benchmarks (Optional)
# ============================================================
echo -e "${GREEN}[4/5] Running system benchmarks...${NC}"

if command -v sysbench &> /dev/null; then
    echo -e "${YELLOW}Running CPU benchmark...${NC}"
    sysbench cpu --cpu-max-prime=20000 --threads=$(nproc) run \
        > "$RESULTS_DIR/sysbench_cpu.txt" 2>&1
    
    echo -e "${YELLOW}Running memory benchmark...${NC}"
    sysbench memory --memory-total-size=10G run \
        > "$RESULTS_DIR/sysbench_memory.txt" 2>&1
    
    echo -e "${GREEN}✓ System benchmarks completed${NC}\n"
else
    echo -e "${YELLOW}⚠ sysbench not installed, skipping system benchmarks${NC}"
    echo -e "${YELLOW}  Install with: sudo apt install sysbench${NC}\n"
fi

# ============================================================
# Generate Summary Report
# ============================================================
echo -e "${GREEN}[5/5] Generating summary report...${NC}"

cat > "$RESULTS_DIR/README.md" << 'EOFSUM'
# Go Benchmark Results

## Files in this directory

### System Information
- `system_info.txt` - Complete system specifications

### Benchmark Results
- `go_benchmark_quick.txt` - Quick 2s benchmark (for fast overview)
- `go_benchmark_standard.txt` - Standard 5s benchmark (recommended for comparison)
- `go_benchmark_extended.txt` - Extended 10s benchmark with 3 runs (most accurate)
- `go_benchmark_profiled.txt` - Benchmark with profiling data

### Profiling Data
- `cpu.prof` - CPU profile (use: `go tool pprof -http=:8080 cpu.prof`)
- `mem.prof` - Memory profile (use: `go tool pprof -http=:8080 mem.prof`)

### System Benchmarks (if sysbench available)
- `sysbench_cpu.txt` - CPU performance
- `sysbench_memory.txt` - Memory performance

## Understanding Go Benchmark Results

### Format
```
BenchmarkFibonacci20-8    100000    12345 ns/op    456 B/op    7 allocs/op
```

- `BenchmarkFibonacci20-8`: Test name with GOMAXPROCS
- `100000`: Number of iterations
- `12345 ns/op`: Nanoseconds per operation (lower is better)
- `456 B/op`: Bytes allocated per operation (lower is better)
- `7 allocs/op`: Number of allocations per operation (lower is better)

## Benchmark Categories

### CPU-Intensive
- **Fibonacci**: Recursive computation
- **PrimeGeneration**: Prime number calculation
- **MatrixMultiply**: Matrix multiplication

### Memory
- **SortingInts**: Array sorting
- **MemoryAllocation**: Large memory allocations
- **MapOperations**: HashMap operations

### String Operations
- **StringConcatenation**: String concatenation with +
- **StringBuilder**: String concatenation with Builder

### JSON
- **JSONMarshal**: Serialize to JSON
- **JSONUnmarshal**: Deserialize from JSON
- **JSONMarshalArray**: Serialize array of objects

### Cryptography
- **SHA256Small**: Hash small data
- **SHA256Large**: Hash large data (1MB)

### Concurrency
- **Goroutines**: Concurrent goroutines (10, 100, 1000)
- **ChannelOperations**: Channel send/receive
- **MutexContention**: Mutex lock contention
- **RWMutexReadHeavy**: Read-heavy RWMutex usage

## Comparing with Another System

1. Run this script on the other system
2. Compare the `go_benchmark_standard.txt` files
3. Look for differences >10% (smaller differences may be noise)

### Key Metrics to Compare:
- **ns/op**: Lower is better (faster)
- **B/op**: Lower is better (less memory)
- **allocs/op**: Lower is better (fewer allocations)

## Analyzing Profiles

### CPU Profile
```bash
go tool pprof -http=:8080 cpu.prof
```
Then open http://localhost:8080 in your browser

### Memory Profile
```bash
go tool pprof -http=:8080 mem.prof
```

### Command Line Analysis
```bash
# Top CPU consumers
go tool pprof -top cpu.prof

# Top memory allocators
go tool pprof -top mem.prof
```

## Performance Tips

1. **Variance**: Run multiple times (extended benchmark does this)
2. **System Load**: Ensure system is idle during benchmarking
3. **Thermal Throttling**: Monitor CPU temperature
4. **Background Processes**: Close unnecessary applications

EOFSUM

# Add run-specific information
{
    echo ""
    echo "## This Run"
    echo "- System: $SYSTEM_NAME"
    echo "- Date: $(date)"
    echo "- Go Version: $(go version)"
    echo "- CPU Cores: $(nproc)"
    echo "- Total RAM: $(free -h | grep Mem | awk '{print $2}')"
} >> "$RESULTS_DIR/README.md"

echo -e "${GREEN}✓ Summary report generated${NC}\n"

# ============================================================
# Final Summary
# ============================================================
echo -e "${BOLD}${GREEN}"
cat << "EOF"
╔═══════════════════════════════════════════════════════════════╗
║                                                               ║
║            BENCHMARKS COMPLETED SUCCESSFULLY!                 ║
║                                                               ║
╚═══════════════════════════════════════════════════════════════╝
EOF
echo -e "${NC}"

echo -e "${CYAN}Results saved to: ${BOLD}$RESULTS_DIR/${NC}\n"

echo -e "${YELLOW}Quick Overview:${NC}"
echo "  - System info:     $RESULTS_DIR/system_info.txt"
echo "  - Quick results:   $RESULTS_DIR/go_benchmark_quick.txt"
echo "  - Standard:        $RESULTS_DIR/go_benchmark_standard.txt"
echo "  - Extended:        $RESULTS_DIR/go_benchmark_extended.txt"
echo ""

echo -e "${YELLOW}View Results:${NC}"
echo "  cat $RESULTS_DIR/go_benchmark_standard.txt | grep Benchmark"
echo ""

echo -e "${YELLOW}Analyze CPU Profile:${NC}"
echo "  go tool pprof -http=:8080 $RESULTS_DIR/cpu.prof"
echo ""

echo -e "${YELLOW}Compare with Another System:${NC}"
echo "  1. Run this script on the other system"
echo "  2. Compare the benchmark files manually or use a diff tool"
echo ""

echo -e "${GREEN}Done! 🎉${NC}\n"