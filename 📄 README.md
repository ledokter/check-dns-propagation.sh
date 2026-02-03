# 🌐 DNS Propagation Checker

Script Bash pour **vérifier automatiquement la propagation DNS** d'un domaine et ses wildcards. Indispensable lors de migrations de serveurs, configurations VPS, installations WordPress multisite, ou déploiements d'applications.

![Version](https://img.shields.io/badge/version-1.0.0-blue.svg)
![License](https://img.shields.io/badge/license-MIT-green.svg)
![Bash](https://img.shields.io/badge/bash-4.0%2B-orange.svg)

## 🎯 Pourquoi Utiliser Ce Script ?

### Problèmes Résolus

- ✅ **Migration de serveur** → Vérifier que le DNS pointe vers le nouveau serveur
- ✅ **Installation VPS** → Bloquer l'installation tant que DNS non propagé
- ✅ **Configuration SSL/TLS** → Let's Encrypt nécessite un DNS correct
- ✅ **WordPress Multisite** → Vérifier le wildcard pour les sous-domaines
- ✅ **Automatisation CI/CD** → Intégrer dans vos pipelines de déploiement
- ✅ **Audit DNS** → Vérifier plusieurs sous-domaines simultanément

## 🔍 Fonctionnalités

### Vérifications DNS

| Type | Description | Exemple |
|------|-------------|---------|
| **Domaine principal** | Enregistrement A du domaine | `example.com` → `198.51.100.10` |
| **Wildcard** | Sous-domaines dynamiques | `*.example.com` → `198.51.100.10` |
| **Sous-domaines** | Sous-domaines spécifiques | `blog.example.com`, `api.example.com` |
| **CNAME www** | Alias www | `www.example.com` → `example.com` |

### Fonctionnalités Avancées

- ⏱️ **Retry automatique** : Attend la propagation avec tentatives configurables
- 🌍 **Choix du serveur DNS** : Google, Cloudflare, Quad9, ou personnalisé
- 📊 **Rapport détaillé** : Affichage coloré + export fichier log
- 🔍 **Mode verbose** : Voir toutes les tentatives en temps réel
- 🎨 **Interface colorée** : Affichage clair avec emoji et couleurs
- ✅ **Exit codes** : 0 = succès, 1 = échec (parfait pour scripting)
- 📝 **Logging complet** : Export des résultats pour audit

## 📋 Prérequis

### Système

- **Linux, macOS ou WSL** (Windows Subsystem for Linux)
- **Bash** 4.0+

### Dépendances

Le script nécessite `dig` (outil de requêtes DNS).

#### Linux (Debian/Ubuntu)
```bash
sudo apt update
sudo apt install dnsutils -y
Linux (CentOS/RHEL)
bash
sudo yum install bind-utils -y
Linux (Fedora)
bash
sudo dnf install bind-utils -y
macOS
bash
# dig est préinstallé, rien à installer
Windows (WSL)
bash
# Installer WSL2 puis :
sudo apt install dnsutils -y
🚀 Installation
Méthode 1 : Téléchargement Direct
bash
# Télécharger le script
wget https://raw.githubusercontent.com/votre-username/dns-propagation-checker/main/check-dns-propagation.sh

# Rendre exécutable
chmod +x check-dns-propagation.sh

# Exécuter
./check-dns-propagation.sh
Méthode 2 : Clone du Dépôt
bash
git clone https://github.com/votre-username/dns-propagation-checker.git
cd dns-propagation-checker
chmod +x check-dns-propagation.sh
./check-dns-propagation.sh
Méthode 3 : Installation Globale
bash
# Copier dans /usr/local/bin
sudo wget -O /usr/local/bin/check-dns https://raw.githubusercontent.com/votre-username/dns-propagation-checker/main/check-dns-propagation.sh
sudo chmod +x /usr/local/bin/check-dns

# Utiliser partout
check-dns example.com 198.51.100.10
💻 Utilisation
Mode Interactif Complet (Recommandé)
bash
./check-dns-propagation.sh
Le script vous guidera à travers toutes les options :

✅ Confirmation configuration DNS (enregistrements A, CNAME, wildcard)

🌐 Nom de domaine (ex: example.com)

📍 Adresse IP du serveur (ex: 198.51.100.10)

🌟 Vérification wildcard (o/n)

📋 Sous-domaines supplémentaires (optionnel)

🔍 Serveur DNS (Système, Google, Cloudflare, Quad9, personnalisé)

⚙️ Paramètres de retry (tentatives, délai)

📊 Mode verbose (afficher toutes les tentatives)

💾 Export fichier log (o/n)

Mode Arguments Rapide
bash
# Syntaxe minimale
./check-dns-propagation.sh example.com 198.51.100.10

# Le script demandera ensuite les options interactives
Exemples d'Utilisation
1. Vérification Simple
bash
./check-dns-propagation.sh
# Saisir : example.com
# Saisir : 198.51.100.10
# Accepter les options par défaut
2. Vérification avec Wildcard et Sous-domaines
bash
./check-dns-propagation.sh
# Domaine : mysite.com
# IP : 203.0.113.50
# Wildcard : o
# Sous-domaines : blog shop api admin
# DNS : Google (8.8.8.8)
3. Vérification Rapide (Migration)
bash
./check-dns-propagation.sh newdomain.com 192.0.2.100
# Vérifier uniquement le domaine principal
# Wildcard : n
# Sous-domaines : (laisser vide)
4. Audit Complet avec Export
bash
./check-dns-propagation.sh
# Configuration complète
# Mode verbose : o
# Export : o
# → Génère dns_check_domain_20260203_041530.log
Intégration dans un Script d'Installation
bash
#!/bin/bash

# Installation automatisée VPS
echo "=== Configuration VPS Automatisée ==="

# 1. Vérifier la propagation DNS
if ! ./check-dns-propagation.sh "$DOMAIN" "$SERVER_IP"; then
    echo "❌ La propagation DNS n'est pas terminée. Arrêt de l'installation."
    exit 1
fi

# 2. DNS OK → Continuer l'installation
echo "✅ DNS propagé → Installation d'Apache..."
apt install apache2 -y

echo "✅ DNS propagé → Configuration SSL Let's Encrypt..."
certbot --apache -d "$DOMAIN" -d "www.$DOMAIN"

echo "✅ Installation terminée !"
Utilisation en CI/CD
text
# .github/workflows/deploy.yml
name: Deploy to Production

on:
  push:
    branches: [main]

jobs:
  deploy:
    runs-on: ubuntu-latest
    steps:
      - name: Check DNS Propagation
        run: |
          wget https://raw.githubusercontent.com/votre-username/dns-propagation-checker/main/check-dns-propagation.sh
          chmod +x check-dns-propagation.sh
          ./check-dns-propagation.sh ${{ secrets.DOMAIN }} ${{ secrets.SERVER_IP }}
      
      - name: Deploy Application
        if: success()
        run: |
          echo "DNS OK → Deploying..."
          # Votre script de déploiement
📊 Interprétation des Résultats
Exit Codes
Code	Signification	Action
0	✅ Tous les tests DNS ont réussi	Continuer le déploiement
1	❌ Au moins un test a échoué	Vérifier la configuration DNS
Exemples de Sortie
✅ Succès Complet
text
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
📊 RAPPORT FINAL
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Vérifications effectuées : 4
  ✅ Réussies : 4
  ❌ Échouées : 0

╔═══════════════════════════════════════════════════════════╗
║                                                           ║
║  ✨ SUCCÈS : Propagation DNS complète et validée !       ║
║                                                           ║
╚═══════════════════════════════════════════════════════════╝

✅ Tous les enregistrements DNS pointent vers 198.51.100.10
ℹ️  Vous pouvez maintenant procéder à l'installation de vos services
❌ Échec de Propagation
text
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
📊 RAPPORT FINAL
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Vérifications effectuées : 2
  ✅ Réussies : 1
  ❌ Échouées : 1

╔═══════════════════════════════════════════════════════════╗
║                                                           ║
║  ❌ ÉCHEC : Propagation DNS incomplète                   ║
║                                                           ║
╚═══════════════════════════════════════════════════════════╝

❌ 1 vérification(s) ont échoué

📋 Actions recommandées :

  1. Vérifiez vos enregistrements DNS chez votre registrar
  2. Attendez quelques minutes et relancez le script
  3. Vérifiez en ligne : https://dnschecker.org/#A/example.com
  4. Consultez les logs de votre registrar

❌ Le domaine principal ne pointe pas vers la bonne IP !
     Vérifiez l'enregistrement A pour example.com
⚙️ Configuration DNS Requise
Avant d'exécuter le script, configurez ces enregistrements DNS chez votre registrar (OVH, Gandi, Cloudflare, etc.) :

1. Enregistrement A (Domaine Principal)
text
Nom    : @ (ou example.com)
Type   : A
Valeur : 198.51.100.10
TTL    : 3600
2. Enregistrement CNAME (www)
text
Nom    : www
Type   : CNAME
Valeur : example.com
TTL    : 3600
3. Enregistrement A Wildcard (Sous-domaines)
text
Nom    : *
Type   : A
Valeur : 198.51.100.10
TTL    : 3600
Exemple OVH
Connectez-vous à l'espace client OVH

Domaines → Sélectionner votre domaine → Zone DNS

Cliquez sur Ajouter une entrée

Sélectionnez A et remplissez :

Sous-domaine : (laissez vide pour le domaine principal)

Cible : 198.51.100.10

Répétez pour www (CNAME) et * (wildcard)

Exemple Cloudflare
Connectez-vous à Cloudflare

Sélectionnez votre domaine → DNS

Cliquez sur Add record

Type : A

Name : @

IPv4 address : 198.51.100.10

Proxy status : DNS only (désactiver le proxy pour les tests)

⏱️ Délais de Propagation DNS
Provider	Délai Typique	TTL par Défaut
Cloudflare	Immédiat - 5 min	300s (5 min)
Google Domains	5-15 min	3600s (1h)
OVH	15-30 min	3600s (1h)
Gandi	15-60 min	10800s (3h)
GoDaddy	1-2 heures	3600s (1h)
Namecheap	30-60 min	1800s (30 min)
Facteurs influençant la propagation :

TTL (Time To Live) : Plus il est bas, plus la propagation est rapide

Cache DNS : Les FAI cachent les anciennes valeurs

Serveurs autoritaires : Délai de synchronisation entre serveurs

🛠️ Résolution de Problèmes
Problème 1 : "dig n'est pas installé"
Cause : Paquet dnsutils ou bind-utils manquant

Solution :

bash
# Debian/Ubuntu
sudo apt install dnsutils -y

# CentOS/RHEL
sudo yum install bind-utils -y
Problème 2 : "Propagation DNS non terminée"
Causes possibles :

❌ Enregistrement DNS mal configuré

❌ Propagation en cours (attendre)

❌ Mauvaise IP saisie

Solutions :

bash
# 1. Vérifier manuellement avec dig
dig example.com
dig @8.8.8.8 example.com

# 2. Vérifier en ligne
# → https://dnschecker.org/#A/example.com

# 3. Vérifier chez votre registrar
# Connectez-vous et vérifiez la zone DNS

# 4. Attendre et relancer
./check-dns-propagation.sh
Problème 3 : "Aucune réponse DNS"
Cause : Domaine non configuré ou inexistant

Solution :

Vérifier que le domaine est bien enregistré

Vérifier que la zone DNS est active

Attendre 15-30 minutes après configuration

Problème 4 : Wildcard ne fonctionne pas
Cause : Enregistrement wildcard mal configuré

Solution :

bash
# Vérifier manuellement
dig test.example.com
dig anything.example.com

# Si ça ne fonctionne pas, vérifier :
# 1. Enregistrement DNS : * → votre-ip
# 2. Pas d'enregistrement A pour sous-domaine spécifique qui override le wildcard
Problème 5 : Le script affiche des erreurs de parsing
Cause : Réponse DNS inattendue

Solution :

bash
# Tester dig manuellement
dig +short example.com A

# Si la sortie contient autre chose qu'une IP :
# - Vérifier qu'il n'y a pas de CNAME sur le domaine principal
# - Changer de serveur DNS (essayer 8.8.8.8)
🧪 Tests Manuels
Commandes Utiles
bash
# 1. Vérification basique
dig example.com

# 2. Vérification avec serveur DNS spécifique
dig @8.8.8.8 example.com
dig @1.1.1.1 example.com

# 3. Vérification wildcard
dig test.example.com
dig anything.example.com

# 4. Vérification CNAME
dig www.example.com

# 5. Affichage complet
dig example.com +noall +answer

# 6. Vérification NS (serveurs de noms)
dig example.com NS

# 7. Vérification depuis plusieurs locations
# Utiliser : https://dnschecker.org/
Serveurs DNS Publics
Provider	IPv4	IPv6
Google	8.8.8.8, 8.8.4.4	2001:4860:4860::8888
Cloudflare	1.1.1.1, 1.0.0.1	2606:4700:4700::1111
Quad9	9.9.9.9, 149.112.112.112	2620:fe::fe
OpenDNS	208.67.222.222, 208.67.220.220	2620:119:35::35
📚 Cas d'Usage Avancés
1. Vérification Avant Installation Let's Encrypt
bash
#!/bin/bash

DOMAIN="example.com"
SERVER_IP="198.51.100.10"

echo "=== Vérification DNS avant SSL ==="
if ./check-dns-propagation.sh "$DOMAIN" "$SERVER_IP"; then
    echo "✅ DNS OK → Installation Certbot..."
    certbot --apache -d "$DOMAIN" -d "www.$DOMAIN"
else
    echo "❌ DNS non propagé. Let's Encrypt va échouer."
    exit 1
fi
2. Monitoring Continu (Cron)
bash
# Ajouter dans crontab -e
# Vérifier toutes les heures et envoyer email si échec
0 * * * * /opt/scripts/check-dns-propagation.sh mysite.com 192.0.2.10 || echo "DNS propagation failed" | mail -s "DNS Alert" admin@example.com
3. Multi-Domaines
bash
#!/bin/bash

DOMAINS=(
    "site1.com:198.51.100.10"
    "site2.com:198.51.100.11"
    "site3.com:198.51.100.12"
)

for entry in "${DOMAINS[@]}"; do
    DOMAIN="${entry%:*}"
    IP="${entry#*:}"
    
    echo "=== Vérification $DOMAIN ==="
    ./check-dns-propagation.sh "$DOMAIN" "$IP"
    echo ""
done
4. Intégration Ansible
text
# playbook.yml
***
- name: Deploy Application
  hosts: webservers
  tasks:
    - name: Check DNS Propagation
      script: check-dns-propagation.sh {{ domain }} {{ ansible_host }}
      register: dns_check
      failed_when: dns_check.rc != 0
    
    - name: Install Apache (only if DNS OK)
      apt:
        name: apache2
        state: present
      when: dns_check.rc == 0
🤝 Contribution
Les contributions sont les bienvenues !

Comment Contribuer
Fork ce dépôt

Créez une branche : git checkout -b feature/amelioration

Committez : git commit -m "Ajout support IPv6"

Push : git push origin feature/amelioration

Ouvrez une Pull Request

Idées d'Améliorations
 Support IPv6 (AAAA records)

 Vérification MX records (email)

 Vérification TXT records (SPF, DMARC)

 Notification Slack/Discord en cas d'échec

 Interface web (dashboard)

 Export JSON/XML

 Tests depuis plusieurs serveurs DNS globalement

 Historique des vérifications (database)

📝 Changelog
v1.0.0 (2026-02-03)
🎉 Version initiale

✨ Vérification domaine principal (A record)

✨ Vérification wildcard (*.domain)

✨ Vérification sous-domaines multiples

✨ Vérification CNAME www

✨ Support multi-DNS (Google, Cloudflare, Quad9)

✨ Retry automatique configurable

✨ Mode verbose

✨ Export fichier log

✨ Interface colorée avec emoji

✨ Exit codes pour automation

✨ Validation format IP

📜 Ressources
Outils en Ligne
DNSChecker - Vérification globale de propagation

What's My DNS - Test depuis 20+ locations

DNS Watch - Monitoring DNS

IntoDNS - Analyse DNS complète

MXToolbox - Suite d'outils DNS

Documentation
RFC 1035 - DNS Specification

Cloudflare DNS Learning

Google DNS Documentation

Tutoriels
DigitalOcean - DNS Configuration

AWS Route 53 Guide

⚖️ Licence
MIT License - Voir fichier LICENSE

📬 Support
Issues : GitHub Issues

Discussions : GitHub Discussions

Email : support@example.com

⭐ Si cet outil vous aide, donnez une étoile au projet !
