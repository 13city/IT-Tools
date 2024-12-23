# ssl_renew.sh

### Purpose
Automates the process of SSL certificate renewal, supporting both self-signed certificates and Let's Encrypt certificates. This script simplifies SSL certificate management for internal and public-facing domains.

### Features
- Supports two certificate types:
  - Self-signed certificates for internal use
  - Let's Encrypt certificates for public domains
- Automated certificate generation/renewal
- Non-interactive mode for automation
- Detailed logging of all operations
- Configurable certificate parameters

### Requirements
- Root or sudo access
- For self-signed: OpenSSL
- For Let's Encrypt: Certbot installed
- Write access to /etc/ssl directory
- Public DNS (for Let's Encrypt mode)

### Usage
```bash
# For self-signed certificates
sudo ./ssl_renew.sh selfsigned mydomain.local

# For Let's Encrypt certificates
sudo ./ssl_renew.sh letsencrypt mydomain.com
```

### Configuration Variables
```bash
MODE="$1"        # Certificate type: "selfsigned" or "letsencrypt"
DOMAIN="$2"      # Domain name
CERT_DIR="/etc/ssl/$DOMAIN"
LOGFILE="/var/log/ssl_renew.log"
```

### Operations Performed
1. **Self-Signed Mode**
   - Creates certificate directory
   - Generates 2048-bit RSA key pair
   - Creates self-signed certificate valid for 365 days
   - Sets appropriate subject fields

2. **Let's Encrypt Mode**
   - Runs certbot in standalone mode
   - Automatically agrees to terms of service
   - Uses domain admin email
   - Handles certificate renewal

### Error Handling
- Validates input parameters
- Checks certificate generation success
- Logs all operations and errors
- Provides clear usage instructions

### Log File
The script maintains a log at `/var/log/ssl_renew.log` containing:
- Timestamp of operations
- Certificate generation details
- Success/failure status
- Error messages if any

### Certificate Locations
- Self-signed certificates: `/etc/ssl/<domain>/`
  - Private key: `<domain>.key`
  - Certificate: `<domain>.crt`
- Let's Encrypt certificates: Managed by certbot
  - Default location: `/etc/letsencrypt/live/<domain>/`

### Customization
To customize the script:
1. Modify the certificate validity period (default: 365 days)
2. Adjust the RSA key size (default: 2048 bits)
3. Change the certificate subject fields
4. Modify the certificate storage location
