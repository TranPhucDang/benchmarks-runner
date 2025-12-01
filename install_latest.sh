# Create working directory
mkdir ~/benchmark-project
cd ~/benchmark-project

# Install Go version (1.23.4)
wget https://go.dev/dl/go1.23.4.linux-amd64.tar.gz
rm -rf /usr/local/go
tar -C /usr/local -xzf go1.23.4.linux-amd64.tar.gz
echo 'export PATH=$PATH:/usr/local/go/bin' >> ~/.bashrc
source ~/.bashrc
go version

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
go version
java -version
mvn -version
sysbench --version
