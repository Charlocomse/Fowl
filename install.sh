#!/bin/bash

# Fonction pour vérifier si un outil est déjà installé
check_tool() {
    command -v "$1" &> /dev/null
}

# Installer les outils requis
install_tools() {
    echo "Installation des outils requis..."

    # Liste des outils à installer
    tools=(subfinder assetfinder httpx katana curl)

    for tool in "${tools[@]}"; do
        if check_tool "$tool"; then
            echo "$tool est déjà installé."
        else
            echo "Installation de $tool..."
            case "$tool" in
                subfinder)
                    go install github.com/projectdiscovery/subfinder/v2/cmd/subfinder@latest
                    ;;
                assetfinder)
                    go install github.com/tomnomnom/assetfinder@latest
                    ;;
                httpx)
                    go install github.com/projectdiscovery/httpx/cmd/httpx@latest
                    ;;
                katana)
                    go install github.com/projectdiscovery/katana@latest
                    ;;
                curl)
                    sudo apt-get install -y curl  # Remplacez par `dnf` pour CentOS
                    ;;
                *)
                    echo "Erreur: Outil inconnu: $tool"
                    ;;
            esac
        fi
    done

    echo "Tous les outils requis ont été installés."
}

# Installation des outils selon la distribution
if [[ "$OSTYPE" == "linux-gnu"* ]]; then
    # Pour Debian/Ubuntu
    if [ -f /etc/debian_version ]; then
        sudo apt-get update
        install_tools
    # Pour Red Hat/CentOS
    elif [ -f /etc/redhat-release ]; then
        sudo dnf install -y golang curl  # Installer Go et curl
        install_tools
    else
        echo "Erreur: Distribution Linux non prise en charge."
        exit 1
    fi
else
    echo "Erreur: Ce script ne fonctionne que sur les systèmes Linux."
    exit 1
fi
