import SwiftUI
import PhotosUI

private let maxProjectPhotos = 6
private let photoGridCoordinateSpaceName = "photoGridLayout"
private let photoGridRowSpacing: CGFloat = 8
private let reorderSlotHoverHysteresis: CGFloat = 26

struct ProjectImageSelectorView: View {
    let imagePaths: [String]
    let imagePathForDisplay: (String) -> String
    let onAddImage: (Data) -> Void
    let onRemoveImage: (String) -> Void
    let onApplyImagePathsOrder: ([String]) -> Void
    let onReorderDragActiveChange: (Bool) -> Void
    let onOpenPreview: (Int) -> Void
    
    @State private var selectedPhotoItem: PhotosPickerItem?
    @State private var gridLayoutWidth: CGFloat = 0
    @State private var draggingPath: String?
    @State private var hoverGapSlotIndex: Int = 0
    @State private var dragFingerInGrid: CGPoint = .zero
    @State private var draggingThumbnailUIImage: UIImage?
    @State private var reorderOthersPathsDuringDrag: [String] = []
    @State private var reorderGestureSessionDidBegin: Bool = false
    @Environment(\.themeColors) private var colors
    
    private var photoCount: Int { imagePaths.count }
    private var isAtMaxPhotos: Bool { photoCount >= maxProjectPhotos }
    private var allowsPhotoReorder: Bool { photoCount > 1 }

