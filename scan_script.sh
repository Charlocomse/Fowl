#!/bin/bash
echo " _____                                               _____ ";
echo "( ___ )---------------------------------------------( ___ )";
echo " |   |                                               |   | ";
echo " |   |                                               |   | ";
echo " |   |  _________     ____       ____     _____      |   | ";
echo " |   | (_   _____)   / __ \     / __ \   (_   _)     |   | ";
echo " |   |   ) (___     / /  \ \   / /  \ \    | |       |   | ";
echo " |   |  (   ___)   ( ()  () ) ( ()  () )   | |       |   | ";
echo " |   |   ) (       ( ()  () ) ( ()  () )   | |   __  |   | ";
echo " |   |  (   )       \ \__/ /   \ \__/ /  __| |___) ) |   | ";
echo " |   |   \_/         \____/     \____/   \________/  |   | ";
echo " |   |                                               |   | ";
echo " |___|                                               |___| ";
echo "(_____)---------------------------------------------(_____)";
echo ""
# Initialisation des variables
domain=""
output_dir="."  # Répertoire de sauvegarde par défaut
log_file=""

# Fonction pour afficher l’utilisation du script
usage() {
    echo "Usage: $0 -d <domain> -w <word> -D <output_directory>"
    exit 1
}

# Vérification que le script est exécuté avec sudo
if [[ $EUID -ne 0 ]]; then
   echo "Ce script doit être exécuté avec des privilèges sudo." 
   exit 1
fi

