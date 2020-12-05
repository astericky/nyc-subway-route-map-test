//
//  MapViewUI.swift
//  RouteMapTest
//
//  Created by Chris Sanders on 10/26/20.
//

import SwiftUI
import MapKit
import SwiftyJSON

enum ColorString: String {
  case blue = "#2185d0"
  case green = "#21ba45"
  case red = "#db2828"
  case yellow = "#fbbd08"
  case orange = "#f2711c"
  case purple = "#a333c8"
  case lightGreen = "#b5cc18"
  case darkGray = "#767676"
  case lightGray = "#A0A0A0"
  case brown = "#a5673f"
}

class BluePolyline: MKPolyline { static let color = Color.createColor(from: ColorString.blue.rawValue) }
class GreenPolyline: MKPolyline { static let color = Color.createColor(from: ColorString.green.rawValue) }
class RedPolyline: MKPolyline { static let color = Color.createColor(from: ColorString.red.rawValue) }
class YellowPolyline: MKPolyline { static let color = Color.createColor(from: ColorString.yellow.rawValue) }
class OrangePolyline: MKPolyline { static let color = Color.createColor(from: ColorString.orange.rawValue) }
class PurplePolyline: MKPolyline { static let color = Color.createColor(from: ColorString.purple.rawValue) }
class LightGreenPolyline: MKPolyline { static let color = Color.createColor(from: ColorString.lightGreen.rawValue) }
class DarkGrayPolyline: MKPolyline { static let color = Color.createColor(from: ColorString.darkGray.rawValue) }
class LightGrayPolyline: MKPolyline { static let color = Color.createColor(from: ColorString.lightGray.rawValue) }
class BrownPolyline: MKPolyline { static let color = Color.createColor(from: ColorString.brown.rawValue) }


struct RouteCoordinates {
  var coordinates: [[CLLocationCoordinate2D]]
  var color: Color
}

/// Gets an array of coordinate lists and color for each route
/// - Parameter route: string which represents the train route
/// - Returns: a tuple including the array of coordinate lists and  the route color
func getCoordinates(for route: String) -> RouteCoordinates {
  // initial variables
  var coordinates = [[CLLocationCoordinate2D]]()
  let stationData: Data
  let routeMapData: Data
  let color: Color
  let colorString: String
  
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
    colorString = routeMapJSON["routes"][route]["color"].stringValue
    color = Color.createColor(from: colorString)
    
    // get route map list; this is an array of routes;
    // each route in the routeList is an array of strings representing the stations
    var routeList = routeMapJSON["routes"][route]["routings"]["south"].arrayValue.map {
      $0.arrayValue.map { String($0.stringValue.dropLast()) }
    }
//    print(routeList)
//    print("-----------------------")
    // fill in station gaps if they exist
    for routeElement in routeList {
        var routeElementList = routeElement
        for (index, element) in routeElement.enumerated() {
            var nextRouteElementIndex = index + 1
            if nextRouteElementIndex < routeElement.count {
                let nextRouteElement = routeElement[nextRouteElementIndex]

                let currentStation = stationJSON[element]
                let nextStation = currentStation["south"][nextRouteElement]

                if !nextStation.exists() {
                    let hasNewStation = !currentStation["south"].arrayValue.isEmpty
                    if (hasNewStation) {
                        let newStation = currentStation["south"].arrayValue[0].stringValue
                        repeat {
                            routeElementList.insert(newStation, at: nextRouteElementIndex)
                            nextRouteElementIndex = nextRouteElementIndex + 1
                        } while (newStation != nextRouteElement)
                    }

                }
            }
        }
    }
    
    print(routeList)
    
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

  return RouteCoordinates(coordinates: coordinates, color: color)
}


func getAllRouteCoordinates() -> [RouteCoordinates]  {
  var routeCoordinates = [RouteCoordinates]()
  let routeMapData: Data
  guard let routeMapFile = Bundle.main.url(forResource: "route-map-data", withExtension: "json") else {
    fatalError("Couldn't find route-map-data.json in main bundle.")
  }

  do {
    routeMapData = try Data(contentsOf: routeMapFile)
    let routeMapJSON = try JSON(data: routeMapData)
    let routes = routeMapJSON["routes"].dictionaryValue.keys
    
    for route in routes {
      routeCoordinates.append(getCoordinates(for: route))
    }
  } catch {
    fatalError("Couldn't load station-data and route-map-data from main bundle:\n\(error)")
  }
  
  return routeCoordinates
}



