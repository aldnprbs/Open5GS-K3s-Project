# 🚀 Quick Start Commands - Open5GS K3s Deployment

Panduan cepat untuk menjalankan ulang deployment yang sudah berhasil.

---

## 📋 Prerequisites Check

```bash
# Check Ubuntu version
lsb_release -a

# Check available resources
free -h
df -h

# Check sudo access
sudo whoami  # Should output: root
```

---

## 1️⃣ System Preparation

```bash
# Update system
sudo apt-get update && sudo apt-get upgrade -y

# Install dependencies
sudo apt-get install -y \
    curl git iptables iptables-persistent \
    net-tools iputils-ping traceroute tcpdump \
    wireshark libsctp1 lksctp-tools

# Enable IP forwarding
sudo sysctl -w net.ipv4.ip_forward=1
sudo sh -c 'echo "net.ipv4.ip_forward=1" >> /etc/sysctl.conf'
```

---

## 2️⃣ Clone Repository

```bash
# Remove old repo if exists
rm -rf ~/Open5GS-Testbed

# Clone fresh copy
git clone https://github.com/rayhanegar/Open5GS-Testbed.git
cd Open5GS-Testbed/open5gs/open5gs-k3s-calico
```

---

## 3️⃣ Install K3s with Calico

```bash
# Make script executable
chmod +x setup-k3s-environment-calico.sh

# Run setup (takes ~5 minutes)
sudo ./setup-k3s-environment-calico.sh

# Verify K3s installation
kubectl get nodes
# Expected: STATUS = Ready

# Verify Calico
kubectl get pods -n kube-system | grep calico
# Expected: calico-node and calico-kube-controllers Running
```

---

## 4️⃣ Build and Import Container Images

```bash
# Fix script permissions
sed -i 's/docker build/sudo docker build/g' build-import-containers.sh
sed -i 's/docker save/sudo docker save/g' build-import-containers.sh
sed -i 's/k3s ctr/sudo k3s ctr/g' build-import-containers.sh

# Make executable
chmod +x build-import-containers.sh

# Build images (takes ~10-15 minutes)
sudo ./build-import-containers.sh

# Verify all images imported
sudo k3s crictl images | grep open5gs
# Expected: 10 images (nrf, scp, amf, smf, upf, udm, udr, ausf, pcf, nssf)
```

---

## 5️⃣ Deploy Open5GS to K3s

```bash
# Make deploy script executable
chmod +x deploy-k3s-calico.sh

# Run deployment
sudo ./deploy-k3s-calico.sh

# Monitor deployment in another terminal
kubectl get pods -n open5gs -w

# Wait until all pods are Running (2-3 minutes)
kubectl get pods -n open5gs
# Expected: 10 pods, all STATUS = Running, READY = 1/1
```

---

## 6️⃣ Setup MongoDB External Endpoint

```bash
# Get host IP
HOST_IP=$(hostname -I | awk '{print $1}')
echo "Host IP: $HOST_IP"

# Create MongoDB external service
cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: Service
metadata:
  name: mongodb
  namespace: open5gs
spec:
  ports:
  - port: 27017
    targetPort: 27017
---
apiVersion: v1
kind: Endpoints
metadata:
  name: mongodb
  namespace: open5gs
subsets:
- addresses:
  - ip: $HOST_IP
  ports:
  - port: 27017
EOF

# Restart PCF and UDR if they crashed
kubectl delete pod pcf-0 udr-0 -n open5gs

# Verify all pods running
kubectl get pods -n open5gs
```

---

## 7️⃣ Configure UERANSIM

### Update gNB Configuration

```bash
cd ~/Open5GS-Testbed/ueransim/configs

# Get AMF pod IP
AMF_IP=$(kubectl get pod amf-0 -n open5gs -o jsonpath='{.status.podIP}')
echo "AMF IP: $AMF_IP"

# Get host IP for gNB
HOST_IP=$(hostname -I | awk '{print $1}')
echo "Host IP: $HOST_IP"

# Update gNB config
sed -i "s/linkIp: .*/linkIp: $HOST_IP/" open5gs-gnb-k3s.yaml
sed -i "s/ngapIp: .*/ngapIp: $HOST_IP/" open5gs-gnb-k3s.yaml
sed -i "s/gtpIp: .*/gtpIp: $HOST_IP/" open5gs-gnb-k3s.yaml
sed -i "s/address: .*/address: $AMF_IP/" open5gs-gnb-k3s.yaml

# Verify changes
grep -E "linkIp|ngapIp|gtpIp|address:" open5gs-gnb-k3s.yaml
```

