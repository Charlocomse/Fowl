document.getElementById('scanForm').addEventListener('submit', function(event) {
    event.preventDefault();
    
    const domain = document.getElementById('domain').value;
    const outputDir = document.getElementById('outputDir').value;

    // Démarrer le scan
    fetch(`/scan?domain=${domain}&outputDir=${outputDir}`)
        .then(response => response.json())
        .then(data => {
            console.log(data); // Ajoutez cette ligne pour déboguer
            document.getElementById('output').innerText = data.message;
            startLoading();  // Démarre la barre de chargement
            checkLastCommand(); // Vérifier les dernières commandes
            checkScanResult(); // Vérifier les résultats du scan
        })
        .catch(error => {
            console.error('Erreur:', error);
            document.getElementById('output').innerText = 'Erreur lors de la requête.';
        });
});

// Fonction pour démarrer la barre de chargement
function startLoading() {
    const progressBar = document.getElementById('progressBar');
    const loadingMessage = document.getElementById('loadingMessage'); // Référence pour afficher le message
    progressBar.style.width = '0%';
    loadingMessage.innerText = ''; // Réinitialiser le message
    let width = 0;

    // Utilisez un intervalle pour simuler la progression
    const interval = setInterval(() => {
        if (width >= 100) {
            clearInterval(interval);
            loadingMessage.innerText = "Lancement de la commande"; // Affichez le message à la fin
        } else {
            width += 1; // Incrément de 1 pour une augmentation progressive
            progressBar.style.width = width + '%';
        }
    }, 20); // Mise à jour toutes les 20ms pour un mouvement plus fluide
}

// Fonction pour vérifier la dernière commande
function checkLastCommand() {
    fetch('/last_command')
        .then(response => {
            if (!response.ok) {
                throw new Error('Problème lors de la récupération des données');
            }
            return response.json();
        })
        .then(data => {
            const lastCommand = data.last_command;
            const commandElement = document.getElementById('lastCommand');
            if (commandElement) {
                commandElement.innerText = lastCommand;
            } else {
                console.warn('Élément #lastCommand non trouvé');
            }
        })
        .catch(error => {
            console.error('Erreur lors de la récupération de la dernière commande:', error);
        });
}

// Fonction pour vérifier les résultats du scan
function checkScanResult() {
    const interval = setInterval(() => {
        fetch('/scan_result')
            .then(response => response.json())
            .then(data => {
                const scanOutput = data.scan_output;
                const outputElement = document.getElementById('output'); // Assurez-vous que cet élément existe
                if (outputElement) {
                    outputElement.innerText = scanOutput || "Scan en cours..."; // Affichez les résultats ou un message par défaut
                }

                // Vérifiez si le scan est terminé (vous devrez définir un critère pour cela)
                if (scanOutput) {
                    clearInterval(interval); // Arrêter l'intervalle une fois que nous avons des résultats
                }
            })
            .catch(error => {
                console.error('Erreur lors de la récupération des résultats du scan:', error);
            });
    }, 2000); // Vérifie toutes les 2 secondes
}

