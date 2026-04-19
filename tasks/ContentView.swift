import SwiftUI

import SwiftUI

struct ContentView: View {
    @StateObject var viewModel = PetViewModel()
    @State private var showingAddPet = false
    @State private var newPetName = ""
    @State private var selectedType: PetType = .dog
    @State private var newPetBirthDate = Date()
    
    var body: some View {
        Group {
            if !viewModel.isAuthenticated {
                AuthView(viewModel: viewModel)
            } else {
                TabView {
                    
                    NavigationView {
                        VStack(spacing: 0) {
                            
                            VStack(spacing: 12) {
                                HStack {
                                    Image(systemName: "magnifyingglass")
                                        .foregroundColor(.secondary)
                                    TextField("Search pets...", text: $viewModel.searchText)
                                }
                                .padding(10)
                                .background(Color.secondary.opacity(0.1))
                                .cornerRadius(10)
                                .padding(.horizontal)
                                
                                ScrollView(.horizontal, showsIndicators: false) {
                                    HStack(spacing: 10) {
                                        Button(action: { viewModel.selectedFilterType = nil }) {
                                            Text("All")
                                                .padding(.horizontal, 15)
                                                .padding(.vertical, 8)
                                                .background(viewModel.selectedFilterType == nil ? Color.blue : Color.secondary.opacity(0.1))
                                                .foregroundColor(viewModel.selectedFilterType == nil ? .white : .primary)
                                                .cornerRadius(20)
                                        }
                                        
                                        ForEach(PetType.allCases, id: \.self) { type in
                                            Button(action: { viewModel.selectedFilterType = type }) {
                                                HStack {
                                                    Text(type.icon)
                                                    Text(type.rawValue)
                                                }
                                                .padding(.horizontal, 15)
                                                .padding(.vertical, 8)
                                                .background(viewModel.selectedFilterType == type ? Color.blue : Color.secondary.opacity(0.1))
                                                .foregroundColor(viewModel.selectedFilterType == type ? .white : .primary)
                                                .cornerRadius(20)
                                            }
                                        }
                                    }
                                    .padding(.horizontal)
                                }
                            }
                            .padding(.vertical, 10)
                            .background(Color(uiColor: .systemBackground))

                            Group {
                                if viewModel.isLoading && viewModel.pets.isEmpty {
                                    ProgressView("Loading Pets...")
                                } else if let error = viewModel.errorMessage, viewModel.pets.isEmpty {
                                    VStack(spacing: 16) {
                                        Image(systemName: "exclamationmark.triangle")
                                            .font(.largeTitle)
                                            .foregroundColor(.orange)
                                        Text(error)
                                        Button("Retry") { viewModel.loadPets() }
                                            .buttonStyle(.borderedProminent)
                                    }
                                } else if viewModel.filteredPets.isEmpty {
                                    VStack(spacing: 16) {
                                        Image(systemName: "heart.text.square")
                                            .font(.system(size: 80))
                                            .foregroundColor(.blue.opacity(0.5))
                                        Text(viewModel.searchText.isEmpty ? "Welcome to PetPulse" : "No results found")
                                            .font(.title2)
                                            .fontWeight(.bold)
                                        Text(viewModel.searchText.isEmpty ? "Start by adding your first companion!" : "Try a different search term")
                                            .font(.subheadline)
                                            .foregroundColor(.secondary)
                                        if viewModel.searchText.isEmpty {
                                            Button("Add a Pet") { showingAddPet = true }
                                                .buttonStyle(.borderedProminent)
                                                .controlSize(.large)
                                        }
                                    }
                                    .frame(maxHeight: .infinity)
                                } else {
                                    List {
                                        ForEach(viewModel.filteredPets) { pet in
                                            NavigationLink(destination: PetDetailView(pet: pet, viewModel: viewModel)) {
                                                PetCardView(pet: pet)
                                            }
                                            .listRowSeparator(.hidden)
                                            .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                                        }
                                        .onDelete(perform: viewModel.deletePet)
                                    }
                                    .listStyle(.plain)
                                }
                            }
                        }
                        .navigationTitle("PetPulse 🐾")
                        .toolbar {
                            ToolbarItem(placement: .navigationBarTrailing) {
                                Button(action: { showingAddPet = true }) {
                                    Image(systemName: "plus.circle.fill")
                                        .font(.title3)
                                }
                            }
                            ToolbarItem(placement: .navigationBarLeading) {
                                Button(action: { viewModel.loadPets() }) {
                                    Image(systemName: "arrow.clockwise")
                                }
                            }
                        }
                    }
                    .tabItem {
                        Label("Pets", systemImage: "pawprint.fill")
                    }
                    
                    
                    MapView()
                        .tabItem {
                            Label("Maps", systemImage: "map.fill")
                        }
                    
                    
                    ProfileView(viewModel: viewModel)
                        .tabItem {
                            Label("Profile", systemImage: "person.fill")
                        }
                }
            }
        }
        .sheet(isPresented: $showingAddPet) {
            NavigationView {
                Form {
                    Section("Pet Info") {
                        TextField("Name", text: $newPetName)
                        Picker("Type", selection: $selectedType) {
                            ForEach(PetType.allCases, id: \.self) { type in
                                Text("\(type.icon) \(type.rawValue)").tag(type)
                            }
                        }
                        DatePicker("Birth Date", selection: $newPetBirthDate, in: ...Date(), displayedComponents: .date)
                    }
                }
                .navigationTitle("New Pet")
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Cancel") { showingAddPet = false }
                    }
                    ToolbarItem(placement: .confirmationAction) {
                        Button("Add") {
                            viewModel.addPet(name: newPetName, type: selectedType, birthDate: newPetBirthDate)
                            newPetName = ""
                            showingAddPet = false
                        }
                        .disabled(newPetName.isEmpty)
                    }
                }
            }
        }
    }
}

