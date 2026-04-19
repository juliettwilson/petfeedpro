import SwiftUI

struct PetCardView: View {
    let pet: Pet
    
    var body: some View {
        HStack(spacing: 16) {
            Text(pet.petType.icon)
                .font(.system(size: 40))
                .padding(12)
                .background(Circle().fill(Color.secondary.opacity(0.1)))
            
            VStack(alignment: .leading, spacing: 4) {
                Text(pet.name)
                    .font(.headline)
                    .fontWeight(.bold)
                Text(pet.type)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                Text(pet.ageString)
                    .font(.caption2)
                    .foregroundColor(.blue)
            }
            
            Spacer()
            
            VStack(alignment: .trailing) {
                Circle()
                    .fill(pet.is_fed ? Color.green : Color.red)
                    .frame(width: 12, height: 12)
                
                Text(pet.is_fed ? "Fed" : "Hungry")
                    .font(.caption)
                    .foregroundColor(pet.is_fed ? .green : .red)
                    .fontWeight(.semibold)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(uiColor: .systemBackground))
                .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
        )
    }
}

struct PetStatsView: View {
    let pet: Pet
    
    var body: some View {
        VStack(spacing: 12) {
            Text("Feeding Progress")
                .font(.headline)
            
            ZStack {
                Circle()
                    .stroke(Color.secondary.opacity(0.2), lineWidth: 10)
                Circle()
                    .trim(from: 0, to: CGFloat(pet.feedingRatio))
                    .stroke(
                        AngularGradient(gradient: Gradient(colors: [.green, .blue]), center: .center),
                        style: StrokeStyle(lineWidth: 10, lineCap: .round)
                    )
                    .rotationEffect(.degrees(-90))
                
                VStack {
                    Text("\(Int(pet.feedingRatio * 100))%")
                        .font(.title)
                        .fontWeight(.bold)
                    Text("of daily goal")
                        .font(.caption)
                }
            }
            .frame(width: 150, height: 150)
            
            HStack {
                VStack {
                    Text("\(pet.feeding_history.count)")
                        .font(.title2)
                        .fontWeight(.bold)
                    Text("Total Feeds")
                        .font(.caption)
                }
                .frame(maxWidth: .infinity)
                
                Divider()
                
                VStack {
                    Text(pet.petType.icon)
                        .font(.title2)
                    Text("Type")
                        .font(.caption)
                }
                .frame(maxWidth: .infinity)
            }
            .padding()
            .background(RoundedRectangle(cornerRadius: 12).fill(Color.secondary.opacity(0.1)))
        }
        .padding()
    }
}

struct PetDetailView: View {
    let pet: Pet
    @ObservedObject var viewModel: PetViewModel
    
    @State private var showingEditSheet = false
    @State private var editName = ""
    @State private var editType: PetType = .dog
    @State private var editBirthDate = Date()
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                PetStatsView(pet: pet)
                
                HStack {
                    Image(systemName: "calendar")
                    Text("Age: \(pet.ageString)")
                        .fontWeight(.semibold)
                    Spacer()
                }
                .padding(.horizontal)
                .foregroundColor(.secondary)
                
                Button(action: { viewModel.feedPet(pet: pet) }) {
                    Label("Feed Now", systemImage: "fork.knife")
                        .font(.headline)
                        .foregroundColor(.white)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.blue)
                        .cornerRadius(12)
                }
                .padding(.horizontal)
                
                VStack(alignment: .leading) {
                    Text("Feeding History")
                        .font(.headline)
                        .padding(.horizontal)
                    
                    if pet.feeding_history.isEmpty {
                        Text("No meals recorded yet.")
                            .foregroundColor(.secondary)
                            .padding()
                    } else {
                        ForEach(pet.feeding_history.reversed()) { log in
                            HStack {
                                Image(systemName: "clock")
                                Text(log.timestamp, style: .time)
                                Spacer()
                                Text(log.amount)
                                    .fontWeight(.bold)
                            }
                            .padding()
                            .background(RoundedRectangle(cornerRadius: 8).fill(Color.secondary.opacity(0.05)))
                            .padding(.horizontal)
                        }
                    }
                }
            }
        }
        .navigationTitle(pet.name)
        .toolbar {
            Button("Edit") {
                editName = pet.name
                editType = PetType(rawValue: pet.type) ?? .dog
                editBirthDate = pet.birth_date ?? Date()
                showingEditSheet = true
            }
        }
        .sheet(isPresented: $showingEditSheet) {
            NavigationView {
                Form {
                    Section("Update Infomation") {
                        TextField("Pet Name", text: $editName)
                        Picker("Type", selection: $editType) {
                            ForEach(PetType.allCases, id: \.self) { type in
                                Text("\(type.icon) \(type.rawValue)").tag(type)
                            }
                        }
                        DatePicker("Birth Date", selection: $editBirthDate, displayedComponents: .date)
                    }
                }
                .navigationTitle("Edit Pet")
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Cancel") { showingEditSheet = false }
                    }
                    ToolbarItem(placement: .confirmationAction) {
                        Button("Save") {
                            viewModel.editPet(pet: pet, newName: editName, newType: editType, newBirthDate: editBirthDate)
                            showingEditSheet = false
                        }
                        .disabled(editName.isEmpty)
                    }
                }
            }
        }
    }
}
