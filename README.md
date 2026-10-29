# 房屋检查 (House Check)

[简体中文](#chinese) | [English](#english)

---

## chinese

一款专为房屋检查、物业巡检、租房交接等场景设计的 Flutter 跨平台应用。支持多小区管理、房间检查项、拍照存证、异常标注、照片对比、二维码扫描等功能，数据本地存储，无需联网即可使用。

### ✨ 功能特性

#### 🏘️ 小区管理
- 支持多个小区独立管理，数据互不干扰
- 小区可自由新增、重命名、删除
- 快速切换当前小区

#### 🏠 房间管理
- 默认包含厨房、主卧、客卧、小房间、卫生间、阳台、客厅等常用房间
- 每个房间配有专属图标和主题色，界面直观
- 房间检查项可自由增删改，不限定内容

#### 📸 检查项与拍照
- 每个检查项支持拍照或从相册选图
- 照片自动记录拍摄时间和文件大小
- 照片按「年-月」分组显示，按时间倒序排列

#### ✏️ 照片标注
- 在照片上自由手绘，圈出异常区域
- 支持多种颜色、多种粗细，支持撤销、清空操作
- 保存后覆盖原图，保留时间和备注

#### 📝 照片备注
- 长按照片可添加备注
- 备注以橙色标签形式显示在照片下方

#### 🔄 照片对比
- 选择两张照片进行滑动对比
- 拖动分割线，左右查看差异（适合对比检查前后的变化）

#### 📱 二维码功能
- 每个检查项可生成二维码
- 二维码内容基于「小区名 + 房间名 + 检查项名」，稳定不失效
- 支持扫一扫直接打开对应检查项，或从相册选择二维码图片识别
- 扫码后如数据不存在，可选择自动创建

#### 📍 定位
- 打开 APP 自动获取当前位置
- 显示城市名（如「浙江 金华」）
- 优先使用 GPS，失败时自动回退到 IP 定位，无需 SIM 卡

### 🛠️ 技术栈

- 框架: Flutter
- 语言: Dart
- 本地存储: JSON 文件 + 应用私有目录
- 核心依赖:
  - image_picker — 拍照与相册
  - image — 图片处理与标注
  - path_provider — 文件路径
  - mobile_scanner — 二维码扫描
  - qr_flutter — 二维码生成
  - geolocator — GPS 定位
  - http — IP 定位与逆地理编码

### 🚀 快速开始

#### 环境要求
- Flutter SDK 3.35 或更高版本
- Dart SDK 3.9 或更高版本
- Android Studio 或 VS Code

#### 安装步骤

1. 克隆项目
   git clone https://github.com/your-username/house_check.git
   cd house_check

2. 安装依赖
   flutter pub get

3. 运行项目
   flutter run

4. 构建 APK
   flutter build apk --release

#### 权限说明
应用需要以下权限：
- CAMERA：拍照与扫码
- ACCESS_FINE_LOCATION：精确定位
- ACCESS_COARSE_LOCATION：粗略定位
- READ_EXTERNAL_STORAGE：读取相册图片（部分 Android 版本）

### 🗂️ 项目结构

lib/
├── main.dart                       # 入口
├── models.dart                     # 数据模型（小区、房间、检查项、照片）
├── room_style.dart                 # 房间图标与配色
├── location_utils.dart             # 定位工具
└── pages/
├── home_page.dart              # 首页（小区 + 房间网格）
├── room_page.dart              # 房间页（检查项列表）
├── item_page.dart              # 检查项页（拍照 + 照片列表）
├── annotate_page.dart          # 照片标注页
├── photo_compare_page.dart     # 照片对比页
├── qr_page.dart                # 二维码生成页
└── scan_page.dart              # 扫码页

### 📄 开源协议
本项目采用 MIT 协议开源。

---

## english

A cross-platform Flutter application designed for house inspection, property patrolling, and rental handover scenarios. It features multi-community management, room inspection items, photo documentation, anomaly annotation, photo comparison, and QR code scanning. All data is stored locally, requiring no internet connection.

### ✨ Features

#### 🏘️ Community Management
- Manage multiple communities independently without data interference.
- Freely add, rename, or delete communities.
- Quickly switch between active communities.

#### 🏠 Room Management
- Comes with default rooms: Kitchen, Master Bedroom, Guest Bedroom, Small Room, Bathroom, Balcony, Living Room.
- Each room has a unique icon and theme color for an intuitive interface.
- Inspection items can be freely added, deleted, or modified.

#### 📸 Inspection & Photos
- Support taking photos or selecting from the gallery for each item.
- Automatically record the capture time and file size.
- Photos are grouped by "Year-Month" and sorted in reverse chronological order.

#### ✏️ Photo Annotation
- Freely draw on photos to mark anomaly areas.
- Supports multiple colors, stroke thicknesses, undo, and clear operations.
- Overwrites the original image while preserving time and notes upon saving.

#### 📝 Photo Notes
- Long press a photo to add notes.
- Notes are displayed below the photo as orange tags.

#### 🔄 Photo Comparison
- Select two photos for a sliding comparison.
- Drag the divider to view differences (ideal for before/after comparisons).

#### 📱 QR Code Features
- Generate a QR code for each inspection item.
- QR content is based on "Community + Room + Item", ensuring stability and no expiration.
- Support scanning to open the item directly, or picking a QR image from the gallery.
- Prompt to auto-create data if the scanned data doesn't exist.

#### 📍 Location
- Auto-fetch current location on app launch.
- Displays city name (e.g., "Zhejiang Jinhua").
- Prioritizes GPS, falling back to IP location (no SIM card required).

### 🛠️ Tech Stack

- Framework: Flutter
- Language: Dart
- Local Storage: JSON file + App private directory
- Core Dependencies:
  - image_picker — Camera and Gallery
  - image — Image processing and annotation
  - path_provider — File paths
  - mobile_scanner — QR code scanning
  - qr_flutter — QR code generation
  - geolocator — GPS location
  - http — IP location and reverse geocoding

### 🚀 Getting Started

#### Requirements
- Flutter SDK 3.35 or higher
- Dart SDK 3.9 or higher
- Android Studio or VS Code

#### Installation

1. Clone the repository
   git clone https://github.com/your-username/house_check.git
   cd house_check

2. Install dependencies
   flutter pub get

3. Run the app
   flutter run

4. Build APK
   flutter build apk --release

#### Permissions
The app requires the following permissions:
- CAMERA: Take photos and scan QR codes
- ACCESS_FINE_LOCATION: Precise location
- ACCESS_COARSE_LOCATION: Approximate location
- READ_EXTERNAL_STORAGE: Read gallery images (some Android versions)

### 🗂️ Project Structure

lib/
├── main.dart                       # Entry point
├── models.dart                     # Data models (Community, Room, Item, Photo)
├── room_style.dart                 # Room icons and colors
├── location_utils.dart             # Location utilities
└── pages/
├── home_page.dart              # Home (Community + Room grid)
├── room_page.dart              # Room page (Item list)
├── item_page.dart              # Item page (Camera + Photo list)
├── annotate_page.dart          # Photo annotation page
├── photo_compare_page.dart     # Photo comparison page
├── qr_page.dart                # QR code generation page
└── scan_page.dart              # QR scanner page

### 🤝 Contributing
Contributions, issues, and feature requests are welcome! Feel free to check the issues page.

### 📄 License
This project is open-sourced under the MIT license.

---
⭐ If this project helps you, please give it a star!