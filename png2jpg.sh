#!/bin/bash

# Vérification des arguments
if [ $# -lt 2 ]; then
  echo "Usage: $0 <qualité 0-100> <fichier(s) PNG>"
  echo "Exemple: $0 90 image1.png image2.png"
  exit 1
fi

# Niveau de qualité choisi
QUALITY=$1
shift

# Création du dossier de sortie
OUTDIR="jpg-$QUALITY"
mkdir -p "$OUTDIR"

# Conversion de chaque PNG en JPG
for IMG in "$@"; do
  if [[ $IMG == *.png ]]; then
    BASENAME="$(basename "${IMG%.*}")"
    OUTFILE="$OUTDIR/${BASENAME}.jpg"
    echo "Conversion de $IMG → $OUTFILE (qualité $QUALITY)"
    magick "$IMG" -quality "$QUALITY" "$OUTFILE"
  else
    echo "⚠️  $IMG n'est pas un fichier PNG, ignoré."
  fi
done