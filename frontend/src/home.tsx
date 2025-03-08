import React, { useState, useEffect } from 'react';
import { Bus, Search, AlertCircle, Plus, Navigation, ArrowRight, Clock, MapPin, Map as MapIcon } from 'lucide-react';
import axios from 'axios';
import { GoogleMap, LoadScript, Polyline, useLoadScript, Marker, InfoWindow } from '@react-google-maps/api';
import './Chat';

import { useNavigate } from 'react-router-dom';

// Original interfaces
interface Station {
  station: string;
  arrivalTime: string;
  departureTime: string;
}

interface Trip {
  trip: number;
  stations: Station[];
}

interface BusSchedule {
  "Vehicle Number": string;
  route: string[];
  schedule: Trip[];
}

interface Waypoint {
  vehicle_number: string;
  trip: number;
  stations: Station[];
}

interface BusRoute {
  type: string;
  firstLeg: string;
  secondLeg: string;
  waypoint: Waypoint[];
}

interface IndirectRoute {
  availableRoute: BusSchedule;
  endStation: string;
  remainingDistance: string;
}

interface NearestStation {
  station: string;
  distance: number;
}

// Google Maps API related interfaces
interface TransitDetails {
  line: {
    name?: string;
    short_name?: string;
    agencies?: any[];
    vehicle?: {
      name?: string;
      type?: string;
    };
  };
  vehicle: string;
  departure_stop: {
    name: string;
    location: {
      lat: number;
      lng: number;
    };
  };
  arrival_stop: {
    name: string;
    location: {
      lat: number;
      lng: number;
    };
  };
  operator?: string;
  vehicle_type?: string;
  departure_time?: string;
  arrival_time?: string;
  fare?: string;
}

interface RouteStep {
  travel_mode: string;
  instruction: string;
  distance: { text: string };
  duration: { text: string };
  transit_details: TransitDetails | null;
}

interface RouteLeg {
  steps: RouteStep[];
  start_address?: string;
  end_address?: string;
}

interface GoogleRoute {
  legs: RouteLeg[];
  summary?: string;
  overview_polyline?: { points: string };
  mode?: string;
  total_distance?: string;
  total_duration?: string;
}

interface GoogleRouteResponse {
  routes: GoogleRoute[];
}

// Added for map display
interface MapOptions {
  center: {
    lat: number;
    lng: number;
  };
  zoom: number;
}

const libraries: ("geometry" | "drawing" | "places" | "visualization")[] = ["geometry"];

const Navbar = () => (

  <nav className="bg-white shadow-sm">
    <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
      <div className="flex justify-between h-16">
        <div className="flex items-center">
          <Bus className="text-blue-600" size={32} />
          <span className="ml-2 text-xl font-bold text-gray-900"> Route Finder</span>
        </div>
        <div className="flex items-center gap-4">
          <a href="#features" className="text-gray-600 hover:text-blue-600">Features</a>
          <a href="#routes" className="text-gray-600 hover:text-blue-600">Routes</a>
          <a href="#contact" className="text-gray-600 hover:text-blue-600">Contact</a>
            <button className="bg-blue-600 text-white px-4 py-2 rounded-lg hover:bg-blue-700 transition duration-300"  >Login</button>
                
        </div>
      </div>
    </div>
  </nav>
);

const Hero = () => (
  <div className="bg-gradient-to-r from-blue-600 to-blue-800 text-white py-16">
    <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
      <div className="text-center">
        <h1 className="text-4xl font-extrabold sm:text-5xl md:text-6xl">
          Find Your Bus Route
        </h1>
        <p className="mt-3 max-w-md mx-auto text-base sm:text-lg md:mt-5 md:text-xl">
          Plan your journey with real-time bus routes, schedules, and live tracking
        </p>
      </div>
    </div>
  </div>
);

const Features = () => (
  <section id="features" className="py-16 bg-gray-50">
    <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
      <h2 className="text-3xl font-bold text-center text-gray-900 mb-12">Features</h2>
      <div className="grid grid-cols-1 md:grid-cols-3 gap-8">
        <FeatureCard 
          icon={<MapIcon size={24} />}
          title="Real-time Tracking"
          description="Track your bus location in real-time with live updates"
        />
        <FeatureCard 
          icon={<Clock size={24} />}
          title="Schedule Updates"
          description="Get accurate arrival and departure times for all routes"
        />
        <FeatureCard 
          icon={<Navigation size={24} />}
          title="Route Planning"
          description="Find the best route with multiple options and fare details"
        />
      </div>
    </div>
  </section>
);

const FeatureCard = ({ icon, title, description }: { icon: React.ReactNode, title: string, description: string }) => (
  <div className="bg-white p-6 rounded-lg shadow-sm">
    <div className="w-12 h-12 rounded-full bg-blue-100 flex items-center justify-center text-blue-600 mb-4">
      {icon}
    </div>
    <h3 className="text-xl font-semibold text-gray-900 mb-2">{title}</h3>
    <p className="text-gray-600">{description}</p>
  </div>
);