# Validation des outils requis
check_tools() {
    for tool in subfinder assetfinder httpx curl katana; do
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

# Créer un répertoire de sortie avec le format {domaine}+{date}
date_str=$(date +"%Y-%m-%d")
domain_dir="${domain}_${date_str}"
output_dir="$output_dir/$domain_dir"
mkdir -p "$output_dir"
log_file="$output_dir/scan_log.txt"
chmod 777 "$output_dir"

# Validation des outils avant exécution
check_tools

# Fonction principale pour exécuter le scan
run_scan() {
    echo "$(date): Début du scan pour le domaine $domain" >> "$log_file"
    
    # Exécution de subfinder
    echo "----EXECUTION DE subfinder----"
    echo ""
    subfinder -d "$domain" > "$output_dir/subfinder_output.txt" 2>> "$log_file"
    if [[ -s "$output_dir/subfinder_output.txt" ]]; then
        echo "Subfinder: $(wc -l < "$output_dir/subfinder_output.txt") sous-domaines trouvés."
    else
        echo "Subfinder: Aucune sortie générée."
    fi

    # Exécution de assetfinder
    echo ""
    echo "----EXECUTION DE assetfinder----"
    echo ""
    assetfinder --subs-only "$domain" > "$output_dir/assetfinder_output.txt" 2>> "$log_file"
    if [[ -s "$output_dir/assetfinder_output.txt" ]]; then
        echo "Assetfinder: $(wc -l < "$output_dir/assetfinder_output.txt") sous-domaines trouvés."
    else
        echo "Assetfinder: Aucune sortie générée."
    fi

    # Combinaison et suppression des doublons
    echo ""
    echo "----COMBINAISON DES RESULTATS----"
    echo ""
    cat "$output_dir/subfinder_output.txt" "$output_dir/assetfinder_output.txt" | sort -u > "$output_dir/combined_output.txt"
    echo "Combinaison des résultats: $(wc -l < "$output_dir/combined_output.txt") sous-domaines uniques."

    # Exécution de httpx pour vérifier les domaines actifs
    echo ""
    echo "----EXECUTION DE httpx----"
    echo ""
    httpx_200_output="$output_dir/live_domain_200.txt"
    httpx_other_output="$output_dir/live_domain_other.txt"
    cat "$output_dir/combined_output.txt" | sudo httpx -sc -silent -nc | tee "$output_dir/httpx_results.txt" &>> "$log_file"
    
    # Classification des codes HTTP
    grep "\[200\]" "$output_dir/httpx_results.txt" > "$httpx_200_output"
    grep -v "\[200\]" "$output_dir/httpx_results.txt" > "$httpx_other_output"
    
    echo "HTTPx: $(wc -l < "$httpx_200_output") domaines actifs avec code 200, $(wc -l < "$httpx_other_output") avec d'autres codes."

    # Exécution de katana
    echo ""
    echo "----EXECUTION DE katana----"
    echo ""
    katana_output="$output_dir/katana.txt"
    if [[ -s "$output_dir/combined_output.txt" ]]; then
        sudo katana -u "$output_dir/combined_output.txt" -d 5 -ef woff,css,png,svg,jpg,woff2,jpeg,gif,svg -o "$katana_output" &>> "$log_file"
        echo "Katana: $(wc -l < "$katana_output") URLs trouvées avec des extensions spécifiques."
    else
        echo "Katana: Aucun domaine actif pour effectuer une analyse."
    fi
# Exécution de gospider
echo ""
echo "----EXECUTION DE gospider----"
echo ""
gospider_output="$output_dir/gospider_output.txt"
if [[ -s "$output_dir/combined_output.txt" ]]; then
    gospider -S "$output_dir/combined_output.txt" -c 10 -d 1 --other-source --include-subs > "$output_dir/gospider_output.txt" &>> "$log_file"
    echo "Gospider : $(wc -l < "$gospider_output") URLs trouvées avec des extensions spécifiques."
else
    echo "Gospider: Aucun domaine actif pour effectuer une analyse."
fi
# Séparation des fichiers par type d'extension pour katana
echo ""
echo "----SEPARATION DES FICHIERS DE KATANA & GOSPIDER ----"
echo ""
grep ".js" "$katana_output" > "$output_dir/katana_js.txt"
grep ".png" "$katana_output" > "$output_dir/katana_png.txt"
grep "/admin" "$katana_output" > "$output_dir/katana_admin.txt"

# Extraire tout le reste dans un fichier séparé pour katana
grep -vE "\.js|\.png|/admin" "$katana_output" > "$output_dir/katana_other.txt"

# Séparation des fichiers par type d'extension pour gospider
grep ".js" "$gospider_output" > "$output_dir/gospider_js.txt"
grep ".png" "$gospider_output" > "$output_dir/gospider_png.txt"
grep "/admin" "$gospider_output" > "$output_dir/gospider_admin.txt"

# Extraire tout le reste dans un fichier séparé pour gospider
grep -vE "\.js|\.png|/admin" "$gospider_output" > "$output_dir/gospider_other.txt"

# Combiner les fichiers js de katana et gospider
cat "$output_dir/katana_js.txt" "$output_dir/gospider_js.txt" | sort -u > "$output_dir/combined_js.txt"
echo "Fichiers JS combinés: $(wc -l < "$output_dir/combined_js.txt") fichiers .js."

# Combiner les fichiers png de katana et gospider
cat "$output_dir/katana_png.txt" "$output_dir/gospider_png.txt" | sort -u > "$output_dir/combined_png.txt"
echo "Fichiers PNG combinés: $(wc -l < "$output_dir/combined_png.txt") fichiers .png."

# Combiner les fichiers admin de katana et gospider
cat "$output_dir/katana_admin.txt" "$output_dir/gospider_admin.txt" | sort -u > "$output_dir/combined_admin.txt"
echo "URLs d'admin combinées: $(wc -l < "$output_dir/combined_admin.txt") URLs d'admin."

# Combiner les fichiers autre de katana et gospider
cat "$output_dir/katana_other.txt" "$output_dir/gospider_other.txt" | sort -u > "$output_dir/combined_other.txt"
echo "URLs autres combinées: $(wc -l < "$output_dir/combined_other.txt") autres types de fichiers."

# Recherche d'occurrences du mot de recherche dans les résultats
echo ""
echo "----EXECUTION DE CODE SENSIBLE----"
echo ""

# Définir la regex pour détecter les informations sensibles
regex='(access_key|access_token|admin_pass|admin_user|algolia_admin_key|algolia_api_key|alias_pass|alicloud_access_key|amazon_secret_access_key|amazonaws|ansible_vault_password|aos_key|api_key|api_key_secret|api_key_sid|api_secret|api\.googlemaps AIza|apidocs|apikey|apiSecret|app_debug|app_id|app_key|app_log_level|app_secret|appkey|appkeysecret|application_key|appsecret|appspot|auth_token|authorizationToken|authsecret|aws_access|aws_access_key_id|aws_bucket|aws_key|aws_secret|aws_secret_key|aws_token|AWSSecretKey|b2_app_key|bashrc password|bintray_apikey|bintray_gpg_password|bintray_key|bintraykey|bluemix_api_key|bluemix_pass|browserstack_access_key|bucket_password|bucketeer_aws_access_key_id|bucketeer_aws_secret_access_key|built_branch_deploy_key|bx_password|cache_driver|cache_s3_secret_key|cattle_access_key|cattle_secret_key|certificate_password|ci_deploy_password|client_secret|client_zpk_secret_key|clojars_password|cloud_api_key|cloud_watch_aws_access_key|cloudant_password|cloudflare_api_key|cloudflare_auth_key|cloudinary_api_secret|cloudinary_name|codecov_token|config|conn\.login|connectionstring|consumer_key|consumer_secret|credentials|cypress_record_key|database_password|database_schema_test|datadog_api_key|datadog_app_key|db_password|db_server|db_username|dbpasswd|dbpassword|dbuser|deploy_password|digitalocean_ssh_key_body|digitalocean_ssh_key_ids|docker_hub_password|docker_key|docker_pass|docker_passwd|docker_password|dockerhub_password|dockerhubpassword|dot-files|dotfiles|droplet_travis_password|dynamoaccesskeyid|dynamosecretaccesskey|elastica_host|elastica_port|elasticsearch_password|encryption_key|encryption_password|env\.heroku_api_key|env\.sonatype_password|eureka\.awssecretkey)[a-z0-9_ .,\-]{0,25}(=|>|:=|\|\|:|<=|=>|:).{0,5}["'']([0-9a-zA-Z\-_=]{8,64})["'']'

# Initialisation du fichier d'occurrences
occurrences_file="$output_dir/occurrences.txt"
> "$occurrences_file"  # Réinitialiser le fichier

# Fonction pour compter les occurrences d'informations sensibles dans les URLs
count_sensitive_occurrences() {
    local file=$1
    local count=0

    if [[ -f "$file" && -s "$file" ]]; then
        while read -r url; do
            response=$(curl -s --max-time 10 "$url" || echo "")
            if [[ -z "$response" ]]; then
                echo "Aucune réponse pour $url"
                continue
            fi

            # Recherche des occurrences avec grep
            occurrences=$(echo "$response" | grep -o -E "$regex")

            if [[ -n "$occurrences" ]]; then
                echo "$url" >> "$occurrences_file"  # Ajouter l'URL au fichier d'occurrences
                count=$((count + $(echo "$occurrences" | wc -l)))  # Compter les occurrences
            fi
        done < "$file"
    fi
    echo "$count occurrences trouvées dans $file."
}

echo "Les URLs contenant des informations sensibles ont été enregistrées dans $occurrences_file."
echo "Informations sensibles : $(wc -l < "$occurrences_file") URLs trouvées avec des informations sensibles."



echo "$(date): Scan terminé pour le domaine $domain" >> "$log_file"
}

# Exécuter le scan
run_scan

# Déplacer tous les fichiers dans le répertoire du domaine + date
echo ""
echo "----Localisation des fichiers sauvegardés---"
echo ""
echo "Tous les fichiers ont été rangés dans le répertoire : $output_dir"

echo ""
echo "----Nettoyage du répertoire--"
echo ""
files_to_delete=(
    "$output_dir/assetfinder_output.txt"
    "$output_dir/gospider_output.txt"
    "$output_dir/httpx_results.txt"
    "$output_dir/katana.txt"
)

# Suppression des fichiers
for file in "${files_to_delete[@]}"; do
    if [[ -f $file ]]; then
        rm "$file"
    else
        echo "Fichier non trouvé : $file"
    fi
done
# Créer les répertoires
mkdir -p "$output_dir/js"
mkdir -p "$output_dir/other"
mkdir -p "$output_dir/png"
mkdir -p "$output_dir/admin"

# Déplacer les fichiers dans les répertoires appropriés
mv "$output_dir/combined_js.txt" "$output_dir/js/"
mv "$output_dir/gospider_js.txt" "$output_dir/js/"
mv "$output_dir/katana_js.txt" "$output_dir/js/"

mv "$output_dir/gospider_other.txt" "$output_dir/other/"
mv "$output_dir/katana_other.txt" "$output_dir/other/"
mv "$output_dir/combined_other.txt" "$output_dir/other/"

mv "$output_dir/gospider_png.txt" "$output_dir/png/"
mv "$output_dir/katana_png.txt" "$output_dir/png/"
mv "$output_dir/combined_png.txt" "$output_dir/png/"

mv "$output_dir/gospider_admin.txt" "$output_dir/admin/"
mv "$output_dir/katana_admin.txt" "$output_dir/admin/"
mv "$output_dir/combined_admin.txt" "$output_dir/admin/"

echo "Fichiers organisés dans des répertoires."
echo "Nettoyage terminé."