### Update UE Configuration

```bash
# Update gnbSearchList
sed -i "s/127.0.0.1/$HOST_IP/" open5gs-ue-embb.yaml
sed -i "s/10.34.4.130/$HOST_IP/" open5gs-ue-embb.yaml

# Update IMSI to match MongoDB
sed -i 's/imsi-001011000000001/imsi-001010000000001/' open5gs-ue-embb.yaml

# Verify changes
grep -A 3 "gnbSearchList:" open5gs-ue-embb.yaml
grep "supi:" open5gs-ue-embb.yaml
```

---

## 8️⃣ Run UERANSIM Tests

### Terminal 1 - Start gNB (Background)

```bash
cd ~/Open5GS-Testbed/ueransim
nohup ./build/nr-gnb -c configs/open5gs-gnb-k3s.yaml > gnb.log 2>&1 &

# Check gNB log
tail -f gnb.log
# Expected: [ngap] [info] NG Setup procedure is successful
# Press Ctrl+C to exit tail
```

### Terminal 2 - Start UE (Background)

```bash
cd ~/Open5GS-Testbed/ueransim
sudo screen -dmS ue bash -c './build/nr-ue -c configs/open5gs-ue-embb.yaml > ue.log 2>&1'

# Wait 3 seconds for registration
sleep 3

# Check UE log
tail -20 ue.log
# Expected: [app] [info] Connection setup for PDU session[1] is successful, 
#           TUN interface[uesimtun0, 10.45.0.X] is up.
```

---

## 9️⃣ Connectivity Tests

### Check TUN Interface

```bash
ip addr show uesimtun0
# Expected: inet 10.45.0.X/24
```

### Test Gateway (UE → UPF)

```bash
sudo ping -I uesimtun0 -c 4 10.45.0.1
# Expected: 0% packet loss
```

### Test Internet

```bash
sudo ping -I uesimtun0 -c 4 8.8.8.8
# Expected: 0% packet loss
```

### Test DNS

```bash
nslookup google.com 8.8.8.8
# Expected: Resolved IPs returned
```

### Test HTTP

```bash
sudo wget --bind-address=10.45.0.3 -O /dev/null http://www.google.com
# Expected: Download successful
```

### Test Traceroute

```bash
sudo traceroute -i uesimtun0 -m 5 8.8.8.8
# Expected: Route through 10.45.0.1 → Gateway → Internet
```

---

## 🔍 Verification Commands

### Check All Pods

```bash
kubectl get pods -n open5gs
# All should be Running with 0 restarts
```

### Check Pod IPs

```bash
kubectl get pods -n open5gs -o wide
# Verify static IPs: 10.10.0.X
```

### Check gNB Process

```bash
ps aux | grep nr-gnb | grep -v grep
# Should show running process
```

### Check UE Process

```bash
ps aux | grep nr-ue | grep -v grep
# Should show running process
```

### Check MongoDB

```bash
sudo docker ps | grep mongo
# Should show MongoDB container running
```

---

## 🛑 Stop All Services

### Stop UERANSIM

```bash
# Kill UE
sudo pkill -f nr-ue

# Kill gNB
pkill -f nr-gnb

# Kill screen session if used
screen -ls
screen -X -S ue quit
```

### Stop Open5GS

```bash
kubectl delete namespace open5gs
```

### Stop K3s (Optional)

```bash
sudo systemctl stop k3s
```

### Uninstall K3s (Optional)

```bash
/usr/local/bin/k3s-uninstall.sh
```

---

## 📊 Monitoring Commands

### Watch Pods

```bash
watch -n 1 kubectl get pods -n open5gs
```

### Follow AMF Logs

```bash
kubectl logs -n open5gs amf-0 -f
```

