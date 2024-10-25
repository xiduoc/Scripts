#!/bin/bash

# Kiểm tra quyền root
if [ "$EUID" -ne 0 ]; then 
    echo "Script này cần chạy với quyền root"
    echo "Vui lòng chạy lại với sudo"
    exit 1
fi

# Function để kiểm tra lệnh đã được cài đặt chưa
check_command() {
    if ! command -v "$1" &> /dev/null; then
        return 1
    else
        return 0
    fi
}

# Function để in thông báo
print_status() {
    echo "----------------------------------------"
    echo "$1"
    echo "----------------------------------------"
}

# Cập nhật package list
print_status "Cập nhật package list..."
apt-get update

# Cài đặt các package cần thiết để build từ source
print_status "Cài đặt các package build essential..."
apt-get install -y \
    build-essential \
    git \
    make \
    autoconf \
    gperf \
    flex \
    bison \
    curl \
    libreadline-dev \
    gawk \
    tcl-dev \
    libffi-dev \
    graphviz \
    xdot \
    pkg-config \
    python3 \
    python3-pip \
    zlib1g-dev

# Tạo thư mục làm việc
WORK_DIR="/tmp/iverilog_setup"
mkdir -p "$WORK_DIR"
cd "$WORK_DIR" || exit

# Cài đặt Icarus Verilog
if ! check_command "iverilog"; then
    print_status "Cài đặt Icarus Verilog..."
    
    # Clone repository
    git clone https://github.com/steveicarus/iverilog.git
    cd iverilog || exit
    
    # Build và cài đặt
    sh autoconf.sh
    ./configure
    make
    make install
    
    # Cập nhật shared library cache
    ldconfig
    
    cd "$WORK_DIR" || exit
else
    print_status "Icarus Verilog đã được cài đặt"
fi

# Cài đặt GTKWave
if ! check_command "gtkwave"; then
    print_status "Cài đặt GTKWave..."
    apt-get install -y gtkwave
else
    print_status "GTKWave đã được cài đặt"
fi

# Tạo thư mục project mẫu
PROJECT_DIR="$HOME/verilog_projects"
mkdir -p "$PROJECT_DIR/example"

# Tạo file Verilog mẫu
cat > "$PROJECT_DIR/example/counter.v" << 'EOL'
module counter (
    input wire clk,
    input wire reset,
    output reg [3:0] count
);

always @(posedge clk or posedge reset) begin
    if (reset)
        count <= 4'b0000;
    else
        count <= count + 1;
end

endmodule
EOL

# Tạo testbench mẫu
cat > "$PROJECT_DIR/example/counter_tb.v" << 'EOL'
module counter_tb;
    reg clk;
    reg reset;
    wire [3:0] count;

    // Instantiate the counter
    counter dut (
        .clk(clk),
        .reset(reset),
        .count(count)
    );

    // Clock generation
    initial begin
        clk = 0;
        forever #5 clk = ~clk;
    end

    // Test stimulus
    initial begin
        $dumpfile("counter_tb.vcd");
        $dumpvars(0, counter_tb);

        // Reset the counter
        reset = 1;
        #10 reset = 0;

        // Let it count for a while
        #200;

        // End simulation
        $finish;
    end

    // Monitor changes
    initial
        $monitor("Time=%0t reset=%b count=%b",
                 $time, reset, count);
endmodule
EOL

# Tạo script compile và run
cat > "$PROJECT_DIR/example/run_sim.sh" << 'EOL'
#!/bin/bash

# Compile the design
iverilog -o sim counter.v counter_tb.v

# Run the simulation
./sim

# View the waveform
gtkwave counter_tb.vcd &
EOL

# Cấp quyền thực thi cho script
chmod +x "$PROJECT_DIR/example/run_sim.sh"

# Tạo file README
cat > "$PROJECT_DIR/example/README.md" << 'EOL'
# Verilog Counter Example

Đây là một ví dụ đơn giản về counter 4-bit trong Verilog.

## Cấu trúc thư mục
- counter.v: Module counter chính
- counter_tb.v: Testbench
- run_sim.sh: Script để chạy simulation

## Cách sử dụng
1. Chạy simulation:
   ```bash
   ./run_sim.sh
   ```

2. Trong GTKWave:
   - Chọn counter_tb trong SST
   - Thêm các tín hiệu cần xem vào waveform
   - Zoom để xem chi tiết

## Tín hiệu
- clk: Clock input
- reset: Reset input
- count: 4-bit counter output
EOL

# Dọn dẹp
cd "$HOME" || exit
rm -rf "$WORK_DIR"

print_status "Cài đặt hoàn tất!"
echo "
Đã cài đặt:
- Icarus Verilog: $(iverilog -V | head -n 1)
- GTKWave: $(gtkwave --version 2>&1 | head -n 1)

Một project mẫu đã được tạo tại: $PROJECT_DIR/example
Để chạy project mẫu:
cd $PROJECT_DIR/example
./run_sim.sh
"