#!/usr/bin/env bash
set -euo pipefail

# png2gif_2colors.sh
# Convertit des images en GIF 2 couleurs avec dithering (par défaut FloydSteinberg).
# Dépendance: ImageMagick (commande "magick" ou "convert").

# Default parameters
OUTDIR="converted_gifs"
COLORS=2
DITHER="FloydSteinberg"   # options: FloydSteinberg, Riemersma, none
RESIZE=""                 # ex: "800x" ou "" pour ne pas redimensionner
OVERWRITE=0

usage() {
  cat <<EOF
Usage: $0 [options] <file-or-glob>...
Options:
  -o DIR      Output directory (default: $OUTDIR)
  -d METHOD   Dither method: FloydSteinberg | Riemersma | none  (default: $DITHER)
  -r SIZE     Resize, e.g. 800x or 640x480  (default: no resize)
  -c N        Number of colors (default: $COLORS)
  -f          Force overwrite existing output files
  -h          Show this help
Examples:
  $0 *.png
  $0 -o gifs -d Riemersma image1.jpg image2.png
EOF
  exit 1
}

# parse options
while getopts "o:d:r:c:fh" opt; do
  case "$opt" in
    o) OUTDIR="$OPTARG" ;;
    d) DITHER="$OPTARG" ;;
    r) RESIZE="$OPTARG" ;;
    c) COLORS="$OPTARG" ;;
    f) OVERWRITE=1 ;;
    h) usage ;;
    *) usage ;;
  esac
done
shift $((OPTIND-1))

if [ $# -lt 1 ]; then
  usage
fi

# find ImageMagick binary
if command -v magick >/dev/null 2>&1; then
  IM_CMD="magick"
elif command -v convert >/dev/null 2>&1; then
  IM_CMD="convert"
else
  echo "Erreur : ImageMagick non trouvé. Installez-le (magick/convert)." >&2
  exit 2
fi

mkdir -p "$OUTDIR"

# normalize dither option
DITHER_LOWER=$(echo "$DITHER" | tr '[:upper:]' '[:lower:]')
for src in "$@"; do
  # support globs: if no match, keep literal -> check file exists
  shopt -s nullglob
  matches=( $src )
  shopt -u nullglob
  if [ ${#matches[@]} -eq 0 ]; then
    echo "Aucun fichier correspondant à: $src" >&2
    continue
  fi
  for file in "${matches[@]}"; do
    if [ ! -f "$file" ]; then
      echo "Ignoré (pas un fichier) : $file" >&2
      continue
    fi
    base=$(basename "$file")
    name="${base%.*}"
    out="$OUTDIR/${name}.gif"

    if [ -f "$out" ] && [ $OVERWRITE -eq 0 ]; then
      echo "Existe déjà (use -f pour écraser) : $out" >&2
      continue
    fi

    # build convert arguments
    ARGS=()
    ARGS+=("$file")
    ARGS+=(-strip)                         # enlever métadonnées
    [ -n "$RESIZE" ] && ARGS+=(-resize "$RESIZE")
    # set dithering
    if [ "$DITHER_LOWER" = "none" ]; then
      ARGS+=(+dither)
    else
      # ImageMagick supports several dither types; use provided or fallback to FloydSteinberg
      case "$DITHER_LOWER" in
        floydsteinberg|floyd|floyd_steinberg) ARGS+=(-dither "FloydSteinberg") ;;
        riemersma) ARGS+=(-dither "Riemersma") ;;
        *) ARGS+=(-dither "FloydSteinberg") ;;
      esac
    fi
    ARGS+=(-colors "$COLORS")
    ARGS+=(-type Palette)
    ARGS+=(-depth 8)
    ARGS+=("$out")

    echo "Conversion : $file -> $out (colors=$COLORS dither=$DITHER ${RESIZE:+resize=$RESIZE})"
    # run
    if [ "$IM_CMD" = "magick" ]; then
      magick "${ARGS[@]}"
    else
      convert "${ARGS[@]}"
    fi

    # Optional: optimize GIF to reduce size (single-frame GIFs often not improved, but kept as option)
    # gifsicle can optimize if installed:
    if command -v gifsicle >/dev/null 2>&1; then
      gifsicle -O3 "$out" -o "$out" || true
    fi
  done
done

echo "Terminé. Fichiers dans : $OUTDIR"
