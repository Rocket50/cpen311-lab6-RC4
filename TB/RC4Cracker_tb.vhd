library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.NbitRegDecs.all;
use work.RC4shufferdecs.all;
use work.RC4fillerdecs.all; 
use work.RC4Crackerdecs.all;

entity RC4Cracker_tb is
end entity;

architecture impl of RC4Cracker_tb is
  
  signal clk : std_logic := '0';
  
  begin
    
    DUT : RC4Cracker port map(run => '1', CLOCK_50 => clk, KEY => (others => '1'), SW => (others => '0'), LEDG => open, LEDR => open);
    
    process begin
      
      for I in 0 to 10000 loop
        wait for 5 ps;
        
        
        clk <= not clk;
        
      end loop;
      
      wait;
    end process;
end impl;
