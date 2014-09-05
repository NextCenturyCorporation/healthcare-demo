#  read in the proposed hostname
HOSTNAME=$1
if [ -z "$HOSTNAME" ]; then
  HOSTNAME='healthcare-demo1'
  echo "hostname not provided using ; " $HOSTNAME
fi

# this is the string that will get the hostname replaced
LOCAL_URL='127.0.1.1'

# change the name in the /etc/hostname file by overwriting the whole file
echo $HOSTNAME >/etc/hostname
echo "Updated /etc/hostname with new hostname ; " $HOSTNAME
# use sed to update the server name in the /etc/hosts file
sed 's/'$LOCAL_URL'.*/'$LOCAL_URL'       '$HOSTNAME'/g' /etc/hosts >/etc/hosts.new
rm /etc/hosts
cp /etc/hosts.new /etc/hosts
echo "Updated /etc/hosts with new hostname; " $HOSTNAME

OZONE_HOST_NAME_PROPERTY='ozone.host'
# use sed to update the server name in the
#/home/demoadmin/healthcare-demo/owf/apache-tomcat-7.0.21/lib/OzoneConfig.properties file
cd /home/demoadmin/healthcare-demo/owf/apache-tomcat-7.0.21/lib/
sed 's/'$OZONE_HOST_NAME_PROPERTY'.*/'$OZONE_HOST_NAME_PROPERTY'       '$HOSTNAME'/g' OzoneConfig.properties > OzoneConfig.properties.new
rm OzoneConfig.properties
mv OzoneConfig.properties.new OzoneConfig.properties
echo "Updated /apache-tomcat-7.0.21/lib/OzoneConfig.properties with new hostname ; " $HOSTNAME
cd -

