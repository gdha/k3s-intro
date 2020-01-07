#!/usr/bin/env bash

# Original script was found on page https://stackoverflow.com/questions/10175812/how-to-create-a-self-signed-certificate-with-openssl
# And also: https://www.runscripts.com/support/guides/tools/ssl-certificates/creating-a-ca
# However, modified by gratien dhaese
#
# Excellent article: https://gist.github.com/Soarez/9688998

# Set the TLD domain we want to use
BASE_DOMAIN="example.com"

# Days for the cert to live
DAYS=1095

# A blank passphrase
PASSPHRASE=""

# Generated configuration file
CONFIG_FILE="config.txt"

cat > $CONFIG_FILE <<-EOF
[ req ]
prompt = no
distinguished_name = req_distinguished_name
x509_extensions = v3_ca

[ req_distinguished_name ]
C = BE
ST = Flanders
L = Antwerp
O = Example Limited
CN = Example Limited CA
emailAddress = webmaster@example.com

[ v3_ca ]
subjectKeyIdentifier=hash
authorityKeyIdentifier=keyid:always,issuer:always
#basicConstraints = critical,CA:true
basicConstraints = CA:true
EOF

# The file name can be anything
FILE_NAME="$BASE_DOMAIN"

# The kubernetes manifests directory
MANIFESTS_DIR="../deploy/manifests"

# Remove previous keys
if [[ -f $FILE_NAME.privkey ]] ; then
   echo "Removing existing certs like $FILE_NAME.*"
   chmod 770 $FILE_NAME.*
   rm $FILE_NAME.*
   rm -f tls.* ca.crt
fi

echo "Generating certs for $BASE_DOMAIN"

# Generate our Private Key, CSR and Certificate
# Use SHA-2 as SHA-1 is unsupported from Jan 1, 2017

# Generate the RSA private key
openssl genpkey -outform PEM -algorithm RSA -pkeyopt rsa_keygen_bits:2048 -out "$FILE_NAME.privkey"

# Generate the public key
openssl rsa -in "$FILE_NAME.privkey" -pubout -out "$FILE_NAME.pubkey"

# Create the CSR (using config.txt)
openssl req -new -nodes -key "$FILE_NAME.privkey" -config $CONFIG_FILE -out "$FILE_NAME.csr"

# Generate the CA certificate
openssl req -new -sha256 -x509 -days $DAYS -key "$FILE_NAME.privkey" -out "$FILE_NAME.crt" -config $CONFIG_FILE

# Line below does not create a CA certificate
#openssl req -new -x509 -newkey rsa:2048 -sha256 -nodes -keyout "$FILE_NAME.key" -days $DAYS -out "$FILE_NAME.crt" -passin pass:$PASSPHRASE -config "$CONFIG_FILE"

# Line below works also, but still interactive input is required.
#openssl req -new -x509 -extensions v3_ca -keyout cakey.pem -out cacert.pem -days $DAYS -passin pass:$PASSPHRASE -config "$CONFIG_FILE"

# Is it a correct CA?
echo "Is $FILE_NAME.crt a correct CA?"
openssl x509 -text -noout -in "$FILE_NAME.crt" |grep "CA:"

# OPTIONAL - write an info to see the details of the generated crt
openssl x509 -noout -fingerprint -text < "$FILE_NAME.crt" > "$FILE_NAME.info"

# Protect the key
chmod 400 "$FILE_NAME.privkey"

# Create the PEM key
#cat "$FILE_NAME.crt" "$FILE_NAME.key" > "$FILE_NAME.pem" 
openssl x509 -in "$FILE_NAME.crt" -out "$FILE_NAME.pem" -outform PEM

# Adding the CA key pair to the namespace "kubernetes-dashboard"

# Before we can add key pairs the namespace has to exist:
kubectl get namespace | grep -q ^kubernetes-dashboard || \
	kubectl create namespace kubernetes-dashboard

echo "apiVersion: v1
kind: Secret
metadata:
  name: ca-key-pair
  namespace: kubernetes-dashboard
data:
  tls.crt: $(cat $FILE_NAME.crt | base64 | tr '\n' ' ' | sed -e 's/ //g') 
  tls.key: $(cat $FILE_NAME.privkey | base64 | tr '\n' ' ' | sed -e 's/ //g')
" > $MANIFESTS_DIR/dashboard-ca-key-pair.yaml

echo "apiVersion: cert-manager.io/v1alpha2
kind: Issuer
metadata:
  name: ca-issuer
  namespace: kubernetes-dashboard
spec:
  ca:
    secretName: ca-key-pair
" > $MANIFESTS_DIR/dashboard-ca-issuer.yaml


# kubectl get issuers ca-issuer -n kubernetes-dashboard -o wide
# NAME        READY   STATUS                                                         AGE
# ca-issuer   False   Error getting keypair for CA issuer: certificate is not a CA   32m

rc=$( kubectl get issuers  -A | grep ^kubernetes-dashboard | grep -q ca-issuer )
if [[ $rc -eq 1 ]]; then
	echo "Adding kubernetes-dashboard ca-key-pair"
	kubectl apply -f $MANIFESTS_DIR/dashboard-ca-key-pair.yaml
	kubectl apply -f $MANIFESTS_DIR/dashboard-ca-issuer.yaml
else
	echo "Replacing kubernetes-dashboard ca-key-pair"
	kubectl replace -f $MANIFESTS_DIR/dashboard-ca-key-pair.yaml
	kubectl replace -f $MANIFESTS_DIR/dashboard-ca-issuer.yaml
fi
echo "Is kubernetes-dashboard ca-key-pair properly inserted into k3s?"
kubectl get issuers ca-issuer -n kubernetes-dashboard -o wide

# Make symbolic links required kubernetes-dashboard-certs
# Read: https://github.com/kubernetes/dashboard/blob/master/docs/user/installation.md
# Do not use symbolic links
cp -f  example.com.crt tls.crt
cp -f  example.com.privkey tls.key
cp -f  example.com.pem ca.crt
kubectl delete secret  kubernetes-dashboard-certs -n kubernetes-dashboard >/dev/null 2>&1
kubectl create secret generic kubernetes-dashboard-certs --from-file=. -n kubernetes-dashboard

# cleanup
rm -f config.txt