### Follow SMF Logs

```bash
kubectl logs -n open5gs smf-0 -f
```

### Follow UPF Logs

```bash
kubectl logs -n open5gs upf-0 -f
```

### Check All Pod Logs

```bash
for pod in $(kubectl get pods -n open5gs -o name); do
    echo "=== $pod ==="
    kubectl logs -n open5gs $pod --tail=10
    echo ""
done
```

---

## 🐛 Troubleshooting Commands

### Check Pod Status

```bash
kubectl describe pod <pod-name> -n open5gs
```

### Check Pod Events

```bash
kubectl get events -n open5gs --sort-by='.lastTimestamp'
```

### Check Network Policies

```bash
kubectl get networkpolicies -n open5gs
```

### Check Services

```bash
kubectl get services -n open5gs
```

### Test Pod-to-Pod Communication

```bash
kubectl exec -it -n open5gs amf-0 -- ping -c 2 10.10.0.10
```

### Check MongoDB Connection from Pod

```bash
kubectl exec -it -n open5gs udr-0 -- nc -zv mongodb 27017
```

### Restart Pod

```bash
kubectl delete pod <pod-name> -n open5gs
# StatefulSet will automatically recreate it
```

---

## ✅ Success Indicators

### Expected Terminal Outputs

**Terminal 1 (gNB):**
```
[ngap] [info] NG Setup procedure is successful
```

**Terminal 2 (UE):**
```
[nas] [info] UE switches to state [MM-REGISTERED/NORMAL-SERVICE]
[nas] [info] PDU Session establishment is successful PSI[1]
[app] [info] Connection setup for PDU session[1] is successful, 
      TUN interface[uesimtun0, 10.45.0.X] is up.
```

**Terminal 3 (Ping):**
```
4 packets transmitted, 4 received, 0% packet loss
```

---

## 📝 Quick Deployment Script

Save this as `quick-deploy.sh`:

```bash
#!/bin/bash
set -e

echo "🚀 Starting Open5GS K3s Deployment..."

# Variables
HOST_IP=$(hostname -I | awk '{print $1}')

# Step 1: Clone repo
echo "📥 Cloning repository..."
rm -rf ~/Open5GS-Testbed
git clone https://github.com/rayhanegar/Open5GS-Testbed.git
cd ~/Open5GS-Testbed/open5gs/open5gs-k3s-calico

# Step 2: Setup K3s
echo "🔧 Setting up K3s..."
chmod +x setup-k3s-environment-calico.sh
sudo ./setup-k3s-environment-calico.sh

# Step 3: Build images
echo "🏗️ Building images..."
sed -i 's/docker build/sudo docker build/g' build-import-containers.sh
sed -i 's/docker save/sudo docker save/g' build-import-containers.sh
sed -i 's/k3s ctr/sudo k3s ctr/g' build-import-containers.sh
chmod +x build-import-containers.sh
sudo ./build-import-containers.sh

# Step 4: Deploy
echo "🚢 Deploying Open5GS..."
chmod +x deploy-k3s-calico.sh
sudo ./deploy-k3s-calico.sh

# Step 5: MongoDB endpoint
echo "💾 Creating MongoDB endpoint..."
kubectl apply -f - <<EOF
apiVersion: v1
kind: Service
metadata:
  name: mongodb
  namespace: open5gs
spec:
  ports:
  - port: 27017
    targetPort: 27017
---
apiVersion: v1
kind: Endpoints
metadata:
  name: mongodb
  namespace: open5gs
subsets:
- addresses:
  - ip: $HOST_IP
  ports:
  - port: 27017
EOF

sleep 10
kubectl delete pod pcf-0 udr-0 -n open5gs 2>/dev/null || true

echo "✅ Deployment complete! Waiting for pods..."
kubectl wait --for=condition=Ready pod --all -n open5gs --timeout=300s

echo "🎉 All done! Check with: kubectl get pods -n open5gs"
```

Make executable and run:
```bash
chmod +x quick-deploy.sh
./quick-deploy.sh
```

---

**Last Updated**: 1 Desember 2025  
**Status**: ✅ Verified Working
