import requests
import os
import sys
import time

def get_export_request_job_id(url):
    try:
        response = requests.post(f"{url}/$export", headers={'Prefer': 'respond-async'})
        response.raise_for_status()  
        content_location = response.headers.get('Content-Location')
        return content_location
    except requests.exceptions.HTTPError as http_err:
        print(f"HTTP error occurred: {http_err}")
        return None
    except Exception as err:
        print(f"An error occurred: {err}")
        return None
    
# Define the function to retrieve the URLs file
def retrieve_urls(url):
    response = requests.get(url)
    if response.status_code == 202:
        time.sleep(1)
        return retrieve_urls(url)
    if response.status_code == 200:
        return response.json()
    else:
        return None

# Define a function to download a file given a URL
def download_file(url):
    response = requests.get(url)
    if response.status_code == 200:
        return response.text
    else:
        return None

# Define a function to combine files of the same type into a single file
def combine_files(output_folder, files):
    combined_files = {}
    for file_data in files:
        file_type = file_data['type']
        file_url = file_data['url']
        file_content = download_file(file_url)
        if file_content:
            if file_type not in combined_files:
                combined_files[file_type] = []
            combined_files[file_type].append(file_content)

    for file_type, content_list in combined_files.items():
        with open(os.path.join(output_folder, f"{file_type}.ndjson"), 'w') as f:
            for content in content_list:
                f.write(content + '\n')

# Execute the script
if __name__ == "__main__":
    if len(sys.argv) != 3:
        print("Usage: python bulk-data-export.py <FHIR_SERVER_URL> <OUTPUT_FOLDER>")
        sys.exit(1)

    fhir_server_url = sys.argv[1]
    output_folder = sys.argv[2]

    os.makedirs(output_folder, exist_ok=True)
    export_job_url = get_export_request_job_id(fhir_server_url)
    urls = retrieve_urls(export_job_url)
    if urls:
        combine_files(output_folder, urls['output'])
    else:
        print("Failed to retrieve URLs.")