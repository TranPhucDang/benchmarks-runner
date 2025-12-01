package benchmark;

import org.openjdk.jmh.annotations.*;
import com.fasterxml.jackson.databind.ObjectMapper;

import java.security.MessageDigest;
import java.util.*;
import java.util.concurrent.*;
import java.util.concurrent.atomic.AtomicInteger;

@State(Scope.Benchmark)
@BenchmarkMode(Mode.Throughput)
@Warmup(iterations = 3, time = 2)
@Measurement(iterations = 5, time = 2)
@Fork(1)
@OutputTimeUnit(TimeUnit.SECONDS)
public class CompleteBenchmarks {

    private Random random = new Random(42);
    private ObjectMapper objectMapper = new ObjectMapper();
    private ExecutorService executorService;

    @Setup(Level.Trial)
    public void setupExecutor() {
        executorService = Executors.newFixedThreadPool(100);
    }

    @TearDown(Level.Trial)
    public void tearDownExecutor() {
        executorService.shutdown();
        try {
            if (!executorService.awaitTermination(60, TimeUnit.SECONDS)) {
                executorService.shutdownNow();
            }
        } catch (InterruptedException e) {
            executorService.shutdownNow();
        }
    }

    // ============================================================
    // CPU-Intensive Benchmarks
    // ============================================================

    @Benchmark
    public int benchmarkFibonacci20() {
        return fibonacci(20);
    }

    @Benchmark
    public int benchmarkFibonacci30() {
        return fibonacci(30);
    }

    private int fibonacci(int n) {
        if (n <= 1) return n;
        return fibonacci(n - 1) + fibonacci(n - 2);
    }

    @Benchmark
    public List<Integer> benchmarkPrimeGeneration10K() {
        return generatePrimes(10000);
    }

    @Benchmark
    public List<Integer> benchmarkPrimeGeneration50K() {
        return generatePrimes(50000);
    }

    private List<Integer> generatePrimes(int limit) {
        List<Integer> primes = new ArrayList<>();
        for (int i = 2; i < limit; i++) {
            if (isPrime(i)) {
                primes.add(i);
            }
        }
        return primes;
    }

    private boolean isPrime(int n) {
        if (n < 2) return false;
        for (int i = 2; i * i <= n; i++) {
            if (n % i == 0) return false;
        }
        return true;
    }

    private int[][] matrix50a, matrix50b;
    private int[][] matrix100a, matrix100b;

    @Setup(Level.Trial)
    public void setupMatrices() {
        matrix50a = createMatrix(50);
        matrix50b = createMatrix(50);
        matrix100a = createMatrix(100);
        matrix100b = createMatrix(100);
    }

    @Benchmark
    public int[][] benchmarkMatrixMultiply50x50() {
        return multiplyMatrix(matrix50a, matrix50b);
    }

    @Benchmark
    public int[][] benchmarkMatrixMultiply100x100() {
        return multiplyMatrix(matrix100a, matrix100b);
    }

    private int[][] createMatrix(int size) {
        int[][] matrix = new int[size][size];
        for (int i = 0; i < size; i++) {
            for (int j = 0; j < size; j++) {
                matrix[i][j] = random.nextInt(100);
            }
        }
        return matrix;
    }

    private int[][] multiplyMatrix(int[][] a, int[][] b) {
        int n = a.length;
        int[][] result = new int[n][n];
        for (int i = 0; i < n; i++) {
            for (int j = 0; j < n; j++) {
                for (int k = 0; k < n; k++) {
                    result[i][j] += a[i][k] * b[k][j];
                }
            }
        }
        return result;
    }

    // ============================================================
    // Memory Benchmarks
    // ============================================================

    private int[] sortData100K, sortData1M;

    @Setup(Level.Trial)
    public void setupSortingData() {
        sortData100K = new int[100000];
        sortData1M = new int[1000000];
        for (int i = 0; i < sortData100K.length; i++) {
            sortData100K[i] = random.nextInt(1000000);
        }
        for (int i = 0; i < sortData1M.length; i++) {
            sortData1M[i] = random.nextInt(1000000);
        }
    }

    @Benchmark
    public int[] benchmarkSortingInts100K() {
        int[] copy = Arrays.copyOf(sortData100K, sortData100K.length);
        Arrays.sort(copy);
        return copy;
    }

    @Benchmark
    public int[] benchmarkSortingInts1M() {
        int[] copy = Arrays.copyOf(sortData1M, sortData1M.length);
        Arrays.sort(copy);
        return copy;
    }

    @Benchmark
    public byte[] benchmarkMemoryAllocation1MB() {
        return new byte[1024 * 1024];
    }

    @Benchmark
    public byte[] benchmarkMemoryAllocation10MB() {
        return new byte[10 * 1024 * 1024];
    }

    @Benchmark
    public void benchmarkMapOperations1K() {
        Map<Integer, String> map = new HashMap<>();
        for (int i = 0; i < 1000; i++) {
            map.put(i, "value");
        }
        for (int i = 0; i < 1000; i++) {
            map.get(i);
        }
    }

    @Benchmark
    public void benchmarkMapOperations10K() {
        Map<Integer, String> map = new HashMap<>();
        for (int i = 0; i < 10000; i++) {
            map.put(i, "value");
        }
        for (int i = 0; i < 10000; i++) {
            map.get(i);
        }
    }

