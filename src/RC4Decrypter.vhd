library ieee; 
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

package RC4decrypterdecs is
  component RC4Decrypter is
    port(msgq : in std_logic_vector(7 downto 0);
       msgAddr : out std_logic_vector(4 downto 0);
       rst : in std_logic;
       CLOCK_50 : in std_logic;
       run : in std_logic;
       status : out std_logic_vector(1 downto 0);
       addr : out std_logic_vector(7 downto 0);
       data : out std_logic_vector(7 downto 0);
       q : in std_logic_vector(7 downto 0);
       wren : out std_logic);
  end component;
end package; 

library ieee; 
use ieee.std_logic_1164.all;
use ieee.numeric_std.all; 

entity RC4Decrypter is
  port(msgq : in std_logic_vector(7 downto 0);
       msgAddr : out std_logic_vector(4 downto 0);
       rst : in std_logic;
       CLOCK_50 : in std_logic;
       run : in std_logic;
       status : out std_logic_vector(1 downto 0);
       addr : out std_logic_vector(7 downto 0);
       data : out std_logic_vector(7 downto 0);
       q : in std_logic_vector(7 downto 0);
       wren : out std_logic);
end entity;

architecture impl of RC4Decrypter is
  
  COMPONENT decryptedRAM is
     PORT (
			address	: IN STD_LOGIC_VECTOR (4 DOWNTO 0);
			clock	: IN STD_LOGIC ;
			data	: IN STD_LOGIC_VECTOR (7 DOWNTO 0);
			wren	: IN STD_LOGIC ;
			q	: OUT STD_LOGIC_VECTOR (7 DOWNTO 0)
	);
	END COMPONENT;
	
	type state_type is (SD0, SD1, SD2, SD3, SD4, FINISHEDFAIL, FINISHEDSUCCESS); 
	
	constant INIT : std_logic_vector(1 downto 0) := "00";
	constant RUNNING : std_logic_vector(1 downto 0) := "01";
  constant DONEFAIL : std_logic_vector(1 downto 0) := "10";
  constant DONESUCCESS : std_logic_vector(1 downto 0) := "11";
  
  signal decryptData : std_logic_vector(7 downto 0);
  signal decryptAddr : std_logic_vector(4 downto 0);
  signal decryptQ : std_logic_vector(7 downto 0);
  signal decryptWren : std_logic := '0';
  
  signal state : state_type := SD0;
  signal nextstate : state_type;
  
  signal nextJ, currJ : unsigned(7 downto 0) := (others => '0');
  signal nextsStored, currsStored : unsigned(7 downto 0) := (others => '0');
  signal nextjStored, currjStored : unsigned(7 downto 0) := (others => '0');
  
  signal iter, nextiter: unsigned(4 downto 0) := (others => '0');
  signal ith, nextith : unsigned(7 downto 0) := to_unsigned(1,8);
  
  begin
    
      
    endRAM : decryptedRAM port map(address => decryptAddr, clock => CLOCK_50, data => decryptData, q => decryptQ, wren => decryptWren);
    
    process(CLOCK_50) begin
      if(rising_edge(CLOCK_50)) then
        if(rst = '0' and run = '1') then
          currJ <= nextJ;
          currsStored <= nextsStored;
          currjStored <= nextjStored;
          iter <= nextiter;
          ith <= nextith;
          state <= nextstate;
        else
          currJ <= (others => '0');
          currsStored <= (others => '0');
          currjStored <= (others => '0');
          iter <= (others => '0');
          ith <= to_unsigned(1,ith'LENGTH);
          state <= SD0;
        end if;
      end if; 
    end process;
    
    process(all) begin
      if(state = SD0) then
        if(run = '1') then
          nextstate <= SD1;
        else
          nextstate <= state;
        end if;
      elsif(state = SD1) then
        nextstate <= SD2;
      elsif(state = SD2) then
        nextstate <= SD3;
      elsif(state = SD3) then
      
        if (((q xor msgq) > 8d"96" and (q xor msgq) < 8d"123") or (q xor msgq) = 8d"32") then
          nextstate <= SD4; 
        else
          nextstate <= FINISHEDFAIL;
        end if;

      elsif(state = SD4) then
        if(iter = to_unsigned(31,iter'LENGTH)) then
          nextstate <= FINISHEDSUCCESS;
        else 
          nextstate <= SD0;
        end if;
      elsif(state = FINISHEDFAIL or state = FINISHEDSUCCESS) then
        if(run = '0') then
          nextstate <= SD0;
        else
          nextstate <= state; 
        end if;
      else
        nextstate <= state;
      end if;
    end process;
    
    process(all) begin
      if(state = SD0) then
        wren <= '0';
        status <= RUNNING;
        addr <= std_logic_vector(ith);
        data <= (others => '-');
        
        decryptWren <= '0';
        decryptAddr <= (others => '-');
        decryptData <= (others => '-');
        
        nextJ <= currJ;
        nextsStored <= currsStored;
        nextjStored <= currjStored;
        nextiter <= iter;
        nextith <= ith;
        
        msgAddr <= (others => '-');
        
      elsif(state = SD1) then
      
        wren <= '0';
        status <= RUNNING;
        addr <= std_logic_vector((currJ + unsigned(q))mod 256);
        data <= (others => '-');
        
        decryptWren <= '0';
        decryptAddr <= (others => '-');
        decryptData <= (others => '-');
        
        nextJ <= (currJ + unsigned(q)) mod 256;
        nextsStored <= unsigned(q);
        nextjStored <= currjStored;
        nextiter <= iter;
        nextith <= ith;

        msgAddr <= (others => '-');
        
      elsif(state = SD2) then
        wren <= '0';
        status <= RUNNING;
        addr <= std_logic_vector((currsStored + unsigned(q)) mod 256);
        data <= (others => '-');
        
        decryptWren <= '0';
        decryptAddr <= (others => '-'); 
        decryptData <= (others => '-');
        
        nextJ <= currJ;
        nextsStored <= currsStored;
        nextjStored <= unsigned(q) mod 256;
        nextiter <= iter;
        nextith <= ith;
        
        msgAddr <= std_logic_vector(iter);
        
      elsif(state = SD3) then
        wren <= '1';
        status <= RUNNING;
        addr <= std_logic_vector(ith);
        data <= std_logic_vector(currjStored);
        
        decryptWren <= '1';
        decryptAddr <= std_logic_vector(iter);
        decryptData <= std_logic_vector(unsigned(q xor msgq) mod 256) ;
        
        nextJ <= currJ;
        nextsStored <= currsStored;
        nextjStored <= currjStored;
        nextiter <= iter;
        nextith <= ith;
        
        msgAddr <= (others => '-');
      
      elsif(state = SD4) then
      
        wren <= '1';
        status <= RUNNING;
        addr <= std_logic_vector(currJ);
        data <= std_logic_vector(currsStored);
        
        decryptWren <= '0';
        decryptAddr <= (others => '-');
        decryptData <= (others => '-');
        
        nextJ <= currJ;
        nextsStored <= currsStored;
        nextjStored <= currjStored;
        nextiter <= iter + 1;
        nextith <= ith + 1;
        
        msgAddr <= (others => '-');
      elsif(state = FINISHEDSUCCESS) then
        wren <= '0';
        status <= DONESUCCESS;
        addr <= (others => '-');
        data <= (others => '-');
        
        decryptWren <= '0';
        decryptAddr <= (others => '-');
        decryptData <= (others => '-');
        
        nextJ <= (others => '0');
        nextsStored <= (others => '0');
        nextjStored <= (others => '0');
        nextiter <= (others => '0');
        nextith <= to_unsigned(1,ith'LENGTH);
        
        msgAddr <= (others => '-');
      
      elsif(state = FINISHEDFAIL) then
        wren <= '0';
        status <= DONEFAIL;
        addr <= (others => '-');
        data <= (others => '-');
        
        decryptWren <= '0';
        decryptAddr <= (others => '-');
        decryptData <= (others => '-');
        
        nextJ <= (others => '0');
        nextsStored <= (others => '0');
        nextjStored <= (others => '0');
        nextiter <= (others => '0');
        nextith <= to_unsigned(1,ith'LENGTH);
        
        msgAddr <= (others => '-');
        
      else
        wren <= '0';
        status <= DONEFAIL;
        addr <= (others => '-');
        data <= (others => '-');
        
        decryptWren <= '0';
        decryptAddr <= (others => '-');
        decryptData <= (others => '-');
        
        nextJ <= (others => '0');
        nextsStored <= (others => '0');
        nextjStored <= (others => '0');
        nextiter <= (others => '0');
        nextith <= to_unsigned(1,ith'LENGTH);
        
        msgAddr <= (others => '-');
        
      end if;
    end process;
      
end impl;