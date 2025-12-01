# 📸 Screenshot Instructions

Untuk mendapatkan screenshot Terminal 1, 2, dan 3, ikuti langkah berikut:

---

## 🖥️ Terminal 1 - gNB (Running)

**Status**: ✅ Sudah running di background

Output yang harus terlihat:
```
UERANSIM v3.2.7
[2025-12-01 11:50:24.497] [sctp] [info] Trying to establish SCTP connection... (10.10.0.5:38412)
[2025-12-01 11:50:24.505] [sctp] [info] SCTP connection established (10.10.0.5:38412)
[2025-12-01 11:50:24.549] [ngap] [info] NG Setup procedure is successful ✅
```

**Untuk melihat output**:
```bash
ssh ubuntu@192.168.100.141
cd ~/Open5GS-Testbed/ueransim
cat gnb_fresh.log
```

Atau lihat live:
```bash
ssh ubuntu@192.168.100.141
cd ~/Open5GS-Testbed/ueransim
tail -f gnb_fresh.log
```

---

## 📱 Terminal 2 - UE

**Buka terminal baru** dan jalankan:
```bash
ssh ubuntu@192.168.100.141
cd ~/Open5GS-Testbed/ueransim
sudo ./build/nr-ue -c configs/open5gs-ue-embb.yaml
```

Password sudo: `1234`

**Output yang harus terlihat**:
```
UERANSIM v3.2.7
[nas] [info] UE switches to state [MM-DEREGISTERED/PLMN-SEARCH]
[rrc] [info] RRC connection established
[nas] [info] UE switches to state [MM-REGISTERED/NORMAL-SERVICE] ✅
[nas] [info] Initial Registration is successful ✅
[nas] [info] PDU Session establishment is successful PSI[1] ✅
[app] [info] Connection setup for PDU session[1] is successful, 
      TUN interface[uesimtun0, 10.45.0.X] is up. ✅
```

**JANGAN TUTUP TERMINAL INI** - biarkan tetap running untuk Terminal 3!

---

## 🧪 Terminal 3 - Connectivity Tests

**Buka terminal baru ketiga** (Terminal 2 harus tetap running!):

```bash
ssh ubuntu@192.168.100.141
sudo bash /tmp/test_terminal3.sh
```

Password sudo: `1234`

**Output yang harus terlihat**:
```
=== TERMINAL 3: CONNECTIVITY TESTS ===

[TEST 1] TUN Interface Status:
    inet 10.45.0.X/24 scope global uesimtun0 ✅

[TEST 2] Gateway Ping (10.45.0.1):
4 packets transmitted, 4 received, 0% packet loss ✅

[TEST 3] Internet Ping (8.8.8.8):
4 packets transmitted, 4 received, 0% packet loss ✅

[TEST 4] DNS Resolution:
Name:   google.com
Address: 172.217.194.113 ✅

=== ALL TESTS COMPLETE ===
```

---

## 📸 Screenshot Checklist

Upload screenshot dengan nama:

- [ ] `terminal1-gnb.png` - Screenshot Terminal 1 (gNB)
- [ ] `terminal2-ue.png` - Screenshot Terminal 2 (UE)  
- [ ] `terminal3-tests.png` - Screenshot Terminal 3 (Connectivity Tests)

Letakkan di folder: `screenshots/`

---

## 🔄 Jika Perlu Restart

**Kill semua process**:
```bash
ssh ubuntu@192.168.100.141
echo '1234' | sudo -S pkill -f nr-gnb
echo '1234' | sudo -S pkill -f nr-ue
```

**Start ulang dari awal**:

Terminal 1:
```bash
cd ~/Open5GS-Testbed/ueransim
./build/nr-gnb -c configs/open5gs-gnb-k3s.yaml
```

Terminal 2 (buka terminal baru):
```bash
cd ~/Open5GS-Testbed/ueransim
sudo ./build/nr-ue -c configs/open5gs-ue-embb.yaml
```

Terminal 3 (buka terminal baru):
```bash
sudo bash /tmp/test_terminal3.sh
```

---

**Setelah screenshot selesai, upload ke folder `screenshots/` di repository!** 📁
