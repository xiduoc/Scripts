#!/bin/bash

# Hàm kiểm tra và hiển thị lỗi
check_error() {
    if [ $? -ne 0 ]; then
        echo "Lỗi: $1"
        exit 1
    fi
}

# Hàm kiểm tra sự tồn tại của file/thư mục
check_existence() {
    if [ ! -e "$1" ]; then
        echo "Cảnh báo: $2"
        return 1
    fi
    return 0
}

# Hiển thị trạng thái hiện tại
echo "Trạng thái hiện tại:"
echo "Shell đang dùng: $SHELL"
echo "ZSH version: $(zsh --version 2>/dev/null || echo 'Chưa cài đặt')"

# Kiểm tra và cài đặt ZSH
if ! command -v zsh &> /dev/null; then
    echo "Đang cài đặt ZSH..."
    sudo apt-get update
    sudo apt-get install -y zsh
    check_error "Không thể cài đặt ZSH"
fi

# Kiểm tra lại cài đặt ZSH
if ! command -v zsh &> /dev/null; then
    echo "Lỗi: ZSH không được cài đặt thành công"
    exit 1
fi

# Cài đặt các dependency
echo "Đang cài đặt các công cụ cần thiết..."
for pkg in curl git; do
    if ! command -v $pkg &> /dev/null; then
        sudo apt-get install -y $pkg
        check_error "Không thể cài đặt $pkg"
    fi
done

# Kiểm tra và cài đặt Oh My Zsh
if [ ! -d "$HOME/.oh-my-zsh" ]; then
    echo "Đang cài đặt Oh My Zsh..."
    sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
    check_error "Không thể cài đặt Oh My Zsh"
fi

# Kiểm tra và cài đặt plugins
ZSH_CUSTOM="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}"

# Plugin autosuggestions
if [ ! -d "$ZSH_CUSTOM/plugins/zsh-autosuggestions" ]; then
    echo "Đang cài đặt zsh-autosuggestions..."
    git clone https://github.com/zsh-users/zsh-autosuggestions "$ZSH_CUSTOM/plugins/zsh-autosuggestions"
    check_error "Không thể cài đặt zsh-autosuggestions"
fi

# Plugin syntax-highlighting
if [ ! -d "$ZSH_CUSTOM/plugins/zsh-syntax-highlighting" ]; then
    echo "Đang cài đặt zsh-syntax-highlighting..."
    git clone https://github.com/zsh-users/zsh-syntax-highlighting.git "$ZSH_CUSTOM/plugins/zsh-syntax-highlighting"
    check_error "Không thể cài đặt zsh-syntax-highlighting"
fi

# Backup .zshrc hiện tại nếu tồn tại
if [ -f "$HOME/.zshrc" ]; then
    backup_file="$HOME/.zshrc.backup_$(date +%Y%m%d_%H%M%S)"
    cp "$HOME/.zshrc" "$backup_file"
    echo "Đã tạo backup tại: $backup_file"
fi

# Tạo file .zshrc mới
echo "Tạo file .zshrc mới..."
cat > "$HOME/.zshrc" << 'EOL'
# Path to oh-my-zsh installation
export ZSH="$HOME/.oh-my-zsh"

# Theme
ZSH_THEME="robbyrussell"

# Plugins
plugins=(
    git
    zsh-autosuggestions
    zsh-syntax-highlighting
    docker
    docker-compose
    npm
    yarn
    sudo
    copypath
    dirhistory
    history
    web-search
)

# Load Oh My Zsh
source $ZSH/oh-my-zsh.sh

# History configuration
HISTSIZE=10000
SAVEHIST=10000
HISTFILE=~/.zsh_history

# Autosuggestions configuration
ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE='fg=8'
ZSH_AUTOSUGGEST_STRATEGY=(history completion)
bindkey '^ ' autosuggest-accept

# Useful aliases
alias ll='ls -lah'
alias l='ls -lh'
alias zshconfig="nano ~/.zshrc"
alias ohmyzsh="nano ~/.oh-my-zsh"
alias update='sudo apt update && sudo apt upgrade -y'
alias c='clear'
alias h='history'
alias ports='netstat -tulanp'

# PATH configuration
export PATH=$HOME/bin:/usr/local/bin:$PATH

# Auto CD
setopt AUTO_CD

# Completion system
autoload -Uz compinit
compinit
EOL

# Kiểm tra file .zshrc đã được tạo
if [ ! -f "$HOME/.zshrc" ]; then
    echo "Lỗi: Không thể tạo file .zshrc"
    exit 1
fi

# Thay đổi shell mặc định sang ZSH
if [ "$SHELL" != "$(which zsh)" ]; then
    echo "Thay đổi shell mặc định sang ZSH..."
    sudo chsh -s $(which zsh) $USER
    check_error "Không thể thay đổi shell mặc định"
fi

# Kiểm tra cài đặt
echo -e "\nKiểm tra cài đặt:"
echo "1. ZSH: $(which zsh)"
echo "2. Oh My Zsh: $(test -d ~/.oh-my-zsh && echo 'Đã cài đặt' || echo 'Chưa cài đặt')"
echo "3. Autosuggestions: $(test -d ~/.oh-my-zsh/custom/plugins/zsh-autosuggestions && echo 'Đã cài đặt' || echo 'Chưa cài đặt')"
echo "4. Syntax Highlighting: $(test -d ~/.oh-my-zsh/custom/plugins/zsh-syntax-highlighting && echo 'Đã cài đặt' || echo 'Chưa cài đặt')"
echo "5. Configuration file: $(test -f ~/.zshrc && echo 'Đã tạo' || echo 'Chưa tạo')"

echo -e "\nĐể áp dụng các thay đổi, vui lòng:"
echo "1. Đăng xuất và đăng nhập lại"
echo "   HOẶC"
echo "2. Chạy lệnh: exec zsh"
echo ""
echo "Nếu có lỗi, bạn có thể khôi phục từ file backup: $backup_file"