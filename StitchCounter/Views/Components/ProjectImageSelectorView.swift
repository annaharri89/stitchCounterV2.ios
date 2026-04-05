import SwiftUI
import PhotosUI

private let maxProjectPhotos = 6

struct ProjectImageSelectorView: View {
    let imagePaths: [String]
    let imagePathForDisplay: (String) -> String
    let onAddImage: (Data) -> Void
    let onRemoveImage: (String) -> Void
    let onOpenPreview: (Int) -> Void
    
    @State private var selectedPhotoItem: PhotosPickerItem?
    @State private var gridLayoutWidth: CGFloat = 0
    @Environment(\.themeColors) private var colors
    
    private var photoCount: Int { imagePaths.count }
    private var isAtMaxPhotos: Bool { photoCount >= maxProjectPhotos }

    private var photoCellSideLength: CGFloat {
        let rowSpacing: CGFloat = 8
        let inner = max(0, gridLayoutWidth - rowSpacing)
        return max(44, inner / 2)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(String(localized: "project.photos.header"))
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(colors.onSurface)
                    .accessibilityAddTraits(.isHeader)
                Spacer()
                Text(
                    String(
                        format: String(localized: "project.photos.countFormat"),
                        locale: .current,
                        photoCount,
                        maxProjectPhotos
                    )
                )
                .font(.caption)
                .foregroundStyle(colors.onSurface.opacity(0.6))
            }
            
