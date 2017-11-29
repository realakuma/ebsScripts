package xxgl.scripts;
import java.util.Map;
import java.util.Iterator;
import java.io.IOException;
import java.sql.CallableStatement;
import java.sql.Connection;
import java.sql.SQLException;
import java.sql.Types;
import oracle.apps.fnd.common.AppsContext;
import java.io.BufferedInputStream;
import java.io.FileInputStream;
import java.io.FileOutputStream;
import java.io.InputStream; 
import java.io.FileNotFoundException;
import java.util.Iterator;
import java.util.Properties; 

public class PWDUtil
{
	static String  fnd_secure="FND_SECURE";
	static String  two_task="TWO_TASK";
	static String  profileName="encryption_password.txt";
	static String  eyEBSSriptHome="ey_EBSScript_HOME";
	static String   profileFullPath="";
    private static Properties props = new Properties();   
    static {   
        try {
			 
			 String osname = System.getProperty("os.name");
	 if (osname.startsWith("win") || osname.startsWith("Win")) 
	 {
		 profileFullPath=getEnvValue(eyEBSSriptHome)+"\\"+profileName;
	 }
	 
	 else
	 {
		 profileFullPath=getEnvValue(eyEBSSriptHome)+"/"+profileName;
	 }
	 
            props.load(new FileInputStream(profileFullPath)); 
        } catch (FileNotFoundException e) {   
            e.printStackTrace();   
            System.exit(-1);   
        } catch (IOException e) {          
            System.exit(-1);   
        }   
    }
	
 public static void main(String[] args) 
 {
 if (args[0].equals("DECRYPT") && !args[1].equals(""))
 {
    System.out.println(getDecryptValue(getKeyValue(args[1])));

 }
 if	(args[0].equals("ENCRYPT") && !args[1].equals("") && !args[2].equals(""))
 {
 	String encrypt_password=getEncryptValue(args[2]);
    System.out.println(encrypt_password);
    writeProperties(args[1],encrypt_password);
 }
 
 if	(args[0].equals("KEYVALUE") && !args[1].equals(""))
 {
    System.out.println(getKeyValue(args[1]));
 }

 System.exit(0);
 }
	
 public static String getEnvValue(String Key)
 {
	  Map<String, String> map = System.getenv();
	  //check LoadBalance wether applied;
      if (Key.equals(two_task))
      {
	   if (map.get(Key).toUpperCase().indexOf("_BALANCE")>=0)
	  {
		  return map.get(Key).substring(0,map.get(Key).indexOf("_"));
	  }
	    else
		{
			return map.get(Key);
			
		}
      }
	  else {
	  return map.get(Key); 
      }	  
 } 
 
 public static String getDecryptValue(String str)
 {
	 Connection conn=null;
	 AppsContext apps;
	 CallableStatement cstmt;
	 String decrypt_value="";
 try
 {
	 String osname = System.getProperty("os.name");
	 if (osname.startsWith("win") || osname.startsWith("Win")) 
	 {
		 apps = new AppsContext(getEnvValue(fnd_secure)+"\\"+getEnvValue(two_task)+".dbc");
		 
	 }
	 
	 else
	 {
		 apps = new AppsContext(getEnvValue(fnd_secure)+"/"+getEnvValue(two_task)+".dbc");
		 
	 }
	 conn = apps.getJDBCConnection();
	 cstmt = conn.prepareCall("{? = call xxgl_apps_pwd.decrypt(?)}");
     cstmt.registerOutParameter(1, Types.VARCHAR);
     cstmt.setString(2, str);
     cstmt.executeUpdate();
     decrypt_value = cstmt.getString(1);
	 
   }
   catch (Exception e) {
			e.printStackTrace();
				} 
		finally {
			try {
			if (conn != null) {
				conn.close();
			}
			return decrypt_value;
		} catch (SQLException e) {
			e.printStackTrace();
			return "";
		}
	}

 }
 public static String getEncryptValue(String str)
 {
	 Connection conn=null;
	 AppsContext apps;
	 CallableStatement cstmt;
	 String decrypt_value="";
 try
 {
	 String osname = System.getProperty("os.name");
	 if (osname.startsWith("win") || osname.startsWith("Win")) 
	 {
		 apps = new AppsContext(getEnvValue(fnd_secure)+"\\"+getEnvValue(two_task)+".dbc");
		 
	 }
	 
	 else
	 {
		 apps = new AppsContext(getEnvValue(fnd_secure)+"/"+getEnvValue(two_task)+".dbc");
		 
	 }
	 conn = apps.getJDBCConnection();
	 cstmt = conn.prepareCall("{? = call xxgl_apps_pwd.encrypt(?)}");
     cstmt.registerOutParameter(1, Types.VARCHAR);
     cstmt.setString(2, str);
     cstmt.executeUpdate();
     decrypt_value = cstmt.getString(1);
	 
   }
   catch (Exception e) {
			e.printStackTrace();
				} 
		finally {
			try {
			if (conn != null) {
				conn.close();
			}
			return decrypt_value;
		} catch (SQLException e) {
			e.printStackTrace();
			return "";
		}
	}

 }
     
  
    
    public static String getKeyValue(String key) {   
        return props.getProperty(key);   
    }   
  
       
    public static String readValue(String filePath, String key) {   
        Properties props = new Properties();   
        try {   
            InputStream in = new BufferedInputStream(new FileInputStream(   
                    filePath));   
            props.load(in);   
            String value = props.getProperty(key);   
            System.out.println(key +"value:"+ value);   
            return value;   
        } catch (Exception e) {   
            e.printStackTrace();   
            return null;   
        }   
    }   
      
    
    public static void writeProperties(String keyname,String keyvalue) {          
        try {   
            
            FileOutputStream fos = new FileOutputStream(profileFullPath);   
            props.setProperty(keyname, keyvalue);     
            props.store(fos, "Update '" + keyname + "' value");   
        } catch (IOException e) {   
            e.printStackTrace();   
        }   
    }   
  
   
    public void updateProperties(String keyname,String keyvalue) {   
        try {   
            props.load(new FileInputStream(profileFullPath));   
            FileOutputStream  fos = new FileOutputStream(profileFullPath);              
            props.setProperty(keyname, keyvalue);   
            props.store(fos, "Update '" + keyname + "' value");   
        } catch (IOException e) {   
             e.printStackTrace();    
        }   
    }   

}