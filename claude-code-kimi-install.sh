#!/bin/bash

set -e

echo "========================================"
echo "   Claude Code + Kimi K2.5 本地独立版安装脚本"
echo "   （无全局安装，完全隔离）"
echo "   支持 Kimi K2.5 / Kimi K2 Thinking"
echo "========================================"
echo

# 1. 询问安装目录
default_dir="$HOME/claude-kimi"
read -p "请输入安装目录 [默认: $default_dir]: " install_dir
install_dir=${install_dir:-$default_dir}

if [ -d "$install_dir" ]; then
    echo "警告: 目录 $install_dir 已存在，将覆盖其中的配置和脚本。"
    read -p "是否继续？(y/N): " confirm
    if [[ ! "$confirm" =~ ^[Yy]$ ]]; then
        echo "安装已取消。"
        exit 1
    fi
    rm -rf "$install_dir"  # 清空重新创建，避免残留
fi

# 创建目录结构
mkdir -p "$install_dir/bin"
mkdir -p "$install_dir/config"
mkdir -p "$install_dir/state"
mkdir -p "$install_dir/project"  # 用于本地 npm 安装的临时项目目录

echo "安装目录: $install_dir"

# 2. 进入临时项目目录并本地安装 Claude Code
echo
echo "正在本地安装 @anthropic-ai/claude-code（无需全局）..."
cd "$install_dir/project"
npm init -y > /dev/null  # 创建 package.json
npm install @anthropic-ai/claude-code > /dev/null

# 3. 询问 Moonshot AI API Key
echo
echo "请从 https://platform.moonshot.ai/console/api-keys 获取您的 API Key"
read -p "请输入 Moonshot AI API Key: " api_key

if [ -z "$api_key" ]; then
    echo "错误: API Key 不能为空！"
    exit 1
fi

# 4. 创建配置文件
cat > "$install_dir/config/settings.json" << EOF
{
  "env": {
    "ANTHROPIC_AUTH_TOKEN": "$api_key",
    "ANTHROPIC_BASE_URL": "https://api.moonshot.ai/anthropic",
    "API_TIMEOUT_MS": "3000000",
    "ANTHROPIC_DEFAULT_HAIKU_MODEL": "kimi-k2-turbo-preview",
    "ANTHROPIC_DEFAULT_SONNET_MODEL": "kimi-k2.5",
    "ANTHROPIC_DEFAULT_OPUS_MODEL": "kimi-k2-thinking"
  }
}
EOF

echo "配置文件已写入: $install_dir/config/settings.json"

# 5. 创建启动脚本（使用 npx 调用本地安装的 claude）
cat > "$install_dir/bin/claude-kimi" << EOF
#!/bin/bash

# 设置独立的配置和状态目录（完全隔离）
export CLAUDE_CONFIG_DIR="$install_dir/config"
export CLAUDE_STATE_DIR="$install_dir/state"
export ANTHROPIC_AUTH_TOKEN="$api_key"

# 确保状态目录存在
mkdir -p "\$CLAUDE_STATE_DIR"

# 使用 npx 调用本地安装的 Claude Code（无需全局 claude 命令）
npx --prefix "$install_dir/project" claude "\$@"
EOF

chmod +x "$install_dir/bin/claude-kimi"

echo "启动脚本已创建: $install_dir/bin/claude-kimi"

# 6. 询问是否加入 PATH
echo
read -p "是否将 $install_dir/bin 加入 PATH（推荐，直接运行 claude-kimi）？(y/N): " add_path
if [[ "$add_path" =~ ^[Yy]$ ]]; then
    shell_config=""
    if [[ "$SHELL" == *"zsh"* ]]; then
        shell_config="$HOME/.zshrc"
    else
        shell_config="$HOME/.bashrc"
    fi

    if ! grep -q "$install_dir/bin" "$shell_config" 2>/dev/null; then
        echo '' >> "$shell_config"
        echo "# Added by claude-kimi local installer" >> "$shell_config"
        echo "export PATH=\"$install_dir/bin:\$PATH\"" >> "$shell_config"
        echo "已添加到 $shell_config"
    else
        echo "PATH 已包含该目录，无需重复添加。"
    fi

    echo "请运行以下命令使 PATH 立即生效："
    echo "    source $shell_config"
fi

# 7. 完成提示
echo
echo "========================================"
echo "本地安装完成！"
echo
echo "使用方法："
echo "  1. 如果添加了 PATH，直接运行："
echo "       claude-kimi"
echo "  2. 否则运行："
echo "       $install_dir/bin/claude-kimi"
echo
echo "进入项目目录后运行上述命令，即可启动完全独立的 Kimi K2.5 驱动 Claude Code。"
echo "如需更新 API Key，直接编辑："
echo "       $install_dir/config/settings.json"
echo
echo "模型说明："
echo "  • kimi-k2.5 - 最强大的模型，支持 256K 上下文"
echo "  • kimi-k2-thinking - 思维模型，擅长复杂推理"
echo "  • kimi-k2-turbo-preview - 快速预览版"
echo
echo "优势："
echo "  • 无需全局安装 Claude Code"
echo "  • 完全隔离配置、历史、缓存"
echo "  • 可同时存在多个独立实例（不同目录）"
echo "  • Kimi K2.5 在代码生成方面有重大突破"
echo "========================================"
