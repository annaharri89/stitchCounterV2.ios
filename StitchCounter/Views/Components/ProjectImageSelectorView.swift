import SwiftUI
import PhotosUI

struct ProjectImageSelectorView: View {
    let imagePaths: [String]
    let onAddImage: (Data) -> Void
    let onRemoveImage: (String) -> Void
    
    @State private var selectedPhotoItem: PhotosPickerItem?
    @Environment(\.themeColors) private var colors
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Project Images")
                .font(.headline)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    PhotosPicker(selection: $selectedPhotoItem, matching: .images) {
                        AddImageButton()
                    }
                    .onChange(of: selectedPhotoItem) { _, newValue in
                        Task {
                            if let newValue = newValue,
                               let data = try? await newValue.loadTransferable(type: Data.self) {
                                onAddImage(data)
                                selectedPhotoItem = nil
                            }
                        }
                    }
                    
                    ForEach(imagePaths, id: \.self) { path in
                        ProjectImageThumbnail(
                            imagePath: path,
                            onRemove: { onRemoveImage(path) }
                        )
                    }
                }
                .padding(.vertical, 4)
            }
        }
    }
}

struct AddImageButton: View {
    @Environment(\.themeColors) private var colors
    
    var body: some View {
        VStack {
            Image(systemName: "plus")
                .font(.system(size: 24))
                .foregroundColor(colors.primary)
        }
        .frame(width: 80, height: 80)
        .background(colors.primaryContainer)
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(colors.primary.opacity(0.3), lineWidth: 2)
        )
    }
}

struct ProjectImageThumbnail: View {
    let imagePath: String
    let onRemove: () -> Void
    
    @Environment(\.themeColors) private var colors
    
    var body: some View {
        ZStack(alignment: .topTrailing) {
            if let uiImage = UIImage(contentsOfFile: imagePath) {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 80, height: 80)
                    .cornerRadius(12)
                    .clipped()
            } else {
                Rectangle()
                    .fill(colors.tertiaryContainer)
                    .frame(width: 80, height: 80)
                    .cornerRadius(12)
                    .overlay(
                        Image(systemName: "photo")
                            .foregroundColor(colors.onTertiaryContainer)
                    )
            }
            
            Button {
                onRemove()
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 20))
                    .foregroundColor(colors.error)
                    .background(Circle().fill(.white))
            }
            .offset(x: 6, y: -6)
        }
    }
}

#Preview {
    ProjectImageSelectorView(
        imagePaths: [],
        onAddImage: { _ in },
        onRemoveImage: { _ in }
    )
    .padding()
}