            VStack(alignment: .leading, spacing: 8) {
                if photoCount == 0 {
                    emptyPlaceholder
                } else {
                    photoGrid
                }
            }
            .padding(12)
            .background(colors.secondaryContainer.opacity(0.35))
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(colors.onSurface.opacity(0.2), lineWidth: 1)
            )
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
    
    private var emptyPlaceholder: some View {
        Group {
            if isAtMaxPhotos {
                placeholderContent(isInteractive: false)
            } else {
                PhotosPicker(selection: $selectedPhotoItem, matching: .images) {
                    placeholderContent(isInteractive: true)
                }
                .buttonStyle(.plain)
                .onChange(of: selectedPhotoItem) { _, newValue in
                    loadPhotoData(from: newValue)
                }
            }
        }
    }
    
    private func placeholderContent(isInteractive: Bool) -> some View {
        VStack(spacing: 8) {
            Image(systemName: "photo.badge.plus")
                .font(.system(size: 32))
                .foregroundStyle(isInteractive ? colors.tertiary : colors.onSurface.opacity(0.55))
            Text(placeholderLabel)
                .font(.caption.weight(.medium))
                .multilineTextAlignment(.center)
                .foregroundStyle(isInteractive ? colors.tertiary : colors.onSurface.opacity(0.55))
        }
        .frame(maxWidth: .infinity)
        .frame(height: 120)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(isInteractive ? colors.primary.opacity(0.2) : colors.secondaryContainer.opacity(0.5))
        )
        .accessibilityElement(children: .combine)
        .accessibilityLabel(String(localized: "project.photos.addPhotoA11y"))
        .accessibilityHint(
            isInteractive
                ? String(localized: "project.photos.addPhotoHint")
                : String(localized: "project.photos.maxReachedA11y")
        )
    }
    
    private var placeholderLabel: String {
        if isAtMaxPhotos {
            String(
                format: String(localized: "project.photos.maxReachedFormat"),
                locale: .current,
                maxProjectPhotos
            )
        } else {
            String(localized: "project.photos.addPhoto")
        }
    }
    
    private var photoGrid: some View {
        let cells = gridCells
        let rows = chunkedPhotoGridRows(cells, columns: 2)
        let side = photoCellSideLength
        return VStack(spacing: 8) {
            ForEach(Array(rows.enumerated()), id: \.offset) { _, row in
                HStack(spacing: 8) {
                    ForEach(row) { cell in
                        gridCellView(cell)
                            .frame(width: side, height: side)
                    }
                    if row.count == 1 {
                        Color.clear
                            .frame(width: side, height: side)
                            .accessibilityHidden(true)
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .background {
            GeometryReader { geo in
                Color.clear
                    .onAppear {
                        let w = geo.size.width
                        if w > 0, abs(w - gridLayoutWidth) > 0.5 {
                            gridLayoutWidth = w
                        }
                    }
                    .onChange(of: geo.size) { _, newSize in
                        if newSize.width > 0, abs(newSize.width - gridLayoutWidth) > 0.5 {
                            gridLayoutWidth = newSize.width
                        }
                    }
            }
        }
    }

    private func chunkedPhotoGridRows(_ items: [GridCell], columns: Int) -> [[GridCell]] {
        stride(from: 0, to: items.count, by: columns).map {
            Array(items[$0..<min($0 + columns, items.count)])
        }
    }
    
    private enum GridCell: Hashable, Identifiable {
        case photo(index: Int)
        case add
        
        var id: String {
            switch self {
            case .photo(let index): return "p-\(index)"
            case .add: return "add"
            }
        }
    }
    
    private var gridCells: [GridCell] {
        var cells: [GridCell] = imagePaths.indices.map { .photo(index: $0) }
        if !isAtMaxPhotos {
            cells.append(.add)
        }
        return cells
    }
    
    @ViewBuilder
    private func gridCellView(_ cell: GridCell) -> some View {
        switch cell {
        case .photo(let index):
            let path = imagePaths[index]
            ProjectImageThumbnailCell(
                imagePath: path,
                absolutePathForLoading: imagePathForDisplay(path),
                onRemove: { onRemoveImage(path) },
                onOpenPreview: { onOpenPreview(index) }
            )
        case .add:
            PhotosPicker(selection: $selectedPhotoItem, matching: .images) {
                addAnotherPhotoButton
            }
            .buttonStyle(.plain)
            .onChange(of: selectedPhotoItem) { _, newValue in
                loadPhotoData(from: newValue)
            }
        }
    }
    
    private var addAnotherPhotoButton: some View {
        Image(systemName: "plus")
            .font(.system(size: 32))
            .foregroundStyle(colors.onPrimaryContainer)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(colors.primaryContainer.opacity(0.5))
            )
            .accessibilityLabel(String(localized: "project.photos.addAnotherPhotoA11y"))
            .accessibilityHint(String(localized: "project.photos.addPhotoHint"))
    }
    
    private func loadPhotoData(from item: PhotosPickerItem?) {
        guard let item else { return }
        Task {
            if let data = try? await item.loadTransferable(type: Data.self) {
                onAddImage(data)
            }
            selectedPhotoItem = nil
        }
    }
}

private struct ProjectImageThumbnailCell: View {
    let imagePath: String
    let absolutePathForLoading: String
    let onRemove: () -> Void
    let onOpenPreview: () -> Void
    
    @Environment(\.themeColors) private var colors
    
    var body: some View {
        ZStack(alignment: .topTrailing) {
            Button(action: onOpenPreview) {
                Color.clear
                    .overlay {
                        Group {
                            if let uiImage = UIImage(contentsOfFile: absolutePathForLoading) {
                                Image(uiImage: uiImage)
                                    .resizable()
                                    .scaledToFill()
                            } else {
                                Rectangle()
                                    .fill(colors.tertiaryContainer)
                                    .overlay(
                                        Image(systemName: "photo")
                                            .foregroundStyle(colors.onTertiaryContainer)
                                    )
                            }
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .clipped()
                    }
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel(String(localized: "project.photos.projectImageA11y"))
            .accessibilityHint(String(localized: "project.photos.openPreviewHint"))
            
            Button(action: onRemove) {
                ZStack {
                    Circle()
                        .fill(Color.white)
                        .frame(width: 26, height: 26)
                    Image(systemName: "trash.fill")
                        .font(.system(size: 14))
                        .foregroundStyle(colors.error)
                }
                .frame(width: 44, height: 44)
                .contentShape(Rectangle())
            }
            .accessibilityLabel(String(localized: "project.photos.removeImageA11y"))
            .offset(x: 4, y: -4)
        }
    }
}

#Preview {
    ProjectImageSelectorView(
        imagePaths: [],
        imagePathForDisplay: { $0 },
        onAddImage: { _ in },
        onRemoveImage: { _ in },
        onOpenPreview: { _ in }
    )
    .padding()
}
