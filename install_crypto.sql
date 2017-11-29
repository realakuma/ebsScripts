
/*plsql scripts for building encryption and decrytion of Stirng*/
CREATE OR REPLACE PACKAGE xxgl_get_pwd AS
    FUNCTION decrypt (
        key     IN VARCHAR2,
        value   IN VARCHAR2
    ) RETURN VARCHAR2;

    FUNCTION encrypt (
        key     IN VARCHAR2,
        value   IN VARCHAR2
    ) RETURN VARCHAR2;

END xxgl_get_pwd;
/
--Package Body

CREATE OR REPLACE PACKAGE BODY xxgl_get_pwd AS

    FUNCTION decrypt (
        key     IN VARCHAR2,
        value   IN VARCHAR2
    ) RETURN VARCHAR2 AS LANGUAGE JAVA NAME 'oracle.apps.fnd.security.WebSessionManagerProc.decrypt(java.lang.String,java.lang.String) return java.lang.String'
;
    FUNCTION encrypt (
        key     IN VARCHAR2,
        value   IN VARCHAR2
    ) RETURN VARCHAR2 AS LANGUAGE JAVA NAME 'oracle.apps.fnd.security.WebSessionManagerProc.encrypt(java.lang.String,java.lang.String) return java.lang.String'
;
END xxgl_get_pwd;
/
CREATE OR REPLACE PACKAGE xxgl_apps_pwd AS
    FUNCTION decrypt (
        value IN VARCHAR2
    ) RETURN VARCHAR2;

    FUNCTION encrypt (
        value IN VARCHAR2
    ) RETURN VARCHAR2;

END;
/
CREATE OR REPLACE PACKAGE BODY xxgl_apps_pwd AS

    FUNCTION get_key RETURN VARCHAR2 AS
        l_key   VARCHAR2(300);
    BEGIN
        SELECT
            (
                SELECT
                    xxgl_get_pwd.decrypt(fnd_web_sec.get_guest_username_pwd,usertable.encrypted_foundation_password)
                FROM
                    dual
            ) AS apps_password
        INTO
            l_key
        FROM
            fnd_user usertable
        WHERE
            usertable.user_name = (
                SELECT
                    substr(fnd_web_sec.get_guest_username_pwd,1,instr(fnd_web_sec.get_guest_username_pwd,'/') - 1)
                FROM
                    dual
            );

        RETURN l_key;
    END;

    FUNCTION decrypt (
        value IN VARCHAR2
    ) RETURN VARCHAR2
        AS
    BEGIN
        RETURN xxgl_get_pwd.decrypt(get_key,value);
    END;

   FUNCTION encrypt (
        value IN VARCHAR2
    ) RETURN VARCHAR2
        AS
    BEGIN
        RETURN xxgl_get_pwd.encrypt(get_key,value);
    END;
END;
/
exit;