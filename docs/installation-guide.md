# Panduan Instalasi Lengkap Lab Mini SOC

Dokumen ini berisi panduan langkah demi langkah untuk membangun infrastruktur laboratorium virtual Mini Security Operations Center (SOC) menggunakan **Splunk Enterprise**, **MikroTik CHR**, dan **Kali Linux** di dalam lingkungan jaringan terisolasi VMware.

---

## 📋 1. Prasyarat & Spesifikasi Sistem

Sebelum memulai instalasi, pastikan sistem host Anda memenuhi spesifikasi minimum berikut untuk menghindari performa lambat atau kegagalan virtualisasi (*hang/crash*):

* **Processor:** Intel Core i5/i7 atau AMD Ryzen 5/7 dengan fitur virtualisasi (**VT-x/AMD-V**) aktif di BIOS.
* **RAM:** Minimal **16 GB** (Alokasi: Windows Host ±6-8GB, Splunk ±4GB, Kali Linux ±2-4GB, MikroTik CHR 256MB).
* **Storage:** Tersisa minimal **40 GB** SSD (Sangat disarankan menggunakan SSD karena SIEM Splunk melakukan operasi I/O yang intensif).
* **Hypervisor:** VMware Workstation Pro / Player (Versi 16 atau 17).

---

## 🌐 2. Konfigurasi Jaringan Virtual (VMware Virtual Network Editor)

Lab ini menggunakan jaringan tipe **Host-Only** yang terisolasi dari internet untuk memastikan aktivitas serangan aman dan konsisten tanpa gangguan dari DHCP server eksternal.

1. Buka aplikasi **VMware Workstation**.
2. Klik menu **Edit** $\rightarrow$ **Virtual Network Editor...** (Jika tombol terkunci, klik *Change Settings* di pojok kanan bawah dengan hak akses Administrator).
3. Pilih salah satu VMnet yang kosong atau buat baru, beri tipe **Host-only** (Contoh: `VMnet2` atau `VMnet3`).
4. **Matikan** opsi **"Use local DHCP service to distribute IP addresses to VMs"** (Dicentang $\rightarrow$ Hilangkan centang). Ini wajib dilakukan agar IP tidak berubah-ubah.
5. Pada kolom **Subnet IP**, masukkan: `192.168.169.0`
6. Pada kolom **Subnet Mask**, masukkan: `255.255.255.0`
7. Klik **Apply** lalu **OK**.

---

## 💻 3. Konfigurasi IP Statis pada Windows Host (SIEM Splunk)

Windows Host bertindak sebagai server utama tempat SIEM Splunk Enterprise berjalan dan mendengarkan log masuk.

1. Di Windows Host, tekan tombol `Win + R`, ketik `ncpa.cpl`, lalu tekan **Enter** untuk membuka *Network Connections*.
2. Cari adapter virtual yang bernama **VMware Network Adapter VMnetX** (Sesuaikan dengan nomor VMnet Host-Only yang Anda pilih pada langkah sebelumnya).
3. Klik kanan pada adapter tersebut $\rightarrow$ **Properties**.
4. Pilih **Internet Protocol Version 4 (TCP/IPv4)** $\rightarrow$ Klik **Properties**.
5. Pilih **Use the following IP address** dan masukkan konfigurasi berikut:
* **IP address:** `192.168.169.253`
* **Subnet mask:** `255.255.255.0`
* **Default gateway:** *Kosongkan*


6. Klik **OK** dan **Close**.

---

## 🛡️ 4. Deployment & Konfigurasi MikroTik CHR

MikroTik Cloud Hosted Router (CHR) bertindak sebagai infrastruktur utama, firewall, dan *log source* (syslog exporter).

### 4.1 Deployment VM

1. Unduh berkas disk MikroTik CHR berformat `.vmdk` atau template `.ova` dari situs resmi MikroTik.
2. Buat VM baru di VMware dengan tipe OS *Other Linux 64-bit*, alokasikan RAM **256 MB** dan 1 Core CPU.
3. Pasang network adapter VM ke jaringan custom Host-Only: **Edit Virtual Machine Settings** $\rightarrow$ **Network Adapter** $\rightarrow$ Pilih **Custom: Specific virtual network** $\rightarrow$ Pilih **VMnetX (Host-only)** yang telah dikonfigurasi.

### 4.2 Konfigurasi IP Statis Dasar

Nyalakan VM MikroTik CHR, masuk menggunakan *username* `admin` (tanpa password default), lalu buka terminal dan jalankan perintah berikut:

```routeros
# Mengonfigurasi IP address pada interface utama (ether1)
/ip address add address=192.168.169.1/24 interface=ether1

# Mengubah identitas router agar mudah dikenali di Splunk
/system identity set name=MIKROTIK-SOC

```

---

## ⚔️ 5. Deployment & Konfigurasi Kali Linux

Kali Linux berperan sebagai mesin penyerang (*Attacker Machine*) yang akan mensimulasikan berbagai macam gangguan keamanan jaringan.

### 5.1 Deployment VM

