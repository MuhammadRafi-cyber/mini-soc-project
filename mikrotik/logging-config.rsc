# Berkas Konfigurasi: mini-soc-project/mikrotik/logging-config.rsc
# Deskripsi: Skrip otomasi Syslog Exporter ke SIEM Splunk Enterprise
# Mata Kuliah: Tugas UAS - Keamanan Jaringan
# Tanggal Ekspor / Modifikasi: 2026

#-------------------------------------------------------------------------------
# LANGKAH 1: MEMBUAT LOGGING ACTION (TARGET REMOTE SERVER)
#-------------------------------------------------------------------------------
# Menentukan ke mana log akan dikirim (IP Windows Host & Port UDP Syslog)
/system logging action
add name=to-splunk target=remote remote=192.168.169.253 remote-port=514 src-address=192.168.169.1

#-------------------------------------------------------------------------------
# LANGKAH 2: MEMETAKAN TOPIK LOG KE TARGET ACTION
#-------------------------------------------------------------------------------
# Mengarahkan aliran log berdasarkan kategori (topics) menuju action 'to-splunk'
/system logging

# Mencatat aktivitas filter firewall (seperti PORT-SCAN, ICMP-FLOOD, FW-VIOLATION)
add topics=firewall action=to-splunk

# Mencatat audit akses administratif (Login sukses, salah password, logout admin)
add topics=account action=to-splunk

# Mencatat perubahan konfigurasi internal sistem (seperti pembuatan/modifikasi rule)
add topics=system action=to-splunk

# Mencatat kegagalan kritis atau malfungsi pada sistem router
add topics=critical action=to-splunk

# Mencatat kejadian informatif umum operasional RouterOS
add topics=info action=to-splunk
