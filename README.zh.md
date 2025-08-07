# Claude Memento v1.0.1 🧠

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
- Node.js（用于图数据库和向量化功能）
- jq（用于 JSON 处理 - 如缺少会自动安装）

### 快速安装

**macOS / Linux:**
```bash
# 克隆并安装
git clone https://github.com/claude-memento/claude-memento.git
cd claude-memento
./install.sh

# 验证安装
/cm:status
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

### 安装功能
- ✅ **自动备份**：安装前创建完整备份
- ✅ **非破坏性**：保留现有的 CLAUDE.md 内容
- ✅ **跨平台**：在 macOS、Linux、Windows 上运行
- ✅ **依赖检查**：验证并安装缺失的依赖项
- ✅ **回滚就绪**：如需要可轻松恢复

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

### 设置结构 (`~/.claude/memento/config/settings.json`)

```json
{
  "autoSave": {
    "enabled": true,        // 布尔值: 自动保存激活
    "interval": 60,         // 数字: 保存间隔（秒）
    "onSessionEnd": true    // 布尔值: 会话结束时保存
  },
  "chunking": {
    "enabled": true,        // 布尔值: 块系统激活
    "threshold": 10240,     // 数字: 分块阈值（字节）
    "chunkSize": 2000,      // 数字: 单个块大小
    "overlap": 50           // 数字: 块之间的重叠
  },
  "memory": {
    "maxSize": 1048576,     // 数字: 最大内存使用量
    "compression": true     // 布尔值: 启用压缩
  },
  "search": {
    "method": "tfidf",      // 字符串: 搜索方法 (tfidf/simple)
    "maxResults": 20,       // 数字: 最大搜索结果
    "minScore": 0.1         // 数字: 最小相似度分数
  }
}
```

**⚠️ 重要**: 使用实际的布尔值/数字类型，而不是字符串（`true` 而不是 `"true"`）。

### 配置命令
```bash
# 查看当前设置
/cm:config

# 启用自动保存，间隔 60 秒
/cm:auto-save enable
/cm:auto-save config interval 60

# 检查系统状态
/cm:status
```

## 项目结构 📁

```
claude-memento/
├── src/
│   ├── commands/      # 命令实现
│   ├── core/          # 核心内存管理
│   ├── chunk/         # 图数据库和分块系统
│   ├── config/        # 配置管理
│   ├── hooks/         # 钩子系统
│   └── bridge/        # Claude Code 集成
├── commands/cm/       # 命令定义
├── test/             # 测试脚本
├── docs/             # 文档
└── examples/         # 使用示例

运行时结构 (~/.claude/memento/):
├── checkpoints/      # 保存的检查点
├── chunks/           # 图数据库和块存储
├── config/           # 运行时配置
└── src/              # 已安装的系统文件
```

## 高级功能 🚀

### 图数据库系统
Claude Memento 包含一个基于图的高级块管理系统：

- **TF-IDF 向量化**：语义相似度搜索
- **图关系**：自动内容关系发现
- **智能加载**：基于查询的选择性上下文恢复
- **性能**：亚50毫秒搜索时间

### 块管理
```bash
# 按关键词搜索块
/cm:chunk search "API 实现"

# 列出所有块
/cm:chunk list

# 构建语义关系
/cm:chunk build-relations

# 获取系统统计信息
/cm:chunk stats
```

## 卸载 🗑️

### 安全移除选项

Claude Memento 提供了全面的卸载功能，并提供数据保留选项：

**完全移除：**
```bash
# 移除所有内容（永久删除数据）
./uninstall.sh
```

**保留数据：**
```bash
# 保留检查点和块
./uninstall.sh --keep-data

# PowerShell 等效命令
.\uninstall.ps1 -KeepData
```

**强制模式（跳过确认）：**
```bash
# 自动移除
./uninstall.sh --force

# 保留数据
./uninstall.sh --keep-data --force
```

### 移除内容
- ✅ **运行中的进程**：自动停止并优雅关闭
- ✅ **Claude Memento 部分**：从 CLAUDE.md 中移除（保留文件）
- ✅ **命令文件**：移除所有 `/cm:` 命令
- ✅ **安装文件**：完整系统清理
- ✅ **临时文件**：清除 PID 文件和缓存

### 数据保留
使用 `--keep-data` 时：
- 检查点备份至 `~/claude-memento-backup-[timestamp]/`
- 保留配置文件
- 维护图数据库和块
- 保存活动上下文文件

## 故障排除 🔍

### 安装问题

**命令不工作：**
```bash
# 检查安装
/cm:status

# 验证命令文件
ls ~/.claude/commands/cm/
```

**自动保存不工作：**
```bash
# 检查配置
/cm:auto-save status

# 如需要启用
/cm:auto-save enable
/cm:auto-save config interval 60
```

**图系统错误：**
```bash
# 运行系统测试
cd ~/.claude/memento/test/
./test-chunk-system.sh

# 检查 Node.js 安装
node --version
```

### 性能问题

**搜索缓慢：**
```bash
# 重建搜索索引
/cm:chunk build-relations

# 检查系统性能
/cm:status --verbose
```

### 恢复选项

**从备份恢复：**
```bash
# 列出可用备份
ls ~/.claude_backup_*/

# 运行恢复脚本
~/.claude_backup_[timestamp]/restore.sh
```

**重置配置：**
```bash
# 重置为默认值
rm ~/.claude/memento/config/settings.json
/cm:status  # 将重新创建默认值
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
- [ ] 块可视化的 Web 界面
- [ ] 高级搜索过滤器和查询
- [ ] 多语言内容支持

**版本 2.0:**
- [ ] 云备份集成
- [ ] 团队协作功能
- [ ] 高级分析仪表板
- [ ] 与其他 AI 工具集成

**最近更新 (v1.0.1):**
- ✅ 增强的卸载脚本和进程管理
- ✅ 改进的配置系统和正确的数据类型
- ✅ 图数据库系统和语义搜索
- ✅ 自动保存功能和后台守护进程
- ✅ 全面的测试套件和性能验证

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

## Star History

<a href="https://www.star-history.com/#claude-memento/claude-memento&Date">
 <picture>
   <source media="(prefers-color-scheme: dark)" srcset="https://api.star-history.com/svg?repos=claude-memento/claude-memento&type=Date&theme=dark" />
   <source media="(prefers-color-scheme: light)" srcset="https://api.star-history.com/svg?repos=claude-memento/claude-memento&type=Date" />
   <img alt="Star History Chart" src="https://api.star-history.com/svg?repos=claude-memento/claude-memento&type=Date" />
 </picture>
</a>