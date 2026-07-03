# 🛡️ Mini Security Operations Center (SOC) Project

> Final Project for Network Security Course  
> Implementation of a Mini SOC using Splunk SIEM, MikroTik CHR, and Kali Linux

---

## 📌 Project Overview

This project demonstrates the implementation of a small-scale Security Operations Center (SOC) environment for monitoring, detecting, and responding to network security incidents in real time using:

- Splunk Enterprise as SIEM platform
- MikroTik CHR as firewall and log source
- Kali Linux as attack simulation machine

---

## 👥 Team Information

| Name | Student ID | Role |
|------|-----------|------|
| Muhammad Rafi’i | 2410512040 | Security Engineer & MikroTik Hardening |
| Pankrasius Aryo Wicaksono | 2410512052 | SOC Analyst & Splunk Architecture |
| Mirza Rabbani Kobandaha | 2410512059 | Penetration Tester & Attack Simulation |

**Course:** Network Security  
**Lecturer:** Rido Zulfahmi, S.Kom., M.T.  
**Study Program:** Information Systems  
**Faculty:** Computer Science  
**University:** Universitas Pembangunan Nasional Veteran Jakarta  
**Academic Year:** 2025/2026

---

# 🏗️ Infrastructure

## Network Topology

```text
                    +-----------------------+
                    |   Splunk Enterprise   |
                    |   192.168.169.253     |
                    +-----------+-----------+
                                |
                     VMware Host-Only Network
                                |
         -------------------------------------------------
         |                                               |
+-------------------+                     +-------------------+
|   MikroTik CHR    |                     |    Kali Linux     |
|   192.168.169.1   |                     |   192.168.169.2   |
| Firewall & Router |                     | Attack Simulator  |
+-------------------+                     +-------------------+
```

## IP Address Mapping

| Device | Function | IP Address |
|--------|----------|-----------|
| Splunk Server | SIEM & Log Receiver | `192.168.169.253` |
| MikroTik CHR | Router & Firewall | `192.168.169.1` |
| Kali Linux | Attack Machine | `192.168.169.2` |

---

# ⚙️ MikroTik Configuration

## Syslog Forwarding

```routeros
/system logging action add \
name=tosplunk \
target=remote \
remote=192.168.169.253 \
remote-port=514

/system logging add topics=firewall action=tosplunk
/system logging add topics=account action=tosplunk
```

## Service Hardening

```routeros
/ip service set telnet disabled=yes
/ip service set ftp disabled=yes
/ip service set www disabled=yes
/ip service set api disabled=yes
/ip service set ssh port=22 disabled=no
```

---

# 🔥 Firewall Protection

Implemented security controls include:

- Established and Related connection handling
- Invalid packet filtering
- ICMP Flood protection
- Port Scan Detection (PSD)
- Multi-stage SSH brute-force blacklist
- Disabled service access monitoring
- Default deny policy

---

# ⚔️ Attack Simulations

## 1. Port Scanning

```bash
nmap -sS -p 1-1000 192.168.169.1
```

Expected result:

- Ports appear as `filtered`
- Splunk generates:
  - `PORT-SCAN-DETECTED`
  - `PORT-SCAN-BLOCKED`

---

## 2. SSH Brute Force

```bash
hydra -l admin -P passlist.txt ssh://192.168.169.1 -t 4 -V
```

Expected result:

- Connection timeout
- Multi-stage blacklist activation
- Alert generated:
  - `SSH-BRUTEFORCE-BLOCKED`

---

## 3. ICMP Flood Attack

```bash
sudo timeout 15 hping3 --icmp --flood 192.168.169.1
```

Expected result:

- Packet loss reaches 100%
- Splunk detects:
  - `ICMP-FLOOD-DETECTED`

---

## 4. Firewall Rule Violation

```bash
nc -vz 192.168.169.1 23
nc -vz 192.168.169.1 21
```

Expected result:

- Connection timeout
- Firewall violation logs generated

---

# 📊 Splunk Dashboard

The SOC dashboard contains:

1. Top Attacker IP
2. Top Destination Port
3. Firewall Drop Trend
4. Login Failure Statistics
5. Attack Timeline
6. ICMP Flood Timeline
7. Disabled Service Access
8. Severity Distribution
9. Host Risk Score

---

# 🚨 Triggered Alerts

| Alert | Severity |
|------|----------|
| Port Scan Detected | Medium |
| SSH Brute Force Attack | High |
| Firewall Rule Violation | High |

---

# 🧠 Incident Analysis (5W1H)

| Category | Analysis |
|----------|----------|
| What | Automated SSH dictionary attack |
| Who | Kali Linux (`192.168.169.2`) |
| When | 28 June 2026 - 10:40:10 |
| Where | MikroTik SSH Service (`192.168.169.1:22`) |
| Why | Default SSH service exposed |
| How | Multi-threaded brute force using Hydra |

---

# 🛡️ Recommendations

- Change default SSH port.
- Implement SSH tarpit protection.
- Use SSH public key authentication.
- Restrict management access using trusted IP addresses.
- Implement MFA whenever possible.

---

# ✅ Conclusion

The project successfully demonstrated how centralized logging and SIEM correlation improve visibility into security incidents and significantly enhance network defense capabilities in a small-scale environment.
