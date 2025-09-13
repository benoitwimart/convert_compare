#!/bin/bash

# Vérification des arguments
if [ $# -lt 2 ]; then
  echo "Usage: $0 <qualité 0-100> <fichier(s) PNG>"
  echo "Exemple: $0 80 image1.png image2.png"
  exit 1
fi

# Récupération du niveau de qualité
QUALITY=$1
shift

# Création du dossier de destination
WEBP_DIR="webp-${QUALITY}"
mkdir -p "$WEBP_DIR"

# Conversion de chaque fichier PNG en WebP
for IMG in "$@"; do
  if [[ $IMG == *.png ]]; then
    BASENAME=$(basename "${IMG%.*}")
    echo "Conversion de $IMG → ${WEBP_DIR}/${BASENAME}.webp (qualité $QUALITY)"
    magick "$IMG" -quality "$QUALITY" "${WEBP_DIR}/${BASENAME}.webp"
  else
    echo "⚠️  $IMG n'est pas un fichier PNG, ignoré."
  fi
done
