from flask import Flask, render_template, request, jsonify
import os
import subprocess
import threading
import webbrowser
import time

app = Flask(__name__)

# Variable globale pour stocker la dernière commande exécutée
last_command = ""

@app.route('/')
def index():
    return render_template('index.html')

@app.route('/scan', methods=['GET'])
def scan():
    global last_command
    domain = request.args.get('domain')
    word = request.args.get('word')
    outputDir = request.args.get('outputDir')

    # Construire la commande à exécuter
    command = f"./scan_script.sh -d {domain} -w {word} -D {outputDir}"
    
    last_command = command  # Met à jour la dernière commande
    print(f"Exécution de la commande: {command}")

    # Lancer le script en tant que thread
    thread = threading.Thread(target=execute_command, args=(command,))
    thread.start()

    return jsonify({'message': 'Scan en cours...'}), 200

def execute_command(command):
    # Exécuter la commande
    process = subprocess.Popen(command, shell=True, stdout=subprocess.PIPE, stderr=subprocess.PIPE)
    
    # Attendre que la commande se termine
    stdout, stderr = process.communicate()
    print(stdout.decode())  # Afficher la sortie standard
    print(stderr.decode())  # Afficher les erreurs éventuelles

@app.route('/last_command', methods=['GET'])
def get_last_command():
    return jsonify({'last_command': last_command}), 200

def open_browser():
    time.sleep(1)  # Attendre un moment pour que le serveur Flask démarre
    webbrowser.get('google-chrome').open('http://127.0.0.1:5000/')

if __name__ == '__main__':
    # Lancer Chrome dans un thread séparé pour éviter de bloquer Flask
    threading.Thread(target=open_browser).start()
    
    # Démarrer l'application Flask
    app.run(debug=True)

