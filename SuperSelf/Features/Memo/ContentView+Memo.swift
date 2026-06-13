import SwiftUI

extension ContentView {
    var anniversaryCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Text("纪念日")
                    .font(.title3.bold())

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
                            solarText: anniversarySolarText(for: item),
                            daysUntil: daysUntilAnniversary(for: item),
                            elapsedText: item.showsElapsedDays ? elapsedDaysText(for: item) : nil
                        ) {
                            editingAnniversaryItem = item
                        } onDelete: {
                            deleteAnniversaryItem(item)
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
                    SheetHeader(
                        icon: "calendar.badge.heart",
                        title: "添加纪念日",
                        subtitle: "记录重要的日子，支持阳历和农历",
                        gradient: [.orange, .pink]
                    )

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
                            placeholder: "记录个重要的日子",
                            text: $anniversaryTitleInput,
                            icon: "calendar.badge.heart",
                            tint: .orange
                        )
                    }

                    VStack(alignment: .leading, spacing: 10) {
                        anniversaryFieldLabel(anniversaryCalendarKind == .lunar ? "日期（按农历选择）" : "日期")
                        WheelDatePicker(
                            date: $anniversaryDate,
                            calendarKind: anniversaryCalendarKind,
                            tint: .orange
                        )
                        .id(anniversaryCalendarKind)

                        if anniversaryCalendarKind == .lunar,
                           let solarPreview = anniversarySolarPreviewText(date: anniversaryDate, calendarKind: .lunar) {
                            HStack(spacing: 8) {
                                Image(systemName: "calendar.badge.clock")
                                    .foregroundStyle(.orange)
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("今年对应阳历")
                                        .font(.caption2)
                                        .foregroundStyle(.secondary)
                                    Text(solarPreview)
                                        .font(.subheadline.bold())
                                        .foregroundStyle(.orange)
                                }
                                Spacer()
                            }
                            .padding(.horizontal, 14)
                            .padding(.vertical, 10)
                            .background(Color.orange.opacity(0.10))
                            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                        }
                    }

                    Toggle(isOn: $anniversaryShowsElapsedDays) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("显示累计天数")
                                .font(.subheadline.bold())
                            Text("从这一天到今天一共多少天，会显示在卡片上。")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .tint(.orange)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 12)
                    .background(Color(.secondarySystemGroupedBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
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

    var todoTasksCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Text("TODO")
                    .font(.title3.bold())

                Spacer()

                Text("\(activeTodoTasks.count) 件待做")
                    .font(.caption.bold())
                    .foregroundStyle(.blue)
            }

            AddEntryBar(
                placeholder: "记录些什么",
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
                    VStack(spacing: 8) {
                        ForEach(activeTodoTasks) { task in
                            TodoTaskRow(task: task) {
                                toggleTodoTask(task)
                            } onEdit: {
                                editingTodoTask = task
                            } onDelete: {
                                deleteTodoTask(task)
                            }
                        }
                    }
                }

                if !completedTodoTasks.isEmpty {
                    DisclosureGroup {
                        VStack(spacing: 8) {
                            ForEach(completedTodoTasks.prefix(8)) { task in
                                TodoTaskRow(task: task) {
                                    toggleTodoTask(task)
                                } onEdit: {
                                    editingTodoTask = task
                                } onDelete: {
                                    deleteTodoTask(task)
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
            Text("愿望清单")
                .font(.title3.bold())

            wishlistFilterBar

            AddEntryBar(
                placeholder: "想要点什么",
                text: $wishlistInput,
                icon: wishlistCategories.first { $0.id == (wishlistFilter.categoryID ?? wishlistCategoryID) }?.icon ?? "sparkles",
                tint: .blue,
                action: addWishlistItem
            )

            if filteredOpenWishlistItems.isEmpty && filteredCompletedWishlistItems.isEmpty {
                AppEmptyState(
                    title: wishlistFilter == .all ? "还没有愿望" : "这里还没有愿望",
                    systemImage: "sparkles",
                    description: wishlistFilter == .all ? "把想读的书、想看的电影、想尝试的新鲜事都放进来。" : "可以直接在当前分类下新增一条。"
                )
                .frame(maxWidth: .infinity, minHeight: 120)
            } else {
                if !filteredOpenWishlistItems.isEmpty {
                    VStack(spacing: 8) {
                        ForEach(filteredOpenWishlistItems) { item in
                            WishlistRow(item: item, category: wishlistCategory(for: item)) {
                                toggleWishlistItem(item)
                            } onEdit: {
                                editingWishlistItem = item
                            } onDelete: {
                                deleteWishlistItem(item)
                            }
                        }
                    }
                }

                if !filteredCompletedWishlistItems.isEmpty {
                    DisclosureGroup {
                        VStack(spacing: 8) {
                            ForEach(filteredCompletedWishlistItems.prefix(8)) { item in
                                WishlistRow(item: item, category: wishlistCategory(for: item)) {
                                    toggleWishlistItem(item)
                                } onEdit: {
                                    editingWishlistItem = item
                                } onDelete: {
                                    deleteWishlistItem(item)
                                }
                            }
                        }
                        .padding(.top, 8)
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: "checkmark.circle")
                            Text("已经实现 \(filteredCompletedWishlistItems.count) 个")
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

    var wishlistFilterBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach([WishlistFilter.all] + wishlistCategories.map(WishlistFilter.init(category:))) { filter in
                    Button {
                        withAnimation(.spring(response: 0.28, dampingFraction: 0.88)) {
                            wishlistFilter = filter
                            if let categoryID = filter.categoryID {
                                wishlistCategoryID = categoryID
                            }
                        }
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: filter.icon)
                                .font(.caption.weight(.bold))

                            Text(filter.title)

                            let count = wishlistCount(for: filter)
                            if count > 0 {
                                Text("\(count)")
                                    .font(.caption2.bold())
                                    .padding(.horizontal, 5)
                                    .padding(.vertical, 2)
                                    .background((wishlistFilter == filter ? Color.white.opacity(0.22) : Color.blue.opacity(0.12)), in: Capsule())
                            }
                        }
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(wishlistFilter == filter ? .white : .blue)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background {
                            if wishlistFilter == filter {
                                Capsule()
                                    .fill(Color.blue.gradient)
                            } else {
                                Capsule()
                                    .fill(Color.blue.opacity(0.08))
                            }
                        }
                    }
                    .buttonStyle(.plain)
                }

                Button {
                    isShowingWishlistCategorySheet = true
                } label: {
                    Image(systemName: "slider.horizontal.3")
                        .font(.caption.bold())
                        .foregroundStyle(.blue)
                        .frame(width: 34, height: 34)
                        .background(Color.blue.opacity(0.10), in: Circle())
                }
                .buttonStyle(.plain)
            }
            .padding(.vertical, 2)
        }
    }
}
