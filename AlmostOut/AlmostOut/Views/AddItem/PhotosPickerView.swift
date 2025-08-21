//
//  PhotosPickerView.swift
//  AlmostOut
//
//  Created by Miles Ranisavljevic on 8/21/25.
//

import PhotosUI
import SwiftUI

struct PhotosPickerView: View {
    @Binding var selectedImages: [UIImage]
    @State private var selectedPhotos: [PhotosPickerItem] = []
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            PhotosPicker(
                selection: $selectedPhotos,
                maxSelectionCount: StorageConstants.maxImagesPerItem,
                matching: .images
            ) {
                Label("Add Photos", systemImage: "camera")
            }
            
            if !selectedImages.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(Array(selectedImages.enumerated()), id: \.offset) { index, image in
                            ZStack(alignment: .topTrailing) {
                                Image(uiImage: image)
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
                                    .frame(width: 80, height: 80)
                                    .clipped()
                                    .cornerRadius(8)
                                
                                Button {
                                    selectedImages.remove(at: index)
                                } label: {
                                    Image(systemName: "xmark.circle.fill")
                                        .foregroundColor(.white)
                                        .background(Color.black.opacity(0.6))
                                        .clipShape(Circle())
                                }
                                .offset(x: 5, y: -5)
                            }
                        }
                    }
                    .padding(.horizontal)
                }
            }
        }
        .onChange(of: selectedPhotos) { _, newPhotos in
            Task {
                await loadSelectedPhotos(newPhotos)
            }
        }
    }
    
    private func loadSelectedPhotos(_ photos: [PhotosPickerItem]) async {
        var images: [UIImage] = []
        
        for photo in photos {
            if let data = try? await photo.loadTransferable(type: Data.self),
               let image = UIImage(data: data) {
                images.append(image)
            }
        }
        
        await MainActor.run {
            selectedImages = images
        }
    }
}
