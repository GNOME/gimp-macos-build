## Steps

Follow this but be sure to use the `-legacy` flag in step 8.

From:
<https://gist.github.com/boodle/77436b2d9facb8e938ad>

1. Create a new directory;
 mkdir Certificate
 cd Certificate

2. Generate a certificate signing request
 openssl req -nodes -newkey rsa:2048 -keyout gimp-apple.key -out CertificateSigningRequest.certSigningRequest

3. With the information like so (ensure you give it a password):
 Country Name (2 letter code) [AU]:GB
 State or Province Name (full name) [Some-State]:London
 Locality Name (eg, city) []:
 Organization Name (eg, company) [Internet Widgits Pty Ltd]:GNOME
 Organizational Unit Name (eg, section) []:
 Common Name (e.g. server FQDN or YOUR name) []:org.gnome.gimp
 Email Address []:

4. Login to developer.apple.com, go to:
 "Member Center" -> "Manage your certificates, App IDs, devices, and provisioning profiles." -> "Certificates" -> "Add"

5. Go through the wizard, selecting the certificate type, and uploading the .csr.

6. Download the .cer file, saving it to the folder created in step 1

7. Convert the .cer file to a .pem file:
 openssl x509 -in gimp-apple.cer -inform DER -out gimp-apple.pem -outform PEM

7a. Generate a password for the .p12 file:
 openssl rand -base64 32 > password.txt

8. Convert the .pem to a .p12:
 openssl pkcs12 -export -legacy -inkey gimp-apple.key -in gimp-apple.pem -out gimp-apple.p12

9. Encode the .p12 file to base64:
 openssl base64 -in gimp-apple.p12 -out gimp-apple.base64

10. Add the base 64 .p12 to circle ci as a secret environment variable:
 osx_crt

11. Add the password to circle ci as a secret environment variable:
 osx_crt_pw

## Notes

If you are using a build system like Ionic Appflow and receive an error like this one:

```
security: SecKeychainItemImport: MAC verification failed during PKCS12 import (wrong password?)
```

It's because "OpenSSL 3.x changed its default algorithm in pkcs12. Which is not compatible with embedded Security frameworks in macOS/iOS. You could alternatively use OpenSSL 1.x."

Add the `-legacy` flag in step 8. See [here](https://stackoverflow.com/a/70656724) for more info. Massive thanks to [i_82](https://stackoverflow.com/users/5227717/i-82) and [Jarrod Moldrich](https://stackoverflow.com/users/2064098/jarrod-moldrich).

## Self-hosted runner

<https://circleci.com/blog/code-signing-with-runner/>
<https://circleci.com/docs/runner-installation-mac/>
