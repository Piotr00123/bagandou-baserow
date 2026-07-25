#!/bin/bash
set -e

# 1. Automatyczne załadowanie środowiska projektu
PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE}")" && pwd)"

# Tworzenie folderu na kopie, jeśli nie istnieje
mkdir -p "$PROJECT_DIR/backups_kopie"

# Generowanie unikalnej nazwy pliku z datą i czasem
DATA=$(date +"%Y-%m-%d_%H-%M-%S")
PLIK_BAZY="$PROJECT_DIR/backups_kopie/baserow_db_$DATA.dump"
PLIK_MEDIA="$PROJECT_DIR/backups_kopie/baserow_media_$DATA.tar.gz"

echo "=== Rozpoczynam pełny backup kontenera Baserow ==="

# 2. Kopia bazy danych (Zrzut do pliku tymczasowego wewnątrz kontenera bez użycia sieci)
echo "1/2: Zrzucanie wbudowanej bazy danych PostgreSQL..."

# Uruchamiamy pg_dump jako lokalny użytkownik procesów bazy (postgres), zapisując plik lokalnie w kontenerze
docker compose exec -T --user postgres baserow sh -c "pg_dump -F c baserow > /tmp/baserow_local.dump"

# Kopiujemy gotowy plik zrzutu z kontenera na Twój laptop
docker cp $(docker compose ps -q baserow):/tmp/baserow_local.dump "$PLIK_BAZY"

# Sprzątamy plik tymczasowy wewnątrz kontenera
docker compose exec -T --user postgres baserow rm /tmp/baserow_local.dump

# 3. Kopia plików multimedialnych (Zdjęcia z ODK / Załączniki)
echo "2/2: Pakowanie plików multimedialnych (media)..."
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
