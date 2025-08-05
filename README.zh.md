# Claude Memento v1.0 🧠

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![GitHub issues](https://img.shields.io/github/issues/claude-memento/claude-memento)](https://github.com/claude-memento/claude-memento/issues)
[![GitHub stars](https://img.shields.io/github/stars/claude-memento/claude-memento)](https://github.com/claude-memento/claude-memento/stargazers)

[English](README.md) | [한국어](README.ko.md) | [日本語](README.ja.md) | [中文](README.zh.md)

一个为 Claude Code 设计的内存管理扩展，可以在对话之间保留上下文并确保长期项目的连续性。

**📢 当前状态**: 初始版本 - 正在积极改进！在我们完善体验的过程中，预计会有一些粗糙的边缘。

## 什么是 Claude Memento？ 🤔

Claude Memento 通过提供以下功能解决了 Claude Code 的上下文丢失问题：
- 💾 **自动内存备份**：为重要的工作状态和上下文自动备份
- 🔄 **会话连续性**：无缝恢复之前的工作
- 📝 **知识积累**：永久存储项目决策
- 🎯 **原生 Claude Code 集成**：通过 `/cm:` 命令命名空间
- 🔐 **非破坏性安装**：保留现有设置

## 当前状态 📊

**运行良好的功能:**
- 核心内存管理系统
- 7 个集成的 Claude Code 命令
- 跨平台安装（macOS、Linux、Windows）
- 自动压缩和索引
- 用于定制的钩子系统

**已知限制:**
- 初始版本存在预期的错误
- 仅限于本地存储（云同步即将推出）
- 目前仅支持单个配置文件
- 手动检查点管理

## 主要功能 ✨

### 命令 🛠️
用于内存管理的 7 个基本命令：

**内存操作:**
- `/cm:save` - 保存当前状态并附带描述
- `/cm:load` - 加载特定检查点
- `/cm:status` - 查看系统状态

**检查点管理:**
- `/cm:list` - 列出所有检查点
- `/cm:last` - 加载最新的检查点

**配置:**
- `/cm:config` - 查看/编辑配置
- `/cm:hooks` - 管理钩子脚本

### 智能功能 🎭
- **自动压缩**：高效存储大型上下文
- **智能索引**：快速检查点搜索和检索
- **钩子系统**：用于保存/加载事件的自定义脚本
- **增量备份**：仅保存更改以优化存储
- **完整系统备份**：安装前创建~/.claude目录的完整备份
- **简单恢复**：备份中包含一键恢复脚本

## 安装 📦

Claude Memento 通过单个脚本安装。

### 前提条件
- 已安装 Claude Code（或存在 `~/.claude/` 目录）
- Bash 环境（Windows 上的 Git Bash、WSL 或 PowerShell）

### 快速安装

**macOS / Linux:**
```bash
# 克隆并安装
git clone https://github.com/claude-memento/claude-memento.git
cd claude-memento
./install.sh

# 在 Claude Code 中验证
# /cm:status
```

**Windows (PowerShell):**
```powershell
# 克隆存储库
git clone https://github.com/claude-memento/claude-memento.git
cd claude-memento

# 如需要，设置执行策略
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser

# 运行安装程序
.\install.ps1
```

**Windows (Git Bash):**
```bash
# 克隆并安装
git clone https://github.com/claude-memento/claude-memento.git
cd claude-memento
./install.sh
```

## 工作原理 🔄

1. **状态捕获**：Claude Memento 捕获您当前的工作上下文
2. **压缩**：智能压缩大型上下文
3. **存储**：检查点与元数据和时间戳一起存储
4. **检索**：加载任何检查点以恢复完整上下文
5. **集成**：原生 Claude Code 命令实现无缝工作流

### 架构概览

```
Claude Code 会话
    ↓
/cm:save 命令
    ↓
上下文处理 → 压缩 → 存储
                     ↓
                 检查点
                     ↓
             ~/.claude/memento/
                     ↓
/cm:load 命令 ← 解压缩 ← 检索
    ↓
恢复的会话
```

## 使用示例 💡

### 基本工作流
```bash
# 开始新功能
/cm:save "初始功能设置完成"

# 重要进展后
/cm:save "API 端点已实现"

# 第二天 - 恢复上下文
/cm:last

# 或加载特定检查点
/cm:list
/cm:load checkpoint-20240119-143022
```

### 高级用法
```bash
# 配置自动保存间隔
/cm:config set autoSave true
/cm:config set saveInterval 300

# 添加自定义钩子
/cm:hooks add post-save ./scripts/backup-to-cloud.sh
/cm:hooks add pre-load ./scripts/validate-checkpoint.sh

# 检查系统健康状况
/cm:status --verbose
```

## 配置 🔧

默认配置（`~/.claude/memento/config/default.json`）：
```json
{
  "checkpoint": {
    "retention": 10,
    "auto_save": true,
    "interval": 900,
    "strategy": "full"
  },
  "memory": {
    "max_size": "10MB",
    "compression": true,
    "format": "markdown"
  },
  "session": {
    "timeout": 300,
    "auto_restore": true
  },
  "integration": {
    "superclaude": true,
    "command_prefix": "cm:"
  }
}
```

## 项目结构 📁

```
claude-memento/
├── src/
│   ├── core/          # 核心内存管理
│   ├── commands/      # 命令实现
│   ├── utils/         # 实用工具和助手
│   └── bridge/        # Claude Code 集成
├── templates/         # 配置模板
├── commands/          # 命令定义
├── docs/             # 文档
└── examples/         # 使用示例
```

## 故障排除 🔍

### 常见问题

**命令不工作:**
```bash
# 检查命令是否已安装
ls ~/.claude/commands/cm/

# 验证状态命令
/cm:status
```

**安装失败:**
```bash
# 检查权限
chmod +x install.sh
./install.sh --verbose
```

**内存加载错误:**
```bash
# 验证检查点完整性
/cm:status --check
# 如需要则修复
./src/utils/repair.sh
```

**安装后的路径结构问题:**
```bash
# 如果命令失败并显示"file not found"错误
# 这可能是由于不正确的安装
# 使用更新的脚本重新安装:
./uninstall.sh && ./install.sh
```

**权限错误:**
```bash
# 如果遇到"permission denied"错误
# 检查文件权限
ls -la ~/.claude/memento/src/**/*.sh

# 如需要，手动修复权限
find ~/.claude/memento/src -name "*.sh" -type f -exec chmod +x {} \;
```

## 贡献 🤝

我们欢迎贡献！请查看我们的[贡献指南](CONTRIBUTING.md)了解详情。

1. Fork 存储库
2. 创建您的功能分支（`git checkout -b feature/amazing-feature`）
3. 提交更改（`git commit -m 'Add amazing feature'`）
4. 推送到分支（`git push origin feature/amazing-feature`）
5. 开启拉取请求

## 路线图 🗺️

**版本 1.1:**
- [ ] 云备份支持
- [ ] 多配置文件管理
- [ ] 实时同步能力

**版本 2.0:**
- [ ] Web UI 仪表板
- [ ] 团队协作功能
- [ ] 高级搜索和过滤
- [ ] 与其他 AI 工具集成

## 常见问题 ❓

**问：我的数据安全吗？**
答：所有数据都本地存储在您的主目录中。云功能将包括加密。

**问：我可以在多个项目中使用吗？**
答：可以！检查点会自动按项目上下文组织。

**问：如果 Claude Code 更新了会怎样？**
答：Claude Memento 设计为与 Claude Code 更新向前兼容。

## 许可证 📄

该项目根据 MIT 许可证授权 - 有关详细信息，请参阅 [LICENSE](LICENSE) 文件。

## 致谢 🙏

特别感谢 Claude Code 社区的反馈和贡献。

---

**需要帮助？** 查看我们的[文档](docs/README.md)或[提交问题](https://github.com/claude-memento/claude-memento/issues)。

**喜欢 Claude Memento？** 在 [GitHub](https://github.com/claude-memento/claude-memento) 上给我们一个 ⭐！