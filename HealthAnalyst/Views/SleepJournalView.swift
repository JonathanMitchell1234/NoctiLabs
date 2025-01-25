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
//                if let latestEntry = entries.first {
//                    Text(latestEntry.text)
//                        .font(.subheadline)
//                        .lineLimit(1)
//                        .foregroundColor(.secondary)
//                } else {
//                    Text("No entries yet")
//                        .font(.subheadline)
//                        .foregroundColor(.secondary)
//                }
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
                            VStack(alignment: .leading, spacing: 8) {
                                HStack {
                                    Text(entry.date, style: .date)
                                        .font(.caption)
                                        .foregroundColor(.gray)
                                    Spacer()
                                    Button {
                                        editingEntry = entry
                                        newEntryText = entry.text
                                        showingEditor = true
                                    } label: {
                                        Image(systemName: "pencil")
                                            .foregroundColor(.blue)
                                    }
                                }
                                
                                Text(entry.text)
                                    .font(.body)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                            }
                            .padding()
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color(uiColor: .systemGray5))
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
