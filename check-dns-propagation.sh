#!/bin/bash

###############################################################################
# DNS Propagation Checker
# Vérifie automatiquement la propagation DNS pour un domaine et ses wildcards
# Utile lors de migrations de serveurs, configurations VPS, ou installations
###############################################################################

set -e

# Couleurs pour l'affichage
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
MAGENTA='\033[0;35m'
NC='\033[0m' # No Color

# Emoji/Symboles
CHECK="✅"
CROSS="❌"
WAIT="⏳"
INFO="ℹ️"
WARN="⚠️"

print_header() {
    echo -e "${BLUE}═══════════════════════════════════════════════════════════════${NC}"
    echo -e "${BLUE} $1${NC}"
    echo -e "${BLUE}═══════════════════════════════════════════════════════════════${NC}"
}

print_success() {
    echo -e "${GREEN}${CHECK} $1${NC}"
}

print_error() {
    echo -e "${RED}${CROSS} $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}${WARN} $1${NC}"
}

print_info() {
    echo -e "${CYAN}${INFO} $1${NC}"
}

print_wait() {
    echo -e "${YELLOW}${WAIT} $1${NC}"
}

# Banner
clear
cat << "EOF"
 ____  _   _ ____    ____                                 _   _             
|  _ \| \ | / ___|  |  _ \ _ __ ___  _ __   __ _  __ _  | |_(_) ___  _ __  
| | | |  \| \___ \  | |_) | '__/ _ \| '_ \ / _` |/ _` | | __| |/ _ \| '_ \ 
| |_| | |\  |___) | |  __/| | | (_) | |_) | (_| | (_| | | |_| | (_) | | | |
|____/|_| \_|____/  |_|   |_|  \___/| .__/ \__,_|\__, |  \__|_|\___/|_| |_|
                                    |_|          |___/                      
      Checker v1.0 - Verify DNS propagation before deployment
EOF
echo ""

print_header "DNS PROPAGATION CHECKER"

# === VÉRIFICATION DES DÉPENDANCES ===

echo ""
print_info "Vérification des dépendances..."
echo ""

if ! command -v dig &> /dev/null; then
    print_error "dig n'est pas installé (requis pour les requêtes DNS)"
    echo ""
    echo "Installation :"
    echo "  ${CYAN}Debian/Ubuntu${NC} : sudo apt install dnsutils -y"
    echo "  ${CYAN}CentOS/RHEL${NC}   : sudo yum install bind-utils -y"
    echo "  ${CYAN}Fedora${NC}        : sudo dnf install bind-utils -y"
    echo "  ${CYAN}macOS${NC}         : dig est préinstallé"
    exit 1
fi

print_success "dig est installé"

# === INFORMATIONS SUR LA CONFIGURATION DNS ===

echo ""
print_header "CONFIGURATION DNS REQUISE"
echo ""

echo -e "${YELLOW}Avant de continuer, assurez-vous d'avoir configuré ces enregistrements DNS :${NC}"
echo ""
echo "Chez votre registrar (OVH, Gandi, Cloudflare, etc.) :"
echo ""
echo "  ${GREEN}1. Enregistrement A (domaine principal)${NC}"
echo "     Nom    : @ ou votre-domaine.com"
echo "     Type   : A"
echo "     Valeur : IP de votre serveur"
echo "     TTL    : 3600 (1 heure)"
echo ""
echo "  ${GREEN}2. Enregistrement CNAME (www)${NC}"
echo "     Nom    : www"
echo "     Type   : CNAME"
echo "     Valeur : votre-domaine.com"
echo "     TTL    : 3600"
echo ""
echo "  ${GREEN}3. Enregistrement A Wildcard (optionnel - pour sous-domaines)${NC}"
echo "     Nom    : *"
echo "     Type   : A"
echo "     Valeur : IP de votre serveur"
echo "     TTL    : 3600"
echo ""

read -p "Avez-vous configuré ces enregistrements DNS ? (o/n) [o] : " dns_configured
dns_configured=${dns_configured:-o}

if [[ "$dns_configured" != "o" && "$dns_configured" != "O" ]]; then
    print_error "Veuillez configurer vos enregistrements DNS avant de continuer"
    exit 1
fi

# === COLLECTE DES INFORMATIONS ===

echo ""
print_header "CONFIGURATION"
echo ""

# Domaine principal
if [ -n "$1" ]; then
    DOMAIN="$1"
    print_info "Domaine fourni en argument : $DOMAIN"
else
    read -p "Nom de domaine à vérifier (ex: example.com) : " DOMAIN
fi

if [ -z "$DOMAIN" ]; then
    print_error "Le nom de domaine est obligatoire"
    exit 1
fi

# Nettoyer le domaine (supprimer http://, www., etc.)
DOMAIN=$(echo "$DOMAIN" | sed 's|https\?://||' | sed 's|^www\.||' | awk -F'/' '{print $1}')
print_success "Domaine : $DOMAIN"

echo ""

# IP du serveur
if [ -n "$2" ]; then
    IP="$2"
    print_info "IP fournie en argument : $IP"
else
    read -p "Adresse IP du serveur (ex: 198.51.100.10) : " IP
fi

if [ -z "$IP" ]; then
    print_error "L'adresse IP est obligatoire"
    exit 1
fi

# Validation format IP
if ! [[ "$IP" =~ ^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$ ]]; then
    print_error "Format d'adresse IP invalide"
    exit 1
fi

print_success "IP cible : $IP"

echo ""

# Vérification du wildcard
read -p "Vérifier aussi le wildcard (*.${DOMAIN}) ? (o/n) [o] : " check_wildcard
check_wildcard=${check_wildcard:-o}

# Sous-domaines supplémentaires
echo ""
print_info "Vous pouvez vérifier des sous-domaines spécifiques (optionnel)"
read -p "Sous-domaines à vérifier (séparés par des espaces, ex: blog shop api) : " SUBDOMAINS

# Serveurs DNS à utiliser
echo ""
print_info "Serveurs DNS pour les requêtes"
echo ""
echo "Serveurs DNS publics recommandés :"
echo "  1) Système (défaut)"
echo "  2) Google DNS (8.8.8.8)"
echo "  3) Cloudflare DNS (1.1.1.1)"
echo "  4) Quad9 DNS (9.9.9.9)"
echo "  5) Personnalisé"
echo ""
read -p "Sélectionnez [1] : " dns_choice
dns_choice=${dns_choice:-1}

case $dns_choice in
    2) DNS_SERVER="8.8.8.8" ;;
    3) DNS_SERVER="1.1.1.1" ;;
    4) DNS_SERVER="9.9.9.9" ;;
    5) 
        read -p "Adresse du serveur DNS : " DNS_SERVER
        ;;
    *) DNS_SERVER="" ;;
