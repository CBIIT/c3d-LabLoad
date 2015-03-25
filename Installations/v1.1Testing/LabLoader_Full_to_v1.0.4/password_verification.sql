CREATE OR REPLACE FUNCTION password_verification
(username VARCHAR2,
   PASSWORD VARCHAR2,
   old_password VARCHAR2)
   RETURN BOOLEAN IS
   n BOOLEAN;
   m INTEGER;
   differ INTEGER;
   isdigit BOOLEAN;
   ischar  BOOLEAN;
   ispunct BOOLEAN;
   digitarray VARCHAR2(20);
   punctarray VARCHAR2(25);
   chararray VARCHAR2(52);

BEGIN
   digitarray:= '0123456789';
   chararray:= 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ';
   punctarray:='!"#$%&()''*+,-/:;<=>?_';

--Check if the password is same as the username
IF PASSWORD = username THEN
   RAISE_APPLICATION_ERROR(-20001, 'Password same as user');
END IF;

--Check for the minimum length of the password
IF LENGTH(PASSWORD) < 8 THEN
   RAISE_APPLICATION_ERROR(-20002, 'Password length less than 8');
END IF;

--Check if the password is too simple. A dictionary of words may be
--maintained and a check may be made so as not to allow the words
--that are too simple for the password.
--IF NLS_LOWER(password) IN ('welcome', 'database', 'account', 'user',
--   'password', 'oracle', 'computer', 'abcd')
--   THEN raise_application_error(-20002, 'Password too simple');
--END IF;

--Check if the password contains at least one letter,
--one digit and one punctuation mark.
--1. Check for the digit
--You may delete 1. and replace with 2. or 3.
isdigit:=FALSE;
m := LENGTH(PASSWORD);
FOR i IN 1..10 LOOP
  FOR j IN 1..m LOOP
    IF SUBSTR(PASSWORD,j,1) = SUBSTR(digitarray,i,1) THEN
      isdigit:=TRUE;
        GOTO findchar;
    END IF;
   END LOOP;
END LOOP;
IF isdigit = FALSE THEN
  RAISE_APPLICATION_ERROR(-20003, 'Password should contain at least one \
  digit, one CHARACTER AND one punctuation');
END IF;
--2. Check for the character

<<findchar>>
ischar:=FALSE;
FOR i IN 1..LENGTH(chararray) LOOP
  FOR j IN 1..m LOOP
    IF SUBSTR(PASSWORD,j,1) = SUBSTR(chararray,i,1) THEN
       ischar:=TRUE;
         GOTO findpunct;
       END IF;
    END LOOP;
END LOOP;
IF ischar = FALSE THEN
  RAISE_APPLICATION_ERROR(-20003, 'Password should contain at least one digit,\
    one CHARACTER AND one punctuation');
END IF;
--3. Check for the punctuation

<<findpunct>>
ispunct:=FALSE;
FOR i IN 1..LENGTH(punctarray) LOOP
  FOR j IN 1..m LOOP
    IF SUBSTR(PASSWORD,j,1) = SUBSTR(punctarray,i,1) THEN
       ispunct:=TRUE;
         GOTO endsearch;
       END IF;
   END LOOP;
END LOOP;
IF ispunct = FALSE THEN RAISE_APPLICATION_ERROR(-20003, 'Password should \
 contain AT LEAST one digit, one CHARACTER AND one punctuation');
END IF;

<<endsearch>>
--Check if the password differs from the previous password by at least 3 letters
--IF old_password = '' THEN
--  raise_application_error(-20004, 'Old password is null');
--END IF;
--Everything is fine; return TRUE ;
--differ := length(old_password) - length(password);
--IF abs(differ) < 3 THEN
--  IF length(password) < length(old_password) THEN
--    m := length(password);
--  ELSE
--    m:= length(old_password);
--  END IF;
--  differ := abs(differ);
--  FOR i IN 1..m LOOP
--    IF substr(password,i,1) != substr(old_password,i,1) THEN
--             differ := differ + 1;
--    END IF;
--  END LOOP;
--  IF differ < 3 THEN
--    raise_application_error(-20004, 'Password should differ by at \
--      least 3 characters');
--    END IF;
--  END IF;
--Everything is fine; return TRUE ;
  RETURN(TRUE);
END;
/
