import SwiftUI
import UIKit

struct ProjectImagePreviewSheet: View {
    let imagePaths: [String]
    let initialIndex: Int
    let absolutePathForLoading: (String) -> String
    let onClose: () -> Void
    
    @Environment(\.accessibilityReduceMotion) private var accessibilityReduceMotion
    @State private var selectedPage: Int = 0
    
    var body: some View {
        let safeIndex = clampedInitialIndex
        ZStack(alignment: .top) {
            Color.black.ignoresSafeArea()
            
            TabView(selection: $selectedPage) {
                ForEach(Array(imagePaths.enumerated()), id: \.offset) { index, path in
                    previewPage(for: path, pageNumber: index + 1)
                        .tag(index)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: imagePaths.count > 1 ? .automatic : .never))
            .padding(.top, 56)
            .modifier(ConditionalPageAnimation(enabled: !accessibilityReduceMotion, value: selectedPage))
            
            previewTopBar(currentPage: selectedPage + 1)
        }
        .onAppear {
            selectedPage = safeIndex
        }
    }
    
    private var clampedInitialIndex: Int {
        guard !imagePaths.isEmpty else { return 0 }
        return min(max(0, initialIndex), imagePaths.count - 1)
    }
    
    private func previewTopBar(currentPage: Int) -> some View {
        HStack {
            Text(
                String(
                    format: String(localized: "project.imagePreview.pageFormat"),
                    locale: .current,
                    currentPage,
                    imagePaths.count
                )
            )
            .font(.headline)
            .foregroundStyle(Color.primary)
            .padding(.leading, 8)
            
            Spacer()
            
            Button(action: onClose) {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 28))
                    .symbolRenderingMode(.hierarchical)
                    .foregroundStyle(Color.primary)
                    .frame(minWidth: 44, minHeight: 44)
                    .contentShape(Rectangle())
            }
            .accessibilityLabel(String(localized: "project.imagePreview.closeA11y"))
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 8)
        .background(.ultraThinMaterial)
    }
    
    private func previewPage(for path: String, pageNumber: Int) -> some View {
        let absolute = absolutePathForLoading(path)
        return Group {
            if let uiImage = UIImage(contentsOfFile: absolute) {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFit()
                    .padding(.horizontal, 16)
                    .accessibilityLabel(
                        String(
                            format: String(localized: "project.imagePreview.fullImageA11y"),
                            locale: .current,
                            pageNumber
                        )
                    )
            } else {
                ContentUnavailableView(
                    String(localized: "project.imagePreview.unavailableTitle"),
                    systemImage: "photo",
                    description: Text(String(localized: "project.imagePreview.unavailableMessage"))
                )
                .foregroundStyle(Color.primary)
            }
        }
    }
}

private struct ConditionalPageAnimation<V: Equatable>: ViewModifier {
    let enabled: Bool
    let value: V
    
    @ViewBuilder
    func body(content: Content) -> some View {
        if enabled {
            content.animation(.default, value: value)
        } else {
            content
        }
    }
}
