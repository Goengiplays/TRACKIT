import SwiftUI

struct TodoPageView: View {
    @EnvironmentObject private var store: FinanceStore
    @State private var newTodo = ""
    @State private var filter: TodoFilter = .open

    private var filteredTodos: [TodoItem] {
        switch filter {
        case .open:
            return store.visibleTodos.filter { !$0.isDone }
        case .done:
            return store.visibleTodos.filter(\.isDone)
        case .all:
            return store.visibleTodos
        }
    }

    private var completionProgress: Double {
        guard !store.visibleTodos.isEmpty else { return 0 }
        let done = store.visibleTodos.filter(\.isDone).count
        return Double(done) / Double(store.visibleTodos.count)
    }

    var body: some View {
        List {
            Section {
                VStack(alignment: .leading, spacing: 18) {
                    TrackerHeader(eyebrow: "Daily money control", title: "Todo")
                    ScopeSwitcher()
                    todoHero
                    addTodoBar
                    filterPicker
                }
                .listRowInsets(EdgeInsets(top: 16, leading: 20, bottom: 10, trailing: 20))
                .listRowSeparator(.hidden)
                .listRowBackground(Color.clear)
            }

            Section {
                if filteredTodos.isEmpty {
                    EmptyOrganizerCard(
                        icon: "checkmark.seal",
                        title: "Nothing here yet",
                        message: filter == .open ? "Add one money task for today and keep it simple." : "Completed tasks will show here."
                    )
                    .listRowSeparator(.hidden)
                    .listRowInsets(EdgeInsets(top: 8, leading: 20, bottom: 8, trailing: 20))
                    .listRowBackground(Color.clear)
                } else {
                    ForEach(filteredTodos) { todo in
                        TodoTaskRow(todo: todo)
                            .contentShape(Rectangle())
                            .onTapGesture {
                                withAnimation(.snappy(duration: 0.25)) {
                                    store.toggleTodo(todo)
                                }
                            }
                            .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                Button(role: .destructive) {
                                    withAnimation { store.deleteTodo(todo) }
                                } label: {
                                    Label("Delete", systemImage: "trash")
                                }
                                .tint(AppTheme.expense)
                            }
                            .listRowSeparator(.hidden)
                            .listRowInsets(EdgeInsets(top: 7, leading: 20, bottom: 7, trailing: 20))
                            .listRowBackground(Color.clear)
                    }
                }
            }
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
        .background(AppTheme.background)
        .toolbar(.hidden, for: .navigationBar)
    }

    private var todoHero: some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Focus board")
                        .font(.title2.weight(.medium))
                        .foregroundStyle(AppTheme.ink)
                    Text("\(store.visibleTodos.filter { !$0.isDone }.count) open tasks")
                        .font(.subheadline)
                        .foregroundStyle(AppTheme.secondary)
                }
                Spacer()
                ZStack {
                    Circle()
                        .stroke(AppTheme.blueSoft, lineWidth: 11)
                    Circle()
                        .trim(from: 0, to: max(0.04, completionProgress))
                        .stroke(AppTheme.forest, style: StrokeStyle(lineWidth: 11, lineCap: .round))
                        .rotationEffect(.degrees(-90))
                    Text("\(Int(completionProgress * 100))%")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(AppTheme.forest)
                }
                .frame(width: 64, height: 64)
            }

            HStack(spacing: 8) {
                OrganizerStat(title: "All", value: "\(store.visibleTodos.count)", icon: "list.bullet")
                OrganizerStat(title: "Open", value: "\(store.visibleTodos.filter { !$0.isDone }.count)", icon: "circle")
                OrganizerStat(title: "Done", value: "\(store.visibleTodos.filter(\.isDone).count)", icon: "checkmark.circle")
            }
        }
        .padding(20)
        .background(
            LinearGradient(colors: [AppTheme.surface, AppTheme.blueSoft], startPoint: .topLeading, endPoint: .bottomTrailing)
        )
        .clipShape(RoundedRectangle(cornerRadius: 30, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 30, style: .continuous).stroke(AppTheme.border, lineWidth: 1))
        .shadow(color: AppTheme.blue.opacity(0.18), radius: 22, y: 12)
    }

    private var addTodoBar: some View {
        HStack(spacing: 10) {
            TextField("Add a money task", text: $newTodo)
                .padding(.horizontal, 15)
                .padding(.vertical, 13)
                .background(AppTheme.surface)
                .clipShape(Capsule())
                .overlay(Capsule().stroke(AppTheme.border, lineWidth: 1))
            Button {
                store.addTodo(newTodo)
                newTodo = ""
            } label: {
                Image(systemName: "plus")
                    .font(.headline.weight(.semibold))
                    .foregroundStyle(.white)
                    .frame(width: 46, height: 46)
                    .background(AppTheme.forest)
                    .clipShape(Circle())
                    .shadow(color: AppTheme.blue.opacity(0.2), radius: 14, y: 7)
            }
            .disabled(newTodo.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            .opacity(newTodo.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? 0.45 : 1)
        }
    }

    private var filterPicker: some View {
        Picker("Todo filter", selection: $filter) {
            ForEach(TodoFilter.allCases, id: \.self) { item in
                Text(item.rawValue).tag(item)
            }
        }
        .pickerStyle(.segmented)
    }
}

