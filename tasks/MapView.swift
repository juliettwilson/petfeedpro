import SwiftUI
import MapKit

struct MapLocation: Identifiable {
    let id = UUID()
    let name: String
    let coordinate: CLLocationCoordinate2D
    let type: String
}

struct MapView: View {
    
    @State private var region = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 43.2389, longitude: 76.8897), // Almaty center
        span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
    )
    
    let locations = [
        MapLocation(name: "Happy Paws Vet", coordinate: CLLocationCoordinate2D(latitude: 43.245, longitude: 76.905), type: "Vet"),
        MapLocation(name: "PetWorld Shop", coordinate: CLLocationCoordinate2D(latitude: 43.235, longitude: 76.875), type: "Shop"),
        MapLocation(name: "Animal Health Care", coordinate: CLLocationCoordinate2D(latitude: 43.255, longitude: 76.895), type: "Vet"),
        MapLocation(name: "ZooMarket", coordinate: CLLocationCoordinate2D(latitude: 43.225, longitude: 76.915), type: "Shop")
    ]
    
    var body: some View {
        NavigationView {
            Map(coordinateRegion: $region, annotationItems: locations) { location in
                MapAnnotation(coordinate: location.coordinate) {
                    VStack {
                        Image(systemName: location.type == "Vet" ? "cross.case.fill" : "cart.fill")
                            .resizable()
                            .frame(width: 25, height: 25)
                            .foregroundColor(location.type == "Vet" ? .red : .blue)
                            .padding(8)
                            .background(Circle().fill(Color.white))
                            .shadow(radius: 4)
                        
                        Text(location.name)
                            .font(.caption)
                            .fontWeight(.bold)
                            .padding(4)
                            .background(RoundedRectangle(cornerRadius: 4).fill(Color.white.opacity(0.8)))
                    }
                }
            }
            .navigationTitle("Nearby Vets & Shops")
            .ignoresSafeArea(edges: .bottom)
        }
    }
}
