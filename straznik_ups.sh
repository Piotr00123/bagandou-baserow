#!/bin/bash
# ADRES IP ROUTERA WPIĘTEGO PRZED UPS
ROUTER_IP="192.168.1.1" 

# Próba pingowania routera miejskiego
if ! ping -c 2 -W 3 $ROUTER_IP > /dev/null; then
    echo "[$(date)] Brak prądu miejskiego! Router nie odpowiada." >> straznik_ups.log

    # Czekamy dodatkowe 10 minut, żeby sprawdzić czy prąd wróci
    sleep 600

    # Ponowna weryfikacja
    if ! ping -c 2 -W 3 $ROUTER_IP > /dev/null; then
        echo "[$(date)] Prąd nie wrócił. Uruchamiam bezpieczne zamykanie systemów Misji Bagandou!" >> straznik_ups.log

        # Bezpieczne wyłączenie baz danych i kontenerów
        cd /home/kolodpi3/bagandou-baserow
        /usr/bin/docker compose down

        # Twarde wyłączenie komputera/Raspberry Pi
        sudo shutdown -h now
    fi
else
    echo "[$(date)] Zasilanie stabilne." > /dev/null
fi
