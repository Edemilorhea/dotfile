# 安装指南

## 快速开始

### 1. Claude Code 安装

这是推荐的使用方式，不需要额外配置。

#### 方式 A：项目级安装（推荐）

在你的项目主目录执行：

```bash
mkdir -p .claude/skills
git clone https://github.com/YuzeHao2023/love-skill .claude/skills/match-maker
```

然后在 Claude Code 中输入：
```
/match-maker
```

#### 方式 B：全局安装

```bash
git clone https://github.com/YuzeHao2023/love-skill ~/.claude/skills/match-maker
```

这样所有项目都能使用该 Skill。

### 2. 依赖安装（可选）

如果你想要照片分析功能，需要 Python 3.9+：

```bash
pip3 install -r requirements.txt
```

或者只安装 Pillow：

```bash
pip3 install Pillow>=9.0.0
```

**注意**：即使不安装依赖，基础功能（聊天记录分析、性格分析）也能正常使用。

---

## 验证安装

### 检查 Claude Code 安装

1. 打开 Claude Code
2. 输入 `/match-maker`
3. 看到欢迎消息即表示安装成功

### 检查 Python 依赖

```bash
python3 -c "from PIL import Image; print('✓ Pillow 安装成功')" 2>/dev/null || echo "✗ Pillow 暂未安装（可选）"
```

---

## 卸载

### 卸载 Skill

```bash
# 项目级卸载
rm -rf .claude/skills/match-maker

# 全局卸载
rm -rf ~/.claude/skills/match-maker
```

### 卸载 Python 依赖

```bash
pip3 uninstall Pillow
```

---

## 常见问题

### Q: 为什么我找不到 `/match-maker` 命令？

**A:** 检查以下几点：

1. 确保你在 Claude Code 中输入，不是普通 Chat
2. 确保 `.claude/skills/match-maker` 文件夹确实存在
3. 确保是在 git 仓库中（有 `.git` 文件夹）
4. 尝试重启 Claude Code
5. 查看 SKILL.md 中的"触发条件"，尝试其他命令

### Q: 我收到"permission denied"错误

**A:** 确保 Claude Code 在 `.claude/skills/` 中有读写权限：

```bash
chmod +x ~/.claude/skills/match-maker/tools/*.py
```

### Q: 我想在 OpenClaw 中使用怎么办？

**A:** OpenClaw 是 Claude Code 的替代前端。安装步骤类似，需要将 `match-maker` 放在 OpenClaw 的 skills 目录中。详见 [OpenClaw 文档](https://github.com/nicepkg/openclaw)。

### Q: 我可以自己修改这个 Skill 吗？

**A:** 当然可以。Skill 文件位于 `.claude/skills/match-maker/` 中，你可以：

- 编辑 `SKILL.md` 修改工作流
- 编辑 `prompts/*.md` 修改提示词
- 修改 `tools/*.py` 增强数据处理

修改后的 Skill 会自动生效。

### Q: 数据存在哪里？

**A:** 所有生成的配对数据存储在：

```
./matches/{pair-slug}/
  ├── persona-a.md
  ├── persona-b.md
  ├── compatibility.json
  └── report.md
```

所有数据都是本地的，不上传任何服务器。

---

## 系统需求

- **操作系统**：macOS 10.14+, Linux, Windows 10+
- **Claude Code**：最新版本（支持 Node.js 18+）
- **Python**：3.9+ （仅在需要照片分析时）
- **磁盘空间**：< 100 MB（仅存储 Skill 文件和分析报告）
- **网络**：需要连接到 Claude API（可使用本地 API Key）

---

## 故障排查

### 问题：聊天记录解析失败

**原因** 可能是文件格式不支持或编码问题

**解决**：
1. 尝试导出不同格式（txt/json/html）
2. 检查文件编码（通常应为 UTF-8）
3. 手工复制粘贴聊天记录而不是上传文件

### 问题：配对数据丢失

**原因** 可能是文件被误删或 Skill 文件夹被重置

**防止方法**：
1. 定期备份 `./matches/` 文件夹
2. 使用 git 追踪 `./matches/` 中的文件
3. 启用自动备份：`./tools/backup_matches.sh`

### 问题：分析结果看起来不准确

**原因** 信息不足或 Persona 需要优化

**解决**：
1. 提供更多聊天记录或朋友圈信息
2. 使用 `/update-match` 反馈调整
3. 在 Persona 文件中手工补充关键信息

---

## 获取帮助

- 📖 查看 [README.md](README.md)
- 🗂️ 查看 [SKILL.md](SKILL.md)
- 🐛 报告 Bug：https://github.com/YuzeHao2023/love-skill/issues
- 💬 讨论：https://github.com/YuzeHao2023/love-skill/discussions

---

**祝你安装顺利！** ❤️
