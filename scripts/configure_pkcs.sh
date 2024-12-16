#!/usr/bin/env bash
# Add pkcs11 configuration to openssl.cnf
sed  -i '1i openssl_conf = openssl_init' /etc/pki/tls/openssl.cnf 
cat /etc/aws-kms-pkcs11/openssl-pkcs11.conf >> /etc/pki/tls/openssl.cnf
# Set AWS KMS Token ID from variable
sed -i "s/MY_KMS_ID/$AWS_KMS_KEY_ID/g" /etc/aws-kms-pkcs11/config.json
# Set the module path
export PKCS11_MODULE_PATH=/usr/lib64/pkcs11/aws_kms_pkcs11.so
# Create the public x509 certificate for later signing process
openssl req -config /etc/aws-kms-pkcs11/x509.genkey -x509 -key "pkcs11:model=0;manufacturer=aws_kms;serial=0;token=$AWS_KMS_TOKEN" -keyform engine -engine pkcs11 -out /etc/aws-kms-pkcs11/mycert.pem -days 36500