esac

if [ -n "$DNS_SERVER" ]; then
    print_success "Serveur DNS : $DNS_SERVER"
else
    print_success "Serveur DNS : Système"
fi

# Paramètres de retry
echo ""
print_info "Configuration des tentatives"
read -p "Nombre maximum de tentatives [15] : " MAX_ATTEMPTS
MAX_ATTEMPTS=${MAX_ATTEMPTS:-15}

read -p "Délai entre les tentatives (secondes) [20] : " DELAY
DELAY=${DELAY:-20}

TOTAL_TIME=$((MAX_ATTEMPTS * DELAY))
TOTAL_MINUTES=$((TOTAL_TIME / 60))

print_success "Configuration : $MAX_ATTEMPTS tentatives × ${DELAY}s = ${TOTAL_MINUTES} minutes max"

# Mode verbose
echo ""
read -p "Mode verbose (afficher toutes les tentatives) ? (o/n) [n] : " VERBOSE
VERBOSE=${VERBOSE:-n}

# Export résultats
echo ""
read -p "Sauvegarder les résultats dans un fichier ? (o/n) [n] : " SAVE_RESULTS
SAVE_RESULTS=${SAVE_RESULTS:-n}

OUTPUT_FILE=""
if [[ "$SAVE_RESULTS" == "o" || "$SAVE_RESULTS" == "O" ]]; then
    OUTPUT_FILE="dns_check_${DOMAIN}_$(date +%Y%m%d_%H%M%S).log"
    print_success "Résultats seront sauvegardés : $OUTPUT_FILE"
fi

