//
//  RouteMapView.swift
//  RunDiary
//
//  Created by 김혜지 on 12/5/25.
//

import MapKit
import SwiftUI

struct RouteMapView: View {
    let coordinates: [CLLocationCoordinate2D]

    private var region: MKCoordinateRegion {
        guard !coordinates.isEmpty else {
            return MKCoordinateRegion(
                center: CLLocationCoordinate2D(latitude: 37.5665, longitude: 126.9780),
                span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
            )
        }

        let latitudes = coordinates.map(\.latitude)
        let longitudes = coordinates.map(\.longitude)

        let minLat = latitudes.min()!
        let maxLat = latitudes.max()!
        let minLon = longitudes.min()!
        let maxLon = longitudes.max()!

        let center = CLLocationCoordinate2D(
            latitude: (minLat + maxLat) / 2,
            longitude: (minLon + maxLon) / 2
        )

        let span = MKCoordinateSpan(
            latitudeDelta: max((maxLat - minLat) * 1.3, 0.005),
            longitudeDelta: max((maxLon - minLon) * 1.3, 0.005)
        )

        return MKCoordinateRegion(center: center, span: span)
    }

    var body: some View {
        Map(initialPosition: .region(region)) {
            MapPolyline(coordinates: coordinates)
                .stroke(.blue, lineWidth: 3)
        }
        .mapStyle(.standard)
        .allowsHitTesting(false)
    }
}