const Footer = () => (
  <footer className="bg-gray-900 text-white py-12">
    <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
      <div className="grid grid-cols-1 md:grid-cols-4 gap-8">
        <div>
          <h3 className="text-lg font-semibold mb-4">About</h3>
          <p className="text-gray-400">Route Finder helps you plan your bus journey across Kerala with ease.</p>
        </div>
        <div>
          <h3 className="text-lg font-semibold mb-4">Quick Links</h3>
          <ul className="space-y-2 text-gray-400">
            <li><a href="#routes">Find Routes</a></li>
            <li><a href="#features">Features</a></li>
            <li><a href="#contact">Contact</a></li>
          </ul>
        </div>
        <div>
          <h3 className="text-lg font-semibold mb-4">Contact</h3>
          <ul className="space-y-2 text-gray-400">
            <li>Email: support@ksrtc.com</li>
            <li>Phone: 1800-425-1111</li>
          </ul>
        </div>
        <div>
          <h3 className="text-lg font-semibold mb-4">Follow Us</h3>
          <div className="flex space-x-4">
            {/* Add social media icons here */}
          </div>
        </div>
      </div>
      <div className="mt-8 pt-8 border-t border-gray-800 text-center text-gray-400">
        <p>&copy; 2024 KSRTC Route Finder. All rights reserved.</p>
      </div>
    </div>
  </footer>
);

const BusScheduleDisplay: React.FC<{ schedule: BusSchedule }> = ({ schedule }) => {
  return (
    <div className="bg-white rounded-lg shadow-sm p-6 mb-6">
      <div className="flex items-center gap-2 mb-4">
        <Bus className="text-blue-600" size={20} />
        <h2 className="text-xl font-bold">Bus Schedule: {schedule["Vehicle Number"]}</h2>
      </div>
      
      <div className="mb-6">
        <h3 className="text-sm font-medium text-gray-600 mb-2">Route Path:</h3>
        <div className="flex flex-wrap items-center gap-2">
          {schedule.route.map((station, index) => (
            <React.Fragment key={index}>
              <span className="px-3 py-1 bg-blue-50 rounded-lg text-blue-700 font-medium">
                {station}
              </span>
              {index < schedule.route.length - 1 && (
                <ArrowRight size={16} className="text-gray-400" />
              )}
            </React.Fragment>
          ))}
        </div>
      </div>

      <div className="space-y-6">
        {schedule.schedule.map((trip, index) => (
          <div key={index} className="border rounded-lg p-4">
            <h3 className="font-semibold mb-4 text-lg text-gray-800">
              Trip {trip.trip}
            </h3>
            <div className="relative">
              {trip.stations.map((station, stIndex) => (
                <div key={stIndex} 
                     className={`flex items-start gap-4 ${
                       stIndex < trip.stations.length - 1 ? 'mb-8' : ''
                     }`}>
                  <div className="relative">
                    <div className="w-4 h-4 rounded-full bg-blue-500"></div>
                    {stIndex < trip.stations.length - 1 && (
                      <div className="absolute w-0.5 bg-gray-200 h-12 left-2 top-4 -translate-x-1/2"></div>
                    )}
                  </div>
                  <div className="flex-1 -mt-1">
                    <p className="font-medium text-gray-900">{station.station}</p>
                    <div className="mt-1 grid grid-cols-2 gap-x-4 text-sm text-gray-600">
                      <div className="flex items-center gap-1">
                        <Clock size={14} />
                        <span>Arrival: {station.arrivalTime}</span>
                      </div>
                      <div className="flex items-center gap-1">
                        <Clock size={14} />
                        <span>Departure: {station.departureTime}</span>
                      </div>
                    </div>
                  </div>
                </div>
              ))}
            </div>
          </div>
        ))}
      </div>
    </div>
  );
};

// Helper function for bus schedules search
const searchBusSchedules = (schedules: BusSchedule[], source: string, destination: string) => {
  const upperSource = source.toUpperCase();
  const upperDestination = destination.toUpperCase();
  
  return schedules.filter(schedule => {
    const stationNames = schedule.route.map(station => station.toUpperCase());
    const sourceIndex = stationNames.indexOf(upperSource);
    const destIndex = stationNames.indexOf(upperDestination);
    
    // Only return routes where source comes before destination
    return sourceIndex !== -1 && destIndex !== -1 && sourceIndex < destIndex;
  });
};

// Helper function for partial routes
const findPartialRoutes = (schedules: BusSchedule[], source: string, destination: string): IndirectRoute[] => {
  const upperSource = source.toUpperCase();
  const upperDestination = destination.toUpperCase();
  
  return schedules
    .filter(schedule => {
      const stationNames = schedule.route.map(station => station.toUpperCase());
      const sourceIndex = stationNames.indexOf(upperSource);
      return sourceIndex !== -1;
    })
    .map(schedule => {
      // Find the last reachable station in the route
      const stationNames = schedule.route.map(station => station.toUpperCase());
      const sourceIndex = stationNames.indexOf(upperSource);
      const lastReachableStation = schedule.route[schedule.route.length - 1];
      
      return {
        availableRoute: schedule,
        endStation: lastReachableStation,
        remainingDistance: `${lastReachableStation} to ${destination}`
      };
    });
};

