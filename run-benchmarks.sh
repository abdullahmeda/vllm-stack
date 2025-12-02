#!/bin/bash

# Configuration
VLLM_ENDPOINT="http://localhost:30080/v1"
RESULTS_DIR="./results"
LLMPERF_DIR="./llmperf"

# Ensure llmperf is present
if [ ! -d "$LLMPERF_DIR" ]; then
    echo "Error: llmperf directory not found at $LLMPERF_DIR"
    echo "Please run 'make clone-repos' or clone it manually."
    exit 1
fi

# Setup Environment
export OPENAI_API_BASE="$VLLM_ENDPOINT"
export OPENAI_API_KEY="test"

# Function to run benchmark
run_benchmark() {
    local name=$1
    local model=$2
    local concurrent=$3
    local total=$4
    local input_len=$5
    local output_len=$6
    
    echo "----------------------------------------------------------------"
    echo "Running Benchmark: $name"
    echo "Model: $model"
    echo "Concurrency: $concurrent"
    echo "Total Requests: $total"
    echo "----------------------------------------------------------------"
    
    mkdir -p "$RESULTS_DIR/$name"
    
    python "$LLMPERF_DIR/token_benchmark_ray.py" \
        --model "$model" \
        --mean-input-tokens "$input_len" \
        --stddev-input-tokens 50 \
        --mean-output-tokens "$output_len" \
        --stddev-output-tokens 20 \
        --num-concurrent-requests "$concurrent" \
        --max-num-completed-requests "$total" \
        --timeout 600 \
        --llm-api openai \
        --results-dir "$RESULTS_DIR/$name"
        
    echo "✅ Benchmark $name complete! Results in $RESULTS_DIR/$name"
}

# Menu
echo "vLLM Load Testing Tool"
echo "1. Quick Test (Qwen3-8B, 5 concurrent)"
echo "2. Heavy Load (Qwen3-8B, 20 concurrent)"
echo "3. LoRA Adapter Test (Translator, 10 concurrent)"
echo "4. Vision Model Test (Qwen3-VL-30B, 3 concurrent)"
echo "5. Mixed Workload (Base + LoRA)"
echo "0. Exit"

read -p "Select an option: " option

case $option in
    1)
        run_benchmark "quick-test" "Qwen/Qwen3-8B" 5 20 256 128
        ;;
    2)
        run_benchmark "heavy-load" "Qwen/Qwen3-8B" 20 100 512 256
        ;;
    3)
        run_benchmark "lora-test" "Qwen3-8B-Translator-LoRA" 10 50 200 100
        ;;
    4)
        run_benchmark "vision-test" "Qwen/Qwen3-VL-30B-A3B-Instruct" 3 30 400 200
        ;;
    5)
        echo "Starting Mixed Workload (Parallel Tests)..."
        run_benchmark "mixed-base" "Qwen/Qwen3-8B" 10 50 256 128 &
        PID1=$!
        run_benchmark "mixed-lora" "Qwen3-8B-Translator-LoRA" 10 50 256 128 &
        PID2=$!
        wait $PID1 $PID2
        echo "✅ Mixed workload complete!"
        ;;
    0)
        exit 0
        ;;
    *)
        echo "Invalid option"
        exit 1
        ;;
esac