    // ============================================================
    // String Operations
    // ============================================================

    @Benchmark
    public String benchmarkStringConcatenation1K() {
        String s = "";
        for (int i = 0; i < 1000; i++) {
            s += "a";
        }
        return s;
    }

    @Benchmark
    public String benchmarkStringBuilder1K() {
        StringBuilder sb = new StringBuilder();
        for (int i = 0; i < 1000; i++) {
            sb.append("a");
        }
        return sb.toString();
    }

    // ============================================================
    // JSON Serialization
    // ============================================================

    public static class ComplexData {
        public int id;
        public String name;
        public String email;
        public int age;
        public boolean active;
        public List<String> tags;
        public Map<String, Object> metadata;

        public ComplexData() {
            this.id = 1;
            this.name = "Test User";
            this.email = "test@example.com";
            this.age = 30;
            this.active = true;
            this.tags = Arrays.asList("tag1", "tag2", "tag3");
            this.metadata = new HashMap<>();
            metadata.put("key1", "value1");
            metadata.put("key2", 123);
            metadata.put("key3", true);
        }
    }

    private ComplexData testData = new ComplexData();
    private String jsonString;

    @Setup(Level.Trial)
    public void setupJSON() throws Exception {
        jsonString = objectMapper.writeValueAsString(testData);
    }

    @Benchmark
    public String benchmarkJSONMarshal() throws Exception {
        return objectMapper.writeValueAsString(testData);
    }

    @Benchmark
    public ComplexData benchmarkJSONUnmarshal() throws Exception {
        return objectMapper.readValue(jsonString, ComplexData.class);
    }

    @Benchmark
    public String benchmarkJSONMarshalArray100() throws Exception {
        List<ComplexData> data = new ArrayList<>();
        for (int i = 0; i < 100; i++) {
            data.add(new ComplexData());
        }
        return objectMapper.writeValueAsString(data);
    }

    // ============================================================
    // Cryptographic Operations
    // ============================================================

    private byte[] smallData = "Hello, World!".getBytes();
    private byte[] largeData;

    @Setup(Level.Trial)
    public void setupCryptoData() {
        largeData = new byte[1024 * 1024];
        random.nextBytes(largeData);
    }

    @Benchmark
    public byte[] benchmarkSHA256Small() throws Exception {
        MessageDigest digest = MessageDigest.getInstance("SHA-256");
        return digest.digest(smallData);
    }

    @Benchmark
    public byte[] benchmarkSHA256Large() throws Exception {
        MessageDigest digest = MessageDigest.getInstance("SHA-256");
        return digest.digest(largeData);
    }

    // ============================================================
    // Concurrency Benchmarks
    // ============================================================

    @Benchmark
    public void benchmarkThreads10() throws Exception {
        CountDownLatch latch = new CountDownLatch(10);
        for (int i = 0; i < 10; i++) {
            executorService.submit(() -> {
                try {
                    int sum = 0;
                    for (int k = 0; k < 10000; k++) {
                        sum += k;
                    }
                } finally {
                    latch.countDown();
                }
            });
        }
        latch.await();
    }

    @Benchmark
    public void benchmarkThreads100() throws Exception {
        CountDownLatch latch = new CountDownLatch(100);
        for (int i = 0; i < 100; i++) {
            executorService.submit(() -> {
                try {
                    int sum = 0;
                    for (int k = 0; k < 1000; k++) {
                        sum += k;
                    }
                } finally {
                    latch.countDown();
                }
            });
        }
        latch.await();
    }

    @Benchmark
    public void benchmarkThreads1000() throws Exception {
        CountDownLatch latch = new CountDownLatch(1000);
        for (int i = 0; i < 1000; i++) {
            executorService.submit(() -> {
                try {
                    int sum = 0;
                    for (int k = 0; k < 100; k++) {
                        sum += k;
                    }
                } finally {
                    latch.countDown();
                }
            });
        }
        latch.await();
    }

    @Benchmark
    public void benchmarkBlockingQueueOperations() throws Exception {
        BlockingQueue<Integer> queue = new ArrayBlockingQueue<>(100);
        CountDownLatch latch = new CountDownLatch(2);
        
        executorService.submit(() -> {
            try {
                for (int j = 0; j < 100; j++) {
                    queue.put(j);
                }
            } catch (InterruptedException e) {
                Thread.currentThread().interrupt();
            } finally {
                latch.countDown();
            }
        });
        
        executorService.submit(() -> {
            try {
                for (int j = 0; j < 100; j++) {
                    queue.take();
                }
            } catch (InterruptedException e) {
                Thread.currentThread().interrupt();
            } finally {
                latch.countDown();
            }
        });
        
        latch.await();
    }

    private AtomicInteger atomicCounter = new AtomicInteger(0);

    @Benchmark
    @Threads(4)
    public void benchmarkAtomicContention() {
        atomicCounter.incrementAndGet();
    }

    @Benchmark
    public void benchmarkConcurrentHashMap() {
        ConcurrentHashMap<Integer, String> map = new ConcurrentHashMap<>();
        for (int i = 0; i < 1000; i++) {
            map.put(i, "value");
        }
        for (int i = 0; i < 1000; i++) {
            map.get(i);
        }
    }
}
