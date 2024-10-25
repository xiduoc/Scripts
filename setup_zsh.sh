#!/bin/bash

# Script cài đặt và cấu hình ZSH với autosuggestions
# và một số plugin hữu ích khác

# Kiểm tra và cài đặt ZSH nếu chưa có
if ! command -v zsh &> /dev/null; then
    echo "Đang cài đặt ZSH..."
    sudo apt-get update
    sudo apt-get install -y zsh
fi

# Cài đặt curl nếu chưa có
if ! command -v curl &> /dev/null; then
    echo "Đang cài đặt curl..."
    sudo apt-get install -y curl
fi

# Cài đặt git nếu chưa có
if ! command -v git &> /dev/null; then
    echo "Đang cài đặt git..."
    sudo apt-get install -y git
fi

# Cài đặt Oh My Zsh
if [ ! -d "$HOME/.oh-my-zsh" ]; then
    echo "Đang cài đặt Oh My Zsh..."
    sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
fi

# Cài đặt zsh-autosuggestions
if [ ! -d "${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins/zsh-autosuggestions" ]; then
    echo "Đang cài đặt zsh-autosuggestions..."
    git clone https://github.com/zsh-users/zsh-autosuggestions ${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins/zsh-autosuggestions
fi

# Cài đặt zsh-syntax-highlighting
if [ ! -d "${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins/zsh-syntax-highlighting" ]; then
    echo "Đang cài đặt zsh-syntax-highlighting..."
    git clone https://github.com/zsh-users/zsh-syntax-highlighting.git ${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins/zsh-syntax-highlighting
fi

# Backup file .zshrc cũ nếu tồn tại
if [ -f "$HOME/.zshrc" ]; then
    echo "Tạo backup của file .zshrc cũ..."
    cp "$HOME/.zshrc" "$HOME/.zshrc.backup_$(date +%Y%m%d_%H%M%S)"
fi

# Tạo file .zshrc mới với cấu hình tùy chỉnh
echo "Tạo file .zshrc mới..."
cat > "$HOME/.zshrc" << 'EOL'
# Path to oh-my-zsh installation
export ZSH="$HOME/.oh-my-zsh"

# Theme
ZSH_THEME="robbyrussell"

# Cài đặt các plugin
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

# Cấu hình History
HISTSIZE=10000
SAVEHIST=10000
HISTFILE=~/.zsh_history

# Cấu hình autosuggestions
ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE='fg=8'
ZSH_AUTOSUGGEST_STRATEGY=(history completion)
bindkey '^ ' autosuggest-accept

# Alias hữu ích
alias ll='ls -lah'
alias l='ls -lh'
alias zshconfig="nano ~/.zshrc"
alias ohmyzsh="nano ~/.oh-my-zsh"
alias update='sudo apt update && sudo apt upgrade -y'
alias c='clear'
alias h='history'
alias ports='netstat -tulanp'

# Cấu hình PATH
export PATH=$HOME/bin:/usr/local/bin:$PATH

# Tự động CD
setopt AUTO_CD

# Completion system
autoload -Uz compinit
compinit
EOL

# Thay đổi shell mặc định sang ZSH
if [ "$SHELL" != "$(which zsh)" ]; then
    echo "Thay đổi shell mặc định sang ZSH..."
    chsh -s $(which zsh)
fi

# Áp dụng cấu hình mới
echo "Áp dụng cấu hình mới..."
source "$HOME/.zshrc" >/dev/null 2>&1 || true

echo "Cài đặt và cấu hình ZSH hoàn tất!"
echo "Các tính năng đã được cài đặt:"
echo "1. Oh My Zsh framework"
echo "2. Plugin autosuggestions"
echo "3. Plugin syntax highlighting"
echo "4. Các plugin hữu ích khác (git, docker, npm, ...)"
echo "5. Các alias tiện dụng"
echo ""
echo "Vui lòng đăng xuất và đăng nhập lại hoặc chạy lệnh: exec zsh"
echo "để áp dụng các thay đổi."