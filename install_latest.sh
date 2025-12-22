# Create working directory
mkdir ~/benchmark-project
cd ~/benchmark-project

# Install Go version (1.23.4)
# wget https://go.dev/dl/go1.23.4.linux-amd64.tar.gz
# rm -rf /usr/local/go
# tar -C /usr/local -xzf go1.23.4.linux-amd64.tar.gz
# echo 'export PATH=$PATH:/usr/local/go/bin' >> ~/.bashrc
# source ~/.bashrc
# go version

# Install latest Java version (OpenJDK 21 LTS)
# Option 1: From Ubuntu/Debian repository
#sudo apt update
#sudo apt install -y openjdk-21-jdk maven

# Option 2: Download directly from Oracle/OpenJDK (if repo doesn't have JDK 21)
wget https://download.oracle.com/java/21/latest/jdk-21_linux-x64_bin.tar.gz
tar -xzf jdk-21_linux-x64_bin.tar.gz -C /usr/local/
echo 'export JAVA_HOME=/usr/local/jdk-21' >> ~/.bashrc
echo 'export PATH=$PATH:$JAVA_HOME/bin' >> ~/.bashrc
source ~/.bashrc

# Install latest Maven version
MAVEN_VERSION=3.9.11
wget https://dlcdn.apache.org/maven/maven-3/$MAVEN_VERSION/binaries/apache-maven-$MAVEN_VERSION-bin.tar.gz
tar -xzf apache-maven-$MAVEN_VERSION-bin.tar.gz -C /opt/
ln -sf /opt/apache-maven-$MAVEN_VERSION /opt/maven
echo 'export MAVEN_HOME=/opt/maven' >> ~/.bashrc
echo 'export PATH=$PATH:$MAVEN_HOME/bin' >> ~/.bashrc
source ~/.bashrc

# Install benchmark tools
apt install -y sysbench stress-ng htop

# Check installed versions
echo "=== Versions Installed ==="
# go version
java -version
mvn -version
sysbench --version

# ============================================================
# installation go version go1.24.11 linux/amd64 frome source
# ============================================================

## use scp to copy from another machine if needed
# scp -r user@remote_host:/path/to/goroot ~/benchmark-project/g
git clone https://go.googlesource.com/go goroot 
git checkout go1.24.11
cd goroot/src
./make.bash
# get error:
# ========
# root [ ~/go-install/goroot/src ]# ./make.bash
## ERROR: Cannot find /usr/local/go/bin/go.
## Set $GOROOT_BOOTSTRAP to a working Go tree >= Go 1.22.6.
# ========

# The Go toolchain is written in Go. To build it, you need a Go compiler installed. The scripts that do the initial build of the tools look for a "go" command in $PATH, so as long as you have Go installed in your system and configured in your $PATH, you are ready to build Go from source. Or if you prefer you can set $GOROOT_BOOTSTRAP to the root of a Go installation to use to build the new Go toolchain; $GOROOT_BOOTSTRAP/bin/go should be the go command to use.
# The minimum version of Go required depends on the target version of Go:
# Go <= 1.4: a C toolchain.
# 1.5 <= Go <= 1.19: a Go 1.4 compiler.
# 1.20 <= Go <= 1.21: a Go 1.17 compiler.
# 1.22 <= Go <= 1.23: a Go 1.20 compiler.
# Going forward, Go version 1.N will require a Go 1.M compiler, where M is N-2 rounded down to an even number. Example: Go 1.24 and 1.25 require Go 1.22.
# There are four possible ways to obtain a bootstrap toolchain:

# Download a recent binary release of Go.
# Cross-compile a toolchain using a system with a working Go installation.
# Use gccgo.
# Compile a toolchain from Go 1.4, the last Go release with a compiler written in C.
# These approaches are detailed below.
wget https://go.dev/dl/go1.22.6.linux-amd64.tar.gz
tar -C /usr/local -xzf go1.22.6.linux-amd64.tar.gz
export GOROOT_BOOTSTRAP=/usr/local/go

cd goroot/src # clone repo already in goroot
./make.bash
# Building Go cmd/dist using /usr/local/go. (go1.22.6 linux/amd64)
# Building Go toolchain1 using /usr/local/go.
# Building Go bootstrap cmd/go (go_bootstrap) using Go toolchain1.
# Building Go toolchain2 using go_bootstrap and Go toolchain1.
# Building Go toolchain3 using go_bootstrap and Go toolchain2.
# Building packages and commands for linux/amd64.
# ---
# Installed Go for linux/amd64 in /root/go-install/goroot
# Installed commands in /root/go-install/goroot/bin
# *** You need to add /root/go-install/goroot/bin to your PATH. ***
cd ../..
# Set GOROOT and update PATH
export GOROOT=/root/go-install/goroot
export PATH=$GOROOT/bin:$PATH
go version


# ============================================================
# Uninstallation Instructions
# ============================================================

# To remove Go:
# sudo rm -rf /usr/local/go
# sed -i '/export PATH=\$PATH:\/usr\/local\/go\/bin/d' ~/.bashrc
# source ~/.bashrc

# To remove Java (OpenJDK 21):
# sudo rm -rf /usr/local/jdk-21
# sed -i '/export JAVA_HOME=\/usr\/local\/jdk-21/d' ~/.bashrc
# sed -i '/export PATH=\$PATH:\$JAVA_HOME\/bin/d' ~/.bashrc
# source ~/.bashrc

# To remove Maven:
# sudo rm -rf /opt/apache-maven-3.9.11 /opt/maven
# sed -i '/export MAVEN_HOME=\/opt\/maven/d' ~/.bashrc
# sed -i '/export PATH=\$PATH:\$MAVEN_HOME\/bin/d' ~/.bashrc
# source ~/.bashrc

# To remove benchmark tools:
# sudo apt remove -y sysbench stress-ng htop
