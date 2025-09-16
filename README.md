# Ruby Road Trip Planner

A command-line application built in Ruby that enables users to plan road trips with custom start times, locations, and transportation preferences. It integrates with the Google Maps Directions API to fetch real-time routes, travel durations, and turn-by-turn directions.

## Features

-   **Custom Trip Planning**: Plan a trip for right now or schedule one for a future date and time.
-   **Multiple Travel Modes**: Get directions for driving, walking, bicycling, or various public transit options (bus, train, subway).
-   **Sleep/Pause Scheduling**: Automatically adjusts the itinerary to account for user-defined daily "sleep times" for long, multi-day trips.
-   **Detailed Itinerary**: Provides total distance, estimated duration, and detailed step-by-step instructions for the entire journey.
-   **Interactive CLI**: Easy-to-use command-line interface to guide the user through the planning process.

## Prerequisites

-   [Ruby](https://www.ruby-lang.org/en/documentation/installation/) installed on your system.
-   A valid **Google Maps Directions API Key**. You can get one from the [Google Cloud Console](https://console.cloud.google.com/google/maps-apis/overview).

## Setup & Installation

1.  **Clone the repository:**
    ```sh
    git clone https://github.com/nitink100/RoadTripPlanner.git
    cd RoadTripPlanner
    ```

2.  **Install dependencies:**
    This script uses the `dotenv` gem to manage environment variables securely.
    ```sh
    gem install dotenv
    ```

3.  **Configure your API Key:**
    Create a file named `.env` in the root of the project folder. This file is included in `.gitignore` and will not be committed to the repository.
    ```sh
    touch .env
    ```
    Open the `.env` file and add your Google Maps API key in the following format:
    ```
    GOOGLE_MAPS_API_KEY="YOUR_API_KEY_HERE"
    ```

## How to Run

Execute the script from your terminal using the following command:

```sh
ruby road_trip_planner.rb
```

The application will then prompt you for all the necessary details, including start/end locations, departure time, travel mode, and any scheduled pauses.

### Example Walkthrough

```
$ ruby road_trip_planner.rb

Plan a trip for now? (yes/no)
> yes
Starting location:
> Dallas, TX
Ending location:
> Austin, TX

Select a mode of transport:
1. Driving
2. Bicycling
3. Walking
4. Public Transit
> 1

Do you want to add a daily pause/sleep time? (yes/no)
> no

--- Your Trip Itinerary ---
From: Dallas, TX, USA
To: Austin, TX, USA
Departure: Tuesday, September 16, 2025 at 12:02 PM
Total Distance: 195 mi
Estimated Travel Time: 3 hours 0 mins

--- Turn-by-Turn Directions ---
...
```