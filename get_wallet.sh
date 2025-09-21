#!/bin/bash   # Indique que c'est un script bash

URL="https://iexec.slf.ovh/wallet.txt"   # Lien du fichier ASCII qui contient l'adresse
LOGFILE="wallet.log"                     # Fichier où on va stocker le résultat

curl -s $URL > tmp.txt   # Télécharge le fichier et le met dans tmp.txt (-s = silencieux)

# On cherche la première heure (format HH:MM:SS)
TIME=$(grep -m1 -o '[0-9]\{2\}:[0-9]\{2\}:[0-9]\{2\}' tmp.txt)

# On cherche le morceau avec "1:" et on garde ce qu'il y a après le :
PART1=$(grep -o "1:[0-9A-Za-z]*" tmp.txt | cut -d: -f2)
# Pareil pour "2:"
PART2=$(grep -o "2:[0-9A-Za-z]*" tmp.txt | cut -d: -f2)
# Pareil pour "3:"
PART3=$(grep -o "3:[0-9A-Za-z]*" tmp.txt | cut -d: -f2)
# Pareil pour "4:"
PART4=$(grep -o "4:[0-9A-Za-z]*" tmp.txt | cut -d: -f2)
# Pareil pour "5:"
PART5=$(grep -o "5:[0-9A-Za-z]*" tmp.txt | cut -d: -f2)
# Pareil pour "6:"
PART6=$(grep -o "6:[0-9A-Za-z]*" tmp.txt | cut -d: -f2)

# On colle tous les morceaux ensemble pour reformer l'adresse complète
WALLET=$PART1$PART2$PART3$PART4$PART5$PART6

# On ajoute une ligne au fichier log avec l'heure et l'adresse
echo "$TIME -- $WALLET" >> $LOGFILE

# On affiche aussi le résultat à l'écran
echo "Résultat: $TIME -- $WALLET"