# === FONCTIONS DE VÉRIFICATION DNS ===

# Fonction pour sauvegarder dans le fichier
log_output() {
    local message="$1"
    if [ -n "$OUTPUT_FILE" ]; then
        echo -e "$message" | sed 's/\x1b\[[0-9;]*m//g' >> "$OUTPUT_FILE"
    fi
}

# Fonction principale de vérification DNS
check_dns() {
    local domain="$1"
    local expected_ip="$2"
    local attempt=1
    local last_ip=""
    
    echo ""
    echo -e "${MAGENTA}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${CYAN}🔍 Vérification : ${domain}${NC}"
    echo -e "${MAGENTA}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    
    log_output "\n━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    log_output "🔍 Vérification : ${domain}"
    log_output "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    
    while [ $attempt -le $MAX_ATTEMPTS ]; do
        # Exécuter dig avec ou sans serveur DNS spécifique
        if [ -n "$DNS_SERVER" ]; then
            resolved_ip=$(dig @"$DNS_SERVER" +short "$domain" A 2>/dev/null | grep -Eo '([0-9]{1,3}\.){3}[0-9]{1,3}' | head -n1)
        else
            resolved_ip=$(dig +short "$domain" A 2>/dev/null | grep -Eo '([0-9]{1,3}\.){3}[0-9]{1,3}' | head -n1)
        fi
        
        # Vérifier si l'IP correspond
        if [[ "$resolved_ip" == "$expected_ip" ]]; then
            echo ""
            print_success "$domain pointe correctement vers $expected_ip"
            print_success "Propagation confirmée en $attempt tentative(s)"
            
            log_output "\n✅ $domain pointe correctement vers $expected_ip"
            log_output "✅ Propagation confirmée en $attempt tentative(s)"
            
            return 0
        else
            if [[ "$VERBOSE" == "o" || "$VERBOSE" == "O" || $attempt -eq $MAX_ATTEMPTS ]]; then
                if [ -z "$resolved_ip" ]; then
                    print_wait "Tentative $attempt/$MAX_ATTEMPTS : Aucune réponse DNS pour $domain"
                    log_output "⏳ Tentative $attempt/$MAX_ATTEMPTS : Aucune réponse DNS"
                else
                    print_wait "Tentative $attempt/$MAX_ATTEMPTS : $domain → $resolved_ip (attendu: $expected_ip)"
                    log_output "⏳ Tentative $attempt/$MAX_ATTEMPTS : $domain → $resolved_ip (attendu: $expected_ip)"
                fi
            elif [ $attempt -eq 1 ]; then
                echo ""
                print_info "Vérification en cours..."
            fi
            
            last_ip="$resolved_ip"
            
            if [ $attempt -lt $MAX_ATTEMPTS ]; then
                sleep $DELAY
            fi
        fi
        
        attempt=$((attempt+1))
    done
    
    # Échec après toutes les tentatives
    echo ""
    print_error "Propagation DNS non terminée pour $domain après $MAX_ATTEMPTS tentatives"
    
    if [ -z "$last_ip" ]; then
        print_warning "Cause : Aucune réponse DNS (domaine inexistant ou non configuré)"
    else
        print_warning "Cause : Le domaine pointe vers $last_ip au lieu de $expected_ip"
    fi
    
    log_output "\n❌ Propagation DNS non terminée pour $domain après $MAX_ATTEMPTS tentatives"
    log_output "⚠️  IP actuelle : $last_ip | IP attendue : $expected_ip"
    
    return 1
}

# === VÉRIFICATIONS DNS ===

echo ""
print_header "VÉRIFICATION DE LA PROPAGATION DNS"

if [ -n "$OUTPUT_FILE" ]; then
    cat > "$OUTPUT_FILE" << EOF
═══════════════════════════════════════════════════════════════
 RAPPORT DE VÉRIFICATION DNS - PROPAGATION
═══════════════════════════════════════════════════════════════

Domaine analysé  : $DOMAIN
IP attendue      : $IP
Serveur DNS      : $([ -n "$DNS_SERVER" ] && echo "$DNS_SERVER" || echo "Système")
Date             : $(date '+%d/%m/%Y %H:%M:%S')
Max tentatives   : $MAX_ATTEMPTS
Délai            : ${DELAY}s

