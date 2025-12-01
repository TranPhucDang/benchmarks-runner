#!/bin/bash

# ============================================================
# Java Benchmark Runner Script
# Runs comprehensive Java benchmarks using JMH
# ============================================================

set -e

# Set JAVA_HOME to match Maven's Java version on macOS
if [[ "$OSTYPE" == "darwin"* ]] && [ -d "/opt/homebrew/Cellar/openjdk" ]; then
    LATEST_JDK=$(ls -d /opt/homebrew/Cellar/openjdk/*/libexec/openjdk.jdk/Contents/Home 2>/dev/null | sort -V | tail -1)
    if [ -n "$LATEST_JDK" ]; then
        export JAVA_HOME="$LATEST_JDK"
        export PATH="$JAVA_HOME/bin:$PATH"
    fi
fi

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
║           JAVA BENCHMARK RUNNER (JMH)                         ║
║           Performance Testing Suite                           ║
║                                                               ║
╚═══════════════════════════════════════════════════════════════╝
EOF
echo -e "${NC}"

# Create results directory
SYSTEM_NAME="${1:-java_system}"
RESULTS_DIR="java_benchmark_${SYSTEM_NAME}_$(date +%Y%m%d_%H%M%S)"
mkdir -p "$RESULTS_DIR"

echo -e "${CYAN}System name: ${BOLD}$SYSTEM_NAME${NC}"
echo -e "${CYAN}Results will be saved to: ${BOLD}$RESULTS_DIR${NC}\n"

# ============================================================
# System Information
# ============================================================
echo -e "${GREEN}[1/6] Collecting system information...${NC}"
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
    
    echo "--- Java Version ---"
    java -version 2>&1
    echo ""
    
    echo "--- Maven Version ---"
    mvn -version 2>&1 | head -n 3
    echo ""
    
    echo "--- Current System Load ---"
    uptime
    echo ""
    
} | tee "$RESULTS_DIR/system_info.txt"

echo -e "${GREEN}✓ System information collected${NC}\n"

# ============================================================
# Create Java Project Structure
# ============================================================
echo -e "${GREEN}[2/6] Creating Java benchmark project...${NC}"

PROJECT_DIR="java_benchmarks"
# mkdir -p "$PROJECT_DIR/src/main/java/benchmark"

echo -e "${GREEN}✓ Java project created${NC}\n"

# ============================================================
# Build Project
# ============================================================
echo -e "${GREEN}[3/6] Building Java benchmark project...${NC}"
echo -e "${YELLOW}This may take a few minutes (downloading dependencies)...${NC}\n"

cd "$PROJECT_DIR"

if mvn clean package > "../$RESULTS_DIR/maven_build.log" 2>&1; then
    echo -e "${GREEN}✓ Build successful!${NC}\n"
else
    echo -e "${RED}✗ Build failed! Check $RESULTS_DIR/maven_build.log for details${NC}"
    cat "../$RESULTS_DIR/maven_build.log"
    exit 1
fi

cd ..

# ============================================================
# Run Benchmarks with Different GC
# ============================================================
echo -e "${CYAN}========================================${NC}"
echo -e "${CYAN}[4/6] Running Java Benchmarks${NC}"
echo -e "${CYAN}========================================${NC}\n"

# Get Java version
JAVA_VERSION=$(java -version 2>&1 | head -n 1 | cut -d'"' -f2 | cut -d'.' -f1)

# Default GC
echo -e "${YELLOW}Running benchmarks with default GC...${NC}"
echo -e "${CYAN}This will take 15-20 minutes...${NC}\n"
java -jar "$PROJECT_DIR/target/benchmarks.jar" \
    -rf json -rff "$RESULTS_DIR/java_results_default.json" \
    > "$RESULTS_DIR/java_benchmark_default.txt" 2>&1
echo -e "${GREEN}✓ Default GC benchmarks completed${NC}\n"

# G1GC
echo -e "${YELLOW}Running benchmarks with G1GC...${NC}"
java -XX:+UseG1GC -Xlog:gc*:file="$RESULTS_DIR/gc_g1.log" \
    -jar "$PROJECT_DIR/target/benchmarks.jar" \
    -rf json -rff "$RESULTS_DIR/java_results_g1gc.json" \
    > "$RESULTS_DIR/java_benchmark_g1gc.txt" 2>&1
echo -e "${GREEN}✓ G1GC benchmarks completed${NC}\n"

# ZGC (Java 21+)
if [ "$JAVA_VERSION" -ge 21 ]; then
    echo -e "${YELLOW}Running benchmarks with ZGC...${NC}"
    java -XX:+UseZGC -Xlog:gc*:file="$RESULTS_DIR/gc_zgc.log" \
        -jar "$PROJECT_DIR/target/benchmarks.jar" \
        -rf json -rff "$RESULTS_DIR/java_results_zgc.json" \
        > "$RESULTS_DIR/java_benchmark_zgc.txt" 2>&1
    echo -e "${GREEN}✓ ZGC benchmarks completed${NC}\n"
else
    echo -e "${YELLOW}⚠ Java version < 21, skipping ZGC tests${NC}\n"
fi

# Parallel GC
echo -e "${YELLOW}Running benchmarks with Parallel GC...${NC}"
java -XX:+UseParallelGC -Xlog:gc*:file="$RESULTS_DIR/gc_parallel.log" \
    -jar "$PROJECT_DIR/target/benchmarks.jar" \
    -rf json -rff "$RESULTS_DIR/java_results_parallel.json" \
    > "$RESULTS_DIR/java_benchmark_parallel.txt" 2>&1
echo -e "${GREEN}✓ Parallel GC benchmarks completed${NC}\n"

# ============================================================
# System Benchmarks (Optional)
# ============================================================
echo -e "${GREEN}[5/6] Running system benchmarks...${NC}"

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
echo -e "${GREEN}[6/6] Generating summary report...${NC}"

cat > "$RESULTS_DIR/README.md" << 'EOFSUM'
# Java Benchmark Results (JMH)

## Files in this directory

### System Information
- `system_info.txt` - Complete system specifications
- `maven_build.log` - Maven build output

### Benchmark Results (Text Format)
- `java_benchmark_default.txt` - Default JVM GC settings ⭐ Use this for comparison
- `java_benchmark_g1gc.txt` - G1 Garbage Collector
- `java_benchmark_zgc.txt` - Z Garbage Collector (Java 21+)
- `java_benchmark_parallel.txt` - Parallel Garbage Collector

### Benchmark Results (JSON Format)
- `java_results_default.json` - Machine-readable default GC results
- `java_results_g1gc.json` - Machine-readable G1GC results
- `java_results_zgc.json` - Machine-readable ZGC results
- `java_results_parallel.json` - Machine-readable Parallel GC results

### GC Logs
- `gc_g1.log` - G1GC detailed logs
- `gc_zgc.log` - ZGC detailed logs
- `gc_parallel.log` - Parallel GC detailed logs

### System Benchmarks (if sysbench available)
- `sysbench_cpu.txt` - CPU performance
- `sysbench_memory.txt` - Memory performance

## Understanding JMH Benchmark Results

### Format
```
Benchmark                              Mode  Cnt     Score     Error  Units
benchmarkFibonacci20                  thrpt    5  1234.567 ± 12.345  ops/s
```

- `Benchmark`: Test name
- `Mode`: thrpt = Throughput (operations per second)
- `Cnt`: Number of measurement iterations
- `Score`: Average operations per second (higher is better)
- `Error`: 99.9% confidence interval
- `Units`: ops/s = operations per second

## Benchmark Categories

### CPU-Intensive
- **Fibonacci20/30**: Recursive computation
- **PrimeGeneration10K/50K**: Prime number calculation
- **MatrixMultiply50x50/100x100**: Matrix multiplication

### Memory
- **SortingInts100K/1M**: Array sorting
- **MemoryAllocation1MB/10MB**: Large memory allocations
- **MapOperations1K/10K**: HashMap operations

### String Operations
- **StringConcatenation1K**: String concatenation with +
- **StringBuilder1K**: String concatenation with StringBuilder

### JSON
- **JSONMarshal**: Serialize to JSON
- **JSONUnmarshal**: Deserialize from JSON
- **JSONMarshalArray100**: Serialize array of objects

### Cryptography
- **SHA256Small**: Hash small data
- **SHA256Large**: Hash large data (1MB)

### Concurrency
- **Threads10/100/1000**: Concurrent threads
- **BlockingQueueOperations**: Producer-consumer pattern
- **AtomicContention**: Atomic operations under contention
- **ConcurrentHashMap**: Concurrent map operations

## Comparing with Another System

1. Run this script on the other system
2. Compare the `java_benchmark_default.txt` files
3. Look for differences >10% (smaller differences may be noise)

### Key Metrics:
- **Score (ops/s)**: Higher is better
- **Error**: Lower is better (more consistent)

## Comparing Different GC

Compare results across:
- **Default GC**: Usually G1GC on modern JVMs
- **G1GC**: General-purpose, low-latency GC
- **ZGC**: Ultra-low latency GC (Java 21+)
- **Parallel GC**: High-throughput GC

Look at:
1. Throughput (ops/s) - higher is better
2. GC pause times in gc_*.log files
3. Memory usage patterns

## JVM Tuning Recommendations

Based on results, you may want to:
- Use **G1GC** for balanced performance
- Use **ZGC** for low-latency requirements
- Use **Parallel GC** for high-throughput batch processing
- Adjust heap size: `-Xms4g -Xmx4g`
- Tune GC parameters based on workload

## Analyzing GC Logs

```bash
# View GC pause times
grep "Pause" gc_g1.log

# Count GC events
grep "GC" gc_g1.log | wc -l

# Average pause time
grep "Pause" gc_zgc.log | awk '{sum+=$NF; count++} END {print sum/count}'
```

EOFSUM

# Add run-specific information
{
    echo ""
    echo "## This Run"
    echo "- System: $SYSTEM_NAME"
    echo "- Date: $(date)"
    echo "- Java Version: $(java -version 2>&1 | head -n 1)"
    echo "- CPU Cores: $(nproc)"
    echo "- Total RAM: $(free -h | grep Mem | awk '{print $2}')"
    echo ""
    echo "## Quick Results Summary"
    echo ""
    echo "### Default GC Top 5 Results:"
    grep "thrpt" "$RESULTS_DIR/java_benchmark_default.txt" | head -n 5
} >> "$RESULTS_DIR/README.md"

echo -e "${GREEN}✓ Summary report generated${NC}\n"

# ============================================================
# Final Summary
# ============================================================
echo -e "${BOLD}${GREEN}"
cat << "EOF"
╔═══════════════════════════════════════════════════════════════╗
║                                                               ║
║          JAVA BENCHMARKS COMPLETED SUCCESSFULLY!              ║
║                                                               ║
╚═══════════════════════════════════════════════════════════════╝
EOF
echo -e "${NC}"

echo -e "${CYAN}Results saved to: ${BOLD}$RESULTS_DIR/${NC}\n"

echo -e "${YELLOW}Quick Overview:${NC}"
echo "  - System info:       $RESULTS_DIR/system_info.txt"
echo "  - Default GC:        $RESULTS_DIR/java_benchmark_default.txt"
echo "  - G1GC:              $RESULTS_DIR/java_benchmark_g1gc.txt"
if [ "$JAVA_VERSION" -ge 21 ]; then
    echo "  - ZGC:               $RESULTS_DIR/java_benchmark_zgc.txt"
fi
echo "  - Parallel GC:       $RESULTS_DIR/java_benchmark_parallel.txt"
echo ""

echo -e "${YELLOW}View Top Results:${NC}"
echo "  grep 'thrpt' $RESULTS_DIR/java_benchmark_default.txt | head -10"
echo ""

echo -e "${YELLOW}View GC Logs:${NC}"
echo "  less $RESULTS_DIR/gc_g1.log"
echo ""

echo -e "${YELLOW}Compare with Another System:${NC}"
echo "  1. Run this script on the other system"
echo "  2. Compare benchmark files side-by-side"
echo "  3. Look for >10% differences in ops/s"
echo ""

echo -e "${GREEN}Done! 🎉${NC}\n"