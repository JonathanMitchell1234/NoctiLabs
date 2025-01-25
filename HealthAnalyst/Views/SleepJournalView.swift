//
//  SleepJournalView.swift
//  HealthAnalyst
//
//  Created by Jonathan Mitchell on 1/24/25.
//
import SwiftUI
import UIKit

// MARK: - Journal Data Structures
struct JournalEntry: Identifiable, Codable {
    let id: UUID
    let date: Date
    var attributedTextData: Data
    
    init(id: UUID = UUID(), date: Date, attributedText: NSAttributedString) {
        self.id = id
        self.date = date
        self.attributedTextData = try! NSKeyedArchiver.archivedData(
            withRootObject: attributedText,
            requiringSecureCoding: false
        )
    }
    
    var attributedText: NSAttributedString {
        (try? NSKeyedUnarchiver.unarchivedObject(
            ofClass: NSAttributedString.self,
            from: attributedTextData
        )) ?? NSAttributedString(string: "")
    }
}

// MARK: - Rich Text Editor
struct RichTextEditor: UIViewRepresentable {
    @Binding var attributedText: NSAttributedString
    @Binding var fontSize: Double
    @Binding var isBold: Bool
    @Binding var isItalic: Bool
    
    private var clampedFontSize: Double {
        min(max(fontSize, 12), 36)
    }
    
    func makeUIView(context: Context) -> UITextView {
        let textView = UITextView()
        textView.delegate = context.coordinator
        textView.font = UIFont.systemFont(ofSize: clampedFontSize)
        textView.autocapitalizationType = .sentences
        textView.isSelectable = true
        textView.isUserInteractionEnabled = true
        textView.backgroundColor = .clear
        textView.layoutManager.allowsNonContiguousLayout = false
        textView.panGestureRecognizer.minimumNumberOfTouches = 1
        return textView
    }
    
    func updateUIView(_ uiView: UITextView, context: Context) {
        if uiView.attributedText != attributedText {
            uiView.attributedText = attributedText
        }
        updateTypingAttributes(uiView)
    }
    