// Helper function to get travel mode icon
const getTravelModeIcon = (mode: string) => {
  switch(mode) {
    case 'WALKING':
      return <Navigation size={16} className="text-green-600" />;
    case 'TRANSIT':
      return <Bus size={16} className="text-blue-600" />;
    case 'DRIVING':
      return <div className="text-red-600">🚗</div>;
    default:
      return <div className="text-gray-600">•</div>;
  }
};

// Map component to display routes
const mapContainerStyle = {
  width: '100%',
  height: '500px',
};

const center = {
  lat: 10.8505, // Default center (Kerala)
  lng: 76.2711,
};

const RouteMap: React.FC<{ route: GoogleRoute }> = ({ route }) => {
  const [selectedMarker, setSelectedMarker] = useState<number | null>(null);
  const path = window.google.maps.geometry.encoding.decodePath(route.overview_polyline?.points || '');
  
  // Extract all stops from the route
  const stops = route.legs[0].steps
    .filter(step => step.transit_details)
    .map(step => ({
      departure: {
        name: step.transit_details!.departure_stop.name,
        location: step.transit_details!.departure_stop.location
      },
      arrival: {
        name: step.transit_details!.arrival_stop.name,
        location: step.transit_details!.arrival_stop.location
      }
    }));

  // Calculate map bounds to fit all markers
  const bounds = new window.google.maps.LatLngBounds();
  stops.forEach(stop => {
    bounds.extend(stop.departure.location);
    bounds.extend(stop.arrival.location);
  });

  return (
    <GoogleMap 
      mapContainerStyle={mapContainerStyle} 
      onLoad={map => map.fitBounds(bounds)}
      options={{
        mapTypeControl: false,
        streetViewControl: false,
        fullscreenControl: true,
        zoomControl: true,
      }}
    >
      {/* Route line */}
      <Polyline
        path={path}
        options={{
          strokeColor: '#4F46E5',
          strokeOpacity: 0.8,
          strokeWeight: 4,
        }}
      />

      {/* Markers for each stop */}
      {stops.map((stop, index) => (
        <React.Fragment key={index}>
          {/* Departure marker */}
          <Marker
            position={stop.departure.location}
            icon={{
              url: index === 0 ? '/start-marker.png' : '/bus-stop.png',
              scaledSize: new window.google.maps.Size(30, 30)
            }}
            onClick={() => setSelectedMarker(index * 2)}
          />
          {selectedMarker === index * 2 && (
            <InfoWindow
              position={stop.departure.location}
              onCloseClick={() => setSelectedMarker(null)}
            >
              <div className="p-2">
                <p className="font-medium">{stop.departure.name}</p>
                <p className="text-sm text-gray-600">Bus Stop</p>
              </div>
            </InfoWindow>
          )}

          {/* Arrival marker */}
          <Marker
            position={stop.arrival.location}
            icon={{
              url: index === stops.length - 1 ? '/end-marker.png' : '/bus-stop.png',
              scaledSize: new window.google.maps.Size(30, 30)
            }}
            onClick={() => setSelectedMarker(index * 2 + 1)}
          />
          {selectedMarker === index * 2 + 1 && (
            <InfoWindow
              position={stop.arrival.location}
              onCloseClick={() => setSelectedMarker(null)}
            >
              <div className="p-2">
                <p className="font-medium">{stop.arrival.name}</p>
                <p className="text-sm text-gray-600">Bus Stop</p>
              </div>
            </InfoWindow>
          )}
        </React.Fragment>
      ))}
    </GoogleMap>
  );
};

