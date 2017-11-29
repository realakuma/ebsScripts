printf '***********please initialize the RUN FILE Env var before following steps *********** \n'

printf '*********** please copy all install files into $HOME/eyEBSScriptHome *********** \n'

if [ ! -d "$HOME/eyEBSScriptHome" ]; then
  mkdir $HOME/eyEBSScriptHome
fi

if grep -Fxq "export ey_EBSScript_HOME=$HOME/eyEBSScriptHome" $HOME/.profile
then
    # code if found
	echo ""
else
    # code if not found
    echo export ey_EBSScript_HOME=$HOME/eyEBSScriptHome >> $HOME/.profile

fi


printf '***********please Input the password of APPS*********** \n'

read APPSPWD

printf '***********please Input the password of Weblogic*********** \n'

read WEBLOGICPWD

printf '***********install crypto package for APPS*********** \n'
sqlplus apps/$APPSPWD @install_crypto.sql

printf "***********compiling JAVA Program for Admin Password crypto*********** \n"
javac -d $JAVA_TOP PWDUtil.java

printf "*********** create encryption_password.txt*********** \n"

echo "" > $ey_EBSScript_HOME/encryption_password.txt

printf "*********** initialize encryption_password.txt*********** \n"
java xxgl.scripts.PWDUtil ENCRYPT APPS $APPSPWD
java xxgl.scripts.PWDUtil ENCRYPT WEBLOGIC $WEBLOGICPWD