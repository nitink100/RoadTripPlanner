require 'uri'
require 'net/http'
require 'json'
require 'time'
require 'dotenv/load'

class RoadTripPlanner
    def initialize
        # Use a loop for better control than a raw while(true)
        loop do
            starting_point, starting_time_input, ending_point = input_taken_from_user

            # This logic can be simplified. The main goal is to get a Time object.
            if starting_time_input.is_a?(Array)
                # Input format: [dd, mm, yyyy, hh, mm, ss]
                # Note: The hardcoded "+05:30" (India Standard Time) might be something you want to make dynamic later.
                starting_time = Time.new(starting_time_input[2], starting_time_input[1], starting_time_input[0], starting_time_input[3], starting_time_input[4], starting_time_input[5], "+05:30")
                date = [starting_time_input[2], starting_time_input[1], starting_time_input[0]]
            else
                starting_time = starting_time_input # This is already a Time object if the user chose "YES"
                date = [starting_time.year, starting_time.month, starting_time.day]
            end

            sleep_time = sleeping_period(date, starting_time)

            transport_mode = choosing_transport_mode
            transport_string = if transport_mode.is_a?(Array)
                                "&mode=#{transport_mode[0]}&transit_mode=#{transport_mode[1]}"
                               else
                                "&mode=#{transport_mode}"
                               end
            
            # --- CRUCIAL SECURITY FIX ---
            # Load the API key from the environment variable instead of hardcoding it.
            api_key = ENV['GOOGLE_MAPS_API_KEY']
            if api_key.nil?
                puts "ERROR: GOOGLE_MAPS_API_KEY not found. Please create a .env file."
                break
            end
            url = URI("https://maps.googleapis.com/maps/api/directions/json?origin=#{starting_point}&destination=#{ending_point}#{transport_string}&key=#{api_key}")
            # --------------------------

            https = Net::HTTP.new(url.host, url.port)
            https.use_ssl = true
            request = Net::HTTP::Get.new(url)
            response = JSON.parse(https.request(request).read_body)
            
            if check_for_correct_route_entry(response)
                route_details = response["routes"][0]["legs"][0]
                start_address = route_details["start_address"]
                end_address = route_details["end_address"]
                journey_duration = route_details["duration"]["text"]
                journey_distance = route_details["distance"]["text"]

                puts "\n\n--- Your Trip Itinerary ---"
                puts "From: #{start_address}"
                puts "To: #{end_address}"
                puts "Departure: #{starting_time.strftime('%A, %B %d, %Y at %I:%M %p')}"
                puts "Total Distance: #{journey_distance}"
                puts "Estimated Travel Time: #{journey_duration}"
                puts "\n--- Turn-by-Turn Directions ---"

                current_time = starting_time
                route_details["steps"].each_with_index do |step, count|
                    step_duration_seconds = step["duration"]["value"]
                    
                    # Check if the step falls within the sleeping period
                    if !sleep_time.nil? && (current_time.hour >= sleep_time[0].hour || (current_time + step_duration_seconds).hour >= sleep_time[0].hour)
                        # This is a simplified check. A more robust solution would handle multi-day trips better.
                        # For now, let's assume if we hit the sleep time, we jump to the next morning.
                        puts "\n** 🛌 SLEEP BREAK: Pausing trip until #{sleep_time[1].strftime('%I:%M %p')} **\n"
                        sleep_jump = (sleep_time[1] - current_time) > 0 ? (sleep_time[1] - current_time) : (sleep_time[1] + 24*60*60 - current_time)
                        current_time += sleep_jump
                    end

                    start_of_step = current_time
                    end_of_step = current_time + step_duration_seconds
                    
                    puts "Step #{count + 1}:"
                    puts "  Distance: #{step['distance']['text']}"
                    puts "  Duration: #{step['duration']['text']}"
                    puts "  Time: #{start_of_step.strftime('%I:%M %p')} -> #{end_of_step.strftime('%I:%M %p')}"
                    puts "  Instruction: #{printing_text(step['html_instructions'])}"
                    puts "-" * 20

                    current_time = end_of_step
                end
                 puts "\nEstimated Arrival: #{current_time.strftime('%A, %B %d, %Y at %I:%M %p')}"
            end

            break unless continue_program?
        end
    end

    private

    # Removes HTML tags from the instruction string
    def printing_text(string)
        string.gsub(/<[^>]*>/, '')
    end

    def check_for_correct_route_entry(result)
        if result["routes"].nil? || result["routes"].empty?
            puts "\nError: #{result['status']}"
            if result["available_travel_modes"]
                puts "Available travel modes for this route are: #{result['available_travel_modes'].join(', ')}"
            end
            return false
        end
        true
    end

    def input_taken_from_user
        puts "\nPlan a trip for now? (yes/no)"
        choice_trip = gets.chomp.upcase

        arr1 = if choice_trip == "YES"
            Time.new
        elsif choice_trip == "NO"
            start_time_str = checking_for_nil("Starting time (HH:MM:SS format): ")
            start_date_str = checking_for_nil("Date of the trip (DD/MM/YYYY format): ")
            # Combine and return as an array of integers for the Time constructor
            date_parts = start_date_str.split('/').map(&:to_i)
            time_parts = start_time_str.split(':').map(&:to_i)
            [date_parts[0], date_parts[1], date_parts[2], time_parts[0], time_parts[1], time_parts[2]]
        else
            puts "Invalid input. Please try again."
            return input_taken_from_user # Recursion is okay for simple validation
        end

        starting_location = checking_for_nil("Starting location: ")
        ending_location = checking_for_nil("Ending location: ")
        return starting_location, arr1, ending_location
    end

    def sleeping_period(date, starting_time)
        puts "Do you want to add a daily pause/sleep time? (yes/no)"
        return nil unless gets.chomp.upcase == 'YES'

        puts "Enter the daily time interval you want to pause the trip (e.g., 22:00-08:00):"
        interval = gets.chomp.split("-")
        start_sleep_parts = interval[0].split(':').map(&:to_i)
        end_sleep_parts = interval[1].split(':').map(&:to_i)

        # Create Time objects for today's date to represent the sleep window
        start_sleep = Time.new(date[0], date[1], date[2], start_sleep_parts[0], start_sleep_parts[1], 0, "+05:30")
        end_sleep = Time.new(date[0], date[1], date[2], end_sleep_parts[0], end_sleep_parts[1], 0, "+05:30")
        
        # If end time is earlier than start time, it means it's overnight (e.g., 22:00 to 08:00)
        end_sleep += 24 * 60 * 60 if end_sleep < start_sleep
        
        [start_sleep, end_sleep]
    end

    def choosing_transport_mode
        puts "\nSelect a mode of transport:"
        puts "1. Driving"
        puts "2. Bicycling"
        puts "3. Walking"
        puts "4. Public Transit"
        
        case gets.chomp.to_i
        when 1 then "driving"
        when 2 then "bicycling"
        when 3 then "walking"
        when 4 then ["transit", public_transport_mode]
        else
            puts "Invalid option, please choose again."
            choosing_transport_mode
        end
    end

    def public_transport_mode
        puts "\nSelect a preferred public transit mode:"
        puts "1. Bus"
        puts "2. Subway"
        puts "3. Train"
        puts "4. Tram"
        puts "5. Rail (Bus, Subway, Train, Tram combined)"
        
        case gets.chomp.to_i
        when 1 then "bus"
        when 2 then "subway"
        when 3 then "train"
        when 4 then "tram"
        when 5 then "rail"
        else
            puts "Invalid option, please choose again."
            public_transport_mode
        end
    end

    def continue_program?
        puts "\nWhat would you like to do?"
        puts "1. Plan another trip"
        puts "2. Exit"
        
        case gets.chomp.to_i
        when 1 then true
        when 2 then false
        else
            puts "Invalid choice."
            continue_program?
        end
    end

    def checking_for_nil(prompt)
        print prompt
        input = gets.chomp
        if !input.nil? && !input.empty?
            return input
        else
            puts "Input cannot be empty. Please try again."
            checking_for_nil(prompt)
        end
    end
end

RoadTripPlanner.new