//
//  MapViewUI.swift
//  RouteMapTest
//
//  Created by Chris Sanders on 10/26/20.
//

import SwiftUI
import MapKit
import SwiftyJSON


/// Gets an array of coordinate lists and color for each route
/// - Parameter route: string which represents the train route
/// - Returns: a tuple including the array of coordinate lists and  the route color
func getCoordinates(for route: String) -> (coordinates: [[CLLocationCoordinate2D]], color: Color) {
  // initial variables
  var coordinates = [[CLLocationCoordinate2D]]()
  let stationData: Data
  let routeMapData: Data
  let color: Color
  
  // get the station-data file
  guard let stationFile = Bundle.main.url(forResource: "station-data", withExtension: "json") else {
    fatalError("Couldn't find station-data.json in main bundle.")
  }
  
  // get the route-map-data file
  guard let routeMapFile = Bundle.main.url(forResource: "route-map-data", withExtension: "json") else {
    fatalError("Couldn't find route-map-data.json in main bundle.")
  }
  
  
  do {
    // get the data from the station-data and route-map-data JSON files
    stationData = try Data(contentsOf: stationFile)
    routeMapData = try Data(contentsOf: routeMapFile)
  } catch {
    fatalError("Couldn't load station-data and route-map-data from main bundle:\n\(error)")
  }
  
  
  do {
    // convert the stationData nd routeMapData to JSON using SwiftyJSON
    let stationJSON = try JSON(data: stationData)
    let routeMapJSON = try JSON(data: routeMapData)
    
    // get route color
    color = Color.createColor(from: routeMapJSON["routes"][route]["color"].stringValue)
    
    // get route map list; this is an array of routes;
    // each route in the routeList is an array of strings representing the stations
    let routeList = routeMapJSON["routes"][route]["routings"]["south"].arrayValue.map {
      $0.arrayValue.map { String($0.stringValue.dropLast()) }
    }
    
    // for each route in the routeList
    for routeElement in routeList {
      var routeCoordinates = [CLLocationCoordinate2D]()
      
      // for each station in the route
      for (index, element) in routeElement.enumerated() {
        var coords = [CLLocationCoordinate2D]()
        let currentStation = stationJSON[element]
        let currentStationSouth = currentStation["south"]
        let stationLatitude = currentStation["latitude"].doubleValue
        let stationLongitude = currentStation["longitude"].doubleValue
        let initialCoordinate = CLLocationCoordinate2D(latitude: stationLatitude, longitude: stationLongitude)
        coords.append(initialCoordinate)
        
        let nextIndex = index + 1
        if nextIndex < routeElement.count {
          if !currentStationSouth.isEmpty {
            let southCoordinates = currentStationSouth[routeElement[nextIndex]].arrayValue.map {
              CLLocationCoordinate2D(latitude: $0[1].doubleValue, longitude: $0[0].doubleValue)
            }

            coords = coords + southCoordinates
          }
        }
        routeCoordinates = routeCoordinates + coords
      }
      coordinates.append(routeCoordinates)
    }

  } catch {
    fatalError("Couldn't convert data to JSON.\n\(error)")
  }

  return (coordinates, color)
}


//static let route =  {
//  let routeMapData: Data
//  guard let routeMapFile = Bundle.main.url(forResource: "route-map-data", withExtension: "json") else {
//    fatalError("Couldn't find route-map-data.json in main bundle.")
//  }
//
//  do {
//    routeMapData = try Data(contentsOf: routeMapFile)
//    let routeMapJSON = try JSON(data: routeMapData)
//    let routes = routeMapJSON["routes"].dictionaryValue.keys
//
//  } catch {
//    fatalError("Couldn't load station-data and route-map-data from main bundle:\n\(error)")
//  }
//  getCoordinates(for: "D")
//}


struct MapViewUI: UIViewRepresentable {
  
  let mapViewType: MKMapType = .standard
  static let route = getCoordinates(for: "A")
  
  func makeUIView(context: Context) -> MKMapView {
    let polylines = MapViewUI.route.coordinates.map { MKPolyline(coordinates: $0, count: $0.count) }
    let coordinate = CLLocationCoordinate2D(latitude: 40.730610, longitude: -73.935242)
    let span = MKCoordinateSpan(latitudeDelta: 0.10, longitudeDelta: 0.10)
    let region = MKCoordinateRegion(center: coordinate, span: span)
    let mapView = MKMapView()
    mapView.setRegion(region, animated: true)
    mapView.mapType = mapViewType
    mapView.addOverlays(polylines)
    mapView.delegate = context.coordinator
    
    return mapView
  }
  
  func updateUIView(_ mapView: MKMapView, context: Context) {
    mapView.mapType = mapViewType
  }
  
  func makeCoordinator() -> MapCoordinator {
    .init()
  }
  
  final class MapCoordinator: NSObject, MKMapViewDelegate {
    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
      if overlay is MKPolyline {
        let renderer = MKPolylineRenderer(overlay: overlay)
        renderer.strokeColor = UIColor(MapViewUI.route.color)
        renderer.lineCap = .round
        renderer.lineWidth = 2.0
        return renderer
      }
      return MKOverlayRenderer(overlay: overlay)
    }
  }
}
