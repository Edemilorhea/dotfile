# 相亲-skill

> *"算法牵红线，我们来验证。"*

**赛博恋爱配对分析工具** - 一个用于蒸馏相亲双方信息、分析性格兼容性、生成配对报告的 AI Skill。

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](README.md)
[![Python 3.9+](https://img.shields.io/badge/Python-3.9%2B-blue.svg)](https://python.org)
[![Claude Code](https://img.shields.io/badge/Claude%20Code-Skill-blueviolet)](https://claude.ai/code)

将恋爱双方蒸馏成 AI Skill，通过多维度分析他们的性格兼容性，用于快速验证双方是否合适。支持导入微信、QQ 聊天记录、朋友圈、照片等原材料。

[快速开始](#快速开始) · [功能特性](#功能特性) · [安全说明](#安全说明) · [安装指南](love-skill/INSTALL.md)

---

## 🚀 快速开始

### 最简单的方式：Claude Code

```
# 在 Claude Code 中输入
/match-maker
```

然后按提示输入两位相亲者的信息即可。

### 或查看完整指南

- 📖 [完整 README](love-skill/README.md)
- 📦 [安装指南](love-skill/INSTALL.md)
- 🔧 [Skill 技术文档](love-skill/SKILL.md)

---


## ✨ 核心功能

✅ **双人性格蒸馏** - 支持微信、QQ、朋友圈、照片等多源导入
✅ **多维度兼容性分析** - MBTI、爱语、沟通风格、生活价值观等
✅ **智能配对报告** - 量化兼容性评分 + 定性深度分析
✅ **持续学习** - 支持增量更新，随着了解加深不断优化
✅ **本地隐私** - 所有数据仅本地存储，无云上传

---

## ❤️ 配对分析报告示例

```
总体兼容性: ⭐⭐⭐⭐☆ (78/100)

MBTI 匹配: ENFP ↔ INTJ
- 外向 x 内向：视角丰富但需协商
- 感觉 x 直觉：灵感碰撞但可能迷茫
- 情感 x 思考：温度 x 逻辑的平衡

三大优势：
✓ 性格互补潜力大
✓ 长期相处有新鲜感  
✓ 价值观核心一致

三大挑战：
⚠️ 沟通节奏差异（频繁 vs 深度）
⚠️ 生活方式不同（社交 vs 聚焦）
⚠️ 表达方式差异（感受驱动 vs 逻辑驱动）
```

---

## 📋 项目结构

```
love-skill/
├── README.md              # 详细说明
├── SKILL.md              # 技术工作流
├── INSTALL.md            # 安装指南
├── LICENSE               # MIT 许可
├── requirements.txt      # Python 依赖
├── docs/                 # 文档
│   ├── COMPLIANCE.md     # 合规说明
│   ├── EXPORT_GUIDE.md   # 聊天记录导出指南
│   └── ALGORITHM.md      # 兼容性算法说明
├── prompts/              # 核心提示词
│   ├── intake.md         # 信息收集
│   ├── persona_builder.md   # Persona 生成
│   ├── compatibility_analyzer.md # 兼容性分析
│   ├── report_generator.md  # 报告生成
│   ├── match_advisor.md     # 相处建议
│   └── session_summary.md   # 总结辅助
└── tools/                # Python 工具
    ├── wechat_parser.py     # 微信解析
    ├── qq_parser.py         # QQ 解析
    ├── social_parser.py     # 朋友圈解析
    ├── photo_analyzer.py    # 照片分析
    ├── skill_writer.py      # Skill 文件生成
    └── version_manager.py   # 版本管理
```

---

## ⚠️ 安全说明

✅ **仅用于娱乐和参考** - 配对分析仅供思考参考  
✅ **隐私保护** - 所有数据本地存储，绝不上传云端  
✅ **尊重隐私** - 仅在双方知情同意下分析  
✅ **理性使用** - AI 分析有局限，真实兼容性来自相处  
✅ **反对骚扰** - 严禁用于隐私侵犯或骚扰任何人  

详见：[合规说明](love-skill/docs/COMPLIANCE.md)

---

## 📖 使用场景

- 💭 **自我认识** - 通过分析更了解自己想要什么
- 🤝 **关系决策** - 在选择前做个理性思考
- 😄 **娱乐社交** - 和朋友们一起玩"兼容性测试"
- 📊 **数据驱动** - 用心理学框架来思考爱情
- 🔄 **持续学习** - 随着相处加深不断更新分析

---

## 🎯 常见问题

**Q: 兼容性低就一定分手吗？**  
A: 不会。AI 分析只是指出挑战，任何两个人都能通过理解、尊重和努力创造美好关系。

**Q: 数据会被发送到服务器吗？**  
A: 不会。所有数据都在你本地 Claude Code 中运行，绝不上传。

**Q: 可以用这个分析我的重要他人吗？**  
A: 可以，但必须经过他/她的同意。在没明确允许的情况下分析他人信息是不尊重隐私的。

更多问题见：[FAQ](love-skill/README.md#常见问题)

---

## 📚 了解更多

- 🔗 [完整项目文档](love-skill/) - 所有细节和技术说明
- 📖 [MBTI 入门](love-skill/docs/RESOURCES.md) - 性格类型介绍
- 🎓 [心理学基础](love-skill/docs/PSYCHOLOGY.md) - 依恋理论、爱语五要素等

---

## 📝 许可证

MIT License - 详见 [LICENSE](love-skill/LICENSE)

---

**Made with ❤️ and AI**

最后的选择权永远在你手中。祝你找到对的人。