    private func updateTypingAttributes(_ textView: UITextView) {
        let validFontSize = clampedFontSize
        var traits: UIFontDescriptor.SymbolicTraits = []
        if isBold { traits.insert(.traitBold) }
        if isItalic { traits.insert(.traitItalic) }
        
        let font = textView.font ?? UIFont.systemFont(ofSize: validFontSize)
        let newFont = font.withTraits(traits)?.withSize(validFontSize) ?? font
        
        textView.typingAttributes = [
            .font: newFont,
            .foregroundColor: UIColor.label
        ]
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, UITextViewDelegate {
        var parent: RichTextEditor
        
        init(_ parent: RichTextEditor) {
            self.parent = parent
        }
        
        func textViewDidChange(_ textView: UITextView) {
            parent.attributedText = textView.attributedText
        }
        
        func textViewDidChangeSelection(_ textView: UITextView) {
            let selectedRange = textView.selectedRange
            if selectedRange.length > 0 {
                let attributes = textView.attributedText.attributes(
                    at: selectedRange.location,
                    effectiveRange: nil
                )
                if let font = attributes[.font] as? UIFont {
                    parent.fontSize = min(max(Double(font.pointSize), 12), 36)
                    parent.isBold = font.fontDescriptor.symbolicTraits.contains(.traitBold)
                    parent.isItalic = font.fontDescriptor.symbolicTraits.contains(.traitItalic)
                }
            } else {
                if let font = textView.typingAttributes[.font] as? UIFont {
                    parent.fontSize = min(max(Double(font.pointSize), 12), 36)
                    parent.isBold = font.fontDescriptor.symbolicTraits.contains(.traitBold)
                    parent.isItalic = font.fontDescriptor.symbolicTraits.contains(.traitItalic)
                }
            }
        }
    }
}

extension UIFont {
    func withTraits(_ traits: UIFontDescriptor.SymbolicTraits) -> UIFont? {
        guard let descriptor = fontDescriptor.withSymbolicTraits(traits) else { return nil }
        return UIFont(descriptor: descriptor, size: pointSize)
    }
}

// MARK: - Journal Views
struct SleepJournalView: View {
    @State private var entries: [JournalEntry] = []
    @State private var showingEditor = false
    @State private var editorAttributedText = NSAttributedString()
    @State private var editingEntry: JournalEntry?
    @State private var isExpanded = false
    @State private var editorFontSize: Double = 16
    @State private var editorIsBold = false
    @State private var editorIsItalic = false
    
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
                attributedText: $editorAttributedText,
                fontSize: $editorFontSize,
                isBold: $editorIsBold,
                isItalic: $editorIsItalic,
                isPresented: $showingEditor,
                onSave: { saveEntry(original: editingEntry) },
                onCancel: {
                    editingEntry = nil
                    resetEditorState()
                }
            )
        }
        .onAppear(perform: loadEntries)
    }
    
    private func resetEditorState() {
        editorFontSize = 16
        editorIsBold = false
        editorIsItalic = false
    }
    
    // MARK: View Components
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
            
            Button(action: expandView) {
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
        .onTapGesture(perform: expandView)
    }
    
    private var expandedJournalView: some View {
        VStack(spacing: 20) {
            collapseButton
            headerView
            entriesListView
            Spacer()
        }
        .padding(.top)
        .background(Color(uiColor: .systemGray6))
        .cornerRadius(20)
        .padding(.horizontal)
        .padding(.bottom)
    }
    
    private var collapseButton: some View {
        HStack {
            Spacer()
            Button(action: collapseView) {
                Image(systemName: "chevron.down")
                    .font(.system(size: 22, weight: .medium))
                    .foregroundColor(.primary)
                    .padding()
            }
        }
    }
    
    private var headerView: some View {
        HStack {
            Text("Sleep Journal")
                .font(.system(size: 18, weight: .bold))
            Spacer()
            Button(action: showEditor) {
                Image(systemName: "plus")
                    .font(.body.bold())
            }
        }
        .padding(.horizontal)
    }
    
    private var entriesListView: some View {
        Group {
            if entries.isEmpty {
                emptyStateView
            } else {
                ScrollView {
                    VStack(spacing: 16) {
                        ForEach(entries) { entry in
                            JournalEntryView(
                                entry: entry,
                                onDelete: { deleteEntry($0) },
                                onEdit: { prepareForEdit($0) }
                            )
                        }
                    }
                    .padding(.horizontal)
                }
            }
        }
    }
    
    private var emptyStateView: some View {
        Text("No entries yet. Tap '+' to add a journal entry.")
            .foregroundColor(.secondary)
            .padding()
            .frame(maxWidth: .infinity)
    }
    
    // MARK: Actions
    private func expandView() {
        withAnimation(.spring()) { isExpanded = true }
    }
    
    private func collapseView() {
        withAnimation(.spring()) { isExpanded = false }
    }
    
    private func showEditor() {
        editorAttributedText = NSAttributedString(string: "")
        editingEntry = nil
        resetEditorState()
        showingEditor = true
    }
    
    private func prepareForEdit(_ entry: JournalEntry) {
        editingEntry = entry
        editorAttributedText = entry.attributedText
        
        var detectedFontSize: Double = 16
        var isBold = false
        var isItalic = false
        
        if entry.attributedText.length > 0 {
            if let font = entry.attributedText.attribute(.font, at: 0, effectiveRange: nil) as? UIFont {
                detectedFontSize = Double(font.pointSize)
                detectedFontSize = min(max(detectedFontSize, 12), 36)
                
                let traits = font.fontDescriptor.symbolicTraits
                isBold = traits.contains(.traitBold)
                isItalic = traits.contains(.traitItalic)
            }
        }
        
        editorFontSize = detectedFontSize
        editorIsBold = isBold
        editorIsItalic = isItalic
        
        showingEditor = true
    }
    
    // MARK: Persistence
    private func loadEntries() {
        UserDefaults.standard.register(defaults: ["sleepJournalEntries": Data()])
        
        if let data = UserDefaults.standard.data(forKey: "sleepJournalEntries") {
            do {
                let decoded = try JSONDecoder().decode([JournalEntry].self, from: data)
                entries = decoded.sorted { $0.date > $1.date }
            } catch {
                entries = []
                UserDefaults.standard.removeObject(forKey: "sleepJournalEntries")
            }
        }
    }
    
    private func saveEntry(original: JournalEntry?) {
        guard !editorAttributedText.string.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        
        if let original = original {
            if let index = entries.firstIndex(where: { $0.id == original.id }) {
                entries[index] = JournalEntry(
                    id: original.id,
                    date: original.date,
                    attributedText: editorAttributedText
                )
            }
        } else {
            entries.insert(JournalEntry(
                date: Date(),
                attributedText: editorAttributedText
            ), at: 0)
        }
        
        saveToUserDefaults()
        resetEditorState()
    }
    
    private func deleteEntry(_ entry: JournalEntry) {
        if let index = entries.firstIndex(where: { $0.id == entry.id }) {
            entries.remove(at: index)
            saveToUserDefaults()
        }
    }
    
    private func saveToUserDefaults() {
        if let encoded = try? JSONEncoder().encode(entries) {
            UserDefaults.standard.set(encoded, forKey: "sleepJournalEntries")
        }
    }
}

struct JournalEntryView: View {
    let entry: JournalEntry
    var onDelete: (JournalEntry) -> Void
    var onEdit: (JournalEntry) -> Void
    
