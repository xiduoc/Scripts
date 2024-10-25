#!/bin/bash

# Kiểm tra quyền root
if [ "$EUID" -ne 0 ]; then 
    echo "Script này cần chạy với quyền root"
    echo "Vui lòng chạy lại với sudo"
    exit 1
fi

# Lấy real user
REAL_USER="${SUDO_USER:-$USER}"
REAL_HOME=$(getent passwd "$REAL_USER" | cut -d: -f6)

# Function để in thông báo
print_status() {
    echo "----------------------------------------"
    echo "$1"
    echo "----------------------------------------"
}

# Function để kiểm tra đường dẫn installer
check_installer() {
    if [ ! -f "$VIVADO_INSTALLER" ]; then
        echo "Không tìm thấy file installer Vivado tại: $VIVADO_INSTALLER"
        echo "Vui lòng tải Vivado từ trang web Xilinx và đặt đường dẫn đúng"
        exit 1
    fi
}

# Cài đặt các dependencies cần thiết
print_status "Cài đặt dependencies..."
apt-get update
apt-get install -y \
    build-essential \
    git \
    make \
    net-tools \
    libtinfo5 \
    libncurses5 \
    libncurses5-dev \
    libncursesw5-dev \
    xterm \
    python3 \
    python3-pip \
    gcc-multilib \
    g++-multilib \
    libc6-dev-i386 \
    lib32z1 \
    lib32stdc++6 \
    libgtk2.0-0 \
    dpkg-dev \
    libffi-dev \
    libssl-dev \
    default-jre \
    default-jdk \
    perl \
    openssh-server \
    locales \
    csh \
    libxtst6 \
    libxrender1 \
    libxi6 \
    libglib2.0-0 \
    libqt5widgets5 \
    libqt5gui5 \
    libqt5core5a \
    libqt5printsupport5 \
    libqt5multimedia5

# Tạo thư mục cài đặt
INSTALL_DIR="/opt/Xilinx"
mkdir -p "$INSTALL_DIR"
chown "$REAL_USER":"$REAL_USER" "$INSTALL_DIR"

# Tạo config file
CONFIG_FILE="/tmp/vivado_config.txt"
cat > "$CONFIG_FILE" << 'EOL'
#### Vivado ML Enterprise Install Configuration ####
Edition=Vivado ML Standard
Destination=$INSTALL_DIR

# Choose the Products/Devices the you would like to install
Modules= Virtex UltraScale+:0,Zynq UltraScale+ MPSoC:1,Zynq-7000:1

# Choose the post install scripts you'd like to run as part of the installation.
InstallOptions=Enable WebTalk for SDK to send usage statistics to Xilinx:0

## Shortcuts and File associations ##
CreateProgramGroupShortcuts=1
CreateDesktopShortcuts=1
CreateFileAssociation=1

EOL

# Tạo script để thêm các biến môi trường
ENV_SCRIPT="$REAL_HOME/.xilinx_env.sh"
cat > "$ENV_SCRIPT" << EOL
# Xilinx Vivado Environment Variables
export XILINX_VIVADO=\$INSTALL_DIR/Vivado/\$(ls \$INSTALL_DIR/Vivado)
export PATH=\$PATH:\$XILINX_VIVADO/bin
EOL

# Thêm source env script vào .bashrc nếu chưa có
if ! grep -q "source ~/.xilinx_env.sh" "$REAL_HOME/.bashrc"; then
    echo "source ~/.xilinx_env.sh" >> "$REAL_HOME/.bashrc"
fi

# Cấp quyền cho env script
chown "$REAL_USER":"$REAL_USER" "$ENV_SCRIPT"
chmod +x "$ENV_SCRIPT"

# Tạo launcher cho Vivado
LAUNCHER="/usr/share/applications/vivado.desktop"
cat > "$LAUNCHER" << EOL
[Desktop Entry]
Version=1.0
Type=Application
Name=Xilinx Vivado
Comment=Xilinx Vivado Design Suite
Exec=\$INSTALL_DIR/Vivado/\$(ls \$INSTALL_DIR/Vivado)/bin/vivado
Icon=\$INSTALL_DIR/Vivado/\$(ls \$INSTALL_DIR/Vivado)/doc/images/vivado_logo.png
Terminal=false
Categories=Development;
EOL

print_status "Vui lòng nhập đường dẫn đến file installer Vivado (ví dụ: /path/to/Xilinx_Vivado_2023.1_0507_1234.tar.gz):"
read -r VIVADO_INSTALLER

# Kiểm tra installer
check_installer

# Tạo thư mục tạm để giải nén
TEMP_DIR="/tmp/vivado_install"
mkdir -p "$TEMP_DIR"
cd "$TEMP_DIR" || exit

print_status "Giải nén installer..."
tar -xzf "$VIVADO_INSTALLER"

# Tìm file cài đặt
INSTALL_SCRIPT=$(find . -name "xsetup" -type f)

if [ -z "$INSTALL_SCRIPT" ]; then
    echo "Không tìm thấy script cài đặt trong file installer"
    exit 1
fi

print_status "Bắt đầu cài đặt Vivado..."
chmod +x "$INSTALL_SCRIPT"
"$INSTALL_SCRIPT" --agree 3rdPartyEULA,XilinxEULA --batch Install --config "$CONFIG_FILE"

# Dọn dẹp
rm -rf "$TEMP_DIR"
rm -f "$CONFIG_FILE"

print_status "Cài đặt hoàn tất!"
echo "
Thông tin quan trọng:
1. Vivado đã được cài đặt tại: $INSTALL_DIR
2. Biến môi trường đã được thêm vào: $ENV_SCRIPT
3. Launcher đã được tạo tại: $LAUNCHER

Để sử dụng Vivado:
1. Đăng xuất và đăng nhập lại để load biến môi trường
2. Khởi động Vivado từ menu ứng dụng hoặc chạy lệnh 'vivado'

Lưu ý:
- Cần license hợp lệ để sử dụng đầy đủ tính năng
- Có thể cần cấu hình cable drivers cho JTAG
"

# Hỏi về cài đặt cable drivers
read -p "Bạn có muốn cài đặt cable drivers cho JTAG không? (y/n) " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    print_status "Cài đặt cable drivers..."
    cd "$INSTALL_DIR/Vivado/$(ls "$INSTALL_DIR/Vivado")/data/xicom/cable_drivers/lin64/install_script/install_drivers" || exit
    sudo ./install_drivers
fi