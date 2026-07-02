# 📑 Penjelasan Konfigurasi MikroTik CHR (Log Source & Perimeter Defense)

Direktori ini berisi berkas skrip otomasi konfigurasi untuk **MikroTik Cloud Hosted Router (CHR)** yang berfungsi sebagai *Gateway*, *Firewall*, sekaligus sumber log jala-jala (*Syslog Exporter*) yang dialirkan ke SIEM Splunk.

---

## 📁 Struktur Berkas

* **`firewall-rules.rsc`**: Skrip pengaturan filter firewall yang berisi 18 aturan komprehensif untuk mendeteksi, mencatat log, dan memitigasi serangan (*Drop & Log Policy*).
* **`logging-config.rsc`**: Skrip otomasi pengiriman log jala-jala (*Remote Syslog*) yang mengarahkan topik log krusial ke IP Splunk Server.

---

## 🚀 Cara Menerapkan Konfigurasi via Terminal

Untuk mereproduksi pengaturan lab ini pada mesin MikroTik CHR segar Anda, ikuti langkah berikut:

### 1. Unggah Berkas Script

Unggah berkas `firewall-rules.rsc` dan `logging-config.rsc` ke dalam direktori *root* MikroTik menggunakan fitur **Files** di Winbox, atau transfer melalui protokol FTP/SCP dari Kali Linux.

### 2. Eksekusi Skrip Otomasi

Buka **New Terminal** di Winbox atau konsol VMware MikroTik, kemudian jalankan perintah *import* berikut secara berurutan:

```routeros
# 1. Terapkan konfigurasi saluran pengiriman Syslog terlebih dahulu
/import file-name=logging-config.rsc

# 2. Terapkan seluruh aturan filter keamanan firewall
/import file-name=firewall-rules.rsc

```

---

## 🧠 Arsitektur & Logika Pertahanan Firewall

Firewall RouterOS dievaluasi menggunakan metode **Top-Down (Atas ke Bawah)**. Urutan penulisan aturan sangat krusial; paket data yang sudah memenuhi kriteria aturan di baris atas akan langsung dieksekusi (*Action*) dan tidak akan diproses oleh aturan di bawahnya.

Aturan dalam proyek ini dibagi menjadi 6 kelompok strategis:

### Kategori 1: Stateful Inspection (Rule 0 - 1)

Mengizinkan paket yang sudah memiliki hubungan koneksi terpercaya (`established, related`) untuk langsung lewat demi menghemat beban CPU, serta membuang paket cacat (`invalid`).

### Kategori 2: ICMP Rate Limiting & DoS Mitigation (Rule 2 - 3)

* **Logika Bisnis:** Mengizinkan aktivitas ping normal maksimal 10 paket per detik. Jika melampaui batas, paket dianggap sebagai serangan *ICMP Flood* dan langsung dijatuhkan serta diberi prefiks log `ICMP-FLOOD-DETECTED`.
* **Catatan Forensik Lab:** Kelompok ini sengaja diletakkan di atas sistem deteksi pemindaian port untuk menghindari efek penguncian awal (*Walled-Off Effect*) oleh skrip pemindai agresif.

### Kategori 3: Port Scan Detection (Rule 4 - 5)

Menggunakan mekanisme *Port Scan Detection* (PSD) bawaan RouterOS. Jika satu IP mencoba meraba banyak port dalam waktu singkat, IP tersebut otomatis dimasukkan ke dalam daftar hitam sementara (`port_scanners`) selama 10 menit dan seluruh lalu lintas berikutnya akan diblokir total (`PORT-SCAN-BLOCKED`).

### Kategori 4: Progressive SSH Blacklist (Rule 6 - 11)

Pertahanan berlapis khusus untuk port 22 (SSH) menggunakan sistem perpindahan tahapan (*Stage Promotion*):

* Koneksi baru masuk ke `stage1`.
* Jika melakukan percobaan berulang dalam 1 menit, naik ke `stage2`, lalu `stage3`.
* Jika tetap agresif menembus batas, IP dimasukkan ke `ssh_blacklist` selama 15 menit, memicu pemblokiran total dan mengirim log `SSH-BRUTEFORCE-BLOCKED` ke Splunk.

### Kategori 5: Unauthorized Service Access Management (Rule 12 - 16)

Menutup rapat dan mencatat log setiap ada entitas luar yang mencoba menyelinap masuk ke port manajemen kritis yang sengaja dinonaktifkan dalam kebijakan lab (Telnet, FTP, HTTP, API, Winbox). Menghasilkan log spesifik `FW-VIOLATION-*`.

### Kategori 6: Zero-Trust Baseline / Catch-All (Rule 17)

Aturan pamungkas paling bawah. Mengikuti prinsip keamanan *Deny by Default*, yaitu menjatuhkan dan mencatat log seluruh lalu lintas data tidak dikenal yang tidak diatur oleh aturan-aturan di atasnya (`FW-DEFAULT-DROP`).

---

## 🔎 Perintah Verifikasi Operasional (Sanity Check)

Untuk memastikan konfigurasi telah terpasang dengan benar dan siap menerima serangan simulator, jalankan perintah pengujian internal ini di terminal router:

```routeros
# Memeriksa daftar aturan filter firewall beserta hitungan jumlah paket yang tertangkap
/ip firewall filter print stats

# Memeriksa apakah IP penyerang masuk ke daftar pemblokiran otomatis saat simulasi
/ip firewall address-list print

# Memeriksa log aktivitas firewall lokal yang siap diekspor ke Splunk
/log print where topics~"firewall"

```
