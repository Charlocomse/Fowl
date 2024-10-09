# Flask Scanning Tool

This project is a Flask web application that allows users to run a scan script with custom inputs such as domain, word, and output directory. The results are shown on the page, and Google Chrome is launched automatically to open the application. The tool is designed to be run both on Linux and Windows environments.

## Features

- Simple web interface to run a scanning script.
- Automatically opens Google Chrome to the Flask app.
- Displays the last executed command and the progress of the scan.
- Includes a custom loading bar that dynamically updates during the scan.

## Prerequisites

- Python 3.x
- Flask
- Google Chrome
- A Linux environment


## Installation

1. Clone the repository:
   git clone https://github.com/charlocomse/fool.git
   cd fool
   
2. chmod +x scan_script.sh

3. Run ./install.sh or bash install.sh to install all the softwares needed

## Usage

1. Run the Flask application:

python app.py

2. The application will start at http://127.0.0.1:5000/ and will automatically open in Google Chrome.

3. On the webpage, you can enter the following information:

    . Domain: The domain to scan.
    . Word: The keyword for scanning.
    . Output Directory: Directory to save the results.

4. Click "Start Scan" and the scan will be launched. The progress bar will display the scan's progress, and the last executed command will be shown at the bottom of the page.


## Code Structure

    . app.py: Main Flask application that handles the routing and scanning functionality.
    . scan_script.sh: Bash script to run the scan (customizable).
    . templates/index.html: The HTML template for the web interface.
    . static/style.css: Custom styles for the web interface, including the loading bar.

## Notes

The script assumes Google Chrome is installed and available in the system's PATH. On Linux, the command google-chrome is used, and on Windows, the correct path to Chrome should be set if necessary.
You can modify the scan_script.sh to adapt it to your specific needs.

## Troubleshooting

Chrome opens multiple tabs: If Chrome opens multiple tabs when the app runs, make sure you're not running conflicting instances of the browser. You can also try modifying the command that launches Chrome in app.py.
Script not executing: Ensure that scan_script.sh has the correct permissions and that the command syntax is valid.

## License

This project is licensed under the MIT License - see the LICENSE file for details.


### Key points:
- **Installation**: Instructions on how to clone the repository and install dependencies.
- **Usage**: Steps for running the Flask app and interacting with the web interface.
- **Code structure**: Brief explanation of the main components.
- **Troubleshooting**: Common issues with possible solutions.
  
Let me know if you'd like to adjust or add any sections!

