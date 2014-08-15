#! /bin/bash
# create-certificates.sh
#
#  This script is provided as a utility to help OWF and Marketplace users
# create simple, self signed server certificates and optionally user 
# PKI certificates.  
#
# Please use this script in conjunction with the User Admin Guide and the
# Quick Start Guide.  
# This script is a backup script that uses openssl for most certificate
# operations as opposed to using keytool in the create-certificates.sh
# script that started failing. Use this script if the create-certificats.sh
# script fails to generate valid certificates.

DEFAULT_USER_PASSWORD="password"
DEFAULT_KEYSTORE_PASSWORD="changeit"
DEFAULT_COUNTRY_CODE="US"
DEFAULT_OU="healthcare-demo"
DEFAULT_O="healthcare-demo"
DEFAULT_CITY="Columbia"
DEFAULT_STATE="MD"
DEFAULT_EMAIL_ADDR="demoadmin@healthcare-demo"

function createConfigFile
{

        # set up local variables
        local l_configFile=${1}.ca-config
        echo "dir=." >> ${l_configFile}
        echo "[ req ]" >> ${l_configFile}
        echo "x509_extensions=vthreeext" >> ${l_configFile}
        echo "output_password=pass:${DEFAULT_KEYSTORE_PASSWORD}" >> ${l_configFile}
        echo "distinguished_name = req_distinguished_name" >> ${l_configFile}
        echo "prompt=no" >> ${l_configFile}
        echo "[ req_distinguished_name ]"  >> ${l_configFile}
        echo "organizationName=${DEFAULT_O}" >> ${l_configFile}
        echo "organizationalUnitName=${DEFAULT_OU}" >> ${l_configFile}
        echo "emailAddress=${DEFAULT_EMAIL_ADDR}" >> ${l_configFile}
        echo "localityName=${DEFAULT_CITY}" >> ${l_configFile}
        echo "stateOrProvinceName=${DEFAULT_STATE}" >> ${l_configFile}
        echo "commonName=${1}" >> ${l_configFile}
        echo "countryName=${DEFAULT_COUNTRY_CODE}" >> ${l_configFile}
        echo "[ vthreeext ]" >> ${l_configFile}
        echo "basicConstraints=CA:true" >> ${l_configFile}
        echo "subjectKeyIdentifier=hash" >> ${l_configFile}
        echo "authorityKeyIdentifier=keyid:always,issuer:always" >> ${l_configFile}

}

# createSelfSigningCertAuthority cakeyname cacertname hostname
#
# This subroutine expects three parameters to be set:
# cakeyname=%hostname%-ca.key  The name of the certificate authority key file to create
# cacertname=%hostname%-ca.crt The name of the certificate authority certificate to create
# hostname= the name of the certificate authority.  Example localhost
#
# It creates two files, the certificate authority keystore (cakeyname) and the certificate
# authority cert, cacertname.  Passwords are set to DEFAULT_KEYSTORE_PASSWORD
#
function createSelfSigningCertAuthority
{
    #set local variables
        local l_cakeyname=${1}
        local l_cacertname=${2}
        if [ -e $l_cakeyname ]; then
            echo "A certificate authority key named $l_cakeyname exists.  Aborting!"
            exit 1
        fi
        # generate the CA's config file if it doesn't exist
        local l_configFile=${3}.ca-config
        if [ ! -e $l_configFile ]; then
              createConfigFile ${3} ;
        fi

        openssl genrsa -des3 -out ${l_cakeyname} -passout pass:${DEFAULT_KEYSTORE_PASSWORD} 4096

        # generate certificate authority's cert request
        openssl req -new -x509 -days 7300 -key ${l_cakeyname} -passin pass:${DEFAULT_KEYSTORE_PASSWORD} -out ${l_cacertname} -config ${l_configFile}



        # this is reused, don't remove it.
#       rm ${l_configFile}
        echo "00" >> ${1}.srl
        echo -e "Created ${l_cakeyname} and ${l_cacertname} in `pwd` \n"
        openssl x509 -text -noout -in ${l_cacertname}

}





