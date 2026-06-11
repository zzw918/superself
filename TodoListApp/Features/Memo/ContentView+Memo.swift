import SwiftUI

extension ContentView {
    var anniversaryCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("纪念日")
                        .font(.title3.bold())
                    Text("生日、结婚纪念日或其他重要日子，阴历阳历都可以记录。")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                Button {
                    isShowingAnniversarySheet = true
                } label: {
                    Image(systemName: "plus")
                        .font(.headline)
                        .foregroundStyle(.white)
                        .frame(width: 36, height: 36)
                        .background(Color.orange)
                        .clipShape(Circle())
                        .shadow(color: Color.orange.opacity(0.22), radius: 8, x: 0, y: 4)
                }
                .buttonStyle(.plain)
            }

            if anniversaryItems.isEmpty {
                ContentUnavailableView(
                    "还没有纪念日",
                    systemImage: "calendar.badge.plus",
                    description: Text("把生日、结婚纪念日或其他重要日子记下来。")
                )
                .frame(maxWidth: .infinity, minHeight: 120)
            } else {
                VStack(spacing: 10) {
                    ForEach(sortedAnniversaryItems) { item in
                        AnniversaryRow(
                            item: item,
                            dateText: anniversaryDateText(for: item),
                            nextText: nextAnniversaryText(for: item)
                        ) {
                            deleteAnniversaryItem(item)
                        }

                        if item.id != sortedAnniversaryItems.last?.id {
                            Divider()
                        }
                    }
                }
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.background)
        .clipShape(RoundedRectangle(cornerRadius: 20))
    }

    var anniversaryAddSheet: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 18) {
                Text("生日、结婚纪念日或其他重要日子，阴历阳历都可以记录。")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                Picker("纪念日类型", selection: $anniversaryKind) {
                    ForEach(AnniversaryKind.allCases) { kind in
                        Label(kind.title, systemImage: kind.icon)
                            .tag(kind)
                    }
                }
                .pickerStyle(.segmented)

                Picker("日期类型", selection: $anniversaryCalendarKind) {
                    ForEach(AnniversaryCalendarKind.allCases) { kind in
                        Text(kind.title)
                            .tag(kind)
                    }
                }
                .pickerStyle(.segmented)

                ModernInputField(
                    placeholder: anniversaryKind == .other ? "例如：第一次旅行" : "例如：妈妈生日",
                    text: $anniversaryTitleInput,
                    icon: anniversaryKind.icon,
                    tint: .orange
                )

                DatePicker("日期", selection: $anniversaryDate, displayedComponents: .date)
                    .datePickerStyle(.graphical)
                    .environment(\.locale, Locale(identifier: "zh_CN"))

                Button {
                    addAnniversaryItem()
                } label: {
                    Label("添加纪念日", systemImage: "plus")
                        .font(.headline)
                        .foregroundStyle(canAddAnniversary ? .white : Color(.tertiaryLabel))
                        .frame(maxWidth: .infinity)
                        .frame(height: 48)
                        .background(canAddAnniversary ? Color.orange : Color(.tertiarySystemFill))
                        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                }
                .buttonStyle(.plain)
                .disabled(!canAddAnniversary)
            }
            .padding()
            .background(Color(.systemGroupedBackground))
            .navigationTitle("添加纪念日")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") {
                        isShowingAnniversarySheet = false
                    }
                }
            }
        }
        .presentationDetents([.large])
    }

    var todoTasksCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("TODO")
                        .font(.title3.bold())
                    Text("想到什么先记下来，做完就打勾。")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                Text("\(activeTodoTasks.count) 件待做")
                    .font(.caption.bold())
                    .foregroundStyle(.blue)
            }

            AddEntryBar(
                placeholder: "例如：周末整理房间",
                text: $todoInput,
                icon: "checklist",
                tint: .blue,
                action: addTodoTask
            )

            if activeTodoTasks.isEmpty && completedTodoTasks.isEmpty {
                ContentUnavailableView(
                    "还没有待办",
                    systemImage: "checklist",
                    description: Text("把要做的事情写在这里，避免之后忘记。")
                )
                .frame(maxWidth: .infinity, minHeight: 120)
            } else {
                if !activeTodoTasks.isEmpty {
                    VStack(spacing: 10) {
                        ForEach(activeTodoTasks) { task in
                            TodoTaskRow(task: task) {
                                toggleTodoTask(task)
                            } onDelete: {
                                deleteTodoTask(task)
                            }

                            if task.id != activeTodoTasks.last?.id {
                                Divider()
                            }
                        }
                    }
                }

                if !completedTodoTasks.isEmpty {
                    Divider()

                    DisclosureGroup {
                        VStack(spacing: 10) {
                            ForEach(completedTodoTasks.prefix(8)) { task in
                                TodoTaskRow(task: task) {
                                    toggleTodoTask(task)
                                } onDelete: {
                                    deleteTodoTask(task)
                                }

                                if task.id != completedTodoTasks.prefix(8).last?.id {
                                    Divider()
                                }
                            }
                        }
                        .padding(.top, 8)
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: "checkmark.circle")
                            Text("已完成 \(completedTodoTasks.count) 件")
                        }
                        .font(.caption.bold())
                        .foregroundStyle(.secondary)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(Color(.tertiarySystemFill))
                        .clipShape(Capsule())
                    }
                    .tint(.secondary)
                }
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.background)
        .clipShape(RoundedRectangle(cornerRadius: 20))
    }

    var wishlistCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            VStack(alignment: .leading, spacing: 4) {
                Text("愿望清单")
                    .font(.title3.bold())
                Text("想去哪玩、吃什么、喝什么，先收集起来，后面一个个去实现。")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Picker("类型", selection: $wishlistCategory) {
                ForEach(WishlistCategory.allCases) { category in
                    Label(category.title, systemImage: category.icon)
                        .tag(category)
                }
            }
            .pickerStyle(.segmented)

            AddEntryBar(
                placeholder: "例如：去海边看日落",
                text: $wishlistInput,
                icon: wishlistCategory.icon,
                tint: .purple,
                action: addWishlistItem
            )

            if openWishlistItems.isEmpty && completedWishlistItems.isEmpty {
                ContentUnavailableView(
                    "还没有愿望",
                    systemImage: "sparkles",
                    description: Text("把想玩的、想吃的、想喝的都放进来。")
                )
                .frame(maxWidth: .infinity, minHeight: 120)
            } else {
                if !openWishlistItems.isEmpty {
                    VStack(spacing: 10) {
                        ForEach(openWishlistItems) { item in
                            WishlistRow(item: item) {
                                toggleWishlistItem(item)
                            } onDelete: {
                                deleteWishlistItem(item)
                            }

                            if item.id != openWishlistItems.last?.id {
                                Divider()
                            }
                        }
                    }
                }

                if !completedWishlistItems.isEmpty {
                    Divider()

                    DisclosureGroup("已经实现 \(completedWishlistItems.count) 个") {
                        VStack(spacing: 10) {
                            ForEach(completedWishlistItems.prefix(8)) { item in
                                WishlistRow(item: item) {
                                    toggleWishlistItem(item)
                                } onDelete: {
                                    deleteWishlistItem(item)
                                }

                                if item.id != completedWishlistItems.prefix(8).last?.id {
                                    Divider()
                                }
                            }
                        }
                        .padding(.top, 8)
                    }
                    .font(.subheadline.bold())
                }
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.background)
        .clipShape(RoundedRectangle(cornerRadius: 20))
    }
}
