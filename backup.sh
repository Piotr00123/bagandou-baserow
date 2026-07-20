#!/bin/bash
set -e

# 1. Automatyczne załadowanie haseł i zmiennych z pliku .env
PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE}")" && pwd)"
if [ -f "$PROJECT_DIR/.env" ]; then
    export $(grep -v '^#' "$PROJECT_DIR/.env" | xargs)
else
    echo "[BŁĄD] Brak pliku .env w katalogu projektu! Nie mogę pobrać haseł."
    exit 1
fi

# Tworzenie folderu na kopie, jeśli nie istnieje
mkdir -p "$PROJECT_DIR/backups_kopie"

# Generowanie unikalnej nazwy pliku z datą i czasem
DATA=$(date +"%Y-%m-%d_%H-%M-%S")
PLIK_BAZY="$PROJECT_DIR/backups_kopie/baserow_db_$DATA.dump"
PLIK_MEDIA="$PROJECT_DIR/backups_kopie/baserow_media_$DATA.tar.gz"

echo "=== Rozpoczynam pełny backup Baserow ==="

# 2. Kopia bazy danych (Używa zmiennej POSTGRES_PASSWORD z Twojego .env)
echo "1/2: Zrzucanie bazy danych PostgreSQL..."
docker compose exec -T postgres sh -c "PGPASSWORD=\$POSTGRES_PASSWORD pg_dump -U baserow -F c baserow" > "$PLIK_BAZY"

# 3. Kopia plików multimedialnych (Zdjęcia z ODK / Załączniki)
echo "2/2: Kopiowanie i pakowanie plików multimedialnych (media)..."
if [ -d "$PROJECT_DIR/dane_baserow/media" ]; then
    tar -czf "$PLIK_MEDIA" -C "$PROJECT_DIR/dane_baserow" media
else
    docker compose exec -T baserow tar -czf /tmp/media.tar.gz -C /baserow/data media
    docker cp $(docker compose ps -q baserow):/tmp/media.tar.gz "$PLIK_MEDIA"
    docker compose exec -T baserow rm /tmp/media.tar.gz
fi

echo "=== Backup zakończony sukcesem! ==="
echo "Baza: $PLIK_BAZY"
echo "Media: $PLIK_MEDIA"
