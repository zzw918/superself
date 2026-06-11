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
                    AppIconCircleButton(icon: "plus", tint: .orange)
                }
                .buttonStyle(.plain)
            }

            if anniversaryItems.isEmpty {
                AppEmptyState(
                    title: "还没有纪念日",
                    systemImage: "calendar.badge.plus",
                    description: "把生日、结婚纪念日或其他重要日子记下来。"
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
            ScrollView {
                VStack(alignment: .leading, spacing: 22) {
                    VStack(alignment: .leading, spacing: 10) {
                        anniversaryFieldLabel("类型")

                        HStack(spacing: 10) {
                            ForEach(AnniversaryKind.allCases) { kind in
                                anniversaryKindChip(kind)
                            }
                        }
                    }

                    VStack(alignment: .leading, spacing: 10) {
                        anniversaryFieldLabel("日期类型")
                        AppSegmentedControl(
                            options: AnniversaryCalendarKind.allCases,
                            selection: $anniversaryCalendarKind,
                            title: \.title
                        )
                    }

                    VStack(alignment: .leading, spacing: 10) {
                        anniversaryFieldLabel("名称")
                        ModernInputField(
                            placeholder: anniversaryKind == .other ? "例如：第一次旅行" : "例如：妈妈生日",
                            text: $anniversaryTitleInput,
                            icon: anniversaryKind.icon,
                            tint: .orange
                        )
                    }

                    VStack(alignment: .leading, spacing: 10) {
                        anniversaryFieldLabel("日期")
                        DatePicker("", selection: $anniversaryDate, displayedComponents: .date)
                            .datePickerStyle(.graphical)
                            .tint(.orange)
                            .environment(\.locale, Locale(identifier: "zh_CN"))
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color(.secondarySystemGroupedBackground))
                            .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                    }
                }
                .padding()
            }
            .background(Color(.systemGroupedBackground))
            .safeAreaInset(edge: .bottom) {
                Button(action: addAnniversaryItem) {
                    Text("添加纪念日")
                }
                .buttonStyle(AppPrimaryButtonStyle(tint: .orange))
                .disabled(!canAddAnniversary)
                .padding(.horizontal)
                .padding(.bottom, 8)
                .background(.bar)
            }
            .navigationTitle("添加纪念日")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") {
                        isShowingAnniversarySheet = false
                    }
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(.secondary)
                }
            }
        }
        .presentationDetents([.large])
    }

    func anniversaryFieldLabel(_ text: String) -> some View {
        Text(text)
            .font(.caption.bold())
            .foregroundStyle(.secondary)
    }

    func anniversaryKindChip(_ kind: AnniversaryKind) -> some View {
        let isSelected = anniversaryKind == kind

        return Button {
            withAnimation(.spring(response: 0.25, dampingFraction: 0.85)) {
                anniversaryKind = kind
            }
        } label: {
            VStack(spacing: 8) {
                Image(systemName: kind.icon)
                    .font(.title3)
                    .foregroundStyle(isSelected ? .white : Color.orange)
                    .frame(width: 40, height: 40)
                    .background(isSelected ? AnyShapeStyle(Color.orange) : AnyShapeStyle(Color.orange.opacity(0.12)), in: Circle())

                Text(kind.title)
                    .font(.caption.weight(.medium))
                    .foregroundStyle(isSelected ? .primary : .secondary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(isSelected ? Color.orange : Color(.separator).opacity(0.18), lineWidth: isSelected ? 2 : 1)
            }
        }
        .buttonStyle(.plain)
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
                AppEmptyState(
                    title: "还没有待办",
                    systemImage: "checklist",
                    description: "把要做的事情写在这里，避免之后忘记。"
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
                AppEmptyState(
                    title: "还没有愿望",
                    systemImage: "sparkles",
                    description: "把想玩的、想吃的、想喝的都放进来。"
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
