CREATE OR REPLACE FUNCTION         make_number (v_text   in varchar2,
                                                v_option in number default 0)
return number is
/* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * */
/* Author: Patrick Conrad - Ekagra Software                                            */
/* Date  : 07/19/2006                                                                  */
/* Descr : The function takes a TEXT value and tries to convert it into a number.      */
/*         The primary use for this function is to allow patient position ids to be    */
/* sorted numerically.  values 1, 2, 3, 4, 11, 12 should appear in this order when     */
/* sorted numerically.  When sorted non-numeric, 1, 11, 12, 2, 3, 4. The TO_NUMBER     */
/* function cannot be used because patient position ids can contain alpha charcaters.  */
/* 1, 2, 3, 3E are all valid patient position ids.                                     */
/* V_OPTION: this option designates where ALPHA values are to appear in the sort.      */
/*           0 - Causes numbers with alpha prefixes to appear at end of sort.          */
/*           1 - Causes numbers with alpha prefixes to appear at beginning of sort.    */
/*           2 - Causes numbers with alpha prefixes to appear mixed within the sort    */
/*               based upon their translated numeric value.                            */
/* Numeric Value: The premise is, take the value, strip off the first '+' sign if      */
/*                it exists, replace all non-numeric values with decimal points,       */
/* replace all extra decimal points with zeros, convert value to number.               */
/* So, 1, 2, 3, 3-1 become 1, 2, 3, 3.1 numerically.                                   */
/* NOTE: Since a group of alpha values can return from this function with the same     */
/*       numeric value, it will be necessary to include a secondary sort. If PT is the */
/*       column to sort, using "order by make_number(PT), PT" will provide the subsort */
/*       needed within the alpha values.                                               */
/* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * */

v_number number;           -- holds numeric value
v_hold   varchar2(2000);   -- holds text to be converted

Begin
   v_hold := rtrim(ltrim(v_text));   -- remove extra spaces, before and after

   If Instr(v_hold,'+') = 1 then     -- If text has '+' prefix,
      v_hold := substr(v_hold,2);    -- remove it.
   End If;

   Begin
      -- for option 0 and 1 convert text to number High and Low, only if it is
      -- prefixed with 'A' through 'Z' all other special characters handled below.

      select decode(v_option,0,'999999999',    -- 0 option sends alpha to end
                             1,'-999999999',    -- 1 option sends alpha to begining
                             v_hold)           -- not 0 or 1, build numeric value
        into v_hold
        from dual
       where upper(substr(v_hold,1,1)) between 'A' and 'Z';

   Exception
      When no_data_found Then Null;

   End;

   -- replace all non-numeric characters with decimal points
   select TRANSLATE(v_hold,
                    '_./ abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ-+',
                    '..........................................................')
     into v_hold
     from dual;


   If Instr(v_hold,'.') <> 0 then          -- if the string has decimal points
      If replace(v_hold,'.') is null then  -- if the string is ALL decimal points
         v_hold := '0';                    --   then make it 0
      Else
         -- for every decimal point after the first one, make them zeroes.
         v_hold := substr(v_hold,1,instr(v_hold,'.'))||
                   replace(substr(v_hold,instr(v_hold,'.')+1),'.','0');
      End If;
   End If;

   Begin
      --Convert value to number
      v_number := to_number(v_hold);

   exception
      -- If the number conversion fail for any reason, set number value to zero
      When Others then
      v_number := 0;
   End;

   -- pass the number value back.
   Return v_number;

End;
/

