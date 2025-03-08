const express = require('express');
const { Client } = require('@googlemaps/google-maps-services-js');
const cors = require('cors');
require('dotenv').config();

const app = express();
app.use(cors());
app.use(express.json());

const googleMapsClient = new Client({});
const GMAPS_API_KEY = process.env.GOOGLE_MAPS_API_KEY || 'AIzaSyAzRiCqyt3irzVZr1n2W-hf4EMrFpGgdss';

// Mock KSRTC bus data (replace with actual database)
const ksrtcBusData = {
  fares: {
    'ordinary': 1.5, // Rate per km
    'fast': 2.0,
    'superfast': 2.5,
    'express': 3.0
  },
  busTypes: ['ordinary', 'fast', 'superfast', 'express']
};

// Helper function to calculate KSRTC fare
function calculateKsrtcFare(distance, busType = 'ordinary') {
  const ratePerKm = ksrtcBusData.fares[busType.toLowerCase()] || ksrtcBusData.fares.ordinary;
  return Math.ceil(distance * ratePerKm);
}

// Function to enhance transit details with KSRTC specific information
function enhanceTransitDetails(step, distance) {
  if (step.transit_details && step.transit_details.line) {
    const busType = ksrtcBusData.busTypes[Math.floor(Math.random() * ksrtcBusData.busTypes.length)];
    const fare = calculateKsrtcFare(distance, busType);
    
    return {
      ...step.transit_details,
      operator: 'KSRTC',
      vehicle_type: busType,
      departure_time: step.transit_details.departure_time?.text || 'Schedule varies',
      arrival_time: step.transit_details.arrival_time?.text || 'Schedule varies',
      fare: fare.toString()
    };
  }
  return step.transit_details;
}

async function getKsrtcRoutes(start, end, mode = 'transit') {
  try {
    const response = await googleMapsClient.directions({
      params: {
        origin: start,
        destination: end,
        mode: mode,
        alternatives: true,
        transit_mode: ['bus'],
        transit_routing_preference: 'less_walking',
        region: 'in', // Set region to India
        key: GMAPS_API_KEY,
      },
    });

    if (!response.data.routes.length) {
      console.error('No routes found.');
      return null;
    }

    // Process and enhance routes with KSRTC information
    const routes = response.data.routes.map(route => {
      const steps = route.legs.flatMap(leg => 
        leg.steps.map(step => {
          const distance = step.distance.value / 1000; // Convert to km
          return {
            travel_mode: step.travel_mode,
            instruction: step.html_instructions.replace(/<[^>]+>/g, ''),
            distance: step.distance.text,
            duration: step.duration.text,
            transit_details: enhanceTransitDetails(step, distance)
          };
        })
      );

      const totalDistance = route.legs.reduce((sum, leg) => sum + leg.distance.value, 0) / 1000;
      
      return {
        mode: 'transit',
        operator: 'KSRTC',
        total_distance: `${totalDistance.toFixed(1)} km`,
        total_duration: route.legs.reduce((sum, leg) => sum + leg.duration.value, 0) / 60 + ' min',
        total_fare: calculateKsrtcFare(totalDistance, 'express').toString(),
        steps: steps,
        overview_polyline: route.overview_polyline,
      };
    });

    return routes;
  } catch (error) {
    console.error('Error fetching KSRTC routes:', error);
    return null;
  }
}

// API endpoint to fetch KSRTC routes
app.post('/get-routes', async (req, res) => {
  const { start, end, mode } = req.body;

  if (!start || !end) {
    return res.status(400).json({ error: 'Start and end locations are required' });
  }

  try {
    const routes = await getKsrtcRoutes(start, end, mode);
    if (!routes) {
      return res.status(404).json({ error: 'No KSRTC routes found for this journey' });
    }

    res.json(routes);
  } catch (error) {
    console.error('Error processing KSRTC route request:', error);
    res.status(500).json({ error: 'An error occurred while fetching KSRTC routes' });
  }
});

// Add bus details endpoint
app.post('/add-bus-details', async (req, res) => {
  const { vehicleNumber, tripRoute, time } = req.body;

  if (!vehicleNumber || !tripRoute || !time) {
    return res.status(400).json({ error: 'All fields are required' });
  }

  try {
    // Here you would typically save to a database
    // For now, just log and return success
    console.log('New bus details added:', { vehicleNumber, tripRoute, time });
    res.json({ message: 'Bus details added successfully' });
  } catch (error) {
    console.error('Error adding bus details:', error);
    res.status(500).json({ error: 'Failed to add bus details' });
  }
});

const PORT = process.env.PORT || 5000;
app.listen(PORT, () => {
  console.log(`KSRTC Route Server running on http://localhost:${PORT}`);
});