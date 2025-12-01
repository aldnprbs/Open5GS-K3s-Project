#!/bin/bash
set -e

echo "=========================================="
echo "OPEN5GS COMPLETE DEPLOYMENT AUTOMATION"
echo "Expected time: ~45-50 minutes"
echo "=========================================="

# PHASE 1: CLEANUP & CLONE
echo ""
echo "=== PHASE 1: CLEANUP & CLONE (3 min) ==="
cd ~
sudo rm -rf ~/Open5GS-Testbed ~/UERANSIM
sudo /usr/local/bin/k3s-uninstall.sh 2>/dev/null || echo 'K3s not installed'
sudo iptables -t nat -F 2>/dev/null || true
git clone https://github.com/rayhanegar/Open5GS-Testbed.git
echo "✓ Repository cloned"

# PHASE 2: SETUP K3S & CALICO
echo ""
echo "=== PHASE 2: SETUP K3S & CALICO (5 min) ==="
cd ~/Open5GS-Testbed/open5gs/open5gs-k3s-calico
chmod +x *.sh
sudo ./setup-k3s-environment-calico.sh
sleep 30
kubectl get nodes
echo "✓ K3s and Calico ready"

# PHASE 3: BUILD IMAGES
echo ""
echo "=== PHASE 3: BUILD IMAGES (15-20 min) ⏰ ==="
echo "This is the longest phase, please wait..."
sudo ./build-import-containers.sh
sudo k3s crictl images | grep open5gs
echo "✓ All images built"

# PHASE 4: DEPLOY OPEN5GS
echo ""
echo "=== PHASE 4: DEPLOY OPEN5GS (3 min) ==="
sudo ./deploy-k3s-calico.sh
sleep 60
kubectl wait --for=condition=ready pod --all -n open5gs --timeout=300s
kubectl get pods -n open5gs -o wide
echo "✓ Open5GS deployed"

# PHASE 5: BUILD UERANSIM
echo ""
echo "=== PHASE 5: BUILD UERANSIM (10 min) ⏰ ==="
cd ~
git clone https://github.com/aligungr/UERANSIM.git
cd UERANSIM
make
echo "✓ UERANSIM built"

# PHASE 6: CONFIGURE
echo ""
echo "=== PHASE 6: CONFIGURE ==="
cd ~/Open5GS-Testbed/ueransim/configs
VM_IP=$(hostname -I | awk '{print $1}')
sed -i "s/address: .*/address: $VM_IP  # AMF address/" open5gs-gnb-k3s.yaml
echo "✓ gNB config updated with VM IP: $VM_IP"
grep -A 3 "amfConfigs:" open5gs-gnb-k3s.yaml

echo ""
echo "=========================================="
echo "✅ DEPLOYMENT COMPLETE!"
echo "=========================================="
echo ""
echo "Next steps - Open 3 terminals:"
echo ""
echo "Terminal 1 (gNB):"
echo "  cd ~/UERANSIM"
echo "  ./build/nr-gnb -c ~/Open5GS-Testbed/ueransim/configs/open5gs-gnb-k3s.yaml"
echo ""
echo "Terminal 2 (UE):"
echo "  cd ~/UERANSIM"
echo "  sudo ./build/nr-ue -c ~/Open5GS-Testbed/ueransim/configs/open5gs-ue-embb.yaml"
echo ""
echo "Terminal 3 (Test):"
echo "  ping -I uesimtun0 -c 4 8.8.8.8"
echo ""