1. Unduh berkas VM Kali Linux siap pakai (.7z/.zip) untuk VMware dari situs Offensive Security.
2. Ekstrak dan jalankan di VMware Workstation.
3. Ubah pengaturan Network Adapter ke jaringan custom yang sama: **Network Adapter** $\rightarrow$ **Custom: Specific virtual network** $\rightarrow$ Pilih **VMnetX (Host-only)**.

### 5.2 Konfigurasi IP Statis

Nyalakan Kali Linux, buka terminal, lalu konfigurasikan IP secara statis menggunakan perintah berikut (ganti `eth0` jika nama interface Anda berbeda):

```bash
# Menambahkan IP statis ke interface eth0
sudo ip addr add 192.168.169.2/24 dev eth0

# Mengaktifkan interface link
sudo ip link set eth0 up

```

*(Catatan: Anda juga bisa mengonfigurasi ini secara permanen melalui GUI Network Manager di pojok kanan atas desktop Kali Linux dengan memilih mode Manual/Static IPv4).*

---

## 📊 6. Instalasi & Konfigurasi Awal Splunk Enterprise

1. Unduh installer **Splunk Enterprise** untuk Windows (`.msi`) dari situs resmi Splunk.
2. Jalankan instalasi, buat akun administrator (misal: *username*: `admin`, *password*: `SplunkAdmin2026`).
3. Setelah instalasi selesai, buka browser di Windows Host dan akses web panel Splunk di URL: `http://localhost:8000`.
4. Login menggunakan kredensial yang telah dibuat.

### 6.1 Membuat Index Khusus

1. Di halaman utama Splunk, klik **Settings** $\rightarrow$ **Data** $\rightarrow$ **Indexes**.
2. Klik tombol **New Index** di pojok kanan atas.
3. Isi **Index Name**: `mikrotik`
4. Biarkan opsi lainnya default, lalu klik **Save**.

### 6.2 Membuka Data Input UDP (Syslog listener)

1. Klik **Settings** $\rightarrow$ **Data** $\rightarrow$ **Data inputs**.
2. Cari bagian **UDP**, lalu klik **+ Add New**.
3. Pada kolom **Port**, isi: `514` (Jika port 514 bentrok dengan service Windows lain, gunakan port `1514` dan sesuaikan port remote pada MikroTik).
4. Klik **Next**.
5. Pada halaman *Input Settings*:
* **Source type:** Klik *Select* $\rightarrow$ Pilih **Operating System** $\rightarrow$ Pilih **syslog**.
* **App context:** Pilih **Search & Reporting (search)**.
* **Host:** Pilih **IP**.
* **Index:** Pilih **mikrotik** (Index yang dibuat pada langkah sebelumnya).


6. Klik **Review** lalu **Submit**.

---

## 🛡️ 7. Konfigurasi Windows Inbound Firewall Rule

Supaya Windows Host mengizinkan paket log UDP dari MikroTik masuk ke Splunk, Anda wajib membuka port di firewall lokal Windows:

1. Buka **Windows Defender Firewall with Advanced Security**.
2. Klik menu **Inbound Rules** di panel kiri, lalu klik **New Rule...** di panel kanan.
3. Pilih **Rule Type**: `Port` $\rightarrow$ Klik **Next**.
4. Pilih **UDP** dan masukkan pada kolom **Specific local ports**: `514` (atau `1514` sesuai konfigurasi data input Anda) $\rightarrow$ Klik **Next**.
5. Pilih **Allow the connection** $\rightarrow$ Klik **Next**.
6. Centang opsi **Domain**, **Private**, dan **Public** $\rightarrow$ Klik **Next**.
7. Beri nama rule tersebut, contoh: `Splunk Syslog Inbound Listener` $\rightarrow$ Klik **Finish**.

---

## 🏁 8. Matriks Validasi Interkoneksi (Uji Koneksi Akhir)

Sebelum masuk ke fase konfigurasi firewall tingkat lanjut dan simulasi serangan, pastikan seluruh komponen dapat saling terhubung dengan melakukan tes ping antar mesin sesuai matriks berikut:

| Dari Komponen (Asal) | Perintah Ping ke Target | Status yang Diharapkan |
| --- | --- | --- |
| **Kali Linux** (`192.168.169.2`) | `ping -c 4 192.168.169.1` (MikroTik) | **REPLY / SUCCESS** |
| **Kali Linux** (`192.168.169.2`) | `ping -c 4 192.168.169.253` (Splunk) | **REPLY / SUCCESS** |
| **MikroTik CHR** (`192.168.169.1`) | `ping 192.168.169.253` (Splunk) | **REPLY / SUCCESS** |

> ⚠️ **PENTING (Jaring Pengaman):** Jika semua status di atas sudah sukses, matikan ketiga VM sebentar lalu lakukan **Take Snapshot** di VMware dengan nama **"Fresh Installation & Network Verified"**. Ini sangat penting sebagai cadangan untuk mengembalikan kondisi sistem jika sewaktu-waktu lab mengalami galat atau macet saat uji coba serangan banjir data (*flooding*).