struct NotesPageView: View {
    @EnvironmentObject private var store: FinanceStore
    @State private var showingAddNote = false

    private var latestNote: NoteItem? {
        store.visibleNotes.first
    }

    var body: some View {
        List {
            Section {
                VStack(alignment: .leading, spacing: 18) {
                    TrackerHeader(eyebrow: "Private money journal", title: "Notes")
                    ScopeSwitcher()
                    notesHero
                    Button {
                        showingAddNote = true
                    } label: {
                        Label("Create new note", systemImage: "square.and.pencil")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(AppTheme.forest)
                            .clipShape(Capsule())
                            .shadow(color: AppTheme.blue.opacity(0.18), radius: 16, y: 8)
                    }
                    .buttonStyle(.plain)
                }
                .listRowInsets(EdgeInsets(top: 16, leading: 20, bottom: 10, trailing: 20))
                .listRowSeparator(.hidden)
                .listRowBackground(Color.clear)
            }

            Section {
                if store.visibleNotes.isEmpty {
                    EmptyOrganizerCard(
                        icon: "note.text",
                        title: "No notes yet",
                        message: "Save ideas about bills, cash, income, goals, or anything you need to remember."
                    )
                    .listRowSeparator(.hidden)
                    .listRowInsets(EdgeInsets(top: 8, leading: 20, bottom: 8, trailing: 20))
                    .listRowBackground(Color.clear)
                } else {
                    ForEach(store.visibleNotes) { note in
                        NoteDetailCard(note: note)
                            .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                Button(role: .destructive) {
                                    withAnimation { store.deleteNote(note) }
                                } label: {
                                    Label("Delete", systemImage: "trash")
                                }
                                .tint(AppTheme.expense)
                            }
                            .listRowSeparator(.hidden)
                            .listRowInsets(EdgeInsets(top: 7, leading: 20, bottom: 7, trailing: 20))
                            .listRowBackground(Color.clear)
                    }
                }
            } header: {
                Text("Saved notes")
            }
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
        .background(AppTheme.background)
        .toolbar(.hidden, for: .navigationBar)
        .sheet(isPresented: $showingAddNote) {
            AddNoteSheet()
        }
    }

    private var notesHero: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Insight notebook")
                        .font(.title2.weight(.medium))
                        .foregroundStyle(AppTheme.ink)
                    Text("\(store.visibleNotes.count) saved notes")
                        .font(.subheadline)
                        .foregroundStyle(AppTheme.secondary)
                }
                Spacer()
                Image(systemName: "sparkle.magnifyingglass")
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(AppTheme.forest)
                    .frame(width: 54, height: 54)
                    .background(AppTheme.limeSoft)
                    .clipShape(Circle())
            }

            if let latestNote {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Latest")
                        .font(.caption.weight(.bold))
                        .tracking(1)
                        .foregroundStyle(AppTheme.secondary)
                    Text(latestNote.title)
                        .font(.headline.weight(.medium))
                        .foregroundStyle(AppTheme.ink)
                    Text(latestNote.body)
                        .font(.subheadline)
                        .foregroundStyle(AppTheme.secondary)
                        .lineLimit(2)
                }
                .padding(14)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(AppTheme.surface.opacity(0.86))
                .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
            }
        }
        .padding(20)
        .background(
            LinearGradient(colors: [AppTheme.blueSoft, AppTheme.surface], startPoint: .topLeading, endPoint: .bottomTrailing)
        )
        .clipShape(RoundedRectangle(cornerRadius: 30, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 30, style: .continuous).stroke(AppTheme.border, lineWidth: 1))
        .shadow(color: AppTheme.blue.opacity(0.18), radius: 22, y: 12)
    }
}