struct MapViewUI: UIViewRepresentable {
  
  let mapViewType: MKMapType = .standard
  static let route = getCoordinates(for: "E")
  
  func makeUIView(context: Context) -> MKMapView {

//    let polylinesList = getAllRouteCoordinates().map { polylineListItem -> [MKPolyline] in
//      polylineListItem.coordinates.map { coordinates -> MKPolyline in
//        switch polylineListItem.color {
//        case BluePolyline.color:
//          return BluePolyline(coordinates: coordinates, count: coordinates.count)
//        case GreenPolyline.color:
//          return GreenPolyline(coordinates: coordinates, count: coordinates.count)
//        case RedPolyline.color:
//          return RedPolyline(coordinates: coordinates, count: coordinates.count)
//        case YellowPolyline.color:
//          return YellowPolyline(coordinates: coordinates, count: coordinates.count)
//        case OrangePolyline.color:
//          return OrangePolyline(coordinates: coordinates, count: coordinates.count)
//        case LightGreenPolyline.color:
//          return LightGreenPolyline(coordinates: coordinates, count: coordinates.count)
//        case LightGrayPolyline.color:
//          return LightGrayPolyline(coordinates: coordinates, count: coordinates.count)
//        case DarkGrayPolyline.color:
//          return DarkGrayPolyline(coordinates: coordinates, count: coordinates.count)
//        case BrownPolyline.color:
//          return BrownPolyline(coordinates: coordinates, count: coordinates.count)
//        default:
//          return MKPolyline(coordinates: coordinates, count: coordinates.count)
//        }
//      }
//    }
    
    var polylines = MapViewUI.route.coordinates.map { BluePolyline(coordinates: $0, count: $0.count) }

    let coordinate = CLLocationCoordinate2D(latitude: 40.730610, longitude: -73.935242)
    let span = MKCoordinateSpan(latitudeDelta: 0.50, longitudeDelta: 0.50)
    let region = MKCoordinateRegion(center: coordinate, span: span)
    let mapView = MKMapView()
    mapView.setRegion(region, animated: true)
    mapView.mapType = mapViewType
//    for polylinesItem in polylinesList {
//      mapView.addOverlays(polylinesItem)
//    }
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
        renderer.lineCap = .round
        renderer.lineWidth = 2.0
        
        if overlay is BluePolyline {
          renderer.strokeColor = UIColor(BluePolyline.color)
          return renderer
        }
        
        if overlay is RedPolyline {
          renderer.strokeColor = UIColor(RedPolyline.color)
          return renderer
        }
        
        if overlay is GreenPolyline {
          renderer.strokeColor = UIColor(GreenPolyline.color)
          return renderer
        }
        
        if overlay is YellowPolyline {
          renderer.strokeColor = UIColor(YellowPolyline.color)
          return renderer
        }
        
        if overlay is OrangePolyline {
          renderer.strokeColor = UIColor(OrangePolyline.color)
          return renderer
        }
        
        if overlay is PurplePolyline {
          renderer.strokeColor = UIColor(PurplePolyline.color)
          return renderer
        }
        
        if overlay is LightGreenPolyline {
          renderer.strokeColor = UIColor(LightGreenPolyline.color)
          return renderer
        }
        
        if overlay is LightGrayPolyline {
          renderer.strokeColor = UIColor(LightGrayPolyline.color)
          return renderer
        }
        
        if overlay is DarkGrayPolyline {
          renderer.strokeColor = UIColor(DarkGrayPolyline.color)
          return renderer
        }
        
        if overlay is BrownPolyline {
          renderer.strokeColor = UIColor(BrownPolyline.color)
          return renderer
        }
      }
      
      return MKOverlayRenderer(overlay: overlay)
    }
  }
}
