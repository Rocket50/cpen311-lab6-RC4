library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.NbitRegDecs.all;

-- Entity part of the description.  Describes inputs and outputs

entity RC4Cracker is
  port(CLOCK_50 : in  std_logic;  -- Clock pin
       KEY : in  std_logic_vector(3 downto 0);  -- push button switches
       SW : in  std_logic_vector(15 downto 0);  -- slider switches
		 LEDG : out std_logic_vector(7 downto 0);  -- green lights
		 LEDR : out std_logic_vector(17 downto 0));  -- red lights
end RC4Cracker;

-- Architecture part of the description

architecture rtl of RC4Cracker is

   -- Declare the component for the ram.  This should match the entity description 
	-- in the entity created by the megawizard. If you followed the instructions in the 
	-- handout exactly, it should match.  If not, look at s_memory.vhd and make the
	-- changes to the component below
	
   COMPONENT s_memory IS
	   PORT (
		   address		: IN STD_LOGIC_VECTOR (7 DOWNTO 0);
		   clock		: IN STD_LOGIC  := '1';
		   data		: IN STD_LOGIC_VECTOR (7 DOWNTO 0);
		   wren		: IN STD_LOGIC ;
		   q		: OUT STD_LOGIC_VECTOR (7 DOWNTO 0));
   END component;

	-- Enumerated type for the state variable.  You will likely be adding extra
	-- state names here as you complete your design
	
	type state_type is (state_init, 
                       state_fill,						
   	 					  state_done);
								
    -- These are signals that are used to connect to the memory													 
	 signal address : STD_LOGIC_VECTOR (7 DOWNTO 0);	 
	 signal data : STD_LOGIC_VECTOR (7 DOWNTO 0);
	 signal wren : STD_LOGIC;
	 signal q : STD_LOGIC_VECTOR (7 DOWNTO 0);	
   signal rst : std_logic;
   
   signal fillerCntCurr : unsigned(7 downto 0) := (others => '0');
   signal fillerStateCurr, fillerStateNext : state_type := state_init;
	 begin
	    -- Include the S memory structurally
	
       u0: s_memory port map (
	        address => address, clock => CLOCK_50, data => data, wren => wren, q => q);
	        	     
	     --Filler state flip flop
	     process(CLOCK_50) begin
	       if(rising_edge(CLOCK_50)) then
	         if(rst = '0') then
	           fillerStateCurr <= fillerStateNext;
	         else
	           fillerStateCurr <= state_init; 
	         end if;
	        end if;
	     end process; 
	     
	     process(CLOCK_50) begin
	       if(rising_edge(CLOCK_50)) then
	         if(rst = '0' and fillerStateCurr = state_fill) then
	           fillerCntCurr <= fillerCntCurr + 1; 
	         else
	           fillerCntCurr <= (others => '0');
	         end if;
	       end if;
	     end process;
	     	     
	     -- write your code here.  As described in Slide Set 14, this 
       -- code will drive the address, data, and wren signals to
       -- fill the memory with the values 0...255
         
       -- You will be likely writing this is a state machine. Ensure
       -- that after the memory is filled, you enter a DONE state which
       -- does nothing but loop back to itself.  

	     --Filler next state logic
	     process(all) begin
	       if(fillerStateCurr = state_init) then
	         fillerStateNext <= state_fill;
	       elsif(fillerStateCurr = state_fill) then
	       
	         if(fillerCntCurr = to_unsigned(255,fillerCntCurr'LENGTH)) then
	           fillerStateNext <= state_done;
	         else
	           fillerStateNext <= fillerStateCurr;
	         end if;
	         
	       elsif(fillerStateCurr = state_done) then
	         fillerStateNext <= fillerStateCurr;
	       else
	         fillerStateNext <= fillerStateCurr;
	       end if;
      end process;
      
      
      address <= std_logic_vector(fillerCntCurr);
      wren <= '1';
      data <= std_logic_vector(fillerCntCurr);
      
      rst <= KEY(0);

end RTL;


