#!/bin/bash


if [ $# -ne 2 ]
then
    echo "Error in $0 - Invalid Argument Count"
    echo "      Usage: $0 <ServerCertificate> <ServerKeyStoreName> (ex ./convertP12ToJKS.sh es-vm22.olan.nextcentury.com.p12 es-vm22-keystore.jks)"
    echo "              ServerCertificate - The server certifcate in P12 format"
    echo "              ServerKeyStoreName - The name use to generated teh jks file"
    exit
fi

echo "keytool -v -importkeystore -srckeystore ${1} -srcstoretype PKCS12 -srcstorepass changeit -destkeystore ${2} -deststoretype JKS -deststorepass changeit"
keytool -v -importkeystore -srckeystore ${1} -srcstoretype PKCS12 -srcstorepass changeit -destkeystore ${2} -deststoretype JKS -deststorepass changeit
