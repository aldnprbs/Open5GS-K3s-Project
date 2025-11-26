#!/bin/bash

# List semua NF
NFS=("scp" "nrf" "amf" "smf" "upf" "ausf" "udm" "udr" "pcf" "nssf")

for nf in "${NFS[@]}"; do
    DOCKERFILE="../open5gs-compose/${nf}/Dockerfile"
    
    if [ -f "$DOCKERFILE" ]; then
        echo "Updating $DOCKERFILE..."
        
        # Backup original
        cp "$DOCKERFILE" "${DOCKERFILE}.backup"
        
        # Tambahkan iputils-ping dan curl jika belum ada
        if ! grep -q "iputils-ping" "$DOCKERFILE"; then
            # Cari baris yang ada 'netbase &&' atau 'netbase \' dan tambahkan setelahnya
            sed -i '/netbase/a\        iputils-ping \\' "$DOCKERFILE"
        fi
        
        if ! grep -q "curl &&" "$DOCKERFILE" && ! grep -q "curl \\\\" "$DOCKERFILE"; then
            sed -i '/iputils-ping/a\        curl \\' "$DOCKERFILE"
        fi
        
        # Fix jika ada double backslash
        sed -i 's/\\\\ \\/\\/g' "$DOCKERFILE"
        
        echo "✓ $nf updated"
    else
        echo "✗ $DOCKERFILE not found"
    fi
done

echo ""
echo "Done! Checking results..."
grep -r "iputils-ping" ../open5gs-compose/*/Dockerfile | wc -l
grep -r "curl" ../open5gs-compose/*/Dockerfile | wc -l
