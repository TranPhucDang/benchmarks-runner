package benchmark

import (
	"crypto/sha256"
	"encoding/json"
	"math/rand"
	"sort"
	"strings"
	"sync"
	"testing"
	"time"
)

// ============================================================
// CPU-Intensive Benchmarks
// ============================================================

func BenchmarkFibonacci20(b *testing.B) {
	for i := 0; i < b.N; i++ {
		fibonacci(20)
	}
}

func BenchmarkFibonacci30(b *testing.B) {
	for i := 0; i < b.N; i++ {
		fibonacci(30)
	}
}

func fibonacci(n int) int {
	if n <= 1 {
		return n
	}
	return fibonacci(n-1) + fibonacci(n-2)
}

func BenchmarkPrimeGeneration10K(b *testing.B) {
	for i := 0; i < b.N; i++ {
		generatePrimes(10000)
	}
}

func BenchmarkPrimeGeneration50K(b *testing.B) {
	for i := 0; i < b.N; i++ {
		generatePrimes(50000)
	}
}

func generatePrimes(limit int) []int {
	primes := []int{}
	for i := 2; i < limit; i++ {
		if isPrime(i) {
			primes = append(primes, i)
		}
	}
	return primes
}

func isPrime(n int) bool {
	if n < 2 {
		return false
	}
	for i := 2; i*i <= n; i++ {
		if n%i == 0 {
			return false
		}
	}
	return true
}

func BenchmarkMatrixMultiply50x50(b *testing.B) {
	a, mat := createMatrix(50), createMatrix(50)
	b.ResetTimer()
	for i := 0; i < b.N; i++ {
		multiplyMatrix(a, mat)
	}
}

func BenchmarkMatrixMultiply100x100(b *testing.B) {
	a, mat := createMatrix(100), createMatrix(100)
	b.ResetTimer()
	for i := 0; i < b.N; i++ {
		multiplyMatrix(a, mat)
	}
}

func createMatrix(size int) [][]int {
	matrix := make([][]int, size)
	for i := range matrix {
		matrix[i] = make([]int, size)
		for j := range matrix[i] {
			matrix[i][j] = rand.Intn(100)
		}
	}
	return matrix
}

func multiplyMatrix(a, b [][]int) [][]int {
	n := len(a)
	result := make([][]int, n)
	for i := range result {
		result[i] = make([]int, n)
	}
	for i := 0; i < n; i++ {
		for j := 0; j < n; j++ {
			for k := 0; k < n; k++ {
				result[i][j] += a[i][k] * b[k][j]
			}
		}
	}
	return result
}

// ============================================================
// Memory Benchmarks
// ============================================================

func BenchmarkSortingInts100K(b *testing.B) {
	data := make([]int, 100000)
	for i := range data {
		data[i] = rand.Intn(1000000)
	}
	b.ResetTimer()
	for i := 0; i < b.N; i++ {
		sorted := make([]int, len(data))
		copy(sorted, data)
		sort.Ints(sorted)
	}
}

func BenchmarkSortingInts1M(b *testing.B) {
	data := make([]int, 1000000)
	for i := range data {
		data[i] = rand.Intn(1000000)
	}
	b.ResetTimer()
	for i := 0; i < b.N; i++ {
		sorted := make([]int, len(data))
		copy(sorted, data)
		sort.Ints(sorted)
	}
}

func BenchmarkMemoryAllocation1MB(b *testing.B) {
	for i := 0; i < b.N; i++ {
		data := make([]byte, 1024*1024)
		_ = data
	}
}

func BenchmarkMemoryAllocation10MB(b *testing.B) {
	for i := 0; i < b.N; i++ {
		data := make([]byte, 10*1024*1024)
		_ = data
	}
}

func BenchmarkMapOperations1K(b *testing.B) {
	for i := 0; i < b.N; i++ {
		m := make(map[int]string)
		for j := 0; j < 1000; j++ {
			m[j] = "value"
		}
		for j := 0; j < 1000; j++ {
			_ = m[j]
		}
	}
}

func BenchmarkMapOperations10K(b *testing.B) {
	for i := 0; i < b.N; i++ {
		m := make(map[int]string)
		for j := 0; j < 10000; j++ {
			m[j] = "value"
		}
		for j := 0; j < 10000; j++ {
			_ = m[j]
		}
	}
}

// ============================================================
// String Operations
// ============================================================

func BenchmarkStringConcatenation1K(b *testing.B) {
	for i := 0; i < b.N; i++ {
		s := ""
		for j := 0; j < 1000; j++ {
			s += "a"
		}
	}
}

func BenchmarkStringBuilder1K(b *testing.B) {
	for i := 0; i < b.N; i++ {
		var sb strings.Builder
		for j := 0; j < 1000; j++ {
			sb.WriteString("a")
		}
		_ = sb.String()
	}
}

