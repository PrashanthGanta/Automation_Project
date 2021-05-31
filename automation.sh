#Autoamtion_Project Upgrad

myname="Prashanth"
s3_bucket="upgrad-prashanth"

# To update all packages
sudo apt update -y

#TO check apache2 is installed or not, if not install the apache2
apache_check=$(dpkg --get-selections | grep apache2| awk '{print $1}')
if [[ "$apache_check" =~ .*"apache2".* ]]; then
  echo "Apache is installed"; 
else
	echo "installing apache"
	apt-get install apache2 -y
fi

## To start apache as service(This will make apache server to run automatically whenever restart happens)
apacheService=$(systemctl list-unit-files | grep apache2.service | awk '{print $2}')
if [[ $apacheService = "enabled" ]];then
	echo "Apache2 service is alredy set"
else
	systemctl start apache2.service
	echo "Apache2 server is enabled"
fi

## To check apache is running or not, if not restart the apache service
apache2Status=$(systemctl list-units --type=service --state=active,running | awk '/apache2.service/ {print $1}')
if [[ $apache2Status = "apache2.service" ]]; then
	echo "Apache server is in active/running state"
else
	systemctl start apache2.service
	sleep 10
	
	#checking if apache restarted or not
	if [[ $apache2Status = "apache2.service" ]]; then
		echo "Apache is in stop state, Automatically restarted succesfully." 
	else
		echo "Apache is in stop state, Automatically restart failed. Please check manually."
    fi
fi

##Creating tar file and copying the tar file s3

# Time stamp
timestamp=$(date '+%d%m%Y-%H%M%S')

# Creating a tar file of .log files to tmp location
tar -cvf /tmp/${myname}-httpd-logs-${timestamp}.tar /var/log/apache2/*.log

# Copying the tar file from tmp location to S3 bucket
aws s3 cp /tmp/${myname}-httpd-logs-${timestamp}.tar s3://${s3_bucket}/${myname}-httpd-logs-${timestamp}.tar
