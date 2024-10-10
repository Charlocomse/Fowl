import logging
from flask import Flask, render_template, request, jsonify
import os
import subprocess
import threading
import webbrowser
import time

app = Flask(__name__)


# Configurer le niveau de log pour supprimer les logs des requêtes
log = logging.getLogger('werkzeug')
log.setLevel(logging.ERROR)  # Affiche seulement les erreurs

# Variable globale pour stocker la dernière commande exécutée et la sortie du scan
last_command = ""
scan_output = ""

@app.route('/')
def index():
    return render_template('index.html')

@app.route('/scan', methods=['GET'])
def scan():
    global last_command, scan_output
    domain = request.args.get('domain')
    outputDir = request.args.get('outputDir')

    # Construire la commande à exécuter
    command = f"sudo ./scan_script.sh -d {domain} -D {outputDir}"  # Ajouter sudo ici
    
    last_command = command  # Met à jour la dernière commande
    print(f"Exécution de la commande: {command}")

    # Lancer le script en tant que thread
    thread = threading.Thread(target=execute_command, args=(command,))
    thread.start()

    return jsonify({'message': 'Scan en cours...'}), 200

def execute_command(command):
    global scan_output
    # Exécuter la commande
    process = subprocess.Popen(command, shell=True, stdout=subprocess.PIPE, stderr=subprocess.PIPE)
    
    # Attendre que la commande se termine
    stdout, stderr = process.communicate()
    scan_output = stdout.decode()  # Enregistrer la sortie standard
    print(scan_output)  # Afficher la sortie standard
    print(stderr.decode())  # Afficher les erreurs éventuelles

@app.route('/last_command', methods=['GET'])
def get_last_command():
    return jsonify({'last_command': last_command}), 200

@app.route('/scan_result', methods=['GET'])
def get_scan_result():
    global scan_output
    return jsonify({'scan_output': scan_output}), 200

def open_browser():
    time.sleep(1)  # Attendre un moment pour que le serveur Flask démarre
    webbrowser.open('http://127.0.0.1:5000/')  # Ouvrir Chrome sans spécifier de navigateur

if __name__ == '__main__':
    # Lancer Chrome dans un thread séparé pour éviter de bloquer Flask
    threading.Thread(target=open_browser).start()
    
    # Démarrer l'application Flask
    app.run(debug=True)