═══════════════════════════════════════════════════════════════
EOF
fi

# Initialiser les compteurs
CHECKS_TOTAL=0
CHECKS_SUCCESS=0
CHECKS_FAILED=0

# 1. Vérification du domaine principal
CHECKS_TOTAL=$((CHECKS_TOTAL + 1))
if check_dns "$DOMAIN" "$IP"; then
    CHECKS_SUCCESS=$((CHECKS_SUCCESS + 1))
else
    CHECKS_FAILED=$((CHECKS_FAILED + 1))
    MAIN_DOMAIN_FAILED=1
fi

# 2. Vérification du wildcard
if [[ "$check_wildcard" == "o" || "$check_wildcard" == "O" ]]; then
    WILDCARD_SUB="test.${DOMAIN}"
    CHECKS_TOTAL=$((CHECKS_TOTAL + 1))
    
    if check_dns "$WILDCARD_SUB" "$IP"; then
        CHECKS_SUCCESS=$((CHECKS_SUCCESS + 1))
    else
        CHECKS_FAILED=$((CHECKS_FAILED + 1))
    fi
fi

# 3. Vérification des sous-domaines supplémentaires
if [ -n "$SUBDOMAINS" ]; then
    for subdomain in $SUBDOMAINS; do
        FULL_SUBDOMAIN="${subdomain}.${DOMAIN}"
        CHECKS_TOTAL=$((CHECKS_TOTAL + 1))
        
        if check_dns "$FULL_SUBDOMAIN" "$IP"; then
            CHECKS_SUCCESS=$((CHECKS_SUCCESS + 1))
        else
            CHECKS_FAILED=$((CHECKS_FAILED + 1))
        fi
    done
fi

# 4. Vérification du CNAME www (optionnel)
echo ""
echo -e "${MAGENTA}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${CYAN}🔍 Vérification bonus : CNAME www${NC}"
echo -e "${MAGENTA}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"

log_output "\n━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
log_output "🔍 Vérification bonus : CNAME www"
log_output "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

if [ -n "$DNS_SERVER" ]; then
    WWW_RECORD=$(dig @"$DNS_SERVER" +short "www.${DOMAIN}" 2>/dev/null | head -n1)
else
    WWW_RECORD=$(dig +short "www.${DOMAIN}" 2>/dev/null | head -n1)
fi

if [ -n "$WWW_RECORD" ]; then
    echo ""
    print_success "www.${DOMAIN} est configuré : $WWW_RECORD"
    log_output "\n✅ www.${DOMAIN} est configuré : $WWW_RECORD"
    
    # Vérifier si c'est un CNAME ou un A record
    if [[ "$WWW_RECORD" =~ ^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$ ]]; then
        print_info "Type : Enregistrement A (IP directe)"
        log_output "ℹ️  Type : Enregistrement A"
    else
        print_info "Type : Enregistrement CNAME"
        log_output "ℹ️  Type : Enregistrement CNAME"
    fi
else
    echo ""
    print_warning "www.${DOMAIN} n'est pas configuré (optionnel)"
    log_output "\n⚠️  www.${DOMAIN} n'est pas configuré"
fi

# === RAPPORT FINAL ===

echo ""
echo -e "${MAGENTA}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${CYAN}📊 RAPPORT FINAL${NC}"
echo -e "${MAGENTA}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"

log_output "\n━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
log_output "📊 RAPPORT FINAL"
log_output "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

echo ""
echo "Vérifications effectuées : $CHECKS_TOTAL"
echo "  ${GREEN}✅ Réussies : $CHECKS_SUCCESS${NC}"
echo "  ${RED}❌ Échouées : $CHECKS_FAILED${NC}"
echo ""

log_output "\nVérifications effectuées : $CHECKS_TOTAL"
log_output "  ✅ Réussies : $CHECKS_SUCCESS"
log_output "  ❌ Échouées : $CHECKS_FAILED"

