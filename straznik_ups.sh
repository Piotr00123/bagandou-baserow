#!/bin/bash

# Konfiguracja środowiska
ROUTER_IP="192.168.1.1" 
PROJECT_DIR="/home/kolodpi3/bagandou-baserow"
LOG_FILE="$PROJECT_DIR/straznik_ups.log"

# Funkcja wykonująca test ping
check_ping() {
    /usr/bin/ping -c 2 -W 3 "$ROUTER_IP" > /dev/null 2>&1
    return $?
}

# Pierwsza próba pingu
if ! check_ping; then
    echo "[$(/usr/bin/date)] [OSTRZEZENIE] Brak odpowiedzi z routera miejskiego. Sprawdzam ponownie..." >> "$LOG_FILE"

    # Petla sprawdzajaca zasilanie: 3 proby, kazda po 60 sekundach zwloki (lacznie 3 minuty oczekiwania)
    PRAD_WROCIL=0
    for i in {1..3}; do
        /usr/bin/sleep 60
        if check_ping; then
            PRAD_WROCIL=1
            break
        fi
        echo "[$(/usr/bin/date)] [ALARM] Proba $i/3: Prad nadal nie wrocil." >> "$LOG_FILE"
    done

    # Jesli po 3 minutach pradu wciaz nie ma – gasimy system
    if [ $PRAD_WROCIL -eq 0 ]; then
        echo "[$(/usr/bin/date)] [KRYTYCZNY] Zasilanie awaryjne wyczerpuje sie. Rozpoczynam procedure wylaczania bazy i kontenerow!" >> "$LOG_FILE"

        # Bezpieczne zatrzymanie kontenerów Dockera
        cd "$PROJECT_DIR" || exit
        /usr/bin/docker compose down >> "$LOG_FILE" 2>&1

        # Bezpieczne zamkniecie systemu operacyjnego Raspberry Pi
        echo "[$(/usr/bin/date)] [SYSTEM] Zamykanie systemu operacyjnego." >> "$LOG_FILE"
        /usr/sbin/shutdown -h now
    else
        echo "[$(/usr/bin/date)] [INFO] Falszywy alarm. Polaczenie z routerem przywrocone." >> "$LOG_FILE"
    fi
fi
