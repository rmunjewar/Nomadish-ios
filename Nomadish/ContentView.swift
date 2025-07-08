//
//  ContentView.swift
//  Nomadish
//
//  Created by Riddhi Munjewar on 5/26/25.
//
import SwiftUI
import MapKit

struct ContentView: View {
    @State private var position = MapCameraPosition.region(
        MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194),
            span: MKCoordinateSpan(latitudeDelta: 0.1, longitudeDelta: 0.1)
        )
    )
    
    @State private var searchText = ""
    
    var body: some View {
        VStack(spacing: 0) {
            // Search bar
            HStack {
                TextField("Search for a place...", text: $searchText, onCommit: search)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .padding()
            }
            .background(Color(.systemBackground).opacity(0.9))
            .zIndex(1) // Keep search bar above map

            // Map
            Map(position: $position) {
                UserAnnotation()
            }
            .edgesIgnoringSafeArea(.all)
        }
    }
    
    // Function to perform location search
    func search() {
        let request = MKLocalSearch.Request()
        request.naturalLanguageQuery = searchText
        
        let search = MKLocalSearch(request: request)
        search.start { response, error in
            guard let coordinate = response?.mapItems.first?.placemark.coordinate else {
                print("Location not found")
                return
            }
            
            // Update the map position
            withAnimation {
                position = .region(MKCoordinateRegion(
                    center: coordinate,
                    span: MKCoordinateSpan(latitudeDelta: 0.1, longitudeDelta: 0.1)
                ))
            }
        }
    }
}


#Preview {
    ContentView()
}