# createServerCertificate cakeyname cacertname hostname hostkeystorename
#
# This subroutine expects four parameters:
# cakeyname=%hostname%-ca.key  The name of the certificate authority key file to create
# cacertname=%hostname%-ca.crt The name of the certificate authority certificate to create
# hostname= the name of the certificate authority.  Example localhost
# hostkeystorename: hostname.jks  the name of the keystore for the server
#
# This subroutine creates a server key with password DEFAULT_KEYSTORE_PASSWORD for hostname, 
# creates a cert request for hostname, signs it with the passed in CA information, and 
# then adds it to the hostkeystorename
#
function createServerCertificate
{

	# set up local variables
	local l_cakeyname="${1}"
	local l_cacertname="${2}"
	local l_hostname="${3}"
	local l_hostkeystorename="${4}"
        local l_caserialfile="${1}.srl"

	local l_servercsrfile=${hostname}.csr

	local l_servercertname=${hostname}-ca.crt
        local l_serverkeyfile=${hostname}-ca.key
        local l_p12file=${hostname}.p12
        local l_configFile=${hostname}.ca-config
        if [ ! -e $l_configFile ]; then
              createConfigFile ${l_hostname} ;
        fi
	echo ""
        # generate a request for a server certificate
        openssl req -new -key ${l_serverkeyfile} -out ${l_servercsrfile} -config ${l_configFile}

        # sign request
        openssl x509 -req -days 365 -in ${l_servercsrfile} -CA ${l_cacertname} -CAkey ${l_cakeyname} -passin pass:${DEFAULT_KEYSTORE_PASSWORD} -CAserial ${l_caserialfile} -out ${l_servercertname} -extfile ${l_configFile} -extensions vthreeext

        # export to p12 file
        openssl pkcs12 -in ${l_servercertname} -inkey ${l_serverkeyfile} -out ${l_p12file} -export -name "${l_friendlyname}" -passout pass:${DEFAULT_KEYSTORE_PASSWORD}

	echo -e "\n************************************************************************\n"
	echo "${l_hostkeystorename} in `pwd` is the server keystore for you to use as your keystore "
	echo "and truststore.  It's password is ${DEFAULT_KEYSTORE_PASSWORD}."
	echo -e "\n************************************************************************\n"
        # convert p12 file to jks
        echo "keytool -v -importkeystore -srckeystore ${l_p12file} -srcstoretype PKCS12 -srcstorepass changeit -destkeystore ${3}.jks -deststoretype JKS -deststorepass changeit"
        keytool -v -importkeystore -srckeystore ${l_p12file} -srcstoretype PKCS12 -srcstorepass changeit -destkeystore ${3}.jks -deststoretype JKS -deststorepass changeit

}


# createUserCertificate cakeyname cacertname
#
# This subroutine expects two paremeters to be set:
# cakeyname=%hostname%-ca.key  The name of the certificate authority key file to create
# cacertname=%hostname%-ca.crt The name of the certificate authority certificate to create
function createUserCertificate
{

	# set up varibles
	local l_cakeyname="${1}"
	local l_cacertname="${2}"
	echo -e "\nEnter the username of the person you want to generate a certificate for:"
	read l_username
	echo ""

	local l_userkeyfile=${l_username}.key
	local l_usercsrfile=${l_username}.csr
	local l_crtfile=${l_username}.crt
	local l_p12file=${l_username}.p12
	local l_configFile=${l_username}.ca-config

	# generate the user's config file
	echo dir=. > ${l_configFile}
	echo [ req ] >> ${l_configFile}
	echo output_password=pass:${DEFAULT_USER_PASSWORD} >> ${l_configFile}
	echo input_password=pass:${DEFAULT_USER_PASSWORD} >> ${l_configFile}
	echo distinguished_name = req_distinguished_name >> ${l_configFile}
	echo prompt=no >> ${l_configFile}
	echo [ req_distinguished_name ]  >> ${l_configFile}
	echo organizationName=${l_username} >> ${l_configFile}
	echo organizationalUnitName=${l_username} >> ${l_configFile}
	echo emailAddress=${l_username} >> ${l_configFile}
	echo localityName=${l_username} >> ${l_configFile}
	echo stateOrProvinceName=${l_username} >> ${l_configFile}
	echo commonName=${l_username} >> ${l_configFile}
	echo countryName=${DEFAULT_COUNTRY_CODE} >> ${l_configFile}

	# generate the user's RSA private key

	openssl genrsa -des3 -out ${l_userkeyfile} -passout pass:${DEFAULT_USER_PASSWORD} 4096 
	
	# generate a request for a user certificate 
	openssl req -new -key ${l_userkeyfile} -passin pass:${DEFAULT_USER_PASSWORD} -out ${l_usercsrfile} -config ${l_configFile}
	
	# sign request
	openssl x509 -req -days 365 -in ${l_usercsrfile} -CA ${l_cacertname} -CAkey ${l_cakeyname} -passin pass:${DEFAULT_KEYSTORE_PASSWORD} -set_serial ${RANDOM} -out ${l_crtfile}  
	
	# export to p12 file	
	openssl pkcs12 -in ${l_crtfile} -inkey ${l_userkeyfile} -out ${l_p12file} -export -name "${l_username}"  -passin pass:${DEFAULT_USER_PASSWORD} -passout pass:${DEFAULT_USER_PASSWORD}

	rm ${l_configFile}

	echo -e "\n*******************************************************\n"
	echo The certificate for your user to import into his/her browser is ${l_p12file} in `pwd`.  The password to import the file into the browser is ${DEFAULT_USER_PASSWORD}.
	echo -e "\n*******************************************************\n"
}


# START MAIN EXECUTION

