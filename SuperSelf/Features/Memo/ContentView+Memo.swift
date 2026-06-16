import SwiftUI

extension ContentView {
    var anniversaryCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            Button {
                isShowingAnniversarySheet = true
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: "plus")
                    Text("添加纪念日")
                }
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.blue)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(Color.blue.opacity(0.12), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
            }
            .buttonStyle(.plain)

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
                            elapsedText: item.showsElapsedDays ? elapsedDaysText(for: item) : nil,
                            onEdit: {
                                editingAnniversaryItem = item
                            },
                            onDelete: {
                                deleteAnniversaryItem(item)
                            }
                        )
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
                            tint: .blue
                        )
                        .focused($isAnniversaryTitleFocused)
                    }

                    VStack(alignment: .leading, spacing: 10) {
                        anniversaryFieldLabel(anniversaryCalendarKind == .lunar ? "日期（按农历选择）" : "日期")
                        WheelDatePicker(
                            date: $anniversaryDate,
                            calendarKind: anniversaryCalendarKind,
                            tint: .blue
                        )
                        .id(anniversaryCalendarKind)

                        if anniversaryCalendarKind == .lunar,
                           let solarPreview = anniversarySolarPreviewText(date: anniversaryDate, calendarKind: .lunar) {
                            HStack(spacing: 8) {
                                Image(systemName: "calendar.badge.clock")
                                    .foregroundStyle(.blue)
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("今年对应阳历")
                                        .font(.caption2)
                                        .foregroundStyle(.secondary)
                                    Text(solarPreview)
                                        .font(.subheadline.bold())
                                        .foregroundStyle(.blue)
                                }
                                Spacer()
                            }
                            .padding(.horizontal, 14)
                            .padding(.vertical, 10)
                            .background(Color.blue.opacity(0.10))
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
                    .tint(.blue)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 12)
                    .background(Color(.secondarySystemGroupedBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                }
                .padding()
            }
            .background(Color(.systemGroupedBackground))
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
                ToolbarItem(placement: .confirmationAction) {
                    Button("添加") {
                        addAnniversaryItem()
                    }
                    .font(.subheadline.bold())
                    .foregroundStyle(.blue)
                    .disabled(!canAddAnniversary)
                }
            }
        }
        .presentationDetents([.large])
        .task {
            try? await Task.sleep(nanoseconds: 350_000_000)
            isAnniversaryTitleFocused = true
        }
    }

    func anniversaryFieldLabel(_ text: String) -> some View {
        Text(text)
            .font(.caption.bold())
            .foregroundStyle(.secondary)
    }

    var todoTasksCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 10) {
                todoFilterBar
                    .frame(maxWidth: .infinity, alignment: .leading)

                Button {
                    todoAddInitialPriority = todoFilter
                    isShowingTodoAddSheet = true
                } label: {
                    Image(systemName: "plus")
                        .font(.subheadline.weight(.bold))
                        .foregroundStyle(.white)
                        .frame(width: 36, height: 36)
                        .background(Color.blue, in: Circle())
                }
                .buttonStyle(.plain)
            }

            if activeTodoTasks.isEmpty && completedTodoTasks.isEmpty {
                AppEmptyState(
                    title: todoFilter == nil ? "还没有待办" : "这个优先级还没有待办",
                    systemImage: "checklist",
                    description: todoFilter == nil ? "把要做的事情写在这里，避免之后忘记。" : "可以直接在这个优先级下新增一条。"
                )
                .frame(maxWidth: .infinity, minHeight: 120)
            } else {
                if !activeTodoTasks.isEmpty {
                    VStack(spacing: 8) {
                        ForEach(activeTodoTasks) { task in
                            TodoTaskRow(task: task, onToggle: {
                                toggleTodoTask(task)
                            }, onEdit: {
                                editingTodoTask = task
                            }, onDelete: {
                                deleteTodoTask(task)
                            })
                        }
                    }
                }

                if !completedTodoTasks.isEmpty {
                    DisclosureGroup {
                        VStack(spacing: 8) {
                            ForEach(completedTodoTasks.prefix(8)) { task in
                                TodoTaskRow(task: task, onToggle: {
                                    toggleTodoTask(task)
                                }, onEdit: {
                                    editingTodoTask = task
                                }, onDelete: {
                                    deleteTodoTask(task)
                                })
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

    var todoFilterBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                todoFilterChip(for: nil)
                ForEach(TodoPriority.allCases) { priority in
                    todoFilterChip(for: priority)
                }
            }
            .padding(.vertical, 2)
        }
    }

    @ViewBuilder
    func todoFilterChip(for priority: TodoPriority?) -> some View {
        let isSelected = todoFilter == priority
        let tint = priority?.color ?? .blue
        let title = priority?.title ?? "全部"

        Button {
            withAnimation(.spring(response: 0.28, dampingFraction: 0.88)) {
                todoFilter = priority
            }
        } label: {
            HStack(spacing: 5) {
                Text(title)

                let count = todoCount(for: priority)
                if count > 0 {
                    Text("\(count)")
                        .font(.caption2.bold())
                        .padding(.horizontal, 5)
                        .padding(.vertical, 2)
                        .background((isSelected ? Color.white.opacity(0.22) : tint.opacity(0.12)), in: Capsule())
                }
            }
            .font(.subheadline.weight(.semibold))
            .foregroundStyle(isSelected ? .white : tint)
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background {
                if isSelected {
                    Capsule().fill(tint.gradient)
                } else {
                    Capsule().fill(tint.opacity(0.08))
                }
            }
        }
        .buttonStyle(.plain)
    }

    var wishlistCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 10) {
                wishlistFilterBar
                    .frame(maxWidth: .infinity, alignment: .leading)

                Button {
                    wishlistInput = ""
                    if let categoryID = wishlistFilter.categoryID {
                        wishlistCategoryID = categoryID
                    }
                    isShowingWishlistAddSheet = true
                } label: {
                    Image(systemName: "plus")
                        .font(.subheadline.weight(.bold))
                        .foregroundStyle(.white)
                        .frame(width: 36, height: 36)
                        .background(Color.blue, in: Circle())
                }
                .buttonStyle(.plain)
            }

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
                            WishlistRow(item: item, category: wishlistCategory(for: item), onToggle: {
                                toggleWishlistItem(item)
                            }, onEdit: {
                                editingWishlistItem = item
                            }, onDelete: {
                                deleteWishlistItem(item)
                            })
                        }
                    }
                }

                if !filteredCompletedWishlistItems.isEmpty {
                    DisclosureGroup {
                        VStack(spacing: 8) {
                            ForEach(filteredCompletedWishlistItems.prefix(8)) { item in
                                WishlistRow(item: item, category: wishlistCategory(for: item), onToggle: {
                                    toggleWishlistItem(item)
                                }, onEdit: {
                                    editingWishlistItem = item
                                }, onDelete: {
                                    deleteWishlistItem(item)
                                })
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

    var wishlistInputIcon: String {
        if wishlistFilter == .all {
            return WishlistFilter.all.icon
        }
        return wishlistCategories.first { $0.id == (wishlistFilter.categoryID ?? wishlistCategoryID) }?.icon ?? "sparkles"
    }

    var wishlistFilterBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach([WishlistFilter.all] + sortedWishlistCategories.map(WishlistFilter.init(category:))) { filter in
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