// ============================================================
// JSON Serialization
// ============================================================

type ComplexData struct {
	ID       int                    `json:"id"`
	Name     string                 `json:"name"`
	Email    string                 `json:"email"`
	Age      int                    `json:"age"`
	Active   bool                   `json:"active"`
	Tags     []string               `json:"tags"`
	Metadata map[string]interface{} `json:"metadata"`
	Created  time.Time              `json:"created"`
}

func BenchmarkJSONMarshal(b *testing.B) {
	data := ComplexData{
		ID:      1,
		Name:    "Test User",
		Email:   "test@example.com",
		Age:     30,
		Active:  true,
		Tags:    []string{"tag1", "tag2", "tag3"},
		Metadata: map[string]interface{}{
			"key1": "value1",
			"key2": 123,
			"key3": true,
		},
		Created: time.Now(),
	}
	b.ResetTimer()
	for i := 0; i < b.N; i++ {
		_, _ = json.Marshal(data)
	}
}

func BenchmarkJSONUnmarshal(b *testing.B) {
	jsonData := []byte(`{"id":1,"name":"Test User","email":"test@example.com","age":30,"active":true,"tags":["tag1","tag2","tag3"],"metadata":{"key1":"value1","key2":123,"key3":true},"created":"2024-01-01T00:00:00Z"}`)
	b.ResetTimer()
	for i := 0; i < b.N; i++ {
		var data ComplexData
		_ = json.Unmarshal(jsonData, &data)
	}
}

func BenchmarkJSONMarshalArray100(b *testing.B) {
	data := make([]ComplexData, 100)
	for i := range data {
		data[i] = ComplexData{
			ID:      i,
			Name:    "User " + string(rune(i)),
			Email:   "user@example.com",
			Age:     20 + i%50,
			Created: time.Now(),
		}
	}
	b.ResetTimer()
	for i := 0; i < b.N; i++ {
		_, _ = json.Marshal(data)
	}
}

// ============================================================
// Cryptographic Operations
// ============================================================

func BenchmarkSHA256Small(b *testing.B) {
	data := []byte("Hello, World!")
	b.ResetTimer()
	for i := 0; i < b.N; i++ {
		_ = sha256.Sum256(data)
	}
}

func BenchmarkSHA256Large(b *testing.B) {
	data := make([]byte, 1024*1024)
	rand.Read(data)
	b.ResetTimer()
	for i := 0; i < b.N; i++ {
		_ = sha256.Sum256(data)
	}
}

// ============================================================
// Concurrency Benchmarks
// ============================================================

func BenchmarkGoroutines10(b *testing.B) {
	for i := 0; i < b.N; i++ {
		var wg sync.WaitGroup
		for j := 0; j < 10; j++ {
			wg.Add(1)
			go func() {
				defer wg.Done()
				sum := 0
				for k := 0; k < 10000; k++ {
					sum += k
				}
			}()
		}
		wg.Wait()
	}
}

func BenchmarkGoroutines100(b *testing.B) {
	for i := 0; i < b.N; i++ {
		var wg sync.WaitGroup
		for j := 0; j < 100; j++ {
			wg.Add(1)
			go func() {
				defer wg.Done()
				sum := 0
				for k := 0; k < 1000; k++ {
					sum += k
				}
			}()
		}
		wg.Wait()
	}
}

func BenchmarkGoroutines1000(b *testing.B) {
	for i := 0; i < b.N; i++ {
		var wg sync.WaitGroup
		for j := 0; j < 1000; j++ {
			wg.Add(1)
			go func() {
				defer wg.Done()
				sum := 0
				for k := 0; k < 100; k++ {
					sum += k
				}
			}()
		}
		wg.Wait()
	}
}

func BenchmarkChannelOperations(b *testing.B) {
	for i := 0; i < b.N; i++ {
		ch := make(chan int, 100)
		var wg sync.WaitGroup
		wg.Add(2)
		go func() {
			defer wg.Done()
			for j := 0; j < 100; j++ {
				ch <- j
			}
			close(ch)
		}()
		go func() {
			defer wg.Done()
			for range ch {
			}
		}()
		wg.Wait()
	}
}

func BenchmarkMutexContention(b *testing.B) {
	var mu sync.Mutex
	counter := 0
	b.RunParallel(func(pb *testing.PB) {
		for pb.Next() {
			mu.Lock()
			counter++
			mu.Unlock()
		}
	})
}

func BenchmarkRWMutexReadHeavy(b *testing.B) {
	var mu sync.RWMutex
	data := make(map[int]int)
	for i := 0; i < 100; i++ {
		data[i] = i
	}
	
	b.RunParallel(func(pb *testing.PB) {
		for pb.Next() {
			mu.RLock()
			_ = data[rand.Intn(100)]
			mu.RUnlock()
		}
	})
}