if [ $CHECKS_FAILED -eq 0 ]; then
    echo -e "${GREEN}╔═══════════════════════════════════════════════════════════╗${NC}"
    echo -e "${GREEN}║                                                           ║${NC}"
    echo -e "${GREEN}║  ✨ SUCCÈS : Propagation DNS complète et validée !       ║${NC}"
    echo -e "${GREEN}║                                                           ║${NC}"
    echo -e "${GREEN}╚═══════════════════════════════════════════════════════════╝${NC}"
    
    log_output "\n✨ SUCCÈS : Propagation DNS complète et validée !"
    
    echo ""
    print_success "Tous les enregistrements DNS pointent vers $IP"
    print_info "Vous pouvez maintenant procéder à l'installation de vos services"
    
    log_output "✅ Tous les enregistrements DNS pointent vers $IP"
    
    EXIT_CODE=0
else
    echo -e "${RED}╔═══════════════════════════════════════════════════════════╗${NC}"
    echo -e "${RED}║                                                           ║${NC}"
    echo -e "${RED}║  ❌ ÉCHEC : Propagation DNS incomplète                   ║${NC}"
    echo -e "${RED}║                                                           ║${NC}"
    echo -e "${RED}╚═══════════════════════════════════════════════════════════╝${NC}"
    
    log_output "\n❌ ÉCHEC : Propagation DNS incomplète"
    
    echo ""
    print_error "$CHECKS_FAILED vérification(s) ont échoué"
    echo ""
    
    echo -e "${YELLOW}📋 Actions recommandées :${NC}"
    echo ""
    echo "  1. Vérifiez vos enregistrements DNS chez votre registrar"
    echo "  2. Attendez quelques minutes et relancez le script"
    echo "  3. Vérifiez en ligne : https://dnschecker.org/#A/$DOMAIN"
    echo "  4. Consultez les logs de votre registrar"
    echo ""
    
    if [ -n "$MAIN_DOMAIN_FAILED" ]; then
        print_error "Le domaine principal ne pointe pas vers la bonne IP !"
        echo "     Vérifiez l'enregistrement A pour $DOMAIN"
    fi
    
    EXIT_CODE=1
fi

# === INFORMATIONS SUPPLÉMENTAIRES ===

echo ""
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${CYAN}💡 INFORMATIONS UTILES${NC}"
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""

log_output "\n━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
log_output "💡 INFORMATIONS UTILES"
log_output "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

echo "🔍 Outils de vérification en ligne :"
echo "   • DNSChecker    : https://dnschecker.org/#A/$DOMAIN"
echo "   • What's My DNS : https://www.whatsmydns.net/#A/$DOMAIN"
echo "   • DNS Propagation: https://www.dnswatch.info/"
echo ""

log_output "\n🔍 Outils de vérification en ligne :"
log_output "   • DNSChecker    : https://dnschecker.org/#A/$DOMAIN"
log_output "   • What's My DNS : https://www.whatsmydns.net/#A/$DOMAIN"

echo "⏱️  Délais de propagation typiques :"
echo "   • Immédiat       : Cloudflare, certains DNS modernes"
echo "   • 15-60 minutes  : La plupart des providers"
echo "   • 2-24 heures    : Anciens systèmes ou TTL élevés"
echo ""

log_output "\n⏱️  Délais de propagation typiques :"
log_output "   • Immédiat       : Cloudflare, certains DNS modernes"
log_output "   • 15-60 minutes  : La plupart des providers"
log_output "   • 2-24 heures    : Anciens systèmes ou TTL élevés"

echo "🛠️  Commandes manuelles utiles :"
echo "   dig $DOMAIN"
echo "   dig @8.8.8.8 $DOMAIN"
echo "   nslookup $DOMAIN"
echo "   host $DOMAIN"
echo ""

if [ -n "$OUTPUT_FILE" ]; then
    echo ""
    print_success "Rapport complet sauvegardé : $OUTPUT_FILE"
    echo ""
    echo "Pour consulter :"
    echo "  cat $OUTPUT_FILE"
    echo "  less $OUTPUT_FILE"
    echo ""
fi

print_header "FIN DE LA VÉRIFICATION"

log_output "\n═══════════════════════════════════════════════════════════════"
log_output "FIN DE LA VÉRIFICATION - $(date '+%d/%m/%Y %H:%M:%S')"
log_output "═══════════════════════════════════════════════════════════════"

exit $EXIT_CODE
