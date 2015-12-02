library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

package RC4shufferdecs is
  component RC4shuffler is
    port(key : in std_logic_vector(23 downto 0);
         rst : in std_logic;
         CLOCK_50 : in std_logic;
         run : in std_logic;
         done : out std_logic;
         addr : out std_logic_vector(7 downto 0);
         data : out std_logic_vector(7 downto 0);
         q : in std_logic_vector(7 downto 0);
         wren : out std_logic);
  end component;
end package;

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity RC4shuffler is
  port(key : in std_logic_vector(23 downto 0);
       rst : in std_logic;
       CLOCK_50 : in std_logic;
       run : in std_logic;
       done : out std_logic;
       addr : out std_logic_vector(7 downto 0);
       data : out std_logic_vector(7 downto 0);
       q : in std_logic_vector(7 downto 0);
       wren : out std_logic);
end entity;

architecture impl of RC4shuffler is 
    type state_type is (FINISHED, SH0, SH1, SH2, SH3);
    type array_type is array(2 downto 0) of unsigned(7 downto 0);
    
    signal keyArray : array_type; 
    
    signal iter, nextiter : unsigned(7 downto 0) := (others => '0'); 
    signal state, nextstate : state_type := SH0;
    signal jnext, jcurr, snext, scurr : unsigned(7 downto 0) := (others => '0');

    begin
      
      keyArray(2) <= unsigned(key(7 downto 0)); 
      keyArray(1) <= unsigned(key(15 downto 8));
      keyArray(0) <= unsigned(key(23 downto 16)); 
    
    process(CLOCK_50) begin
      if(rising_edge(CLOCK_50)) then
        if(rst = '0') then
          state <= nextstate;
        else
          state <= SH0;
        end if;
      end if;
    end process; 
    
    process(CLOCK_50) begin
      if(rising_edge(CLOCK_50)) then
        if(rst = '0' and run = '1') then
          jcurr <= jnext;
          scurr <= snext;
          iter <= nextiter;
        else
          jcurr <= (others =>'0');
          scurr <= (others =>'0');
          iter <= (others =>'0');
        end if;
      end if;
    end process; 
    
		process(all) begin 
		  if(state = SH0) then
		    nextiter <= iter; 
		    if(run = '1') then 
		      
		      nextstate <= SH1;
		     else
		      nextstate <= state;
		    end if;
		  elsif(state = SH1) then
		    nextiter <= iter; 
		    nextstate <= SH2;
		  elsif(state = SH2) then
		    nextiter <= iter; 
		    nextstate <= SH3;
		  elsif(state = SH3) then
		    if(iter = to_unsigned(255, iter'LENGTH)) then
		      nextiter <= (others => '0'); 
		      nextstate <= FINISHED;
		    else
		      nextiter <= iter + 1; 
		      nextstate <= SH0; 
		    end if;
		  elsif(state = FINISHED) then
		    nextiter <= (others => '0'); 
		    if(run = '0') then
		      nextstate <= SH0;
		    else
		      nextstate <= state;
		    end if;
		  else
		    nextiter <= iter; 
		    nextstate <= state;
		  end if;
    end process;
    
    process(all) begin 
		  if(state = SH0) then
		    addr <= std_logic_vector(iter);
		    wren <= '0';
		    data <= (others => '-');
		    done <= '0';
		    
		    jnext <= jcurr;
		    snext <= scurr;
		  elsif(state = SH1) then
		  
		    addr <= std_logic_vector(jcurr + unsigned(q) + unsigned(keyArray(to_integer(iter) mod 3)) mod 256);
		    wren <= '0';
		    data <= (others => '-');
		    done <= '0';
		    
		    jnext <= (jcurr + unsigned(q) + unsigned(keyArray(to_integer(iter) mod 3)))mod 256;
		    snext <= unsigned(q);
		  
		  elsif(state = SH2) then
		    addr <= std_logic_vector(iter);
		    wren <= '1';
		    data <= q;
		    done <= '0';
		    
		    jnext <= jcurr;
		    snext <= scurr;
		    
		    
		  elsif(state = SH3) then
		    addr <= std_logic_vector(jcurr); 
		    wren <= '1';
		    data <= std_logic_vector(scurr);
		    done <= '0';
		    
		    jnext <= jcurr;
		    snext <= scurr;
		  
		  elsif(state = FINISHED) then
		    addr <= (others => '-');
		    wren <= '0';
		    data <= (others => '-');
		    done <= '1';
		    
		    jnext <= (others => '0');
		    snext <= (others => '0');
		  else
		    addr <= (others => '-');
		    wren <= '0';
		    data <= (others => '-');
		    done <= '1';
		    
		    jnext <= (others => '0');
		    snext <= (others => '0');
		  end if;
    end process;
    
end impl;