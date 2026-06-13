# AGENTS.md

## 构建验证（必须执行）

每次完成代码改动后，**必须**确保 Xcode 工程能够编译通过，再向用户报告完成。运行：

```sh
xcodebuild -project SuperSelf.xcodeproj -scheme SuperSelf -destination 'generic/platform=iOS' build 2>&1 | rg "error:"
```

- 没有 Swift 编译错误才算通过。
- `Failed to launch AssetCatalogSimulatorAgent via CoreSimulator spawn` 是与代码无关的环境报错，可忽略。

## 新增源文件时

本工程使用显式文件引用（非 file-system-synchronized group）。新建 `.swift` 文件后，仅写到磁盘还不够，**必须**在 `SuperSelf.xcodeproj/project.pbxproj` 的以下 4 处同步注册，否则会报 "Cannot find ... in scope"：

1. `PBXBuildFile` section
2. `PBXFileReference` section
3. 对应的 `PBXGroup`（按文件所在目录，如 Services / UI / Features 等）
4. `PBXSourcesBuildPhase` 的 `files` 列表

注册完成后重新构建确认通过。

## UI 与交互设计理念（涉及界面/交互改造时参考）

以下理念源自乔布斯的产品设计哲学，每次做 UI 或交互改造时都应对照参考：

1. **简洁是终极的复杂**：删繁就简，把复杂逻辑吃透后隐藏起来，给用户留下尽量干净的界面。简洁不是偷懒，而是深思熟虑后的优雅。
2. **从用户体验倒推技术**：先想用户要什么感受、什么操作最顺手，再决定怎么实现，而不是反过来迁就技术。
3. **软硬件/整体一致性**：各页面、组件的视觉与交互保持统一（配色、圆角、间距、箭头样式等），避免风格割裂。
4. **设计是「如何运作」，不只是「长什么样」**：交互逻辑和工作方式比外观更重要，优先保证操作连贯、符合直觉。
5. **细节与匠心**：连看不见的地方也要做好——对齐、留白、点击区域、边角过渡都要精致。
6. **专注与拒绝**：对一百个好主意说不。砍掉多余功能、多余按钮和多余选择，每个页面只突出真正重要的信息。
7. **直觉与情感优先**：相信审美直觉，做让人用起来愉悦、一眼抓住重点的界面。
8. **合理的默认值，减少决策**：开箱即用，默认即正确，尽量少让用户做选择。
9. **不让人感到设计的存在**：好用到让人觉得理所当然——技术服务于人，设计的目标是「无形」。
