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

## 数据兼容（改动数据结构时必须遵守）

**最高优先级：任何改动都不得丢失用户已有数据。** 修改 `Codable` 模型（新增/重命名/删除字段）时必须做好向后兼容，绝不能让旧数据解码失败被静默清空。

1. **新增字段必须能容忍旧数据缺失该字段**。Swift 自动合成的 `Codable` 解码器在字段缺失时会抛 `keyNotFound`（即使有默认值也不用），配合 `try?` 会导致整条数据被吞掉变空。因此为新增了字段的模型**显式实现 `init(from:)`**，对新字段用 `decodeIfPresent(...) ?? 默认值`；保留对应的 `init(...)` 便利构造器与 `CodingKeys`。
2. **加载失败时绝不回写空值覆盖原数据**。`load*` 解码失败应直接返回、保留磁盘原始 blob，不要用空数组覆盖本地或 iCloud。
3. **同步合并使用并集语义**，`merge*` 只增不删，不能因为云端为空就删掉本地项。
4. **善用快照等冗余副本做自动恢复**。若主数据异常为空但快照/历史里还存有数据，应在启动时自动恢复（参考 `recoverFinanceAssetsFromSnapshotsIfNeeded`）。
5. **改完数据结构后自测旧数据路径**：模拟"旧 JSON（缺新字段）→ 新模型解码"，确认数据不丢。

> 教训：曾因给 `FinanceAsset` 直接加 `note` 字段导致旧数据解码失败、资产被清空。此类问题必须从根上避免。

## 中文本地化（涉及日期/时间显示时必须遵守）

本 App 面向中文用户，**所有日期、时间相关的展示都必须是中文**，绝不能出现英文月份/星期（如 `June 2026`、`SUN MON`、`Jun 15, 2026`）。

1. **系统 `DatePicker`/`Calendar` 等控件默认跟随系统语言，会显示英文**。凡是用到这类控件，**必须**显式加 `.environment(\.locale, Locale(identifier: "zh_CN"))`，否则日历头、星期、日期格式都会是英文。
2. **手动格式化日期用 `DateFormatter` 时**，必须设 `formatter.locale = Locale(identifier: "zh_CN")`，并使用中文格式（如 `"yyyy年M月d日 HH:mm"`、`"M月d日"`）。
3. **新增任何涉及日期/时间的 UI 前，先自查 locale 是否为中文**，这是高频易错点。

> 教训：`TodoDueDateField` 的 `DatePicker` 多次忘记设中文 locale，导致日历显示英文月份/星期，被用户反复指出。此后凡涉及日期展示一律检查 locale。

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
