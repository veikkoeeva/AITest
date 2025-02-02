# Set common variables
$certStore = "Cert:\CurrentUser\My\"
$rootCertName = "PostgreSQL AITest Dev Root CA"
$serverCertName = "PostgreSQL AITest Dev Server"
$clientCertName = "PostgreSQL AITest Dev Client"
$certValidityDays = 365
$password = ConvertTo-SecureString -String "password" -Force -AsPlainText

# Generate the Root CA certificate
$rootCert = New-SelfSignedCertificate `
    -Type Custom `
    -KeyUsageProperty Sign `
    -KeyUsage CertSign `
    -Subject "CN=$rootCertName" `
    -NotAfter (Get-Date).AddDays($certValidityDays) `
    -KeyExportPolicy Exportable `
    -CertStoreLocation $certStore

# Generate the Server Certificate signed by the Root CA
$serverCert = New-SelfSignedCertificate `
    -Type Custom `
    -Subject "CN=$serverCertName" `
    -NotAfter (Get-Date).AddDays($certValidityDays) `
    -KeyExportPolicy Exportable `
    -Signer $rootCert `
    -CertStoreLocation $certStore

# Generate the Client Certificate signed by the Root CA
$clientCert = New-SelfSignedCertificate `
    -Type Custom `
    -Subject "CN=$clientCertName" `
    -NotAfter (Get-Date).AddDays($certValidityDays) `
    -KeyExportPolicy Exportable `
    -Signer $rootCert `
    -CertStoreLocation $certStore

# Create output directory
$exportPath = ".\certs"
New-Item -ItemType Directory -Path $exportPath -Force | Out-Null

# Function to convert certificate to PEM format
function Convert-ToPem {
    param (
        [Security.Cryptography.X509Certificates.X509Certificate2]$cert
    )
    
    $builder = New-Object System.Text.StringBuilder
    $builder.AppendLine("-----BEGIN CERTIFICATE-----")
    $builder.AppendLine([Convert]::ToBase64String($cert.RawData, [System.Base64FormattingOptions]::InsertLineBreaks))
    $builder.AppendLine("-----END CERTIFICATE-----")
    return $builder.ToString()
}

# Function to export private key in PEM format
function Export-PrivateKeyToPem {
    param (
        [Security.Cryptography.X509Certificates.X509Certificate2]$cert
    )
    
    $rsa = [System.Security.Cryptography.X509Certificates.RSACertificateExtensions]::GetRSAPrivateKey($cert)
    if ($null -eq $rsa) {
        throw "Unable to get RSA private key"
    }
    
    $keyBytes = $rsa.ExportPkcs8PrivateKey()
    $builder = New-Object System.Text.StringBuilder
    $builder.AppendLine("-----BEGIN PRIVATE KEY-----")
    $builder.AppendLine([Convert]::ToBase64String($keyBytes, [System.Base64FormattingOptions]::InsertLineBreaks))
    $builder.AppendLine("-----END PRIVATE KEY-----")
    return $builder.ToString()
}

# Export certificates and keys
foreach ($cert in @(
    @{Cert=$rootCert; Name="root"},
    @{Cert=$serverCert; Name="server"},
    @{Cert=$clientCert; Name="client"}
)) {
    # Export PFX
    $pfxPath = Join-Path $exportPath "$($cert.Name).pfx"
    Export-PfxCertificate -Cert $cert.Cert -FilePath $pfxPath -Password $password | Out-Null
    
    # Export certificate in PEM format
    $pemPath = Join-Path $exportPath "$($cert.Name).crt"
    Convert-ToPem -cert $cert.Cert | Out-File -FilePath $pemPath -Encoding ASCII
    
    # Export private key in PEM format
    $keyPath = Join-Path $exportPath "$($cert.Name).key"
    try {
        Export-PrivateKeyToPem -cert $cert.Cert | Out-File -FilePath $keyPath -Encoding ASCII
    }
    catch {
        Write-Warning "Failed to export private key for $($cert.Name): $_"
    }
}

Write-Host "Certificates generated successfully in: $exportPath"