#!/bin/bash

# Kiểm tra quyền root
if [ "$EUID" -ne 0 ]; then 
    echo "Script này cần chạy với quyền root"
    echo "Vui lòng chạy lại với sudo"
    exit 1
fi

# Function để kiểm tra định dạng IP
validate_ip() {
    local ip=$1
    if [[ $ip =~ ^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$ ]]; then
        IFS='.' read -r -a ip_parts <<< "$ip"
        for part in "${ip_parts[@]}"; do
            if [ "$part" -gt 255 ] || [ "$part" -lt 0 ]; then
                return 1
            fi
        done
        return 0
    else
        return 1
    fi
}

# Function để kiểm tra định dạng prefix (subnet mask)
validate_prefix() {
    local prefix=$1
    if [[ "$prefix" =~ ^[0-9]+$ ]] && [ "$prefix" -ge 0 ] && [ "$prefix" -le 32 ]; then
        return 0
    else
        return 1
    fi
}

# Hiển thị danh sách các connection hiện có
echo "Danh sách các connection hiện có:"
nmcli connection show

# Nhập tên connection
read -p "Nhập tên connection (ví dụ: Ethernet hoặc WiFi): " CON_NAME

# Kiểm tra xem connection có tồn tại không
if ! nmcli connection show "$CON_NAME" &> /dev/null; then 
    echo "Connection '$CON_NAME' không tồn tại!"
    exit 1
fi

# Nhập thông tin IP và validate
while true; do
    read -p "Nhập địa chỉ IP (ví dụ: 192.168.1.100): " IP_ADDRESS
    if validate_ip "$IP_ADDRESS"; then
        break
    else
        echo "Địa chỉ IP không hợp lệ. Vui lòng nhập lại!"
    fi
done

while true; do
    read -p "Nhập prefix (subnet mask) (ví dụ: 24 cho 255.255.255.0): " PREFIX
    if validate_prefix "$PREFIX"; then
        break
    else
        echo "Prefix không hợp lệ. Vui lòng nhập một số từ 0 đến 32!"
    fi
done

while true; do
    read -p "Nhập địa chỉ Gateway: " GATEWAY
    if validate_ip "$GATEWAY"; then
        break
    else
        echo "Địa chỉ Gateway không hợp lệ. Vui lòng nhập lại!"
    fi
done

read -p "Nhập DNS servers (phân cách bằng dấu phẩy, ví dụ: 8.8.8.8,8.8.4.4): " DNS_SERVERS

# Backup connection hiện tại
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
nmcli connection show "$CON_NAME" > "connection_backup_${TIMESTAMP}.txt"

# Cấu hình IP tĩnh
echo "Đang cấu hình IP tĩnh..."
nmcli connection modify "$CON_NAME" \
    ipv4.method manual \
    ipv4.addresses "$IP_ADDRESS/$PREFIX" \
    ipv4.gateway "$GATEWAY" \
    ipv4.dns "$DNS_SERVERS"

# Khởi động lại connection
echo "Đang khởi động lại connection..."
nmcli connection down "$CON_NAME"
nmcli connection up "$CON_NAME"

# Kiểm tra kết quả
echo -e "\nKiểm tra cấu hình mới:"
nmcli connection show "$CON_NAME" | grep -E "ipv4\.(addresses|gateway|dns)"

# Kiểm tra kết nối
echo -e "\nKiểm tra kết nối:"
ping -c 3 "$GATEWAY"

echo -e "\nCấu hình đã hoàn tất!"
echo "Backup của cấu hình cũ được lưu trong file: connection_backup_${TIMESTAMP}.txt"