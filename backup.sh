#!/bin/bash
set -e

# Tworzenie folderu na kopie, jeśli nie istnieje
mkdir -p backups_kopie

# Generowanie unikalnej nazwy pliku z datą i czasem
DATA=$(date +"%Y-%m-%d_%H-%M-%S")
PLIK_BAZY="backups_kopie/baserow_db_$DATA.dump"
PLIK_MEDIA="backups_kopie/baserow_media_$DATA.tar.gz"

echo "=== Rozpoczynam pełny backup Baserow ==="

# 1. Kopia bazy danych (Struktura + Wszystkie Dane)
echo "1/2: Zrzucanie bazy danych PostgreSQL..."
docker exec -i bagandou_baserow sh -c 'PGPASSWORD="tf0s4kgs3sx7kw6ovpk37fvg77r1102459r1z7btu2kif1aubk" pg_dump -h localhost -U baserow -F c baserow' > "$PLIK_BAZY"

# 2. Kopia plików multimedialnych (Media)
echo "2/2: Pakowanie plików multimedialnych (zdjęcia/pliki)..."
docker exec -i bagandou_baserow tar -czf - -C /baserow/data media > "$PLIK_MEDIA"

echo "=== Backup zakończony sukcesem! ==="
echo "Baza: $PLIK_BAZY"
echo "Media: $PLIK_MEDIA"
