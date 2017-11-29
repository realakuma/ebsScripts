
# | DESCRIPTION
# | This .sh script will take care of steps described on xxxx
# | You might update the passwords parameters defined below to meet your requirement before running this script.
# |
# | USAGE
# | sh change_apps_pwd.sh
# |
# | PLATFORM
# | EBS R12.2.X
# |
# | CONTACT
# | luohua.HUANG@gmail.com

# ======================================================================
# Set Parameters
# ======================================================================
printf "Enter your APPS Password "
read APPS_OLD

printf "Enter your SYSTEM Password "
read SYSTEM_OLD

printf "Enter your WEBLOGIC Password "
read WEBLOGIC_PWD

printf "Enter your new APPS Password"
read APPS_NEW
#APPS_OLD="apps"

#APPS_NEW="newapps123"
#SYSTEM_NEW="newmanager123"

#PRODUCT_NEW="newebs123"

#WEBLOGIC_PWD="welcome1"

RUN_FS=$RUN_BASE

#RUN_FS="/u01/R122_EBS/fs1"
#ORACLE_HOME="/u01/R122_EBS/11.2.0"

HOST_NAME=`hostname -s`
FULL_HOST_NAME=`hostname -s`

WORKING_DIR=`pwd`
LOGFILE="${WORKING_DIR}/change_apps_pwd.log"

# ======================================================================
# Source db tier and update system password
# ======================================================================
#source ${ORACLE_HOME}/${ORACLE_SID}_${HOST_NAME}.env
#printf "********* Changing SYSTEM password ********* \n";
#DBSHUTDOWN=`sqlplus '/as sysdba'<<!
# alter user SYSTEM identified by ${SYSTEM_NEW};
#exit
#!`
#printf "$DBSHUTDOWN \n" >> $LOGFILE;

# ======================================================================
# Source Apps tier
# ======================================================================
#source ${RUN_FS}/EBSapps/appl/APPS${ORACLE_SID}_${HOST_NAME}.env
PORT=`grep s_wls_adminport $CONTEXT_FILE | sed "s/.*\">//" | sed "s/<.*//"`

# ======================================================================
# Stop mid-tier services
# ======================================================================
printf "********* Running adstpall ********* \n";
{ echo apps; echo ${APPS_OLD}; echo ${WEBLOGIC_PWD}; } | sh adstpall.sh -nopromptmsg >> $LOGFILE;
while ps -ef | grep -i fndlib | grep -v "grep" > /dev/null
do
 sleep 30
 printf "********* Waiting for mid-tier services come down ********* \n";
done

# ======================================================================
# Change Product Schema Passowrd
# ======================================================================
#printf "********* Changing Product Schema Passowrd ********* \n";
#FNDCPASS apps/${APPS_OLD} 0 Y system/${SYSTEM_NEW} ALLORACLE ${PRODUCT_NEW} >> $LOGFILE
#STATUS=$?
#if [ $STATUS -gt 0 ];then
# printf "********* Failed to run FNDCPASS apps/${APPS_OLD} 0 Y system/${SYSTEM_NEW} ALLORACLE ${PRODUCT_NEW} ********* \n";
# exit 1;
#fi

# ======================================================================
# Change APPS Schema Passowrd
# ======================================================================
printf "********* Changing APPS Schema Passowrd ********* \n";
FNDCPASS apps/${APPS_OLD} 0 Y system/${SYSTEM_OLD} SYSTEM APPLSYS ${APPS_NEW} >> $LOGFILE
STATUS=$?
if [ $STATUS -gt 0 ];then
 printf "********* Failed to run FNDCPASS apps/${APPS_OLD} 0 Y system/${SYSTEM_NEW} SYSTEM APPLSYS ${APPS_NEW} ********* \n";
 exit 1;
fi

# ======================================================================
# Run adautocfg.sh in AP tier
# ======================================================================
printf "********* Run adautocfg.sh in AP tier ********* \n";
{ echo ${APPS_NEW}; } | sh adautocfg.sh >> $LOGFILE
STATUS=$?
if [ $STATUS -gt 0 ];then
 printf "********* Failed to run adautocfg!! please check the LOGFILE ********* \n";
 exit 1;
fi

# ======================================================================
# Start WLS adadmin console
# ======================================================================
printf "********* Starting WLS adadmin console only ********* \n";
{ echo ${WEBLOGIC_PWD}; echo ${APPS_NEW}; } | sh adadminsrvctl.sh start -nopromptmsg >> $LOGFILE;
STATUS=$?
if [ $STATUS -gt 0 ];then
 printf "********* Failed to startup WLS adadmin console ********* \n";
 exit 1;
fi
sleep 30