private enum TodoFilter: String, CaseIterable {
    case open = "Open"
    case done = "Done"
    case all = "All"
}

private struct TodoTaskRow: View {
    let todo: TodoItem

    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: todo.isDone ? "checkmark.circle.fill" : "circle")
                .font(.title3.weight(.semibold))
                .foregroundStyle(todo.isDone ? AppTheme.forest : AppTheme.secondary)
            VStack(alignment: .leading, spacing: 4) {
                Text(todo.title)
                    .font(.headline.weight(.medium))
                    .foregroundStyle(AppTheme.ink)
                    .strikethrough(todo.isDone)
                Text(todo.createdAt.formatted(date: .abbreviated, time: .shortened))
                    .font(.caption)
                    .foregroundStyle(AppTheme.secondary)
            }
            Spacer()
            Image(systemName: "chevron.right")
                .font(.caption.weight(.bold))
                .foregroundStyle(AppTheme.secondary.opacity(0.7))
        }
        .padding(16)
        .background(AppTheme.surface)
        .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 22, style: .continuous).stroke(AppTheme.border, lineWidth: 1))
        .shadow(color: AppTheme.blue.opacity(0.11), radius: 16, y: 8)
    }
}

private struct NoteDetailCard: View {
    let note: NoteItem

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "doc.text.fill")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(AppTheme.forest)
                    .frame(width: 34, height: 34)
                    .background(AppTheme.limeSoft)
                    .clipShape(Circle())
                Spacer()
                Text(note.updatedAt.formatted(date: .abbreviated, time: .omitted))
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(AppTheme.secondary)
            }
            Text(note.title)
                .font(.title3.weight(.medium))
                .foregroundStyle(AppTheme.ink)
            Text(note.body)
                .font(.subheadline)
                .foregroundStyle(AppTheme.secondary)
                .lineSpacing(3)
        }
        .padding(18)
        .background(AppTheme.surface)
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 24, style: .continuous).stroke(AppTheme.border, lineWidth: 1))
        .shadow(color: AppTheme.blue.opacity(0.12), radius: 18, y: 9)
    }
}

private struct OrganizerStat: View {
    let title: String
    let value: String
    let icon: String

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Image(systemName: icon)
                .font(.caption.weight(.bold))
                .foregroundStyle(AppTheme.forest)
            Text(value)
                .font(.headline.weight(.semibold))
                .foregroundStyle(AppTheme.ink)
            Text(title)
                .font(.caption2.weight(.semibold))
                .foregroundStyle(AppTheme.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(AppTheme.surface.opacity(0.82))
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
    }
}

private struct EmptyOrganizerCard: View {
    let icon: String
    let title: String
    let message: String

    var body: some View {
        VStack(spacing: 10) {
            Image(systemName: icon)
                .font(.title2.weight(.semibold))
                .foregroundStyle(AppTheme.forest)
                .frame(width: 54, height: 54)
                .background(AppTheme.limeSoft)
                .clipShape(Circle())
            Text(title)
                .font(.headline.weight(.medium))
                .foregroundStyle(AppTheme.ink)
            Text(message)
                .font(.subheadline)
                .foregroundStyle(AppTheme.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(24)
        .background(AppTheme.surface)
        .clipShape(RoundedRectangle(cornerRadius: 26, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 26, style: .continuous).stroke(AppTheme.border, lineWidth: 1))
    }
}

private struct AddNoteSheet: View {
    @EnvironmentObject private var store: FinanceStore
    @Environment(\.dismiss) private var dismiss
    @State private var title = ""
    @State private var bodyText = ""

    var body: some View {
        NavigationStack {
            VStack(spacing: 16) {
                TextField("Title", text: $title)
                    .font(.title3.weight(.medium))
                    .padding(16)
                    .background(AppTheme.canvas)
                    .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))

                TextField("Write your note", text: $bodyText, axis: .vertical)
                    .lineLimit(8...14)
                    .padding(16)
                    .background(AppTheme.canvas)
                    .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))

                Spacer()
            }
            .padding(20)
            .background(AppTheme.background)
            .navigationTitle("New note")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        store.addNote(title: title, body: bodyText)
                        dismiss()
                    }
                    .disabled(bodyText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
    }
}
