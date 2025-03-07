
require("dotenv").config();
const express = require("express");
const axios = require("axios");
const cors = require("cors");
const fs = require('fs');
const path = require('path');

const corsOptions = {
    origin: 'http://localhost:5173',
    credentials: true,
  };

const app = express();
app.use(cors(corsOptions));
app.use(express.json());

function writeBusDetailsToFile(vehicleNumber, tripRoute, time) {
    const filePath = path.join(__dirname, 'busDetails.txt');
    const data = `Vehicle Number: ${vehicleNumber}, Trip Route: ${tripRoute}, Time: ${time}\n`;
    fs.appendFileSync(filePath, data, 'utf8');
}

// Function to read bus details from the text file
function readBusDetailsFromFile() {
    const filePath = path.join(__dirname, 'busDetails.txt');
    if (fs.existsSync(filePath)) {
        const data = fs.readFileSync(filePath, 'utf8');
        return data;
    } else {
        return 'No bus details found.';
    }
}

const GOOGLE_MAPS_API_KEY = process.env.GMAPS_API_KEY;
const BUS_API_URL = process.env.BUS_API_URL;
const GEMINI_API_KEY = process.env.GEMINI_API_KEY;
const GEMINI_API_URL = "https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash:generateContent"; // Updated URL
const PORT = process.env.CHATBOT_PORT || 4000;


// Chatbot function
async function sendMessageToChatbot(message) {
    try {
        const response = await axios.post(
            `${GEMINI_API_URL}?key=${GEMINI_API_KEY}`, // Append API key to URL
            {
                contents: [{
                    parts: [{ text: message }] // Correct payload structure for Gemini API
                }]
            },+
            {
                headers: {
                    "Content-Type": "application/json",
                },
            }
        );
 
        // Extract the text part from the response
        const textResponse = response.data.candidates[0].content.parts[0].text;
        return textResponse;
    } catch (error) {
        console.error("Error communicating with Gemini AI:", error.message);
        console.error("Error Details:", error.response?.data); // Log detailed error
        return null;
    }
}

app.get("/bus-details", (req, res) => {
    const busDetails = readBusDetailsFromFile();
    res.status(200).send(busDetails);
});

// Example usage of writeBusDetailsToFile function
app.post("/add-bus-details", (req, res) => {
    const { vehicleNumber, tripRoute, time } = req.body;

    if (!vehicleNumber || !tripRoute || !time) {
        return res.status(400).json({ error: "Vehicle number, trip route, and time are required" });
    }

    writeBusDetailsToFile(vehicleNumber, tripRoute, time);
    res.status(200).json({ message: "Bus details added successfully" });
});
 
// Route to handle chatbot requests
app.post("/chat", async (req, res) => {
    const { message } = req.body;
 
    if (!message) {
        return res.status(400).json({ error: "Message is required" });
    }
 
    const botResponse = await sendMessageToChatbot(message);
 
    if (botResponse) {
        res.status(200).json({ response: botResponse });
    } else {
        res.status(500).json({ error: "Failed to get a response from the chatbot." });
    }
});


app.get("/get-bus-route", async (req, res) => {
    try {
        const { source, destination } = req.query;

        if (!source || !destination) {
            return res.status(400).json({ error: "Source and destination required" });
        }

        // Step 1: Get Google Maps route
        const gmapsUrl = `https://maps.googleapis.com/maps/api/directions/json?origin=${source}&destination=${destination}&key=${GOOGLE_MAPS_API_KEY}`;
        const gmapsResponse = await axios.get(gmapsUrl);
        const gmapsData = gmapsResponse.data;

        if (gmapsData.status !== "OK") {
            return res.status(400).json({ error: "Route not found" });
        }

        // Extract all waypoints from Google Maps
        const waypoints = gmapsData.routes[0].legs[0].steps.map(step => step.start_location);

        // Step 2: Check for Direct Bus Route
        const directBusUrl = `${BUS_API_URL}?departure=${source}&destination=${destination}`;
        const directBusResponse = await axios.get(directBusUrl);
        if (directBusResponse.data.length > 0) {
            const d = directBusResponse.data;
            console.log(d);
            const y = { type: "direct", firstLeg: '', secondLeg: '', waypoint: directBusResponse.data };
            console.log(y);
            
            return res.json(y);
        }

        // Step 3: Check for Indirect Routes
        for (let i = 0; i < waypoints.length; i++) {
            const waypoint = waypoints[i];
            const waypointName = `${waypoint.lat},${waypoint.lng}`;

            // Check if there's a bus from Source -> Waypoint
            const firstLegUrl = `${BUS_API_URL}?departure=${source}&destination=${waypointName}`;
            const firstLegResponse = await axios.get(firstLegUrl);

            if (firstLegResponse.data.length > 0) {
                // Check if there's a bus from Waypoint -> Destination
                const secondLegUrl = `${BUS_API_URL}?departure=${waypointName}&destination=${destination}`;
                const secondLegResponse = await axios.get(secondLegUrl);

                if (secondLegResponse.data.length > 0) {
                    return res.json({
                        type: "indirect",
                        firstLeg: firstLegResponse.data,
                        secondLeg: secondLegResponse.data,
                        waypoint: waypointName
                    });
                }
            }
        }

        res.json({ error: "No direct or indirect route found" });

    } catch (error) {
        console.error(error);
        res.status(500).json({ error: "Internal Server Error" });
    }
});

// const PORT = process.env.PORT || 5000;
app.listen(PORT, () => console.log(`Server running on port ${PORT}`));
