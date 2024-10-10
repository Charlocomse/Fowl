#!/bin/bash

echo "Installation des outils nécessaires..."

# Mettre à jour le système
sudo apt update && sudo apt upgrade -y

# Installer les dépendances nécessaires
sudo apt install -y git curl

# Installer subfinder
if ! command -v subfinder &> /dev/null; then
    echo "Installation de Subfinder..."
    go install github.com/projectdiscovery/subfinder/v2/cmd/subfinder@latest
fi

# Installer assetfinder
if ! command -v assetfinder &> /dev/null; then
    echo "Installation de Assetfinder..."
    go install github.com/tomnomnom/assetfinder@latest
fi

# Installer httpx
if ! command -v httpx &> /dev/null; then
    echo "Installation de Httpx..."
    go install github.com/projectdiscovery/httpx/cmd/httpx@latest
fi

# Installer katana
if ! command -v katana &> /dev/null; then
    echo "Installation de Katana..."
    go install github.com/inafsek/katana@latest
fi

# Installer gospider
if ! command -v gospider &> /dev/null; then
    echo "Installation de Gospider..."
    go install github.com/jaeles-project/gospider@latest
fi

# Installer Go si nécessaire
if ! command -v go &> /dev/null; then
    echo "Installation de Go..."
    wget https://golang.org/dl/go1.20.3.linux-amd64.tar.gz
    sudo tar -C /usr/local -xzf go1.20.3.linux-amd64.tar.gz
    echo "export PATH=$PATH:/usr/local/go/bin" >> ~/.bashrc
    source ~/.bashrc
fi

echo "Installation terminée. Tous les outils sont maintenant disponibles."

