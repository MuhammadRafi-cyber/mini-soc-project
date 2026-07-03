# 🛡️ Mini SOC Project — Splunk + MikroTik CHR + Kali Linux

> **Security Operations Center Lab Environment**  
> Tugas UAS — Keamanan Jaringan  
> Menggunakan SIEM Splunk untuk mendeteksi dan menganalisis serangan jaringan secara real-time.

---

## 📋 Daftar Isi

- [Deskripsi Project](#-deskripsi-project)
- [Topologi & Infrastruktur](#-topologi--infrastruktur)
- [Komponen Sistem](#-komponen-sistem)
- [Skenario Serangan](#-skenario-serangan)
- [Dashboard](#-dashboard)
- [Alert & Severity](#-alert--severity)
- [Sistem Risk Scoring](#-sistem-risk-scoring)
- [Struktur Repository](#-struktur-repository)
- [Cara Reproduksi Lab](#-cara-reproduksi-lab)
- [Hasil & Temuan](#-hasil--temuan)

---

## 📌 Deskripsi Project

Project ini membangun lingkungan **Mini Security Operations Center (SOC)** menggunakan:
- **Splunk Enterprise** sebagai SIEM (Security Information and Event Management)
- **MikroTik CHR** sebagai router/firewall sumber log
- **Kali Linux** sebagai simulator penyerang

Lab ini dirancang sebagai **isolated environment** (VMware Host-Only Network) sehingga semua traffic bersifat terkontrol dan mudah dianalisis.

---

## 🖧 Topologi & Infrastruktur

```
┌─────────────────────────────────────────────┐
│              HOST WINDOWS                    │
│         Splunk Enterprise                    │
│         IP: 192.168.169.253                  │
│                    │                         │
│      VMware Host-Only (VMnet)                │
│         ┌──────────┴──────────┐             │
│         │                     │             │
│  ┌─────────────┐    ┌──────────────────┐   │
│  │ MikroTik CHR│    │   Kali Linux     │   │
│  │192.168.169.1│    │ 192.168.169.2    │   │
│  │Router/FW    │    │ Attacker/Scanner │   │
│  └─────────────┘    └──────────────────┘   │
└─────────────────────────────────────────────┘

Alur Log: MikroTik → Syslog UDP 514 → Splunk index=mikrotik
```

| Komponen | Spesifikasi |
|---|---|
| Host OS | Windows 10/11 |
| Hypervisor | VMware Workstation |
| SIEM | Splunk Enterprise (free license) |
| Router/Firewall | MikroTik CHR (RouterOS) |
| Attacker | Kali Linux |
| Network | VMware Host-Only (isolated) |
| RAM Minimum | 16 GB |

---

## 🔧 Komponen Sistem

### MikroTik CHR — Firewall Rules

| Rule # | Fungsi | Log Prefix |
|---|---|---|
| 0 | Allow established/related | — |
| 1 | Drop invalid | — |
| 2 | Allow limited ICMP (rate limit) | — |
| 3 | Detect port scan (PSD) | `PORT-SCAN-DETECTED` |
| 4 | Drop excess ICMP | `ICMP-FLOOD-DETECTED` |
| 5 | Block detected scanners | `PORT-SCAN-BLOCKED` |
| 6 | Jump ke ssh-brute chain | — |
| 7–12 | SSH progressive blacklist | `SSH-BRUTEFORCE-DETECTED/BLOCKED` |
| 13 | Block Telnet (port 23) | `FW-VIOLATION-TELNET` |
| 14 | Block FTP (port 21) | `FW-VIOLATION-FTP` |
| 15 | Block WWW (port 80) | `FW-VIOLATION-WWW` |
| 16 | Block API (port 8728) | `FW-VIOLATION-API` |
| 17 | Block Winbox eksternal (8291) | `FW-VIOLATION-WINBOX` |
| 18 | Default drop — log semua sisanya | `FW-DEFAULT-DROP` |

### Splunk — Index & Konfigurasi

- **Index:** `mikrotik`
- **Data Input:** UDP port 514 (Syslog)
- **Sourcetype:** `mikrotik:syslog`
- **Field Extractions:** `alert_type`, `src_ip`, `src_port`, `dst_ip`, `dst_port`
- **Search Macro:** `get_severity` (severity classification + risk scoring)

---

## ⚔️ Skenario Serangan

| # | Skenario | Tool | Alert Type | Severity |
|---|---|---|---|---|
| 1 | Port Scanning | Nmap | `PORT-SCAN-DETECTED` | Low |
| 2 | SSH Brute Force | Hydra | `SSH-BRUTEFORCE-BLOCKED` | High |
| 3 | DoS / SYN Flood | hping3 | `FW-DEFAULT-DROP` | Medium |
| 4 | ICMP Flood / Ping Sweep | hping3 | `ICMP-FLOOD-DETECTED` | Medium |
| 5 | Firewall Rule Violation | netcat | `FW-VIOLATION-*` | Medium |
| 6 | Service Enumeration | Nmap -sV | `PORT-SCAN-DETECTED` | Low |
| 7 | Connection to Disabled Service | netcat | `FW-VIOLATION-*` | Medium |

---

## 📊 Dashboard

Dashboard dibuat di Splunk dengan total **9 panel**:

| Panel | Deskripsi | SPL Query |
|---|---|---|
| 1 | Top Attacker IP | Lihat `splunk/queries/dashboard_queries.spl` |
| 2 | Top Destination Port | Lihat `splunk/queries/dashboard_queries.spl` |
| 3 | Firewall Drop Events | Lihat `splunk/queries/dashboard_queries.spl` |
| 4 | Login Failure | Lihat `splunk/queries/dashboard_queries.spl` |
| 5 | Timeline Serangan | Lihat `splunk/queries/dashboard_queries.spl` |
| 6 | ICMP Flood Timeline | Lihat `splunk/queries/dashboard_queries.spl` |
| 7 | Top ICMP Flood Source | Lihat `splunk/queries/dashboard_queries.spl` |
| 8 | Connection to Disabled Service | Lihat `splunk/queries/dashboard_queries.spl` |
| 9 | Attack Category Breakdown | Lihat `splunk/queries/dashboard_queries.spl` |

---

## 🚨 Alert & Severity

### Tingkatan Severity

| Severity | Skor | Tindakan |
|---|---|---|
| **Low** | 1–2 | Hanya dicatat di dashboard, tidak ada alert |
| **Medium** | 5 | Tampil di dashboard Severity Distribution, tidak ada alert otomatis |
| **High** | 8 | **Alert otomatis dikirim**, perlu investigasi segera |
| **Critical** | 10 | **Alert prioritas tertinggi**, respons segera diperlukan |

### Alert yang Dikonfigurasi

| Alert | Trigger Condition | Severity |
|---|---|---|
| Persistent Port Scanning | ≥3 scan dari 1 IP dalam 10 menit | High |
| SSH Brute Force Confirmed | IP masuk `ssh_blacklist` | High |
| Repeated Unauthorized Access | ≥5 violation dari 1 IP dalam 5 menit | High |
| Possible Account Compromise | Login sukses setelah ≥3 kali gagal | Critical |

---

## 📈 Sistem Risk Scoring

Risk score dihitung secara dinamis per IP penyerang berdasarkan akumulasi event:

| Risk Level | Rentang Skor | Arti |
|---|---|---|
| LOW | 0–5 | Aktivitas normal / percobaan tunggal |
| MEDIUM | 6–15 | Perlu dipantau, pola berulang |
| HIGH | 16–29 | Butuh investigasi aktif |
| CRITICAL | 30+ | Insiden serius, respons segera |

---

## 📁 Struktur Repository

```
mini-soc-project/
├── README.md                          # Dokumen ini
├── .gitignore                         # File yang tidak ditrack
├── docs/
│   ├── installation-guide.md          # Panduan instalasi lengkap
│   ├── attack-scenarios.md            # Panduan simulasi serangan
│   └── vulnerability-assessment.md   # Hasil asesmen kerentanan sistem
├── mikrotik/
│   ├── firewall-rules.rsc             # Export config firewall rules
│   ├── logging-config.rsc             # Export konfigurasi logging/syslog
│   └── README.md                      # Penjelasan konfigurasi MikroTik
├── splunk/
│   ├── queries/
│   │   └── dashboard_queries.spl      # Semua SPL query untuk dashboard
│   ├── dashboards/
│   │   └── mini_soc_dashboard.xml     # Export XML dashboard Splunk
│   ├── alerts/
│   │   └── alert_definitions.md       # Definisi & SPL semua alert
│   └── macros/
│       └── get_severity.md            # Definisi macro get_severity
├── kali-linux/
│   ├── attack_commands.sh             # Script semua command serangan
│   └── passlist.txt                   # Wordlist minimal untuk demo Hydra
├── screenshots/
│   ├── mikrotik/                      # Screenshot konfigurasi MikroTik
│   ├── splunk-dashboard/              # Screenshot dashboard Splunk
│   ├── splunk-alerts/                 # Screenshot triggered alerts
│   └── attacks/                       # Screenshot eksekusi serangan
└── reports/
    └── incident-report-template.md   # Template laporan insiden
```

---

## 🚀 Cara Reproduksi Lab

Lihat panduan lengkap di [`docs/installation-guide.md`](docs/installation-guide.md).

Secara ringkas:
1. Setup VMware Host-Only Network (subnet `192.168.169.0/24`)
2. Import MikroTik CHR `.ova` ke VMware, set IP `192.168.169.1`
3. Install Kali Linux di VMware, set IP `192.168.169.2`
4. Install Splunk Enterprise di Windows Host, set adapter VMnet ke `192.168.169.253`
5. Apply konfigurasi dari folder `mikrotik/` ke MikroTik
6. Buat index, data input, field extraction, dan macro di Splunk (lihat `splunk/`)
7. Import dashboard dari `splunk/dashboards/mini_soc_dashboard.xml`
8. Jalankan skenario serangan dari `kali-linux/attack_commands.sh`

---

## 📝 Hasil & Temuan

Semua serangan berhasil **terdeteksi dan tercatat** di Splunk:

- ✅ Port Scanning → `PORT-SCAN-DETECTED` + `PORT-SCAN-BLOCKED`
- ✅ SSH Brute Force → Progressive blacklist aktif, `SSH-BRUTEFORCE-BLOCKED`
- ✅ ICMP Flood → `ICMP-FLOOD-DETECTED` (rate limit 1 pkt/detik enforced)
- ✅ Firewall Violation → `FW-VIOLATION-*` per service
- ✅ Dashboard 9 panel berhasil menampilkan data real-time
- ✅ Alert High/Critical ter-trigger sesuai threshold yang dikonfigurasi

---

## ⚠️ Disclaimer

Project ini dibuat **hanya untuk tujuan pendidikan** dalam lingkungan lab terisolasi. Semua teknik serangan yang didemonstrasikan dilakukan terhadap sistem milik sendiri dalam jaringan tertutup. Penggunaan teknik ini terhadap sistem tanpa izin adalah ilegal.

---

*Dibuat sebagai Tugas UAS — Mata Kuliah Keamanan Jaringan*
