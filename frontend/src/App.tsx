import React, { useState } from 'react';
import { Bus, Search, AlertCircle, Plus } from 'lucide-react';
import './Chat';

interface Station {
  station: string;
  arrivalTime: string;
  departureTime: string;
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

  const handleSearch = async (e: React.FormEvent) => {
    e.preventDefault();
    setLoading(true);
    setError(null);
    setRoutes([]);

    try {
      // Input validation
      if (!source.trim() || !destination.trim()) {
        throw new Error('Please enter both source and destination locations');
      }

      const response = await fetch(`http://127.0.0.1:5000/get-bus-route?source=${encodeURIComponent(source.trim())}&destination=${encodeURIComponent(destination.trim())}`, {
        method: 'GET',
        headers: {
          'Accept': 'application/json',
          'Origin': window.location.origin,
        },
        credentials: 'include',
      }).catch((networkError) => {
        throw new Error('Unable to connect to the server. Please check your connection and try again.');
      });

      // Handle different response scenarios
      if (response.status === 404) {
        throw new Error(`No bus routes found from ${source} to ${destination}. Try searching for a different route.`);
      }

      if (response.status === 403 || response.status === 401) {
        throw new Error('Access to bus routes is currently restricted. Please try again later.');
      }

      if (!response.ok) {
        throw new Error('Unable to fetch bus routes at the moment. Please try again later.');
      }

      const contentType = response.headers.get('content-type');
      if (!contentType?.includes('application/json')) {
        throw new Error('Unexpected response from server. Please try again.');
      }

      const data = await response.json().catch(() => {
        throw new Error('Invalid response data received. Please try again.');
      });

      // Log the response to the console
      console.log('Bus Route Response:', data);

      // Convert single object response to array if needed
      const routesData = Array.isArray(data) ? data : 
        (data && typeof data === 'object' && data !== null && 'type' in data && (data.type === 'direct' || data.type === 'indirect')) ? [data] : [];
      
      setRoutes(routesData);

      if (routesData.length === 0) {
        throw new Error(`No bus routes available between ${source} and ${destination}. Try searching for a different route.`);
      }
    } catch (err) {
      const errorMessage = err instanceof Error ? err.message : 'An unexpected error occurred. Please try again.';
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

  const handleAddBusDetails = async (e: React.FormEvent) => {
    e.preventDefault();
    try {
      const response = await fetch('http://127.0.0.1:5000/add-bus-details', {
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

  return (
    <div className="min-h-screen bg-gray-100 p-8">
      <div className="max-w-4xl mx-auto">
        <div className="flex items-center gap-2 mb-6">
          <Bus className="text-blue-600" size={24} />
          <h1 className="text-2xl font-bold text-gray-900">Bus Route Finder</h1>
          <button
            onClick={() => setShowAddForm(!showAddForm)}
            className="ml-auto bg-green-600 text-white rounded-md p-2 hover:bg-green-700 focus:outline-none focus:ring-2 focus:ring-green-500 focus:ring-offset-2"
          >
            <Plus size={20} />
          </button>
        </div>

        {showAddForm && (
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
        )}

        <form onSubmit={handleSearch} className="bg-white rounded-lg shadow-sm p-6 mb-6">
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
          <button
            type="submit"
            disabled={loading}
            className="mt-4 w-full md:w-auto px-6 py-2 bg-blue-600 text-white rounded-md hover:bg-blue-700 focus:outline-none focus:ring-2 focus:ring-blue-500 focus:ring-offset-2 disabled:opacity-50 disabled:cursor-not-allowed flex items-center justify-center gap-2"
          >
            {loading ? (
              <>
                <Bus className="animate-spin" size={20} />
                <span>Searching...</span>
              </>
            ) : (
              <>
                <Search size={20} />
                <span>Find Routes</span>
              </>
            )}
          </button>
        </form>

        {error && (
          <div className="bg-red-50 p-4 rounded-lg border border-red-200 mb-6 flex items-start gap-3">
            <AlertCircle className="text-red-600 flex-shrink-0 mt-0.5" size={20} />
            <p className="text-red-600">{error}</p>
          </div>
        )}

        <div className="grid gap-4">
          {routes.map((route, index) => (
            <div 
              key={index}
              className="bg-white rounded-lg shadow-sm p-4 hover:shadow-md transition-shadow"
            >
              <h2 className="text-lg font-semibold text-gray-800">{route.type} Route</h2>
              {route.waypoint.map((waypoint, wpIndex) => (
                <div key={wpIndex} className="mt-4">
                  <h3 className="text-md font-semibold text-gray-700">Vehicle: {waypoint.vehicle_number} (Trip: {waypoint.trip})</h3>
                  <ul className="mt-2">
                    {waypoint.stations.map((station, stIndex) => (
                      <li key={stIndex} className="text-sm text-gray-600">
                        {station.station} - Arrival: {station.arrivalTime}, Departure: {station.departureTime}
                      </li>
                    ))}
                  </ul>
                </div>
              ))}
            </div>
          ))}
          
          {routes.length === 0 && !loading && !error && (
            <div className="bg-gray-50 rounded-lg p-8 text-center">
              <p className="text-gray-600">Enter source and destination locations to find available bus routes</p>
            </div>
          )}
        </div>
      </div>
    </div>
  );
}

export default App;