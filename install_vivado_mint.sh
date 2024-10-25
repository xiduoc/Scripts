#!/bin/bash

# Script cài đặt Vivado ML Standard Edition trên Linux Mint
# Yêu cầu file cài đặt dạng .bin đã được tải về

# Kiểm tra quyền root
if [ "$EUID" -ne 0 ]; then 
    echo "Vui lòng chạy script với quyền root (sudo)"
    exit 1
fi

# Cài đặt các gói phụ thuộc cần thiết
echo "Đang cài đặt các gói phụ thuộc..."
apt-get update
apt-get install -y \
    build-essential \
    git \
    libtinfo5 \
    libncurses5-dev \
    libx11-dev \
    libxterm-dev \
    libxtst-dev \
    libxi-dev \
    gcc-multilib \
    libc6-i386 \
    libstdc++6:i386 \
    lib32stdc++6

# Tạo thư mục cài đặt
INSTALL_DIR="/opt/Xilinx"
mkdir -p $INSTALL_DIR

# Kiểm tra file cài đặt
INSTALLER_PATH=""
read -p "Nhập đường dẫn đến file cài đặt Vivado (.bin): " INSTALLER_PATH

if [ ! -f "$INSTALLER_PATH" ]; then
    echo "Không tìm thấy file cài đặt tại: $INSTALLER_PATH"
    exit 1
fi

# Cấp quyền thực thi cho file cài đặt
chmod +x "$INSTALLER_PATH"

# Tạo file config cho cài đặt tự động
CONFIG_FILE="/tmp/vivado_config.txt"
cat << EOF > $CONFIG_FILE
#### Vivado ML Standard Edition Install Configuration ####
Edition=Vivado ML Standard
# Path where Xilinx software will be installed.
Destination=$INSTALL_DIR
# Choose the Products/Devices the you would like to install.
# Chỉ chọn các device được hỗ trợ trong bản Standard
Modules=Artix-7:1,Zynq-7000:1,Spartan-7:1,DocNav:1
# Choose the post install scripts you'd like to run as part of the installation.
InstallOptions=Acquire or Manage a License Key:1
## Shortcuts and File associations ##
# Choose whether Start menu/Application menu shortcuts will be created or not.
CreateProgramGroupShortcuts=1
# Choose the name of the Start menu/Application menu shortcut.
ProgramGroupFolder=Xilinx Design Tools
# Choose whether shortcuts will be created for All users or just the Current user.
CreateShortcutsForAllUsers=0
# Choose whether shortcuts will be created on the desktop or not.
CreateDesktopShortcuts=1
# Choose whether file associations will be created or not.
CreateFileAssociation=1
EOF

# Chạy cài đặt
echo "Bắt đầu cài đặt Vivado ML Standard..."
"$INSTALLER_PATH" --agree 3rdPartyEULA,WebTalkTerms,XilinxEULA --batch Install --config "$CONFIG_FILE"

# Xóa file config tạm
rm -f "$CONFIG_FILE"

# Tạo biến môi trường
echo "Thiết lập biến môi trường..."
VIVADO_SCRIPT="/etc/profile.d/vivado.sh"
cat << EOF > $VIVADO_SCRIPT
export XILINX_VIVADO=$INSTALL_DIR/Vivado/\$(ls $INSTALL_DIR/Vivado)
export PATH=\$PATH:\$XILINX_VIVADO/bin
EOF

source "$VIVADO_SCRIPT"

echo "Cài đặt hoàn tất!"
echo "Hướng dẫn sau khi cài đặt:"
echo "1. Đăng xuất và đăng nhập lại để áp dụng các thay đổi môi trường"
echo "2. Khởi động Vivado và đăng nhập vào tài khoản Xilinx của bạn"
echo "3. Tạo giấy phép miễn phí trong Vivado License Manager"
echo "4. Bạn có thể chạy Vivado bằng lệnh: vivado"