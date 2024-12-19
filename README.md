Container for [PKCS11 implementation](https://github.com/JackOfMostTrades/aws-kms-pkcs11) using AWS KMS backend.
`enable_kms_pkcs11` will configure the needed bits to sign with KMS keys.

AWS auth to your account and the following variables should be set before the running `enable_kms_pkcs11`


AWS_KMS_TOKEN - The key ID from KMS

AWS_DEFAULT_REGION - The AWS region where the key is hosted

AWS_KMS_KEY_LABEL - The alias/label you want to set for the key
