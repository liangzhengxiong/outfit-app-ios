# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## 项目概述

**项目名称：** WhatToWear - 男生AI智能穿搭APP
**技术栈：** iOS (Swift 5.9+) + Node.js + MySQL + 百度AI SDK
**开发阶段：** 阶段一进行中（框架搭建+核心功能）

---

## 项目背景

男生AI智能穿搭APP（iOS + Android），支持：
- 衣物拍照/网图存档、AI高精度抠图
- 2D平铺 + 2.5D锚点式3D上身试穿
- 智能搭配（韩系/日系/通勤/甜酷/复古/极简/运动）
- 天气穿搭推荐、穿搭日历
- 会员+穿搭课程盈利模式

---

## 设计规范（强制）

### 色彩体系

| 类型 | 色值 | 用途 |
|------|------|------|
| 主色（藏青蓝） | #1A365D | 导航栏、核心按钮、标题 |
| 辅助色-基础白 | #FFFFFF | 背景、卡片 |
| 辅助色-深空灰 | #2D2D2D | 正文文字、图标 |
| 辅助色-浅灰 | #F5F5F5 | 次要背景、卡片底色 |
| 辅助色-雾霾银 | #C9CDD4 | 分割线、禁用状态 |
| 强调色（低饱和橙） | #F59F45 | 会员标识、重点按钮 |

禁用：高饱和粉、紫、亮红、亮黄、花哨渐变色

### 字体

- 标题：20pt/18pt，粗体600
- 正文：16pt，常规400
- 辅助文字：14pt，轻量300

### 组件规范

- 圆角半径：4pt（小圆角）
- 阴影：模糊度4pt，透明度10%
- 大按钮：高度48pt
- 输入框：高度44pt

### 图标风格

SF Symbols线性极简风，线条粗细2pt，无填充、无拟人卡通

---

## 核心开发要求

- 3D上身试穿误差 ≤5%，无穿模、肩线错位
- 核心功能操作步骤 ≤3步
- 适配机型：iOS 13+、安卓9.0+，屏幕4.7-6.7英寸

---

## 代码组织约定

```
what_to_ware/
├── CLAUDE.md
├── 开发进度报告.md
├── 男生AI穿搭APP 开发任务书+视觉&交互规范文档.md
├── apps/
│   └── ios/
│       ├── project.yml               # XcodeGen配置
│       └── WhatToWear/
│           ├── Info.plist
│           ├── App/                  # AppDelegate, SceneDelegate, MainTabBarController
│           ├── Features/             # 功能模块（按业务划分）
│           │   ├── Auth/             # 登录相关
│           │   ├── Home/             # 首页
│           │   ├── Wardrobe/         # 衣橱管理
│           │   ├── Outfit/           # 穿搭搭配
│           │   ├── TryOn/            # 3D试穿
│           │   ├── Profile/          # 个人中心
│           │   └── Onboarding/       # 新手引导
│           ├── Core/                 # 核心组件
│           │   ├── AI/               # WeatherService, OutfitGenerationService
│           │   ├── DesignSystem/     # WTWDesignSystem (颜色/字体/布局)
│           │   ├── Network/          # WTWAPI (Alamofire封装)
│           │   └── Storage/         # TokenStorage (Token管理)
│           └── Resources/            # Assets, LaunchScreen
├── services/
│   └── api/                         # Node.js后端 (Express)
│       ├── package.json
│       ├── tsconfig.json
│       └── src/
│           ├── index.ts             # 入口
│           ├── middleware/          # JWT认证中间件
│           └── routes/             # API路由
│               ├── auth.ts          # /api/auth
│               ├── users.ts         # /api/users
│               ├── clothes.ts       # /api/clothes
│               ├── outfits.ts      # /api/outfits
│               ├── ai.ts           # /api/ai
│               ├── weather.ts       # /api/weather
│               └── upload.ts        # /api/upload
└── database/
    └── schema.prisma                # Prisma MySQL Schema
```

### 功能模块说明

**Features模块：**
- `Auth/` - LoginViewController (手机号登录、验证码、微信登录入口)
- `Home/` - HomeViewController (天气显示、拍照存衣、智能搭配入口)
- `Wardrobe/` - WardrobeViewController, AddClothingViewController (衣物管理)
- `Outfit/` - OutfitViewController, OutfitCalendarViewController (穿搭+日历)
- `TryOn/` - TryOnViewController (3D上身试穿，手势微调)
- `Profile/` - Profile/Member/Courses/Settings/BodyModel 等VC
- `Onboarding/` - OnboardingViewController (3页新手引导)

**Core模块：**
- `AI/WeatherService` - 定位、天气获取、穿搭推荐
- `AI/OutfitGenerationService` - 智能搭配生成（7种风格）
- `DesignSystem/WTWDesignSystem` - 设计规范实现
- `Network/WTWAPI` - Alamofire封装，所有API调用
- `Storage/TokenStorage` - Token存储、AuthService

---

## 构建与验证

### GitHub Actions iOS构建（当前使用）
```bash
# 代码推送到 GitHub 后自动触发构建
# 构建产物在 Actions -> Artifacts 下载 .ipa
```

### iOS 本地构建（需Mac）
```bash
cd apps/ios && npx xcodegen generate
```

### 后端启动（暂缓）
```bash
cd services/api && npm install && npm run dev
```

### 后端API列表
| 方法 | 路径 | 说明 |
|------|------|------|
| GET | /health | 健康检查 |
| POST | /api/auth/send-code | 发送验证码 |
| POST | /api/auth/login | 手机号登录 |
| POST | /api/auth/wechat | 微信登录 |
| GET | /api/users/me | 获取用户信息 |
| PUT | /api/users/me | 更新用户信息 |
| POST | /api/users/body-model | 创建身形模型 |
| GET | /api/clothes | 获取衣物列表 |
| POST | /api/clothes | 添加衣物 |
| POST | /api/clothes/remove-bg | AI抠图 |
| POST | /api/outfits/generate | 智能生成穿搭 |
| GET | /api/outfits/calendar | 获取日历记录 |
| GET | /api/weather/weather | 获取天气信息 |
| POST | /api/upload/image | 上传图片 |

### iOS项目生成
```bash
cd apps/ios && npx xcodegen generate
```

**注意：** XcodeGen在Windows环境下需通过WSL或单独安装二进制文件运行。

### 数据库操作
```bash
cd services/api && npx prisma generate    # 生成Client
cd services/api && npx prisma migrate dev # 执行迁移
```

---

## 数据库Schema概览

**核心表：**
- `User` - 用户（手机号/微信openid/身高体重/身形类型）
- `Cloth` - 衣物（类型/尺码/版型/图片URL/抠图URL）
- `Outfit` - 穿搭方案（风格/天气/场合）
- `OutfitCloth` - 穿搭-衣物关联
- `BodyModel` - 身形模型（3种录入方式）
- `Member` - 会员（等级/有效期）
- `CalendarRecord` - 穿搭日历
- `ClothingModel` - 衣物3D模型（锚点信息）
- `BodyModel3D` - 3D模特模板（20套预制）

---

## 开发进度

详见 `开发进度报告.md`

**当前阶段：** iOS 构建调试（GitHub Actions 云端构建）

**当前状态：**
- iOS: ~70% (核心UI完成，待XcodeGen生成项目)
- 后端: ~60% (API框架完成，待MySQL连接)
- Android: 未开始