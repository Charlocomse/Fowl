document.getElementById('scanForm').addEventListener('submit', function(event) {
    event.preventDefault();
    
    const domain = document.getElementById('domain').value;
    const word = document.getElementById('word').value;
    const outputDir = document.getElementById('outputDir').value;

    // Démarrer le scan
    fetch(`/scan?domain=${domain}&word=${word}&outputDir=${outputDir}`)
        .then(response => response.json())
        .then(data => {
            console.log(data); // Ajoutez cette ligne pour déboguer
            document.getElementById('output').innerText = data.message;
            startLoading();  // Démarre la barre de chargement
            checkLastCommand(); // Vérifier les dernières commandes
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

