require("dotenv").config();
const express = require("express");
const axios = require("axios");
const cors = require("cors");

const app = express();
app.use(cors());
app.use(express.json());

const GOOGLE_MAPS_API_KEY = process.env.GMAPS_API_KEY;
const BUS_API_URL = "https://busapi.amithv.xyz/api/v1/schedules";

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
            return res.json({ type: "direct", route: directBusResponse.data });
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

const PORT = process.env.PORT || 5000;
app.listen(PORT, () => console.log(`Server running on port ${PORT}`));