function App() {
  const [source, setSource] = useState('');
  const [destination, setDestination] = useState('');
  const [routes, setRoutes] = useState<BusRoute[]>([]);
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [showAddForm, setShowAddForm] = useState(false);
  const [vehicleNumber, setVehicleNumber] = useState('');
  const [tripRoute, setTripRoute] = useState('');
  const [time, setTime] = useState('');
  
  // Google Maps route state
  const [googleRoutes, setGoogleRoutes] = useState<GoogleRoute[]>([]);
  const [showGoogleRoutes, setShowGoogleRoutes] = useState(false);
  const [selectedGoogleRoute, setSelectedGoogleRoute] = useState<number | null>(null);
  const [showMap, setShowMap] = useState(false);

  const { isLoaded, loadError } = useLoadScript({
    googleMapsApiKey:'AIzaSyAzRiCqyt3irzVZr1n2W-hf4EMrFpGgdss',
    libraries, // Use the constant libraries array
  });

  const [isLoggedIn, setIsLoggedIn] = useState(false);
  const [currentUser, setCurrentUser] = useState(null);

  const handleLogin = (user: any) => {
    setIsLoggedIn(true);
    setCurrentUser(user);
  };

  // Handle bus schedule search
  const handleSearch = async (e: React.FormEvent) => {
    e.preventDefault();
    setLoading(true);
    setError(null);
    setRoutes([]);
    setGoogleRoutes([]);
    setShowGoogleRoutes(false);
    setSelectedGoogleRoute(null);
    setShowMap(false);

    try {
      if (!source.trim() || !destination.trim()) {
        throw new Error('Please enter both source and destination locations');
      }

      // Update the JSON file path and add error handling for the fetch
      const response = await fetch('/dataset_default/json_processed/combined_bus_schedules.json');
      if (!response.ok) {
        throw new Error(`Failed to load bus schedules: ${response.statusText}`);
      }

      let schedules: BusSchedule[];
      try {
        schedules = await response.json();
      } catch (jsonError) {
        console.error('JSON Parse Error:', jsonError);
        throw new Error('Failed to parse bus schedule data');
      }

      // Validate the data structure
      if (!Array.isArray(schedules)) {
        throw new Error('Invalid bus schedule data format');
      }

      // First try direct routes
      const directRoutes = searchBusSchedules(schedules, source.trim(), destination.trim());

      if (directRoutes.length > 0) {
        const routesData: BusRoute[] = directRoutes.map(schedule => ({
          type: 'direct',
          firstLeg: schedule.route[0],
          secondLeg: schedule.route[schedule.route.length - 1],
          waypoint: schedule.schedule.map(trip => ({
            vehicle_number: schedule["Vehicle Number"],
            trip: trip.trip,
            stations: trip.stations
          }))
        }));
        setRoutes(routesData);
        return;
      }

      // If no direct routes, find partial routes
      const partialRoutes = findPartialRoutes(schedules, source.trim(), destination.trim());

      if (partialRoutes.length > 0) {
        const routesData: BusRoute[] = partialRoutes.map(partial => ({
          type: 'partial',
          firstLeg: partial.availableRoute.route[0],
          secondLeg: partial.endStation,
          waypoint: partial.availableRoute.schedule.map(trip => ({
            vehicle_number: partial.availableRoute["Vehicle Number"],
            trip: trip.trip,
            stations: trip.stations
          }))
        }));
        setRoutes(routesData);
        setError(`Note: Direct bus route not available to ${destination}. 
          Showing routes to nearest stations. You may need alternative transport for the remaining journey.`);
        return;
      }

      throw new Error(`No bus routes found from ${source}. Consider alternative transport options.`);

    } catch (err) {
      const errorMessage = err instanceof Error ? err.message : 'An unexpected error occurred';
      console.error('Bus Route Finder Error:', {
        error: err,
        source,
        destination,
        timestamp: new Date().toISOString(),
        errorMessage
      });
      setError(errorMessage);
    } finally {
      setLoading(false);
    }
  };

  // New function to fetch Google Routes
  const fetchGoogleRoutes = async () => {
    setLoading(true);
    setError(null);
    setShowMap(false);
    
    try {
      if (!source.trim() || !destination.trim()) {
        throw new Error('Please enter both source and destination locations');
      }
      
      // Fetch KSRTC specific routes
      const response = await axios.post('http://localhost:5000/get-routes', {
        start: source.trim(),
        end: destination.trim(),
        mode: 'transit',
        transit_mode: 'bus',
        transit_routing_preference: 'less_walking',
        alternatives: true,
        operator: 'KSRTC' // Add operator filter
      });
      
      if (response.data.error) {
        throw new Error(response.data.error);
      }
      
      // Filter and format KSRTC bus routes
      const formattedRoutes: GoogleRoute[] = response.data
        .filter((route: any) => {
          // Check if any step in the route is operated by KSRTC
          return route.steps.some((step: any) => 
            step.transit_details?.operator?.toUpperCase().includes('KSRTC')
          );
        })
        .map((route: any) => ({
          legs: [{
            steps: route.steps.map((step: any) => ({
              travel_mode: step.travel_mode,
              instruction: step.instruction,
              distance: { text: step.distance },
              duration: { text: step.duration },
              transit_details: step.transit_details ? {
                line: {
                  name: step.transit_details.line.name || '',
                  short_name: step.transit_details.line.short_name || '',
                  vehicle: {
                    name: step.transit_details.line.vehicle?.name || '',
                    type: step.transit_details.line.vehicle?.type || ''
                  }
                },
                vehicle: step.transit_details.line.vehicle?.name || 'Bus',
                departure_stop: {
                  name: step.transit_details.departure_stop.name || '',
                  location: step.transit_details.departure_stop.location || { lat: 0, lng: 0 }
                },
                arrival_stop: {
                  name: step.transit_details.arrival_stop.name || '',
                  location: step.transit_details.arrival_stop.location || { lat: 0, lng: 0 }
                },
                operator: step.transit_details.operator || 'KSRTC',
                vehicle_type: step.transit_details.vehicle_type || 'Bus',
                departure_time: step.transit_details.departure_time || '',
                arrival_time: step.transit_details.arrival_time || '',
                fare: step.transit_details.fare || ''
              } : null
            })),
            start_address: source.trim(),
            end_address: destination.trim()
          }],
          summary: ' Bus Route',
          overview_polyline: { points: route.overview_polyline.points },
          mode: 'transit',
          total_distance: route.total_distance,
          total_duration: route.total_duration
        }));

      if (formattedRoutes.length === 0) {
        throw new Error('No  bus routes found for this journey');
      }
      
      setGoogleRoutes(formattedRoutes);
      setSelectedGoogleRoute(0);
      setShowGoogleRoutes(true);
      
    } catch (err) {
      const errorMessage = err instanceof Error ? err.message : 'An unexpected error occurred';
      console.error(' Route Finder Error:', {
        error: err,
        source,
        destination,
        timestamp: new Date().toISOString(),
        errorMessage
      });
      setError(errorMessage);
    } finally {
      setLoading(false);
    }
  };

  const handleAddBusDetails = async (e: React.FormEvent) => {
    e.preventDefault();
    try {
      const response = await fetch('http://localhost:5000/add-bus-details', {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
        },
        body: JSON.stringify({ vehicleNumber, tripRoute, time }),
      });

      if (!response.ok) {
        throw new Error('Failed to add bus details');
      }

      const result = await response.json();
      console.log(result.message);
      setShowAddForm(false);
      setVehicleNumber('');
      setTripRoute('');
      setTime('');
    } catch (err) {
      console.error('Error adding bus details:', err);
    }
  };

  if (loadError) return <div>Error loading maps</div>;
  if (!isLoaded) return <div>Loading Maps...</div>;

  return (
    <div className="min-h-screen bg-gray-100">
      
        
      
        <>
          <Navbar />
          <Hero />
          
          <main className="py-12">
            <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
              {/* Search Section */}
              <section id="routes" className="bg-white rounded-lg shadow-lg p-8 mb-12">
                <h2 className="text-2xl font-bold text-gray-900 mb-6">Find Your Route</h2>
                {/* Existing search form */}
                <div className="grid grid-cols-1 md:grid-cols-2 gap-6 mb-6">
                  <form onSubmit={handleSearch} className="bg-white rounded-lg shadow-sm p-6">
                    <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
                      <div>
                        <label htmlFor="source" className="block text-sm font-medium text-gray-700 mb-1">
                          Source Location
                        </label>
                        <input
                          type="text"
                          id="source"
                          value={source}
                          onChange={(e) => setSource(e.target.value)}
                          className="w-full px-4 py-2 border border-gray-300 rounded-md focus:ring-2 focus:ring-blue-500 focus:border-blue-500"
                          placeholder="Enter source location"
                          required
                        />
                      </div>
                      <div>
                        <label htmlFor="destination" className="block text-sm font-medium text-gray-700 mb-1">
                          Destination
                        </label>
                        <input
                          type="text"
                          id="destination"
                          value={destination}
                          onChange={(e) => setDestination(e.target.value)}
                          className="w-full px-4 py-2 border border-gray-300 rounded-md focus:ring-2 focus:ring-blue-500 focus:border-blue-500"
                          placeholder="Enter destination"
                          required
                        />
                      </div>
                    </div>
                    <div className="mt-4 flex flex-col md:flex-row gap-3">
                      <button
                        type="submit"
                        disabled={loading}
                        className="w-full md:w-auto px-6 py-2 bg-blue-600 text-white rounded-md hover:bg-blue-700 focus:outline-none focus:ring-2 focus:ring-blue-500 focus:ring-offset-2 disabled:opacity-50 disabled:cursor-not-allowed flex items-center justify-center gap-2"
                      >
                        {loading ? (
                          <>
                            <Bus className="animate-spin" size={20} />
                            <span>Searching Bus Schedule...</span>
                          </>
                        ) : (
                          <>
                            <Bus size={20} />
                            <span>Find Bus Routes</span>
                          </>
                        )}
                      </button>
                      
                      <button
                        type="button"
                        onClick={fetchGoogleRoutes}
                        disabled={loading}
                        className="w-full md:w-auto px-6 py-2 bg-purple-600 text-white rounded-md hover:bg-purple-700 focus:outline-none focus:ring-2 focus:ring-purple-500 focus:ring-offset-2 disabled:opacity-50 disabled:cursor-not-allowed flex items-center justify-center gap-2"
                      >
                        {loading ? (
                          <>
                            <Search className="animate-spin" size={20} />
                            <span>Searching Route...</span>
                          </>
                        ) : (
                          <>
                            <Search size={20} />
                            <span>Find Routes</span>
                          </>
                        )}
                      </button>
                    </div>
                  </form>
                  
                  {/* Route type selector */}
                  {(routes.length > 0 || googleRoutes.length > 0) && (
                    <div className="bg-white rounded-lg shadow-sm p-6">
                      <h2 className="text-lg font-semibold mb-4">Route Options</h2>
                      
                      <div className="flex flex-col md:flex-row gap-4">
                        <button
                          onClick={() => {
                            setShowGoogleRoutes(false);
                            setShowMap(false);
                          }}
                          className={`flex-1 p-3 rounded-md border ${
                            !showGoogleRoutes ? 'border-blue-500 bg-blue-50' : 'border-gray-200'
                          }`}
                        >
                          <div className="flex items-center justify-center gap-2">
                            <Bus size={20} className="text-blue-600" />
                            <span className="font-medium">Bus Schedules</span>
                          </div>
                        </button>
                        
                        <button
                          onClick={() => {
                            setShowGoogleRoutes(true);
                            setShowMap(false);
                          }}
                          className={`flex-1 p-3 rounded-md border ${
                            showGoogleRoutes && !showMap ? 'border-purple-500 bg-purple-50' : 'border-gray-200'
                          }`}
                        >
                          <div className="flex items-center justify-center gap-2">
                            <Navigation size={20} className="text-purple-600" />
                            <span className="font-medium">Other bus Routes</span>
                          </div>
                        </button>
                        
                        {googleRoutes.length > 0 && (
                          <button
                            onClick={() => {
                              setShowGoogleRoutes(true);
                              setShowMap(true);
                            }}
                            className={`flex-1 p-3 rounded-md border ${
                              showMap ? 'border-green-500 bg-green-50' : 'border-gray-200'
                            }`}
                          >
                            <div className="flex items-center justify-center gap-2">
                              <MapIcon size={20} className="text-green-600" />
                              <span className="font-medium">Map View</span>
                            </div>
                          </button>
                        )}
                      </div>
                      
                      {showGoogleRoutes && googleRoutes.length > 0 && !showMap && (
                        <div className="mt-4 space-y-3">
                          <h3 className="font-medium text-gray-700">Available bus Routes</h3>
                          {googleRoutes.map((route, index) => (
                            <button
                              key={index}
                              onClick={() => setSelectedGoogleRoute(index)}
                              className={`w-full text-left p-3 rounded-md border ${
                                selectedGoogleRoute === index 
                                  ? 'border-purple-500 bg-purple-50' 
                                  : 'border-gray-200 hover:bg-gray-50'
                              }`}
                            >
                              <div className="flex justify-between items-center">
                                <div className="font-medium">Route {index + 1}</div>
                                <span className={`text-xs px-2 py-1 rounded ${
                                  route.mode === 'transit' ? 'bg-blue-100 text-blue-800' :
                                  route.mode === 'driving' ? 'bg-green-100 text-green-800' :
                                  route.mode === 'walking' ? 'bg-orange-100 text-orange-800' :
                                  'bg-gray-100 text-gray-800'
                                }`}>
                                  {route.summary}
                                </span>
                              </div>
                              <div className="text-sm text-gray-500 mt-1">
                                {route.total_distance} • {route.total_duration}
                              </div>
                            </button>
                          ))}
                        </div>
                      )}
                    </div>
                  )}
                </div>
              </section>

              {/* Results Section */}
              {(routes.length > 0 || googleRoutes.length > 0) && (
                <section className="bg-white rounded-lg shadow-lg p-8 mb-12">
                  <h2 className="text-2xl font-bold text-gray-900 mb-6">Available Routes</h2>
                  {/* ... existing results display code ... */}
                  {showGoogleRoutes ? (
                    showMap ? (
                      // Map View
                      selectedGoogleRoute !== null && googleRoutes.length > 0 && (
                        <div className="bg-white rounded-lg shadow-sm p-6">
                          <h2 className="text-xl font-bold mb-4">Map View</h2>
                          <RouteMap route={googleRoutes[selectedGoogleRoute]} />
                          
                          <div className="mt-6">
                            <h3 className="font-semibold text-lg mb-2">Route Summary</h3>
                            <div className="bg-gray-50 p-4 rounded-lg">
                              <div className="flex flex-wrap gap-4">
                                <div>
                                  <span className="font-medium text-gray-700">Distance:</span> {googleRoutes[selectedGoogleRoute].total_distance}
                                </div>
                                <div>
                                  <span className="font-medium text-gray-700">Duration:</span> {googleRoutes[selectedGoogleRoute].total_duration}
                                </div>
                                <div>
                                  <span className="font-medium text-gray-700">Mode:</span> {googleRoutes[selectedGoogleRoute].summary}
                                </div>
                              </div>
                              <div className="mt-2">
                                <span className="font-medium text-gray-700">Route:</span> {source} to {destination}
                              </div>
                              <button
                                onClick={() => setShowMap(false)}
                                className="mt-4 px-4 py-2 bg-blue-600 text-white rounded-md text-sm hover:bg-blue-700"
                              >
                                View Detailed Steps
                              </button>
                            </div>
                          </div>
                        </div>
                      )
                    ) : (
                      // Google Routes text display
                      selectedGoogleRoute !== null && googleRoutes.length > 0 ? (
                        <div className="bg-white rounded-lg shadow-sm p-6">
                          <h2 className="text-xl font-bold mb-6">Route Details</h2>
                          
                          <div className="space-y-6">
                            {googleRoutes[selectedGoogleRoute].legs.map((leg, legIndex) => (
                              <div key={legIndex}>
                                <div className="flex items-center mb-4">
                                  <MapPin size={18} className="text-gray-500 mr-2" />
                                  <span className="font-medium">
                                    {leg.start_address || 'Starting point'} 
                                    <ArrowRight size={14} className="inline mx-2" /> 
                                    {leg.end_address || 'Destination'}
                                  </span>
                                </div>
                                
                                <div className="space-y-4">
                                  {leg.steps.map((step, stepIndex) => (
                                    <div key={stepIndex} className="border-l-2 border-gray-200 pl-4 py-1 ml-2">
                                      <div className="flex items-start">
                                        <div className="mt-1 mr-3">
                                          {getTravelModeIcon(step.travel_mode)}
                                        </div>
                                        
                                        <div className="flex-1">
                                          <div className="font-medium">{step.instruction}</div>
                                          
                                          <div className="flex text-sm text-gray-500 mt-1 space-x-3">
                                            <span className="flex items-center">
                                              <Navigation size={14} className="mr-1" />
                                              {step.distance.text}
                                            </span>
                                            
                                            <span className="flex items-center">
                                              <Clock size={14} className="mr-1" />
                                              {step.duration.text}
                                            </span>
                                          </div>
                                          
                                          {step.transit_details && (
                                            <TransitDetailsCard details={step.transit_details} />
                                          )}
                                        </div>
                                      </div>
                                    </div>
                                  ))}
                                </div>
                              </div>
                            ))}
                          </div>
                          
                          {!showMap && (
                            <button
                              onClick={() => setShowMap(true)}
                              className="mt-6 px-4 py-2 bg-green-600 text-white rounded-md flex items-center gap-2 hover:bg-green-700"
                            >
                              <MapIcon size={18} />
                              View on Map
                            </button>
                          )}
                        </div>
                      ) : null
                    )
                  ) : (
                    // Bus schedule display
                    <div className="space-y-6">
                      {routes.map((route, index) => (
                        <BusRouteDisplay key={index} route={route} />
                      ))}
                      {routes.length === 0 && !loading && !error && (
                        <div className="text-center py-12 bg-white rounded-lg">
                          <Bus size={48} className="text-gray-400 mx-auto mb-4" />
                          <p className="text-gray-500">No bus routes found. Try different locations.</p>
                        </div>
                      )}
                    </div>
                  )}
                </section>
              )}

              <Features />
            </div>
          </main>

          <Footer />

          {/* Admin Panel Modal */}
          {showAddForm && (
            <div className="fixed inset-0 bg-black bg-opacity-50 z-50 flex items-center justify-center">
              <div className="bg-white rounded-lg w-full max-w-2xl p-6">
                <div className="flex justify-between items-center mb-4">
                  <h2 className="text-xl font-bold text-gray-900">Add Bus Details</h2>
                  <button onClick={() => setShowAddForm(false)} className="text-gray-500">×</button>
                </div>
                <form onSubmit={handleAddBusDetails} className="bg-white rounded-lg shadow-sm p-6 mb-6">
                  <div className="grid grid-cols-1 md:grid-cols-3 gap-4">
                    <div>
                      <label htmlFor="vehicleNumber" className="block text-sm font-medium text-gray-700 mb-1">
                        Vehicle Number
                      </label>
                      <input
                        type="text"
                        id="vehicleNumber"
                        value={vehicleNumber}
                        onChange={(e) => setVehicleNumber(e.target.value)}
                        className="w-full px-4 py-2 border border-gray-300 rounded-md focus:ring-2 focus:ring-blue-500 focus:border-blue-500"
                        placeholder="Enter vehicle number"
                        required
                      />
                    </div>
                    <div>
                      <label htmlFor="tripRoute" className="block text-sm font-medium text-gray-700 mb-1">
                        Trip Route
                      </label>
                      <input
                        type="text"
                        id="tripRoute"
                        value={tripRoute}
                        onChange={(e) => setTripRoute(e.target.value)}
                        className="w-full px-4 py-2 border border-gray-300 rounded-md focus:ring-2 focus:ring-blue-500 focus:border-blue-500"
                        placeholder="Enter trip route"
                        required
                      />
                    </div>
                    <div>
                      <label htmlFor="time" className="block text-sm font-medium text-gray-700 mb-1">
                        Time
                      </label>
                      <input
                        type="text"
                        id="time"
                        value={time}
                        onChange={(e) => setTime(e.target.value)}
                        className="w-full px-4 py-2 border border-gray-300 rounded-md focus:ring-2 focus:ring-blue-500 focus:border-blue-500"
                        placeholder="Enter time"
                        required
                      />
                    </div>
                  </div>
                  <button
                    type="submit"
                    className="mt-4 w-full md:w-auto px-6 py-2 bg-green-600 text-white rounded-md hover:bg-green-700 focus:outline-none focus:ring-2 focus:ring-green-500 focus:ring-offset-2"
                  >
                    Add Bus Details
                  </button>
                </form>
              </div>
            </div>
          )}
        </>
      
    </div>
  );
}

