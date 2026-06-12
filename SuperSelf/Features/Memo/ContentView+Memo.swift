import SwiftUI

extension ContentView {
    var anniversaryCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("纪念日")
                        .font(.title3.bold())
                    Text("记录重要的日子，阴历阳历都可以，可选显示已过去多少天。")
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
                            solarText: anniversarySolarText(for: item),
                            daysUntil: daysUntilAnniversary(for: item),
                            elapsedText: item.showsElapsedDays ? elapsedDaysText(for: item) : nil
                        ) {
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
                        DatePicker("", selection: $anniversaryDate, displayedComponents: .date)
                            .datePickerStyle(.graphical)
                            .tint(.orange)
                            .environment(\.locale, Locale(identifier: "zh_CN"))
                            .environment(\.calendar, anniversaryCalendarKind == .lunar ? Calendar(identifier: .chinese) : Calendar.current)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color(.secondarySystemGroupedBackground))
                            .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))

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
                placeholder: "想要点什么",
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
                    VStack(spacing: 8) {
                        ForEach(openWishlistItems) { item in
                            WishlistRow(item: item) {
                                toggleWishlistItem(item)
                            } onDelete: {
                                deleteWishlistItem(item)
                            }
                        }
                    }
                }

                if !completedWishlistItems.isEmpty {
                    DisclosureGroup("已经实现 \(completedWishlistItems.count) 个") {
                        VStack(spacing: 8) {
                            ForEach(completedWishlistItems.prefix(8)) { item in
                                WishlistRow(item: item) {
                                    toggleWishlistItem(item)
                                } onDelete: {
                                    deleteWishlistItem(item)
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
