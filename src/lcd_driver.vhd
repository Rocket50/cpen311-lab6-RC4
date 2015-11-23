
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity lcd_driver is
	port( 
	     clk : in std_logic;
		  resetb : in std_logic;
		  displ_char : in std_logic_vector(7 downto 0);
		  displ_write : in std_logic;
		  displ_ready : out std_logic;
        lcd_rw : out std_logic;
        lcd_en : out std_logic;
        lcd_rs : out std_logic;
        lcd_on : out std_logic;
        lcd_blon : out std_logic;
        lcd_data : out std_logic_vector(7 downto 0));
end lcd_driver ;



architecture behavioural of lcd_driver is

-- Define a few constants that are related to the LCD display

-- This indicates the speed of the LCD.  A larger number means it goes slower.
-- If you start to see some characters "missing" in the display, increase this constant
constant speed : integer := 32768;

-- This defines a sequences of commands that will initialize the LCD.  Information on 
-- the commands can be found in the LCD datasheet
type startup_array_type is array (0 to 5) of std_logic_vector(7 downto 0);
constant startup_array : startup_array_type := (x"38",x"38",x"0C",x"01",x"06",x"80");

-- These commands are used after the 8th and 16th character is printed
constant return_command: std_logic_vector(7 downto 0) := x"c0";  -- go to row 2, pos 1
constant home_command: std_logic_vector(7 downto 0) := x"80";  -- go to row 1, pos 1
constant width_of_line : integer := 16;  -- width of the line on the LCD

-- States for this module
type state_type is (lcd_state_initialize, lcd_state_wait, lcd_state_character, lcd_state_cr, lcd_state_char_done);

begin

   -- turn on the LCD.  These should be always driven.
	
   lcd_blon <= '1'; 
	lcd_on <= '1';
   lcd_rw <= '0';	

	-- Main process of the LCD driver.  It is written as a simple state machine
	
	process(clk, resetb)
	variable cnt : integer := 0;   -- used to slow down writing to the LCD
	variable i : integer := 0;     -- steps through commands to initialize LCD
	variable state : state_type;   -- state of the state machine
	variable position : integer := 0;  -- number of characters we have printed so far
	variable local_copy_of_character : std_logic_vector(7 downto 0);
	begin
	   -- Asynchronous reset
		if resetb = '0' then
			state := lcd_state_initialize;
			cnt := 0;
			i := 0;
			position := 0;
--	      lcd_data <= "00000000";
--      	lcd_rs <= '0';
--	      lcd_en <= '1';			
				
		elsif rising_edge(clk) then
		   case state is
			
			   -- initialize the LCD.  This means sending the 5 commands indiciated earlier

			   when lcd_state_initialize =>  
				   displ_ready <= '0';  -- we are not ready to accept characters while initializing
               lcd_data <= startup_array(i);  -- send command i
               lcd_rs <= '0';                 -- rs is 0 means this is a command not a character
               cnt := cnt + 1;                -- loop to slow down writing
               if (cnt < speed/2) then        -- produce a slow clock for the LCD
                  lcd_en <= '1';                
					else
					   lcd_en <= '0';
					end if;

               -- See if we are done with this character					
               if (cnt = speed) then 
				      cnt := 0;				 
			         i := i + 1;  -- skip to next character
                  if (i=6) then
				          state := lcd_state_wait;
 				      end if;
 			      end if;

            -- We have initalized the LCD, so now wait for the caller to indicate
            -- that it has data to send
				
				when lcd_state_wait =>
               displ_ready <= '1';	-- we are ready and waiting														
				   if displ_write = '1' then  -- if the user indicates he/she is writing...
				       displ_ready <= '0';  -- not ready anymore.  Need to process
						 local_copy_of_character := displ_char;  -- save character
      				 position := position + 1;	 -- keep track of # characters
					    state := lcd_state_character;
					end if;
				
			   when lcd_state_character =>

				   -- send character
				   lcd_data <= local_copy_of_character;
					lcd_rs <= '1';  -- 1 indicates this is a character not a command
		
               -- keep sending this for many cycles, since LCD is slow
          		cnt := cnt + 1;
               if (cnt <= speed/2) then  -- create a slow clock for LCD
                  lcd_en <= '1';
					else
					   lcd_en <= '0';
					end if;
					
		     	   if (cnt = speed) then 
				      cnt := 0;
						         
					   -- If we are at position 16 or 32, we need to insert a carriage return				
		            if position = width_of_line or
						   position = width_of_line*2 then				
						   state := lcd_state_cr;
						else
						   -- otherwise, we are done with this character
	    			      state := lcd_state_char_done;
						end if;
   			   end if;

             -- State to print a carriage return or "home"					
				 when lcd_state_cr =>
				 
				   -- depending on whether this was the 16th or 32nd character, choose
					-- to send a CR or Home command
				   if position = width_of_line then
   				   lcd_data <= return_command;
					else
					   lcd_data <= home_command;
					end if;
					lcd_rs <= '0';  -- 0 means this is a command, not a character

               cnt := cnt + 1;			
               if (cnt <= speed/2) then  -- create a slow clock, as before
                  lcd_en <= '1';	
					else
					   lcd_en <= '0';
					end if;
					
		     	   if (cnt = speed) then 
				      cnt := 0;				 
				      state := lcd_state_char_done;
 			      end if;				
	
				 -- the character is done, wait until the user has lowered displ_write
				 when lcd_state_char_done =>				 	
				   if displ_write = '0' then					
					   state := lcd_state_wait;  -- go to next command
					end if;
             when others =>					 
		         state := lcd_state_initialize;				
			    end case;
			end if;
		end process;
	end behavioural;
	