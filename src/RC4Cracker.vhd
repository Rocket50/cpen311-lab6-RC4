library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

package RC4Crackerdecs is
  component RC4Cracker is
    port(status : out std_logic_vector(1 downto 0);
         keystart, keyend : in std_logic_vector(23 downto 0);
         run : in std_logic;
         CLOCK_50 : in  std_logic;  -- Clock pin
         KEY : in  std_logic_vector(3 downto 0);  -- push button switches
         SW : in  std_logic_vector(15 downto 0);  -- slider switches
		     LEDG : out std_logic_vector(7 downto 0);  -- green lights
		     LEDR : out std_logic_vector(17 downto 0));  -- red lights
  end component;
end package;

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.NbitRegDecs.all;
use work.RC4shufferdecs.all;
use work.RC4fillerdecs.all; 
use work.RC4decrypterdecs.all;

-- Entity part of the description.  Describes inputs and output

entity RC4Cracker is
  port(status : out std_logic_vector(1 downto 0);
       keystart, keyend : in std_logic_vector(23 downto 0);
       run : in std_logic;
       CLOCK_50 : in  std_logic;  -- Clock pin
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
   
   
	
	COMPONENT messageROM is
	   PORT (
			address	: IN STD_LOGIC_VECTOR (4 DOWNTO 0);
			clock	: IN STD_LOGIC ;
			q	: OUT STD_LOGIC_VECTOR (7 DOWNTO 0)
	);
	END COMPONENT;
	

	-- Enumerated type for the state variable.  You will likely be adding extra
	-- state names here as you complete your design
	
	type state_type is (state_init, state_fill, state_shuffle, state_decrypt, state_keySuccess, state_failed);
								
    -- These are signals that are used to connect to the memory													 
	 signal address, fillerAddr, shuffleAddr, decryptAddr : STD_LOGIC_VECTOR (7 DOWNTO 0);	 
	 signal data, fillerData, shuffleData, decryptData: STD_LOGIC_VECTOR (7 DOWNTO 0);
	 signal wren, fillerWren, shuffleWren, decryptWren: STD_LOGIC;
	 signal fillerRun, shuffleRun, decryptRun : std_logic := '0';
	 signal fillerDone, shuffleDone : std_logic;
	 
	 signal decryptStatus : std_logic_vector(1 downto 0);
	 
	 signal q : STD_LOGIC_VECTOR (7 DOWNTO 0);	
   signal rst : std_logic;
   
   signal msgq : std_logic_vector(7 downto 0);
   signal msgAddr : std_logic_vector(4 downto 0); 
   
   signal currKey, nextKey : std_logic_vector(23 downto 0);
   
   
   
   
      
   signal state, nextstate : state_type := state_init;
   
	 begin
	    -- Include the S memory structurally
	
       u0: s_memory port map (
	        address => address, clock => CLOCK_50, data => data, wren => wren, q => q);
      
       filler : RC4filler port map(rst => rst, CLOCK_50 => CLOCK_50, addr => fillerAddr, wren => fillerWren, data => fillerData, 
                                   done => fillerDone, run => fillerRun);
      
       shuffler : RC4shuffler port map(rst => rst, key => currKey, CLOCK_50 => CLOCK_50, run => shuffleRun, done => shuffleDone,
                                       addr => shuffleAddr, data => shuffleData, q => q, wren => shuffleWren);
                                       
        
       decrypter : RC4decrypter port map(rst => rst, msgq => msgq, msgAddr => msgAddr, CLOCK_50 => CLOCK_50, run => decryptRun,
                                         status => decryptStatus, addr => decryptAddr, data => decryptData, q => q, wren => decryptWren);
       
       msgROM : messageROM port map(address => msgAddr, q => msgq, clock => CLOCK_50);        
                               
       process(CLOCK_50) begin
          if(rising_edge(CLOCK_50)) then
            if(rst = '0') then
              if(state = state_init) then
                currKey <= keystart;
              else
                currKey <= nextKey;
              end if;
              state <= nextstate;
            else
              currKey <= keystart;              
              state <= state_init;
            end if;
          end if;
        end process;
      --Next state logic;
      process(all) begin 
        if(state = state_init) then
          nextKey <= currKey;
          if(run = '1') then
            nextstate <= state_fill;
          else
            nextstate <= state;
          end if;
        elsif(state = state_fill) then
          nextKey <= currKey;
          if(fillerDone) then
            nextstate <= state_shuffle;
          else
            nextstate <= state;
          end if;
        elsif(state = state_shuffle) then
          nextKey <= currKey;
          if(shuffleDone) then
            nextstate <= state_decrypt;
          else
            nextstate <= state;
          end if;
        elsif(state = state_decrypt) then
          
          if(decryptStatus = "10") then --done fail
            if(currKey = keyend) then
              nextKey <= currKey;
              nextstate <= state_failed;
            else
              nextKey <= std_logic_vector(unsigned(currKey) + 1);
              nextstate <= state_fill;
            end if;
          
          elsif(decryptStatus = "11") then
              nextKey <= currKey;
              nextstate <= state_keySuccess;
          else
              nextKey <= currKey;
              nextstate <= state;
          end if;
        elsif(state = state_failed or state = state_keySuccess) then
          nextKey <= currKey;
          nextstate <= state; 
        else
          nextKey <= currKey;
          nextstate <= state;
        end if;
      end process;
      
      process(all) begin
        if(state = state_keySuccess) then
          status <= "11";
        elsif(state = state_failed) then
          status <= "10";
        elsif(state = state_init) then
          status <= "00";
        else
          status <= "01";
        end if;
      end process;

        
      --Control signal logic
      process(all) begin
        
        if(state = state_init) then
          address <= (others => '-');
          data <= (others => '-');
          wren <= '0';
          
          decryptRun <= '0';
          shuffleRun <= '0';
          fillerRun <= '0';
        elsif(state = state_fill) then
          address <= fillerAddr;
          data <= fillerData;
          wren <= fillerWren;
          
          decryptRun <= '0';
          shuffleRun <= '0';
          fillerRun <= '1';
        elsif(state = state_shuffle) then
          address <= shuffleAddr;
          data <= shuffleData;
          wren <= shuffleWren;
          
          decryptRun <= '0';
          shuffleRun <= '1';
          fillerRun <= '0'; 
        elsif(state = state_decrypt) then
          address <= decryptAddr;
          data <= decryptData;
          wren <= decryptWren;
          
          decryptRun <= '1';
          shuffleRun <= '0';
          fillerRun <= '0'; 
        elsif(state = state_keySuccess or state = state_failed) then
          address <= (others => '-');
          data <= (others => '-');
          wren <= '0';
          
          decryptRun <= '0';
          shuffleRun <= '0';
          fillerRun <= '0'; 
        else
          address <= (others => '-');
          data <= (others => '-');
          wren <= '0';
          
          decryptRun <= '0';
          shuffleRun <= '0';
          fillerRun <= '0';
        end if;
      end process;
         
	     -- write your code here.  As described in Slide Set 14, this 
       -- code will drive the address, data, and wren signals to
       -- fill the memory with the values 0...255
         
       -- You will be likely writing this is a state machine. Ensure
       -- that after the memory is filled, you enter a DONE state which
       -- does nothing but loop back to itself.  

	     --Filler next state logic
	    
	    
      
      rst <= not KEY(0);

end RTL;


