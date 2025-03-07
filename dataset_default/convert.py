import json
import pathlib

dir_ = pathlib.Path(__file__).parent

import json
import os

def extract_bus_schedules(json_file_path):
    """
    Extracts the 'busSchedules' content from a JSON file.

    Args:
        json_file_path (str): The path to the JSON file.

    Returns:
        list: The 'busSchedules' list, or None if an error occurs.
    """
    try:
        with open(json_file_path, 'r') as f:
            data = json.load(f)
            return data.get('busSchedules')
    except FileNotFoundError:
        print(f"Error: File not found at {json_file_path}")
        return None
    except json.JSONDecodeError:
        print(f"Error: Invalid JSON format in {json_file_path}")
        return None
    except Exception as e:
        print(f"An unexpected error occurred: {e}")
        return None

def process_json_files(directory, output_directory):
    """
    Processes multiple JSON files in a directory and extracts 'busSchedules'.

    Args:
        directory (str): The directory containing the JSON files.
        output_directory (str): the directory where the combined output should be stored.

    Returns:
        list: A list containing all 'busSchedules' lists from the JSON files.
    """
    all_bus_schedules = []
    try:
        for filename in os.listdir(directory):
            if filename.endswith('.json'):
                file_path = os.path.join(directory, filename)
                bus_schedules = extract_bus_schedules(file_path)
                if bus_schedules:
                    all_bus_schedules.extend(bus_schedules)

        if not os.path.exists(output_directory):
            os.makedirs(output_directory)

        output_file_path = os.path.join(output_directory, 'combined_bus_schedules.json')

        with open(output_file_path, 'w') as f:
            json.dump(all_bus_schedules, f, indent=2)

        return all_bus_schedules

    except FileNotFoundError:
        print(f"Error: Directory not found at {directory}")
        return None
    except Exception as e:
        print(f"An unexpected error occurred: {e}")
        return None

# Example usage:
directory_path = str(dir_) # Replace with the actual directory path
output_directory = dir_ / 'json_processed'

all_extracted_schedules = process_json_files(directory_path, str(output_directory))

if all_extracted_schedules:
    print(f"Combined data saved to {os.path.join(output_directory, 'combined_bus_schedules.json')}")