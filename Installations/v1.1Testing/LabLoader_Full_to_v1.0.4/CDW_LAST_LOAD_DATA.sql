--
-- This table must contain a date.  It will be seeded with today's date.
--

Insert into CDW_LAST_LOAD
 values (SYSDATE);
 
 Commit;
 