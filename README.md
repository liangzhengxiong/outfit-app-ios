# WhatToWear - 男生AI智能穿搭APP

[![Build iOS](https://github.com/liangzhengxiong/outfit-app-ios/workflows/Build%20iOS/badge.svg)](https://github.com/liangzhengxiong/outfit-app-ios/actions)

一款专为男生打造的AI智能穿搭APP，支持衣物拍照存档、智能搭配推荐、天气穿搭建议等功能。

## 功能特性

- **智能衣橱** - 拍照/网图存档，AI高精度抠图
- **穿搭推荐** - 支持韩系/日系/通勤/甜酷/复古/极简/运动7种风格
- **天气搭配** - 根据天气情况智能推荐穿搭
- **穿搭日历** - 记录每日穿搭，方便回顾整理
- **3D试穿** - 2.5D锚点式上身效果预览（开发中）

## 技术栈

### iOS App
- **语言:** Swift 5.9+
- **UI框架:** UIKit + SnapKit
- **网络:** Alamofire
- **图片缓存:** Kingfisher
- **动画:** Lottie
- **项目生成:** XcodeGen

### 后端 API
- **运行环境:** Node.js + Express
- **数据库:** MySQL + Prisma ORM
- **认证:** JWT

## 项目结构

```
what_to_ware/
├── apps/
│   └── ios/
│       ├── project.yml          # XcodeGen 配置
│       └── WhatToWear/         # iOS 源代码
│           ├── App/            # AppDelegate, SceneDelegate
│           ├── Core/           # 网络、设计系统、存储
│           ├── Features/       # 功能模块
│           └── Resources/      # 资源文件
├── services/
│   └── api/                   # Node.js 后端
│       └── src/
│           ├── routes/        # API 路由
│           ├── middleware/     # 中间件
│           └── lib/           # 工具库
└── database/
    └── schema.prisma          # 数据库 Schema
```

## 快速开始

### iOS 开发

1. 克隆项目
```bash
git clone https://github.com/liangzhengxiong/outfit-app-ios.git
cd outfit-app-ios
```

2. 安装依赖（需要 Mac）
```bash
cd apps/ios
npx xcodegen generate
```

3. 使用 Xcode 打开 `.xcodeproj` 文件即可运行

### 后端开发

```bash
cd services/api
npm install

# 首次运行需要配置数据库
npm run db:generate
npm run db:push

npm run dev
```

### 环境变量配置

后端运行需要配置以下环境变量（复制 `secrets/template.env` 为 `.env`）：

```env
DATABASE_URL="mysql://user:password@host:3306/what_to_wear"
JWT_SECRET="your-secret-key"
PORT=3000
```

第三方服务集成详见 [第三方服务集成指南](第三方服务集成指南.md)。

## CI/CD

项目使用 GitHub Actions 进行 iOS 云端构建：

- **构建环境:** macos-14
- **触发条件:** 提交到 `master` 分支自动构建
- **构建产物:** `.ipa` 文件

构建完成后在 **Actions** 页面下载 IPA，使用爱思助手安装到 iPhone。

## 设计规范

| 元素 | 规范 |
|------|------|
| 主色 | #1A365D（藏青蓝） |
| 强调色 | #F59F45（低饱和橙） |
| 圆角 | 4pt |
| 按钮高度 | 48pt |
| 图标风格 | SF Symbols 线性风格 |

详见 [开发任务书](男生AI穿搭APP%20开发任务书+视觉&交互规范文档%20(1).md)。

## 开发进度

详见 [开发进度报告](开发进度报告.md)。

## 贡献指南

欢迎提交 Issue 和 Pull Request！

## 许可证

MIT License