    @State private var offset = CGSize.zero
    @State private var initialOffset = CGSize.zero
    
    var body: some View {
        ZStack {
            deleteButtonBackground
            entryContent
                .offset(x: offset.width)
                .gesture(dragGesture)
        }
    }
    
    private var deleteButtonBackground: some View {
        HStack {
            Spacer()
            Button(action: { deleteWithAnimation() }) {
                Image(systemName: "trash")
                    .foregroundColor(.white)
                    .padding()
                    .background(Color.red)
                    .cornerRadius(12)
            }
            .padding(.trailing, 20)
        }
    }
    
    private var entryContent: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(entry.date, style: .date)
                    .font(.caption)
                    .foregroundColor(.gray)
                Spacer()
                Button(action: { onEdit(entry) }) {
                    Image(systemName: "pencil")
                        .foregroundColor(.blue)
                }
            }
            
            AttributedText(attributedString: entry.attributedText)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding()
        .background(Color(uiColor: .systemGray5))
        .cornerRadius(12)
    }
    
    private var dragGesture: some Gesture {
        DragGesture(minimumDistance: 20, coordinateSpace: .local)
            .onChanged { gesture in
                if abs(gesture.translation.width) > abs(gesture.translation.height) {
                    if gesture.translation.width < 0 {
                        offset = CGSize(width: gesture.translation.width + initialOffset.width, height: 0)
                    }
                }
            }
            .onEnded { gesture in
                withAnimation(.interactiveSpring()) {
                    if gesture.translation.width < -100 {
                        deleteWithAnimation()
                    } else {
                        resetPosition()
                    }
                }
            }
            .simultaneously(with: TapGesture())
            .exclusively(before: MagnificationGesture())
    }
    
    private func deleteWithAnimation() {
        withAnimation {
            offset = CGSize(width: -UIScreen.main.bounds.width, height: 0)
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
            onDelete(entry)
        }
    }
    
    private func resetPosition() {
        offset = .zero
        initialOffset = .zero
    }
}

struct AttributedText: UIViewRepresentable {
    let attributedString: NSAttributedString
    
    func makeUIView(context: Context) -> UITextView {
        let textView = UITextView()
        textView.isEditable = false
        textView.isScrollEnabled = false
        textView.backgroundColor = .clear
        textView.textContainerInset = .zero
        textView.textContainer.lineFragmentPadding = 0
        return textView
    }
    
    func updateUIView(_ uiView: UITextView, context: Context) {
        uiView.attributedText = attributedString
    }
}

struct JournalEditorView: View {
    @Binding var attributedText: NSAttributedString
    @Binding var fontSize: Double
    @Binding var isBold: Bool
    @Binding var isItalic: Bool
    @Binding var isPresented: Bool
    var onSave: () -> Void
    var onCancel: () -> Void
    
    private let fontSizeRange: ClosedRange<Double> = 12...36
    private let fontSizeStep: Double = 2
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                formattingToolbar
                    .padding(.horizontal)
                    .padding(.vertical, 8)
                    .background(Color(uiColor: .systemGray6))
                
                RichTextEditor(
                    attributedText: $attributedText,
                    fontSize: $fontSize,
                    isBold: $isBold,
                    isItalic: $isItalic
                )
                .padding()
            }
            .navigationTitle(attributedText.string.isEmpty ? "New Entry" : "Edit Entry")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel", action: cancel)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save", action: save)
                        .disabled(attributedText.string.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
            .ignoresSafeArea(.keyboard)
            .defersSystemGestures(on: .vertical)
        }
    }
    
    private var formattingToolbar: some View {
        HStack(spacing: 20) {
            Stepper(
                "Size: \(Int(fontSize))",
                value: Binding(
                    get: { self.fontSize },
                    set: { newValue in
                        self.fontSize = min(max(newValue, 12), 36)
                    }
                ),
                in: 12...36,
                step: 2
            )
            
            Button(action: { isBold.toggle() }) {
                Image(systemName: "bold")
                    .foregroundColor(isBold ? .blue : .primary)
                    .frame(width: 44, height: 44)
                    .background(isBold ? Color.blue.opacity(0.1) : Color.clear)
                    .cornerRadius(8)
            }
            
            Button(action: { isItalic.toggle() }) {
                Image(systemName: "italic")
                    .foregroundColor(isItalic ? .blue : .primary)
                    .frame(width: 44, height: 44)
                    .background(isItalic ? Color.blue.opacity(0.1) : Color.clear)
                    .cornerRadius(8)
            }
            
            Spacer()
        }
    }
    
    private func cancel() {
        isPresented = false
        onCancel()
    }
    
    private func save() {
        onSave()
        isPresented = false
    }
}
