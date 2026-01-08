#!/bin/bash

set -e

echo "========================================"
echo "   Claude Code + MiniMax-M2.1 本地独立版安装脚本（修正版）"
echo "   （无全局安装，完全隔离）"
echo "   支持 MiniMax-M2.1（顶级 agentic 编码模型）"
echo "========================================"
echo

# 1. 询问安装目录
default_dir="$HOME/claude-minimax"
read -p "请输入安装目录 [默认: $default_dir]: " install_dir
install_dir=${install_dir:-$default_dir}

if [ -d "$install_dir" ]; then
    echo "警告: 目录 $install_dir 已存在，将覆盖其中的配置和脚本。"
    read -p "是否继续？(y/N): " confirm
    if [[ ! "$confirm" =~ ^[Yy]$ ]]; then
        echo "安装已取消。"
        exit 1
    fi
    rm -rf "$install_dir"
fi

# 创建目录结构
mkdir -p "$install_dir/bin"
mkdir -p "$install_dir/config"
mkdir -p "$install_dir/state"
mkdir -p "$install_dir/project"

echo "安装目录: $install_dir"

# 2. 本地安装 Claude Code
echo
echo "正在本地安装 @anthropic-ai/claude-code..."
cd "$install_dir/project"
npm init -y > /dev/null
npm install @anthropic-ai/claude-code > /dev/null

# 3. 询问 MiniMax API Key
echo
echo "请从 https://platform.minimax.io/ 获取您的 MiniMax API Key（推荐 Coding Plan 以获得更高限额）"
read -p "请输入 MiniMax API Key: " api_key

if [ -z "$api_key" ]; then
    echo "错误: API Key 不能为空！"
    exit 1
fi

# 4. 创建配置文件（修正模型名称为 MiniMax-M2.1）
cat > "$install_dir/config/settings.json" << EOF
{
  "env": {
    "ANTHROPIC_AUTH_TOKEN": "$api_key",
    "ANTHROPIC_BASE_URL": "https://api.minimaxi.com/anthropic",
    "API_TIMEOUT_MS": "3000000",
    "CLAUDE_CODE_DISABLE_NONESSENTIAL_TRAFFIC": "1",
    "ANTHROPIC_MODEL": "MiniMax-M2.1",
    "ANTHROPIC_SMALL_FAST_MODEL": "MiniMax-M2.1",
    "ANTHROPIC_DEFAULT_HAIKU_MODEL": "MiniMax-M2.1",
    "ANTHROPIC_DEFAULT_SONNET_MODEL": "MiniMax-M2.1",
    "ANTHROPIC_DEFAULT_OPUS_MODEL": "MiniMax-M2.1"
  }
}
EOF

echo "配置文件已写入（模型名称修正为 MiniMax-M2.1）"

# 5. 创建启动脚本
cat > "$install_dir/bin/claude-minimax" << EOF
#!/bin/bash

export CLAUDE_CONFIG_DIR="$install_dir/config"
export CLAUDE_STATE_DIR="$install_dir/state"

mkdir -p "\$CLAUDE_STATE_DIR"

npx --prefix "$install_dir/project" claude "\$@"
EOF

chmod +x "$install_dir/bin/claude-minimax"

echo "启动脚本已创建: $install_dir/bin/claude-minimax"

# 6. 询问是否加入 PATH
echo
read -p "是否将 $install_dir/bin 加入 PATH？(y/N): " add_path
if [[ "$add_path" =~ ^[Yy]$ ]]; then
    shell_config=""
    if [[ "$SHELL" == *"zsh"* ]]; then
        shell_config="$HOME/.zshrc"
    else
        shell_config="$HOME/.bashrc"
    fi

    if ! grep -q "$install_dir/bin" "$shell_config" 2>/dev/null; then
        echo '' >> "$shell_config"
        echo "# Added by claude-minimax installer" >> "$shell_config"
        echo "export PATH=\"$install_dir/bin:\$PATH\"" >> "$shell_config"
        echo "已添加到 $shell_config"
    else
        echo "PATH 已包含该目录。"
    fi

    echo "请运行 source $shell_config 使 PATH 生效"
fi

# 7. 完成提示
echo
echo "========================================"
echo "安装完成！现在应该可以正常运行"
echo
echo "使用：claude-minimax（进入项目目录后运行）"
echo "如果仍报错，请检查："
echo "  • API Key 是否正确（从 https://platform.minimax.io/ 新生成一个试试）"
echo "  • 是否购买了 Coding Plan（免费额度可能不足或不支持完整功能）"
echo "  • 网络是否能正常访问 api.minimax.io（国内用户建议使用国内平台）"
echo "========================================"