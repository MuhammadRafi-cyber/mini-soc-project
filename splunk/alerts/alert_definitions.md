# 🚨 Definisi & Konfigurasi Alert Berbasis Risiko (Risk-Based Alerting)

Dokumen ini mendokumentasikan konfigurasi sistem deteksi peringatan otomatis (*automated alerting*) pada SIEM Splunk Enterprise. Konfigurasi ini dirancang menggunakan prinsip **Anti-Alert Fatigue**, di mana sistem hanya akan memicu alarm aktif (*Triggered Alerts*) untuk insiden kategori *High* dan *Critical*, sedangkan serangan ringan (*Low/Medium*) cukup diakumulasikan ke dalam dashboard pemantauan.

---

## 📊 1. Matriks Klasifikasi Severity & Aksi Respons

| Severity | Batas Threshold | Logika / Justifikasi di Dunia Nyata | Tindakan Sistem & Analis SOC |
| --- | --- | --- | --- |
| **LOW** | Hasil Tunggal / Pasif | Aktivitas *reconnaissance* awal atau noise jaringan biasa (pemindaian port tunggal). | Hanya dicatat dalam indeks dan divisualisasikan pada grafik dashboard. **Tidak memicu alert.** |
| **MEDIUM** | Pola Berulang Rendah | Aktivitas anomali terkoordinasi berskala kecil (misalnya kegagalan login tunggal). | Ditampilkan di dashboard *Severity Distribution*. Masuk ke pemantauan manual analis SOC Tier-1. **Tidak memicu alert.** |
| **HIGH** | Agresif / Terstruktur | Pola serangan persisten yang berpotensi merusak availabilitas atau integritas sistem (Brute Force terblokir). | **Sistem memicu alert otomatis.** Analis SOC Tier-2 wajib melakukan investigasi forensik dan validasi status pertahanan. |
| **CRITICAL** | Kompromi Sistem | Indikasi kuat bahwa perimeter pertahanan telah ditembus oleh penyerang (Akses akun ilegal). | **Sistem memicu alert prioritas tertinggi.** *Incident Response Team* diaktifkan seketika untuk melakukan isolasi host. |

---

## 🛠️ 2. Spesifikasi Teknis Konfigurasi 4 Alert Utama

### 1. [ALERT-HIGH] Persistent Port Scanning Detected

* **Deskripsi:** Mendeteksi aktor yang melakukan pemindaian port secara persisten dan berulang kali (minimal 3 kali pemindaian terdeteksi/terblokir) dalam jendela waktu 10 menit.
* **Spesifikasi Pengaturan di Splunk GUI:**
* **Alert Type:** `Scheduled`
* **Time Range:** `Last 10 minutes`
* **Cron Schedule:** `*/5 * * * *` (Berjalan otomatis setiap 5 menit)
* **Trigger Condition:** `Number of Results > 0`
* **Trigger Actions:** `Add to Triggered Alerts`
* **Severity:** `High`


* **Query SPL:**

```spl
index=mikrotik alert_type="PORT-SCAN-DETECTED" OR alert_type="PORT-SCAN-BLOCKED"
| bucket _time span=10m
| stats count by src_ip, _time
| where count >= 3
| eval severity="High", reason="Port scan berulang ".count." kali dalam 10 menit — pola persisten/otomatis"

```

---

### 2. [ALERT-HIGH] SSH Brute Force - Blocked (Confirmed Attack Pattern)

* **Deskripsi:** Memicu alarm ketika mekanisme pertahanan eskalasi lapisan (*Stage Promotion*) MikroTik telah resmi mengunci IP penyerang ke dalam daftar hitam (`ssh_blacklist`) akibat serangan brute force agresif pada port 22.
* **Spesifikasi Pengaturan di Splunk GUI:**
* **Alert Type:** `Scheduled`
* **Time Range:** `Last 5 minutes`
* **Cron Schedule:** `*/5 * * * *` (Berjalan otomatis setiap 5 menit)
* **Trigger Condition:** `Number of Results > 0`
* **Trigger Actions:** `Add to Triggered Alerts`
* **Severity:** `High`


* **Query SPL:**

```spl
index=mikrotik alert_type="SSH-BRUTEFORCE-BLOCKED"
| `get_severity`
| where severity="High"
| stats count, values(alert_type) as detected_stages by src_ip

```

---

### 3. [ALERT-HIGH] Repeated Unauthorized Service Access Attempt

* **Deskripsi:** Mendeteksi adanya upaya pelanggaran kebijakan jala-jala (*network policy violation*) secara berulang (minimal 5 kali dalam 5 menit) pada port layanan manajemen internal yang sengaja dinonaktifkan (Telnet/FTP).
* **Spesifikasi Pengaturan di Splunk GUI:**
* **Alert Type:** `Scheduled`
* **Time Range:** `Last 5 minutes`
* **Cron Schedule:** `*/5 * * * *` (Berjalan otomatis setiap 5 menit)
* **Trigger Condition:** `Number of Results > 0`
* **Trigger Actions:** `Add to Triggered Alerts`
* **Severity:** `High`


* **Query SPL:**

```spl
index=mikrotik alert_type="FW-VIOLATION-TELNET" OR alert_type="FW-VIOLATION-FTP"
| bucket _time span=5m
| stats count by src_ip, _time
| where count >= 5
| eval severity="High", reason="Percobaan akses service terlarang berulang ".count." kali"

```

---

### 4. [ALERT-CRITICAL] Possible Account Compromise Detected

* **Deskripsi:** Alert paling kritikal (korelasi forensik cerdas). Mendeteksi situasi di mana penyerang (`src_ip`) berhasil melakukan login secara sukses (`logged in`) sesaat setelah melakukan minimal 3 kali kegagalan login berturut-turut (`login failure`) dalam runtutan *event tracking*.
* **Spesifikasi Pengaturan di Splunk GUI:**
* **Alert Type:** `Real-time` atau `Scheduled (Every 5 minutes)`
* **Time Range:** `Last 15 minutes`
* **Trigger Condition:** `Number of Results > 0`
* **Trigger Actions:** `Add to Triggered Alerts`
* **Severity:** `Critical`


* **Query SPL:**

```spl
index=mikrotik topics=account
| eval login_result=if(match(_raw, "(?i)logged in"), "success", if(match(_raw, "(?i)login failure|invalid"), "failure", "other"))
| where login_result!="other"
| streamstats current=f window=10 count(eval(login_result="failure")) as recent_failures by src_ip
| where login_result="success" AND recent_failures>=3
| eval severity="Critical", reason="Login berhasil setelah ".recent_failures." kali gagal — indikasi potensi compromise"

```

---

## 🔎 Cara Verifikasi Operasional Alert di SOC

Untuk memastikan visualisasi bukti deteksi otomatis ini dapat ditangkap dalam berkas laporan UAS Anda:

1. Pastikan simulasi serangan agresif (Hydra/Nmap) atau skenario *Account Compromise* (sengaja salah password lalu benar) telah dieksekusi di Kali Linux.
2. Tunggu jadwal interval *Cron* Splunk berjalan, lalu masuk ke bilah menu navigasi atas Splunk Web.
3. Klik menu **Activity** $\rightarrow$ **Triggered Alerts**.
4. Ambil tangkapan layar (*screenshot*) pada tabel alarm yang menyala merah untuk dilampirkan sebagai bukti autentik keberhasilan implementasi pertahanan aktif Mini SOC Anda.
