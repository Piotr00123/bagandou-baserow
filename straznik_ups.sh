#!/bin/bash

# ====================================================================
# SPRZĘTOWY STRAŻNIK ZASILANIA (UPS) DLA RASPBERRY PI 5 - MISJA BAGANDOU
# ====================================================================
# Skrypt monitoruje stan sieci elektrycznej poprzez pingowanie routera.
# Wymaga uruchamiania z uprawnieniami roota (sudo crontab -e).

# Konfiguracja środowiska
ROUTER_IP="192.168.1.1" 
PROJECT_DIR="/home/kolodpi3/bagandou-baserow"
LOG_FILE="$PROJECT_DIR/straznik_ups.log"

# Funkcja wykonująca test ping
check_ping() {
    /usr/bin/ping -c 2 -W 3 "$ROUTER_IP" > /dev/null 2>&1
    return $?
}

# Pierwsza próba pingu - wykrycie potencjalnego zaniku zasilania miejskiego
if ! check_ping; then
    echo "[$(/usr/bin/date)] [OSTRZEZENIE] Brak odpowiedzi z routera miejskiego. Sprawdzam ponownie..." >> "$LOG_FILE"

    # Pętla sprawdzająca zasilanie: sprawdzanie sieci co 10 sekund przez 3 minuty (łącznie 18 obrotów)
    PRAD_WROCIL=0
    for i in {1..18}; do
        /usr/bin/sleep 10
        if check_ping; then
            PRAD_WROCIL=1
            break
        fi
        
        # Loguj alarm co 6 obrotów (czyli co pełną minutę), aby nie zapychać pliku logów
        if [ $((i % 6)) -eq 0 ]; then
            echo "[$(/usr/bin/date)] [ALARM] Minuta $((i / 6))/3: Prąd nadal nie wrócił." >> "$LOG_FILE"
        fi
    done

    # Jeśli po 3 minutach prądu wciąż nie ma – gasimy system w bezpieczny sposób
    if [ $PRAD_WROCIL -eq 0 ]; then
        echo "[$(/usr/bin/date)] [KRYTYCZNY] Zasilanie awaryjne wyczerpuje sie. Rozpoczynam procedure wylaczania bazy i kontenerow!" >> "$LOG_FILE"

        # Próba wejścia do katalogu projektu
        if cd "$PROJECT_DIR" 2>/dev/null; then
            # Poprawiono wywołanie binarne wtyczki docker compose
            /usr/bin/docker compose down >> "$LOG_FILE" 2>&1
        else
            echo "[$(/usr/bin/date)] [BLAD] Nie można wejść do katalogu projektu $PROJECT_DIR! Wymuszam natychmiastowe zamknięcie OS." >> "$LOG_FILE"
        fi

        # Bezpieczne zamknięcie systemu operacyjnego Raspberry Pi (zapobiega uszkodzeniu karty SD/dysku)
        echo "[$(/usr/bin/date)] [SYSTEM] Zamykanie systemu operacyjnego." >> "$LOG_FILE"
        /usr/sbin/shutdown -h now
    else
        echo "[$(/usr/bin/date)] [INFO] Falszywy alarm lub krótkotrwały zanik sieci. Połączenie przywrócone." >> "$LOG_FILE"
    fi
fi