    private var photoCellSideLength: CGFloat {
        let inner = max(0, gridLayoutWidth - photoGridRowSpacing)
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
                    photoGridWithFloatingDrag
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
    
    private var photoGridWithFloatingDrag: some View {
        let side = photoCellSideLength
        return ZStack(alignment: .topLeading) {
            standardPhotoGrid(side: side)
                .animation(.easeOut(duration: 0.2), value: hoverGapSlotIndex)
            
            if draggingPath != nil {
                reorderFloatingThumbnail(side: side)
                    .position(dragFingerInGrid)
                    .animation(nil, value: dragFingerInGrid)
                    .allowsHitTesting(false)
                    .zIndex(1)
            }
        }
    }
    
    private func standardPhotoGrid(side: CGFloat) -> some View {
        let cells = gridCells
        let rows = chunkedPhotoGridRows(cells, columns: 2)
        return VStack(spacing: photoGridRowSpacing) {
            ForEach(Array(rows.enumerated()), id: \.offset) { _, row in
                HStack(spacing: photoGridRowSpacing) {
                    ForEach(row) { cell in
                        gridCellView(cell, side: side)
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
        .coordinateSpace(name: photoGridCoordinateSpaceName)
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
    
    private func reorderVisualOffset(forPhotoIndex photoIndex: Int, side: CGFloat) -> CGSize {
        guard let dragged = draggingPath else { return .zero }
        guard let sourceIndex = imagePaths.firstIndex(of: dragged), photoIndex != sourceIndex else { return .zero }
        let path = imagePaths[photoIndex]
        let others = reorderOthersPathsDuringDrag.isEmpty
            ? imagePaths.filter { $0 != dragged }
            : reorderOthersPathsDuringDrag
        guard let j = others.firstIndex(of: path) else { return .zero }
        let hover = min(max(0, hoverGapSlotIndex), others.count)
        let targetSlot = j < hover ? j : j + 1
        let rowI = photoIndex / 2
        let colI = photoIndex % 2
        let rowT = targetSlot / 2
        let colT = targetSlot % 2
        let step = side + photoGridRowSpacing
        return CGSize(
            width: CGFloat(colT - colI) * step,
            height: CGFloat(rowT - rowI) * step
        )
    }
    
    private func reorderCallbacks(for path: String, pathIndex: Int, side: CGFloat) -> PhotoReorderGestureCallbacks {
        PhotoReorderGestureCallbacks(
            gridCoordinateSpaceName: photoGridCoordinateSpaceName,
            onBegan: {
                beginReorderDrag(path: path, pathIndex: pathIndex, side: side)
            },
            onLocationChanged: { locationInGrid in
                updateReorderHover(fingerInGrid: locationInGrid, side: side)
            },
            onEnded: {
                finishReorderDrag()
            }
        )
    }
    
    private func reorderFloatingThumbnail(side: CGFloat) -> some View {
        Group {
            if let uiImage = draggingThumbnailUIImage {
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
        .frame(width: side, height: side)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
    
    private func beginReorderDrag(path: String, pathIndex: Int, side: CGFloat) {
        guard reorderGestureSessionDidBegin == false else { return }
        reorderGestureSessionDidBegin = true
        let resolvedPath = imagePathForDisplay(path)
        draggingThumbnailUIImage = UIImage(contentsOfFile: resolvedPath)
        reorderOthersPathsDuringDrag = imagePaths.filter { $0 != path }
        draggingPath = path
        hoverGapSlotIndex = min(pathIndex, imagePaths.count - 1)
        var fingerTransaction = Transaction()
        fingerTransaction.disablesAnimations = true
        withTransaction(fingerTransaction) {
            dragFingerInGrid = centerOfPhotoSlot(
                slotIndex: hoverGapSlotIndex,
                side: side,
                spacing: photoGridRowSpacing
            )
        }
        onReorderDragActiveChange(true)
    }
    
    private func updateReorderHover(fingerInGrid: CGPoint, side: CGFloat) {
        var fingerTransaction = Transaction()
        fingerTransaction.disablesAnimations = true
        withTransaction(fingerTransaction) {
            dragFingerInGrid = fingerInGrid
        }
        guard let dragged = draggingPath else { return }
        let others = reorderOthersPathsDuringDrag.isEmpty
            ? imagePaths.filter { $0 != dragged }
            : reorderOthersPathsDuringDrag
        let slotCount = others.count + 1
        guard slotCount > 0 else { return }
        let nextHover = hystereticGapSlot(
            finger: fingerInGrid,
            slotCount: slotCount,
            side: side,
            spacing: photoGridRowSpacing,
            currentHover: hoverGapSlotIndex
        )
        if nextHover != hoverGapSlotIndex {
            hoverGapSlotIndex = nextHover
        }
    }
    
    private func finishReorderDrag() {
        guard let path = draggingPath else {
            reorderGestureSessionDidBegin = false
            draggingThumbnailUIImage = nil
            reorderOthersPathsDuringDrag = []
            onReorderDragActiveChange(false)
            return
        }
        let others = reorderOthersPathsDuringDrag.isEmpty
            ? imagePaths.filter { $0 != path }
            : reorderOthersPathsDuringDrag
        let insertIndex = min(max(0, hoverGapSlotIndex), others.count)
        var result = others
        result.insert(path, at: insertIndex)
        if result != imagePaths {
            onApplyImagePathsOrder(result)
        }
        reorderGestureSessionDidBegin = false
        draggingPath = nil
        draggingThumbnailUIImage = nil
        reorderOthersPathsDuringDrag = []
        onReorderDragActiveChange(false)
    }
    
    private func centerOfPhotoSlot(slotIndex: Int, side: CGFloat, spacing: CGFloat) -> CGPoint {
        let row = slotIndex / 2
        let col = slotIndex % 2
        let step = side + spacing
        let x = CGFloat(col) * step + side / 2
        let y = CGFloat(row) * step + side / 2
        return CGPoint(x: x, y: y)
    }
    
    private func nearestGapSlot(to finger: CGPoint, slotCount: Int, side: CGFloat, spacing: CGFloat) -> Int {
        var bestIndex = 0
        var bestDistance = CGFloat.infinity
        for slotIndex in 0..<slotCount {
            let center = centerOfPhotoSlot(slotIndex: slotIndex, side: side, spacing: spacing)
            let distance = hypot(finger.x - center.x, finger.y - center.y)
            if distance < bestDistance {
                bestDistance = distance
                bestIndex = slotIndex
            }
        }
        return bestIndex
    }
    
    private func hystereticGapSlot(
        finger: CGPoint,
        slotCount: Int,
        side: CGFloat,
        spacing: CGFloat,
        currentHover: Int
    ) -> Int {
        let naive = nearestGapSlot(to: finger, slotCount: slotCount, side: side, spacing: spacing)
        let clampedCurrent = min(max(0, currentHover), max(0, slotCount - 1))
        guard naive != clampedCurrent else { return clampedCurrent }
        let centerCurrent = centerOfPhotoSlot(slotIndex: clampedCurrent, side: side, spacing: spacing)
        let centerNaive = centerOfPhotoSlot(slotIndex: naive, side: side, spacing: spacing)
        let distanceCurrent = hypot(finger.x - centerCurrent.x, finger.y - centerCurrent.y)
        let distanceNaive = hypot(finger.x - centerNaive.x, finger.y - centerNaive.y)
        if distanceNaive + reorderSlotHoverHysteresis < distanceCurrent {
            return naive
        }
        return clampedCurrent
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
    private func gridCellView(_ cell: GridCell, side: CGFloat) -> some View {
        switch cell {
        case .photo(let index):
            let path = imagePaths[index]
            ProjectImageThumbnailCell(
                imagePath: path,
                absolutePathForLoading: imagePathForDisplay(path),
                allowsReorder: allowsPhotoReorder,
                showsReorderSourcePlaceholder: draggingPath == path,
                hidesRemoveButtonWhileReordering: draggingPath != nil,
                onRemove: { onRemoveImage(path) },
                onOpenPreview: { onOpenPreview(index) },
                reorderGesture: reorderCallbacks(for: path, pathIndex: index, side: side)
            )
            .offset(reorderVisualOffset(forPhotoIndex: index, side: side))
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

private struct PhotoReorderGestureCallbacks {
    let gridCoordinateSpaceName: String
    let onBegan: () -> Void
    let onLocationChanged: (CGPoint) -> Void
    let onEnded: () -> Void
}

private struct PhotoThumbnailImageWell: View {
    @Environment(\.themeColors) private var colors
    let absolutePathForLoading: String
    let accessibilityHint: String
    let allowsReorder: Bool
    let showsReorderSourcePlaceholder: Bool
    let gridCoordinateSpaceName: String
    let onOpenPreview: () -> Void
    let onReorderSequenceChanged: (SequenceGesture<LongPressGesture, DragGesture>.Value) -> Void
    let onReorderSequenceEnded: (SequenceGesture<LongPressGesture, DragGesture>.Value) -> Void
    
    @State private var decodedThumbnail: UIImage?
    
    var body: some View {
        Group {
            if allowsReorder {
                imageCore
                    .gesture(reorderExclusiveGesture)
            } else {
                imageCore
                    .onTapGesture(perform: onOpenPreview)
            }
        }
        .onAppear {
            decodedThumbnail = UIImage(contentsOfFile: absolutePathForLoading)
        }
        .onChange(of: absolutePathForLoading) { _, newPath in
            decodedThumbnail = UIImage(contentsOfFile: newPath)
        }
    }
    
    private var imageCore: some View {
        ZStack {
            Color.clear
                .overlay {
                    Group {
                        if let uiImage = decodedThumbnail {
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
                .opacity(showsReorderSourcePlaceholder ? 0 : 1)
                .accessibilityHidden(showsReorderSourcePlaceholder)
            if showsReorderSourcePlaceholder {
                RoundedRectangle(cornerRadius: 12)
                    .strokeBorder(colors.tertiary.opacity(0.55), style: StrokeStyle(lineWidth: 2, dash: [6, 5]))
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(colors.secondaryContainer.opacity(0.25))
                    )
                    .allowsHitTesting(false)
                    .accessibilityHidden(true)
            }
        }
        .contentShape(Rectangle())
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(String(localized: "project.photos.projectImageA11y"))
        .accessibilityHint(accessibilityHint)
        .accessibilityAddTraits(.isButton)
        .accessibilityAction {
            onOpenPreview()
        }
    }
    
    private var reorderExclusiveGesture: some Gesture {
        ExclusiveGesture(
            TapGesture().onEnded { onOpenPreview() },
            LongPressGesture(minimumDuration: 0.35)
                .sequenced(
                    before: DragGesture(
                        minimumDistance: 0,
                        coordinateSpace: .named(gridCoordinateSpaceName)
                    )
                )
                .onChanged { onReorderSequenceChanged($0) }
                .onEnded { onReorderSequenceEnded($0) }
        )
    }
}

private struct ProjectImageThumbnailCell: View {
    let imagePath: String
    let absolutePathForLoading: String
    let allowsReorder: Bool
    let showsReorderSourcePlaceholder: Bool
    let hidesRemoveButtonWhileReordering: Bool
    let onRemove: () -> Void
    let onOpenPreview: () -> Void
    let reorderGesture: PhotoReorderGestureCallbacks?
    
    @Environment(\.themeColors) private var colors
    
    private var previewAccessibilityHint: String {
        if allowsReorder {
            String(localized: "project.photos.openPreviewAndReorderHint")
        } else {
            String(localized: "project.photos.openPreviewHint")
        }
    }
    
    var body: some View {
        ZStack(alignment: .topTrailing) {
            if let callbacks = reorderGesture, allowsReorder {
                PhotoThumbnailImageWell(
                    absolutePathForLoading: absolutePathForLoading,
                    accessibilityHint: previewAccessibilityHint,
                    allowsReorder: true,
                    showsReorderSourcePlaceholder: showsReorderSourcePlaceholder,
                    gridCoordinateSpaceName: callbacks.gridCoordinateSpaceName,
                    onOpenPreview: onOpenPreview,
                    onReorderSequenceChanged: { value in
                        Self.handleReorderSequenceChanged(value, callbacks: callbacks)
                    },
                    onReorderSequenceEnded: { value in
                        Self.handleReorderSequenceEnded(value, callbacks: callbacks)
                    }
                )
            } else {
                PhotoThumbnailImageWell(
                    absolutePathForLoading: absolutePathForLoading,
                    accessibilityHint: previewAccessibilityHint,
                    allowsReorder: false,
                    showsReorderSourcePlaceholder: false,
                    gridCoordinateSpaceName: "",
                    onOpenPreview: onOpenPreview,
                    onReorderSequenceChanged: { _ in },
                    onReorderSequenceEnded: { _ in }
                )
            }
            
            if !hidesRemoveButtonWhileReordering {
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
    
    private static func handleReorderSequenceChanged(
        _ value: SequenceGesture<LongPressGesture, DragGesture>.Value,
        callbacks: PhotoReorderGestureCallbacks
    ) {
        switch value {
        case .second(true, let drag):
            callbacks.onBegan()
            if let drag {
                callbacks.onLocationChanged(drag.location)
            }
        default:
            break
        }
    }
    
    private static func handleReorderSequenceEnded(
        _: SequenceGesture<LongPressGesture, DragGesture>.Value,
        callbacks: PhotoReorderGestureCallbacks
    ) {
        callbacks.onEnded()
    }
}

#Preview {
    ProjectImageSelectorView(
        imagePaths: [],
        imagePathForDisplay: { $0 },
        onAddImage: { _ in },
        onRemoveImage: { _ in },
        onApplyImagePathsOrder: { _ in },
        onReorderDragActiveChange: { _ in },
        onOpenPreview: { _ in }
    )
    .padding()
}
