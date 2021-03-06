library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.RC4Crackerdecs.all;

entity RC4Watchdog is
  port(  CLOCK_50 : in  std_logic;  -- Clock pin
         KEY : in  std_logic_vector(3 downto 0);  -- push button switches
         SW : in  std_logic_vector(15 downto 0);  -- slider switches
		     LEDG : out std_logic_vector(7 downto 0);  -- green lights
		     LEDR : out std_logic_vector(17 downto 0));  -- red lights
end entity; 

architecture impl of RC4Watchdog is
  --2 MSB of key are 0, total key space = 1677216 / (2 * 2) = 419304 
  constant secretCode : std_logic_vector(23 downto 0) := "00000011" & "01011111" & "00111100";
  --constant CORE1START : std_logic_vector(23 downto 0) :=  "00000000" & "00000000" & "00000000";
  --constant CORE1END : std_logic_vector(23 downto 0) :=  "00111111" & "11111111" & "11111111";
  --"00000000" & "00110001" & "11111111";
  constant CORE1START : std_logic_vector(23 downto 0) := "00000000" & "00000000" & "00000000"; 
  constant CORE1END : std_logic_vector(23 downto 0) := "00010000" & "00000000" & "00000000"; 
  constant CORE2START : std_logic_vector(23 downto 0) := "00010000" & "00000000" & "00000000"; 
  constant CORE2END : std_logic_vector(23 downto 0) := "00111111" & "11111111" & "11111111";
  
  constant COREDONESUCCESS : std_logic_vector := "11";
  constant COREDONEFAILED : std_logic_vector := "10";
  
  type state_type is (GO, STATEDONE, STATEDONEFAILED);
    
  signal c1_status, c2_status : std_logic_vector(1 downto 0);
  signal c1_start, c1_end, c2_start, c2_end : std_logic_vector(23 downto 0);
  signal c1_run, c2_run : std_logic;
  signal state, nextstate : state_type := GO;
  
  signal rst : std_logic;   
  begin
    
    CORE1 : RC4Cracker port map(CLOCK_50 => CLOCK_50, status => c1_status, keystart => c1_start, keyend => c1_end, run => c1_run, KEY => KEY, SW => SW, LEDG => open, LEDR => open);
    CORE2 : RC4Cracker port map(CLOCK_50 => CLOCK_50, status => c2_status, keystart => c2_start, keyend => c2_end, run => c2_run, KEY => KEY, SW => SW, LEDG => open, LEDR => open);

    c1_start <= CORE1START;
    c1_end <= CORE1END;
    
    c2_start <= CORE2START;
    c2_end <= CORE2END;
    
    process(CLOCK_50) begin
      if(rising_edge(CLOCK_50)) then
        if(rst = '1') then
          state <= GO;
        else
          state <= nextstate;
        end if;
      end if;
    end process;
  
    process(all) begin
      if(c1_status = COREDONESUCCESS or c2_status = COREDONESUCCESS) then
        nextstate <= STATEDONE;
      elsif(c1_status = COREDONEFAILED and c2_status = COREDONEFAILED) then
        nextstate <= STATEDONEFAILED;
      else
        nextstate <= GO;
      end if;
    end process;
    
    LEDG(2 downto 1) <= c1_status;
    
    process(all) begin
      if(state = STATEDONE) then
        c1_run <= '0';
        c2_run <= '0';
        LEDG(0) <= '1';
        LEDR <= (others => '0');
        
      elsif(state = STATEDONEFAILED) then
        c1_run <= '0';
        c2_run <= '0';
        LEDG(0) <= '0';
        LEDR <= (others => '1');
      else
        c1_run <= '1';
        c2_run <= '1';
        LEDG(0) <= '0';
        LEDR <= (others => '0');
      end if;
    end process;
  
    rst <= not KEY(0);
    
end impl; 