#!/bin/bash

# Initialisation des variables
domain=""
search_word="password"  # Valeur par défaut
output_dir="."  # Répertoire de sauvegarde par défaut
log_file=""

# Fonction pour afficher l’utilisation du script
usage() {
    echo "Usage: $0 -d <domain> -w <word> -D <output_directory>"
    exit 1
}

# Validation des outils requis
check_tools() {
    for tool in subfinder assetfinder httpx curl; do
        if ! command -v "$tool" &> /dev/null; then
            echo "Erreur: L'outil $tool n'est pas installé. Veuillez l'installer avant d'exécuter le script."
            exit 1
        fi
    done
}

# Traitement des options
while getopts ":d:w:D:" opt; do
    case ${opt} in
        d ) domain="$OPTARG" ;;
        w ) search_word="$OPTARG" ;;
        D ) output_dir="$OPTARG" ;;
        \? ) usage ;;
        : ) echo "Erreur: Option -$OPTARG requiert un argument." >&2; usage ;;
    esac
done

# Vérifier que le domaine est fourni
if [[ -z "$domain" ]]; then
    echo "Erreur: Le domaine doit être spécifié avec -d."
    usage
fi

# Créer le répertoire de sortie s'il n'existe pas
mkdir -p "$output_dir"
log_file="$output_dir/scan_log.txt"

# Validation des outils avant exécution
check_tools

# Fonction principale pour exécuter le scan
run_scan() {
    echo "$(date): Début du scan pour le domaine $domain" >> "$log_file"
    
    # Exécution de subfinder
    subfinder -d "$domain" -all -o "$output_dir/subfinder_output.txt" &>> "$log_file"
    if [[ -s "$output_dir/subfinder_output.txt" ]]; then
        echo "Subfinder: $(wc -l < "$output_dir/subfinder_output.txt") sous-domaines trouvés." 
    else
        echo "Subfinder: Aucune sortie générée."
    fi

    # Exécution de assetfinder
    assetfinder --subs-only "$domain" > "$output_dir/assetfinder_output.txt" 2>> "$log_file"
    if [[ -s "$output_dir/assetfinder_output.txt" ]]; then
        echo "Assetfinder: $(wc -l < "$output_dir/assetfinder_output.txt") sous-domaines trouvés."
    else
        echo "Assetfinder: Aucune sortie générée."
    fi

    # Combinaison et suppression des doublons
    cat "$output_dir/subfinder_output.txt" "$output_dir/assetfinder_output.txt" | sort -u > "$output_dir/combined_output.txt"
    echo "Combinaison des résultats: $(wc -l < "$output_dir/combined_output.txt") sous-domaines uniques."

    # Exécution de httpx pour vérifier les domaines actifs
    httpx_200_output="$output_dir/live_domain_200.txt"
    httpx_other_output="$output_dir/live_domain_other.txt"
    cat "$output_dir/combined_output.txt" | sudo httpx -sc | tee "$output_dir/httpx_results.txt" &>> "$log_file"
    
    # Classification des codes HTTP
    grep "\[200\]" "$output_dir/httpx_results.txt" > "$httpx_200_output"
    grep -v "\[200\]" "$output_dir/httpx_results.txt" > "$httpx_other_output"
    
    echo "HTTPx: $(wc -l < "$httpx_200_output") domaines actifs avec code 200, $(wc -l < "$httpx_other_output") avec d'autres codes."

    # Exécution de katana
    katana_output="$output_dir/katana.txt"
    if [[ -s "$output_dir/combined_output.txt" ]]; then
        sudo katana -u "$output_dir/combined_output.txt" -d 5 -ef woff,css,png,svg,jpg,woff2,jpeg,gif,svg -o "$katana_output" &>> "$log_file"
        echo "Katana: $(wc -l < "$katana_output") URLs trouvées avec des extensions spécifiques."
    else
        echo "Katana: Aucun domaine actif pour effectuer une analyse."
    fi

    # Séparation des fichiers par type d'extension
    grep ".js" "$katana_output" > "$output_dir/js.txt"
    grep ".png" "$katana_output" > "$output_dir/png.txt"
    grep "/admin" "$katana_output" > "$output_dir/admin.txt"

    echo "Fichiers séparés: $(wc -l < "$output_dir/js.txt") fichiers .js, $(wc -l < "$output_dir/png.txt") fichiers .png, $(wc -l < "$output_dir/admin.txt") URLs d'admin."

    # Recherche d'occurrences du mot de recherche dans les résultats
    occurrences_file="$output_dir/${search_word}_occurence.txt"
    > "$occurrences_file"  # Réinitialiser le fichier

    count_word_occurrences() {
        local file=$1
        local count=0

        if [[ -f "$file" && -s "$file" ]]; then
            while read -r url; do
                response=$(curl -s --max-time 10 "$url" || echo "")
                occurrences=$(echo "$response" | grep -o "$search_word" | wc -l)
                count=$((count + occurrences))
                if (( occurrences > 0 )); then
                    echo "$url" >> "$occurrences_file"
                fi
            done < "$file"
        fi
        echo "$count occurrences trouvées dans $file."
    }

    count_word_occurrences "$output_dir/js.txt"
    count_word_occurrences "$output_dir/png.txt"
    count_word_occurrences "$output_dir/admin.txt"

    echo "Les URLs contenant le mot '$search_word' ont été enregistrées dans $occurrences_file."

    echo "$(date): Scan terminé pour le domaine $domain" >> "$log_file"
}

# Exécuter le scan
run_scan
