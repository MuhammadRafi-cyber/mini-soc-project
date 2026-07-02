# Berkas Konfigurasi: mini-soc-project/mikrotik/firewall-rules.rsc
# Deskripsi: Skrip otomasi import aturan firewall MikroTik CHR untuk Lab Mini SOC
# Mata Kuliah: Tugas UAS - Keamanan Jaringan
# Tanggal Ekspor / Modifikasi: 2026

/interface wireless info
/ip firewall filter

#-------------------------------------------------------------------------------
# KELOMPOK 1: JARING PENGAMAN UTAMA (STATEFUL INSPECTION)
#-------------------------------------------------------------------------------
add chain=input connection-state=established,related action=accept \
    comment="0. SOC-HARDENING: Allow established and related connections"

add chain=input connection-state=invalid action=drop \
    comment="1. SOC-HARDENING: Drop invalid packets to save CPU resource"


#-------------------------------------------------------------------------------
# KELOMPOK 2: ANOMALI LAYER 3 (ICMP FLOOD DETECTION)
# Catatan Forensik: Diletakkan di atas PSD untuk mencegah intersepsi log global
#-------------------------------------------------------------------------------
add chain=input protocol=icmp limit=10,5:packet action=accept \
    comment="2. SOC-HARDENING: Allow limited and safe ICMP traffic (Ping)"

add chain=input protocol=icmp action=drop log=yes log-prefix="ICMP-FLOOD-DETECTED" \
    comment="3. SOC-MONITOR: Drop and log excess ICMP traffic as DoS indication"


#-------------------------------------------------------------------------------
# KELOMPOK 3: PENGINTAIAN JARINGAN (PORT SCAN DETECTION)
#-------------------------------------------------------------------------------
add chain=input protocol=tcp psd=21,3s,3,1 action=add-src-to-address-list \
    address-list=port_scanners address-list-timeout=10m log=yes log-prefix="PORT-SCAN-DETECTED" \
    comment="4. SOC-MONITOR: Detect port scanning activity and flag attacker IP"

add chain=input src-address-list=port_scanners action=drop log=yes log-prefix="PORT-SCAN-BLOCKED" \
    comment="5. SOC-HARDENING: Block all subsequent traffic from flagged port scanners"


#-------------------------------------------------------------------------------
# KELOMPOK 4: PENCURIAN KREDENSIAL (PROGRESSIVE SSH BRUTE FORCE PROTECTION)
#-------------------------------------------------------------------------------
add chain=input protocol=tcp dst-port=22 connection-state=new action=jump \
    jump-target=ssh-brute comment="6. SOC-HARDENING: Jump to SSH brute force inspection chain"

add chain=ssh-brute protocol=tcp src-address-list=ssh_blacklist action=drop \
    log=yes log-prefix="SSH-BRUTEFORCE-BLOCKED" \
    comment="7. SOC-HARDENING: Drop and log traffic from blacklisted SSH brute forcers"

add chain=ssh-brute protocol=tcp src-address-list=ssh_stage3 action=add-src-to-address-list \
    address-list=ssh_blacklist address-list-timeout=15m log=yes log-prefix="SSH-BRUTEFORCE-DETECTED" \
    comment="8. SOC-MONITOR: Upgrade attacker to temporary blacklist after Stage 3 violation"

add chain=ssh-brute protocol=tcp src-address-list=ssh_stage2 action=add-src-to-address-list \
    address-list=ssh_stage3 address-list-timeout=5m \
    comment="9. SOC-HARDENING: Promote attacker to Stage 3 tracking list"

add chain=ssh-brute protocol=tcp src-address-list=ssh_stage1 action=add-src-to-address-list \
    address-list=ssh_stage2 address-list-timeout=5m \
    comment="10. SOC-HARDENING: Promote attacker to Stage 2 tracking list"

add chain=ssh-brute protocol=tcp action=add-src-to-address-list \
    address-list=ssh_stage1 address-list-timeout=5m \
    comment="11. SOC-HARDENING: Catch first new SSH connection attempt and register to Stage 1"


#-------------------------------------------------------------------------------
# KELOMPOK 5: PELANGGARAN KEBIJAKAN (UNAUTHORIZED SERVICE ACCESS MANAGEMENT)
#-------------------------------------------------------------------------------
add chain=input protocol=tcp dst-port=23 action=drop log=yes log-prefix="FW-VIOLATION-TELNET" \
    comment="12. SOC-POLICY: Block and log unauthorized cleartext Telnet management access"

add chain=input protocol=tcp dst-port=21 action=drop log=yes log-prefix="FW-VIOLATION-FTP" \
    comment="13. SOC-POLICY: Block and log unauthorized cleartext FTP file transfer access"

add chain=input protocol=tcp dst-port=80 action=drop log=yes log-prefix="FW-VIOLATION-WWW" \
    comment="14. SOC-POLICY: Block and log unauthorized unencrypted Web GUI management access"

add chain=input protocol=tcp dst-port=8728 action=drop log=yes log-prefix="FW-VIOLATION-API" \
    comment="15. SOC-POLICY: Block and log unauthorized remote API automation system access"

add chain=input protocol=tcp dst-port=8291 action=drop log=yes log-prefix="FW-VIOLATION-WINBOX" \
    comment="16. SOC-POLICY: Block and log external Winbox GUI connectivity attempt"


#-------------------------------------------------------------------------------
# KELOMPOK 6: BENTENG AKHIR (CATCH-ALL DENY POLICY)
#-------------------------------------------------------------------------------
add chain=input action=drop log=yes log-prefix="FW-DEFAULT-DROP" \
    comment="17. SOC-POLICY: Zero-Trust baseline rule - Drop and log everything else"
