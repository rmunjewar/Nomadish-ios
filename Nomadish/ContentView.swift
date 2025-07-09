//
//  ContentView.swift
//  Nomadish
//
//  Created by Riddhi Munjewar on 5/26/25.
//

import SwiftUI
import MapKit

struct ContentView: View {
    
    // defining the map region
    @State private var position = MapCameraPosition.region(
        MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194), // defining where
            span: MKCoordinateSpan(latitudeDelta: 0.07, longitudeDelta: 0.07) // defining how zoomed in
        )
    )
    
    @State private var searchText = ""
    
    var body: some View {
        VStack {
            
            HStack {
                TextField("Have a place in mind?", text: $searchText)
                    .padding(12)
                    .background(Color(.systemGray6))
                    .cornerRadius(10)
                
                Button(action: {
                    searchForLocation()
                }) {
                    Image(systemName: "magnifyingglass")
                        .padding()
                }
            }
            .padding()
            
            // display the map
            Map(position: $position) {}
            .ignoresSafeArea() // fills the entire screen
        }
    }
    
    func searchForLocation() {
        let request = MKLocalSearch.Request()
        request.naturalLanguageQuery = searchText
        
        let search = MKLocalSearch(request: request)
        // search is seidng a request to apple's servers, and runs block when finished
        search.start { response, error in // gblock ives response and error
            guard let coordinate =
                    // response might be nil so ? to access safely
                    // .mapItems.first gets first search result
                    // .placemark.coordinate gets actual location
                    // guard let ... else is if any part is missing, exit early (need this value to exist else can't continue
                    
                    response?.mapItems.first?.placemark.coordinate else {
                print("No results found.")
                return
            }
            
            withAnimation {
                position = .region(MKCoordinateRegion(center: coordinate, span: MKCoordinateSpan(latitudeDelta: 0.7, longitudeDelta: 0.7)))
            }
        }
    }
}

#Preview {
    ContentView()
}