echo -e "Welcome to the OWF and Marketplace Self-Signed Certificate Creation Script. \n"
echo -e "In order to use this script, you must have openssl on your path.  To test " 
echo -e "this, open a command prompt and type 'openssl'.  If it errors out, install "
echo -e "openssl."
echo -e "You also have to have keytool.  To test if you have keytool, open a cmd "
echo -e "prompt and type keytool.\n"
echo -e "This script is provided as a utility to help OWF and Marketplace users"
echo -e "create simple, self signed server certificates and optionally user "
echo -e "PKI certificates.  \n"
echo -e "Please use this script in conjunction with the User Admin Guide and the"
echo -e "Quick Start Guide.  \n"
echo -e "Be aware that self-signed certificates do not constitute a good quality"
echo -e "production security system, and any self-signed certificate will trigger"
echo -e "warnings and potentially security problems.  It is recommended"
echo -e "that prior to considering a security system production quality all"
echo -e "certificates be signed by a recognized certificate authority, such"
echo -e "as Verisign or an internally trusted agent. \n"
echo "Press enter to continue...."
read -e temp


# STARTING MENU LOOP

menuChoice="0"
until [ "${menuChoice}" -eq "5" ]; do

   echo -e "\n--------------------------------------------------------------------------\n"
   echo -e "MENU \n"
   echo "1.  EASY: Create self-signed certificate authority key and certificate, server certificate, and user certificates."
   echo "2.  Create only a self-signed certificate authority key and certificate."
   echo "3.  Create only a server certificate.  You must already have certificate authority key and crt files."
   echo "4.  Create only PKI user certificates.  You must already have certificate authority key and crt files."
   echo "5.  Exit."
   echo ""
   echo -e "--------------------------------------------------------------------------\n\n"
   echo "Your choice: "
   read menuChoice
   echo -e "\n--------------------------------------------------------------------------\n"
	

	if [ "${menuChoice}" -eq "1" ]; then
		
		echo -e "Create self-signed certificate authority key and certificate, server certificate, and user certificates. \n"

		echo "What is your hostname?  It should match your expected url. (IE localhost):"
		read hostname

		cakeyname=${hostname}-ca.key
		cacertname=${hostname}-ca.crt
		hostkeystorename=${hostname}.jks
		
		# call function that creates the certificate authority files
		# createSelfSigningCertAuthority cakeyname cacertname hostname
		createSelfSigningCertAuthority "${cakeyname}" "${cacertname}" "${hostname}"

		# this function creates the server certificate files
		# createServerCertificate cakeyname cacertname hostname hostkeystorename
		createServerCertificate "${cakeyname}" "${cacertname}" "${hostname}" "${hostkeystorename}"

                anotherRound="Y"
		while [ "${anotherRound}" = "Y" ] || [ "${anotherRound}" = "y" ] ;  do
		
			# createUserCertificate cakeyname cacertname
			createUserCertificate ${cakeyname} ${cacertname}

			echo "Would you like to create another user certificate? (Y/N)"
			read anotherRound
		done  # end create user certificates


	elif [ "${menuChoice}" -eq "2" ]; then
		 
		echo -e  "Create only a self-signed certificate authority key and certificate.\n"
		echo "What is your hostname?  (IE localhost):"
		read hostname

		# call function that creates the files
		# createSelfSigningCertAuthority cakeyname cacertname hostname
		createSelfSigningCertAuthority "${hostname}-ca.key" "${hostname}-ca.crt" "${hostname}"

		
	elif [ "${menuChoice}" -eq "3" ]; then
		 
		echo Create only a server certificate.  You must already have certificate authority key and crt files.
		
		echo -e "\nWhat is your hostname:"
		read hostname
	
		echo "What is your certificate authority filename?  ( probably named ${hostname}-ca.crt):"
		read cacertname
		
		echo "What is your certificate key filename?  ( probably named ${hostname}-ca.key):"
		read cakeyname
		
		hostkeystorename=${hostname}.jks

		# this function creates the server certificate files
		# createServerCertificate cakeyname cacertname hostname hostkeystorename
		createServerCertificate "${cakeyname}" "${cacertname}" "${hostname}" "${hostkeystorename}"

		
	elif [ "${menuChoice}" -eq "4" ]; then
		 
		

   	    echo Create only PKI user certificates.  You must already have certificate authority key and crt files.
		
		anotherRound="Y"
		while [ "${anotherRound}" = "Y" ] || [ "${anotherRound}" = "y" ] ;  do
		
			echo "Enter the name of the certificate authority key file (probably HOSTNAME-ca.key):"
			read cakeyname
			
			echo "Enter the name of the certificate authority file (probably HOSTNAME-ca.crt):"
			read cacertname

			
			# createUserCertificate cakeyname cacertname
			createUserCertificate ${cakeyname} ${cacertname}

			echo "Would you like to create another user certificate? (Y/N)"
			read anotherRound
		done  # end create user certificates
		
	fi


done  # end menu loop

echo 
echo Exiting....
echo 