const TransitDetailsCard = ({ details }: { details: TransitDetails }) => (
  <div className="mt-2 bg-blue-50 p-2 rounded text-sm">
    <div className="font-medium">
      <Bus size={14} className="inline mr-1 text-blue-700" />
      {details.line.short_name || details.line.name || 'Bus'} - {details.vehicle}
      {details.operator && (
        <span className="ml-2 px-2 py-1 bg-yellow-100 text-yellow-800 rounded text-xs">
          {details.operator}
        </span>
      )}
    </div>
    <div className="text-gray-600 mt-1">
      <div>From: {details.departure_stop.name}</div>
      <div>To: {details.arrival_stop.name}</div>
      {details.departure_time && (
        <div className="mt-1 text-sm">
          Departure: {details.departure_time}
        </div>
      )}
      {details.arrival_time && (
        <div className="text-sm">
          Arrival: {details.arrival_time}
        </div>
      )}
      {details.fare && (
        <div className="mt-1 font-medium text-green-700">
          Fare: ₹{details.fare}
        </div>
      )}
    </div>
  </div>
);

const BusRouteDisplay: React.FC<{ route: BusRoute }> = ({ route }) => {
  return (
    <div className="bg-white rounded-lg shadow-sm p-6">
      <div className="flex items-center gap-3 mb-4">
        <Bus className="text-blue-600" size={24} />
        <div>
          <h3 className="text-lg font-semibold text-gray-900">
            {route.type === 'direct' ? 'Direct Route' : 'Partial Route'}
          </h3>
          <p className="text-sm text-gray-500">Vehicle: {route.waypoint[0].vehicle_number}</p>
        </div>
      </div>

      <div className="relative mt-8">
        <div className="absolute left-8 top-0 bottom-0 w-0.5 bg-blue-200"></div>
        
        <div className="flex items-center mb-8">
          <div className="relative z-10">
            <div className="w-16 h-16 rounded-full bg-blue-100 flex items-center justify-center">
              <MapPin className="text-blue-600" size={24} />
            </div>
          </div>
          <div className="ml-4">
            <p className="font-medium text-gray-900">{route.firstLeg}</p>
            <p className="text-sm text-gray-500">Starting Point</p>
          </div>
        </div>

        {route.waypoint[0].stations
          .filter(station => 
            station.station !== route.firstLeg && 
            station.station !== route.secondLeg)
          .map((station, index) => (
            <div key={index} className="flex items-center mb-8">
              <div className="relative z-10">
                <div className="w-16 h-16 rounded-full bg-gray-100 flex items-center justify-center">
                  <Bus className="text-gray-600" size={24} />
                </div>
              </div>
              <div className="ml-4">
                <div className="flex items-center gap-2">
                  <p className="font-medium text-gray-900">{station.station}</p>
                  <span className="px-2 py-0.5 bg-blue-100 text-blue-800 text-xs rounded-full">
                    Stop {index + 1}
                  </span>
                </div>
                <div className="mt-1 grid grid-cols-2 gap-4 text-sm text-gray-500">
                  <div className="flex items-center gap-1">
                    <Clock size={14} />
                    <span>Arrival: {station.arrivalTime}</span>
                  </div>
                  <div className="flex items-center gap-1">
                    <Clock size={14} />
                    <span>Departure: {station.departureTime}</span>
                  </div>
                </div>
              </div>
            </div>
          ))}

        <div className="flex items-center">
          <div className="relative z-10">
            <div className="w-16 h-16 rounded-full bg-green-100 flex items-center justify-center">
              <MapPin className="text-green-600" size={24} />
            </div>
          </div>
          <div className="ml-4">
            <p className="font-medium text-gray-900">{route.secondLeg}</p>
            <p className="text-sm text-gray-500">Destination</p>
            {route.type === 'partial' && (
              <div className="mt-2 p-2 bg-amber-50 border border-amber-200 rounded-md">
                <p className="text-sm text-amber-800 flex items-center gap-1">
                  <AlertCircle size={14} />
                  <span>Partial route - alternative transport needed beyond this point</span>
                </p>
              </div>
            )}
          </div>
        </div>
      </div>

      <div className="mt-6 p-4 bg-gray-50 rounded-lg">
        <h4 className="font-medium text-gray-900 mb-2">Schedule Information</h4>
        <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
          {route.waypoint.map((trip, index) => (
            <div key={index} className="p-3 bg-white rounded border border-gray-200">
              <div className="font-medium text-gray-900 mb-2">Trip {trip.trip}</div>
              <div className="space-y-2">
                {[trip.stations[0], trip.stations[trip.stations.length - 1]].map((station, stIndex) => (
                  <div key={stIndex} className="flex justify-between text-sm">
                    <span className="text-gray-600">{station.station}</span>
                    <span className="text-gray-900">{station.departureTime}</span>
                  </div>
                ))}
              </div>
            </div>
          ))}
        </div>
      </div>
    </div>
  );
};

export default App;
