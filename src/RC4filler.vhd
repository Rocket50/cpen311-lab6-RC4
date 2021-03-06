library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

package RC4fillerdecs is
  component RC4filler is
    port(rst : in std_logic;
       CLOCK_50 : in std_logic;
	     addr : out std_logic_vector(7 downto 0);
	     wren : out std_logic;
	     data : out std_logic_vector(7 downto 0);
	     done : out std_logic;
	     run  : in std_logic);
	end component;
end package;

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity RC4filler is
  port(rst : in std_logic;
       CLOCK_50 : in std_logic;
	     addr : out std_logic_vector(7 downto 0);
	     wren : out std_logic;
	     data : out std_logic_vector(7 downto 0);
	     done : out std_logic;
	     run  : in std_logic);
end entity;

architecture impl of RC4filler is
  type state_type is (StFilling, StDone);
    
  signal state, nextstate : state_type := StFilling;
  signal donedummy : std_logic := '0';
  signal fillerCntCurr : unsigned(7 downto 0) := (others => '0'); 
  
  begin
    
  process(CLOCK_50) begin
	  if(rising_edge(CLOCK_50)) then
	    if(rst = '0' and state = StFilling and run = '1') then
	       fillerCntCurr <= fillerCntCurr + 1; 
	    else
	       fillerCntCurr <= (others => '0');
	    end if;
	  end if;
	end process;  
  
  process(CLOCK_50) begin
      if(rising_edge(CLOCK_50)) then
        if(rst = '0') then
          state <= nextstate;
        else
          state <= StFilling;
        end if;
    end if;
  end process; 
  
  process(all) begin 
    if(state = StFilling) then
      if(fillerCntCurr = to_unsigned(255,fillerCntCurr'LENGTH)) then
        nextstate <= StDone;
        donedummy <= '0';
      else
        nextstate <= state;
        donedummy <= '0';
      end if; 
      
    elsif(state = StDone) then
      donedummy <= '1';
      if(run = '0') then
        nextstate <= StFilling;
      else
        nextstate <= state;
      end if;
    else
      donedummy <= '0';
      nextstate <= state;
    end if;
  end process;
  
  wren <= not donedummy;  
  done <= donedummy;   
  data <= std_logic_vector(fillerCntCurr);
  addr <= std_logic_vector(fillerCntCurr);
    
end impl; 


	     