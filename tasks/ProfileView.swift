import SwiftUI

struct ProfileView: View {
    @ObservedObject var viewModel: PetViewModel
    @State private var showingImagePicker = false
    @State private var inputImage: UIImage?
    
    var body: some View {
        NavigationView {
            VStack {
                if let user = viewModel.user {
                    VStack(spacing: 25) {
                        
                        
                        ZStack(alignment: .bottomTrailing) {
                            if let avatarUrl = user.avatar_url, let url = URL(string: avatarUrl) {
                                AsyncImage(url: url) { image in
                                    image
                                        .resizable()
                                        .scaledToFill()
                                } placeholder: {
                                    ProgressView()
                                }
                                .frame(width: 120, height: 120)
                                .clipShape(Circle())
                                .overlay(Circle().stroke(Color.blue.opacity(0.3), lineWidth: 4))
                            } else {
                                Image(systemName: "person.circle.fill")
                                    .resizable()
                                    .frame(width: 120, height: 120)
                                    .foregroundColor(.blue.opacity(0.8))
                            }
                            
                            Button(action: { showingImagePicker = true }) {
                                Circle()
                                    .fill(Color.blue)
                                    .frame(width: 35, height: 35)
                                    .overlay(Image(systemName: "camera.fill").foregroundColor(.white).font(.system(size: 14)))
                            }
                        }
                        .padding(.top, 20)
                        
                        VStack(spacing: 4) {
                            Text(user.full_name)
                                .font(.title)
                                .fontWeight(.bold)
                            Text("@\(user.username)")
                                .foregroundColor(.secondary)
                        }
                        
                        List {
                            Section(header: Text("Account Details")) {
                                Label {
                                    Text(user.email)
                                } icon: {
                                    Image(systemName: "envelope.fill").foregroundColor(.blue)
                                }
                            }
                            
                            Section(header: Text("Stats")) {
                                HStack {
                                    Label("My Pets", systemImage: "pawprint.fill")
                                        .foregroundColor(.orange)
                                    Spacer()
                                    Text("\(viewModel.pets.count)")
                                        .fontWeight(.bold)
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 4)
                                        .background(Color.orange.opacity(0.1))
                                        .cornerRadius(8)
                                }
                            }
                            
                            Section {
                                Button(action: { viewModel.logout() }) {
                                    HStack {
                                        Spacer()
                                        Image(systemName: "rectangle.portrait.and.arrow.right")
                                        Text("Log Out")
                                        Spacer()
                                    }
                                    .foregroundColor(.red)
                                    .fontWeight(.semibold)
                                }
                            }
                        }
                        .listStyle(.insetGrouped)
                    }
                } else {
                    ProgressView("Loading Profile...")
                }
            }
            .navigationTitle("Profile")
            .sheet(isPresented: $showingImagePicker, onDismiss: loadImage) {
                ImagePicker(image: $inputImage)
            }
        }
    }
    
    func loadImage() {
        guard let inputImage = inputImage else { return }
        viewModel.uploadAvatar(uiImage: inputImage)
    }
}


struct ImagePicker: UIViewControllerRepresentable {
    @Binding var image: UIImage?
    @Environment(\.presentationMode) var presentationMode

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject, UINavigationControllerDelegate, UIImagePickerControllerDelegate {
        let parent: ImagePicker

        init(_ parent: ImagePicker) {
            self.parent = parent
        }

        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            if let uiImage = info[.originalImage] as? UIImage {
                parent.image = uiImage
            }
            parent.presentationMode.wrappedValue.dismiss()
        }
    }
}
