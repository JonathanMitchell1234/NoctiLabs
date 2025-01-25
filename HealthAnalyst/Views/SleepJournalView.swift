//
//  SleepJournalView.swift
//  HealthAnalyst
//
//  Created by Jonathan Mitchell on 1/24/25.
//
import SwiftUI

// MARK: - Journal Data Structures
struct JournalEntry: Identifiable, Codable {
    let id: UUID
    let date: Date
    var text: String
}

// MARK: - Journal Views
struct SleepJournalView: View {
    @State private var entries: [JournalEntry] = []
    @State private var showingEditor = false
    @State private var newEntryText = ""
    @State private var editingEntry: JournalEntry?
    @State private var isExpanded = false
    
    var body: some View {
        VStack {
            if isExpanded {
                expandedJournalView
            } else {
                miniJournalView
            }
        }
        .background(Color(uiColor: .systemBackground))
        .sheet(isPresented: $showingEditor) {
            JournalEditorView(
                text: $newEntryText,
                isPresented: $showingEditor,
                onSave: { saveEntry(original: editingEntry) },
                onCancel: { editingEntry = nil }
            )
        }
        .onAppear(perform: loadEntries)
    }
    
    private var miniJournalView: some View {
        HStack(spacing: 16) {
            Image(systemName: "book.closed.fill")
                .resizable()
                .scaledToFit()
                .frame(width: 30, height: 30)
                .cornerRadius(6)
                .foregroundColor(.blue)
            
            VStack(alignment: .leading) {
                Text("Sleep Journal")
                    .font(.headline)
            }
            
            Spacer()
            
            Button(action: {
                withAnimation(.spring()) {
                    isExpanded = true
                }
            }) {
                Image(systemName: "chevron.up")
                    .font(.system(size: 22))
                    .foregroundColor(.primary)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(uiColor: .systemGray6))
        )
        .padding(.horizontal)
        .onTapGesture {
            withAnimation(.spring()) {
                isExpanded = true
            }
        }
    }
    
    private var expandedJournalView: some View {
        VStack(spacing: 20) {
            HStack {
                Spacer()
                Button(action: {
                    withAnimation(.spring()) {
                        isExpanded = false
                    }
                }) {
                    Image(systemName: "chevron.down")
                        .font(.system(size: 22, weight: .medium))
                        .foregroundColor(.primary)
                        .padding()
                }
            }
            
            HStack {
                Text("Sleep Journal")
                    .font(.system(size: 18, weight: .bold))
                Spacer()
                Button {
                    newEntryText = ""
                    editingEntry = nil
                    showingEditor = true
                } label: {
                    Image(systemName: "plus")
                        .font(.body.bold())
                }
            }
            .padding(.horizontal)
            
            if entries.isEmpty {
                Text("No entries yet. Tap '+' to add a journal entry.")
                    .foregroundColor(.secondary)
                    .padding()
                    .frame(maxWidth: .infinity)
            } else {
                ScrollView {
                    VStack(spacing: 16) {
                        ForEach(entries) { entry in
                            JournalEntryView(
                                entry: entry,
                                onDelete: {
                                    if let index = entries.firstIndex(where: { $0.id == entry.id }) {
                                        deleteEntry(at: IndexSet(integer: index))
                                    }
                                },
                                onEdit: {
                                    editingEntry = entry
                                    newEntryText = entry.text
                                    showingEditor = true
                                }
                            )
                        }
                    }
                    .padding(.horizontal)
                }
            }
            
            Spacer()
        }
        .padding(.top)
        .background(Color(uiColor: .systemGray6))
        .cornerRadius(20)
        .padding(.horizontal)
        .padding(.bottom)
    }
    
    // MARK: Journal Persistence
    private func loadEntries() {
        if let data = UserDefaults.standard.data(forKey: "sleepJournalEntries") {
            if let decoded = try? JSONDecoder().decode([JournalEntry].self, from: data) {
                entries = decoded.sorted { $0.date > $1.date }
            }
        }
    }
    
    private func saveEntry(original: JournalEntry?) {
        let text = newEntryText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return }
        
        if let original = original {
            if let index = entries.firstIndex(where: { $0.id == original.id }) {
                entries[index].text = text
            }
        } else {
            let newEntry = JournalEntry(id: UUID(), date: Date(), text: text)
            entries.insert(newEntry, at: 0)
        }
        
        if let encoded = try? JSONEncoder().encode(entries) {
            UserDefaults.standard.set(encoded, forKey: "sleepJournalEntries")
        }
        newEntryText = ""
        editingEntry = nil
    }
    
    private func deleteEntry(at offsets: IndexSet) {
        entries.remove(atOffsets: offsets)
        if let encoded = try? JSONEncoder().encode(entries) {
            UserDefaults.standard.set(encoded, forKey: "sleepJournalEntries")
        }
    }
}

struct JournalEntryView: View {
    let entry: JournalEntry
    var onDelete: () -> Void
    var onEdit: () -> Void
    
    @State private var offset = CGSize.zero
    @State private var initialOffset = CGSize.zero
    
    var body: some View {
        ZStack {
            HStack {
                Spacer()
                deleteButton
            }
            
            content
                .offset(x: offset.width)
                .gesture(dragGesture)
        }
    }
    
    private var content: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(entry.date, style: .date)
                    .font(.caption)
                    .foregroundColor(.gray)
                Spacer()
                
                Button(action: onEdit) {
                    Image(systemName: "pencil")
                        .foregroundColor(.blue)
                }
            }
            
            Text(entry.text)
                .font(.body)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding()
        .background(Color(uiColor: .systemGray5))
        .cornerRadius(12)
    }
    
    private var deleteButton: some View {
        Button(action: {
            withAnimation {
                offset = CGSize(width: -UIScreen.main.bounds.width, height: 0)
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
                onDelete()
            }
        }) {
            Image(systemName: "trash")
                .foregroundColor(.white)
                .padding()
                .background(Color.red)
                .cornerRadius(12)
        }
        .padding(.trailing, 20)
    }
    
    private var dragGesture: some Gesture {
        DragGesture()
            .onChanged { gesture in
                if gesture.translation.width < 0 {
                    offset = CGSize(width: gesture.translation.width + initialOffset.width, height: 0)
                }
            }
            .onEnded { gesture in
                withAnimation(.interactiveSpring()) {
                    if gesture.translation.width < -100 {
                        offset = CGSize(width: -UIScreen.main.bounds.width, height: 0)
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
                            onDelete()
                        }
                    } else {
                        offset = .zero
                    }
                    initialOffset = offset
                }
            }
    }
}

struct JournalEditorView: View {
    @Binding var text: String
    @Binding var isPresented: Bool
    var onSave: () -> Void
    var onCancel: () -> Void
    
    var body: some View {
        NavigationView {
            TextEditor(text: $text)
                .padding()
                .navigationTitle(text.isEmpty ? "New Entry" : "Edit Entry")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Cancel") {
                            isPresented = false
                            onCancel()
                        }
                    }
                    ToolbarItem(placement: .confirmationAction) {
                        Button("Save") {
                            onSave()
                            isPresented = false
                        }
                        .disabled(text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    }
                }
        }
    }
}
