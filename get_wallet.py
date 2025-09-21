#!/usr/bin/env python3   # Indique que c'est un script Python3
import requests, re       # On importe requests (pour télécharger) et re (regex)

URL = "https://iexec.slf.ovh/wallet.txt"   # Lien du fichier ASCII
LOGFILE = "wallet.log"                     # Fichier log pour écrire le résultat

r = requests.get(URL)   # On télécharge le fichier
text = r.text           # On met le texte entier dans une variable

# On cherche la première heure (ex: 12:45:33)
time_match = re.search(r"[0-9]{2}:[0-9]{2}:[0-9]{2}", text)
time_str = time_match.group(0) if time_match else "00:00:00"  # Si trouvé ok, sinon 00:00:00

# On crée un petit dictionnaire (tableau associatif) pour stocker les morceaux
parts = {}

# On cherche toutes les lignes du type "N:xxxxx" où N va de 1 à 6
for match in re.findall(r"([1-6]):([0-9A-Za-z]+)", text):
    idx, frag = match         # idx = numéro (1 à 6), frag = morceau d'adresse
    parts[int(idx)] = frag    # On stocke dans le dictionnaire

# On colle les morceaux dans l'ordre de 1 à 6
wallet = "".join(parts.get(i, "") for i in range(1, 7))

# On ouvre (ou crée) le fichier log en mode ajout
with open(LOGFILE, "a") as f:
    # On écrit l'heure + l'adresse dans une ligne
    f.write(f"{time_str} -- {wallet}\n")

# On affiche aussi le résultat à l'écran
print(f"Résultat: {time_str} -- {wallet}")
