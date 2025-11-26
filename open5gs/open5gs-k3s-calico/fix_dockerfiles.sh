#!/bin/bash

# Fix all Dockerfiles
for nf in amf ausf nrf nssf pcf scp smf udm udr upf; do
    dockerfile="${nf}/Dockerfile"
    echo "Fixing $dockerfile..."
    
    # Backup original
    cp "$dockerfile" "${dockerfile}.bak"
    
    # Fix the RUN command - replace the broken section
    sed -i '/apt-get install -y --no-install-recommends \\/,/rm -rf \/var\/lib\/apt\/lists\*/c\
    apt-get install -y --no-install-recommends \\\
        open5gs-'"$nf"' \\\
        open5gs-common \\\
        gosu \\\
        ca-certificates \\\
        netbase \\\
        iputils-ping \\\
        curl && \\\
    mkdir -p /var/log/open5gs /etc/open5gs/tls /etc/open5gs/custom /var/run/open5gs && \\\
    apt-get clean && \\\
    rm -rf /var/lib/apt/lists/*' "$dockerfile"
    
    echo "✓ Fixed $dockerfile"
done

echo ""
echo "All Dockerfiles fixed!"
