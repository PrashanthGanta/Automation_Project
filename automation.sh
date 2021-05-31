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

##Creating tar file and copying the tar file to s3

# Time stamp
timestamp=$(date '+%d%m%Y-%H%M%S')

# Creating a tar file of .log files to tmp location
tar -cvf /tmp/${myname}-httpd-logs-${timestamp}.tar /var/log/apache2/*.log

# Copying the tar file from tmp location to S3 bucket
aws s3 cp /tmp/${myname}-httpd-logs-${timestamp}.tar s3://${s3_bucket}/${myname}-httpd-logs-${timestamp}.tar

#loading the tarfilesize to variable
tarFileSize=$(du -h /tmp/${myname}-httpd-logs-${timestamp}.tar | awk '{print $1}')

# Creating inventory.html in /var/www/html/ and appending data to the file
if [ -f /var/www/html/inventory.html ]
then
	echo httpd-logs $'\t' ${timestamp} $'\t' tar $'\t' ${tarFileSize} | tee -a /var/www/html/inventory.html
else
	echo Log Type $'\t' Time Created $'\t\t' Type $'\t' Size | tee /var/www/html/inventory.html
	echo httpd-logs $'\t' ${timestamp} $'\t' tar $'\t' ${tarFileSize} | tee -a /var/www/html/inventory.html
fi

# To set cron job task
# As the specific time is not mentined in the task, i am scheduling the cronjob to run at 9:01 Am every day
if [ -f /etc/cron.d/automation ]
then
        task="1 9 * * * root /root/Automation_Project/automation.sh"
        cronJonTask=$(head -1 /etc/cron.d/automation)
        if [[ "$cronJonTask" = $task ]]; then
                echo "cron job is set already"
		else
			echo "1 9 * * * root /root/Automation_Project/automation.sh" | tee /etc/cron.d/automation
        fi
else
        echo "1 9 * * * root /root/Automation_Project/automation.sh" | tee /etc/cron.d/automation
fi
