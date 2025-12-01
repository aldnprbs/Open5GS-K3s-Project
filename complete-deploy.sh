#!/bin/bash
set -e
echo "=========================================="
echo "COMPLETE DEPLOYMENT - Starting..."
echo "=========================================="

# Cleanup previous deployment
echo "Step 1: Cleanup..."
cd ~/Open5GS-Testbed/open5gs/open5gs-k3s-calico
echo '1234' | sudo -S kubectl delete namespace open5gs --force --grace-period=0 2>/dev/null || true
sleep 10

# Build and import images
echo "Step 2: Building and importing images..."
echo '1234' | sudo -S ./build-import-containers.sh
sleep 5

# Deploy Open5GS
echo "Step 3: Deploying Open5GS to K3s..."
echo '1234' | sudo -S ./deploy-k3s-calico.sh
sleep 90

# Check deployment
echo "Step 4: Checking deployment..."
kubectl get pods -n open5gs

# Clone UERANSIM
echo "Step 5: Setting up UERANSIM..."
cd ~
if [ ! -d "UERANSIM" ]; then
  git clone https://github.com/aligungr/UERANSIM.git
fi
cd UERANSIM
make

# Configure gNB
echo "Step 6: Configuring gNB..."
cd ~/Open5GS-Testbed/ueransim/configs
VM_IP=$(hostname -I | awk '{print $1}')
sed -i "s/address: .*/address: $VM_IP/" open5gs-gnb-k3s.yaml

echo ""
echo "=========================================="
echo "✅ DEPLOYMENT COMPLETE!"
echo "=========================================="
echo "VM IP: $VM_IP"
echo ""
echo "Next: Open 3 terminals and run:"
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