# ======================================================================
# Change Datasource password on WLS adadmin console
# ======================================================================
printf "********* Changing Datasource password on WLS adadmin console ********* \n";
rm -f updateDSpwd.py
printf "username = 'weblogic' \n" >> updateDSpwd.py;
printf "password = '${WEBLOGIC_PWD}' \n" >> updateDSpwd.py;
printf "URL='t3://$FULL_HOST_NAME:$PORT' \n" >> updateDSpwd.py;
printf "connect(username,password,URL) \n" >> updateDSpwd.py;
printf "edit() \n" >> updateDSpwd.py;
printf "startEdit() \n" >> updateDSpwd.py;
printf "en = encrypt('$APPS_NEW','${EBS_DOMAIN_HOME}') \n" >> updateDSpwd.py;
printf "dsName = 'EBSDataSource' \n" >> updateDSpwd.py;
printf "cd('/JDBCSystemResources/'+dsName+'/JDBCResource/'+dsName+'/JDBCDriverParams/'+dsName) \n" >> updateDSpwd.py;
printf "set('PasswordEncrypted',en) \n" >> updateDSpwd.py;
printf "print ('') \n" >> updateDSpwd.py;
printf "print ('') \n" >> updateDSpwd.py;
printf "save() \n" >> updateDSpwd.py;
printf "activate() \n" >> updateDSpwd.py;
java -cp $FMW_HOME/wlserver_10.3/server/lib/weblogic.jar weblogic.WLST updateDSpwd.py >> Datasource.log;
STATUS=$?
if [ $STATUS -gt 0 ];then
 printf "********* Failed to change Datasource password on WLS adadmin console ********* \n";
 exit 1;
fi

# ======================================================================
# Startup oacore_server1
# ======================================================================
printf "********* Startup-ing oacore_server1 ********* \n";
 echo ${WEBLOGIC_PWD} | admanagedsrvctl.sh start oacore_server1 -nopromptmsg >> $LOGFILE;
STATUS=$?
if [ $STATUS -gt 0 ];then
 printf "********* Failed to startup oacore_server1 ********* \n";
 exit 1;
fi

# ======================================================================
# Startup ALL services
# ======================================================================
printf "********* Startup-ing ALL services ********* \n";
{ echo apps; echo ${APPS_NEW}; echo ${WEBLOGIC_PWD}; } | sh adstrtal.sh -nopromptmsg >> $LOGFILE;
STATUS=$?
if [ $STATUS -gt 0 ];then
 printf "********* Failed to startup ALL services ********* \n";
 exit 1;
fi

# ======================================================================
# Connect to WLS console to check managed servers statues
# ======================================================================
#rm -f serverStateAll.py
#printf "username = 'weblogic' \n" >> serverStateAll.py;
#printf "password = '${WEBLOGIC_PWD}' \n" >> serverStateAll.py;
#printf "URL='t3://$FULL_HOST_NAME:$PORT' \n" >> serverStateAll.py;
#printf " \n" >> serverStateAll.py;
#printf "connect(username,password,URL) \n" >> serverStateAll.py;
#printf "domainConfig() \n" >> serverStateAll.py;
#printf "serverList=cmo.getServers(); \n" >> serverStateAll.py;
#printf "domainRuntime() \n" >> serverStateAll.py;
#printf "cd('/ServerLifeCycleRuntimes/') \n" >> serverStateAll.py;
#printf "\n" >> serverStateAll.py;
#printf "print 'Servers Status on ' +URL \n" >> serverStateAll.py;
#printf "for server in serverList: \n" >> serverStateAll.py;
#printf "    name=server.getName() \n" >> serverStateAll.py;
#printf "    cd(name) \n" >> serverStateAll.py;
#printf "    serverState=cmo.getState() \n" >> serverStateAll.py;
#printf "    if serverState!='RUNNING': \n" >> serverStateAll.py;
#printf "        print '**** FoundBadServer ****' \n" >> serverStateAll.py;
#printf "        print '***Server: '+ name +'-'+serverState \n" >> serverStateAll.py;
#printf "        break \n" >> serverStateAll.py;
#printf "        print '***Server: '+ name +'-'+serverState \n" >> serverStateAll.py;
#printf "    cd('..') \n" >> serverStateAll.py;
#wlsstatus=`java -cp $FMW_HOME/wlserver_10.3/server/lib/weblogic.jar weblogic.WLST serverStateAll.py`
#printf "$wlsstatus \n" >> $LOGFILE;
#if [[ "$wlsstatus" =~ "FoundBadServer" ]]; then
 #printf "********* FOUND managed server(s) NOT in RUNNING status ********* \n";
 #exit 1;
#fi
#printf "********* ALL services are UP ********* \n";

printf "*********** create encryption_password.txt*********** \n"

echo "" > $ey_EBSScript_HOME/encryption_password.txt

printf "*********** initialize encryption_password.txt with NEW Passowrd *********** \n"
java xxgl.scripts.PWDUtil ENCRYPT APPS $APPS_NEW
java xxgl.scripts.PWDUtil ENCRYPT WEBLOGIC $WEBLOGIC_PWD

printf "********* Done! ********* \n";