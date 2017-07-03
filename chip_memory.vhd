-- single-port RAM with synchronous read
-- modified from XST 8.1i rams_07
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

USE work.program_config.all;

entity chip_memory is
 port(
	clk:in std_logic; 
	we:in std_logic;
	ram_enable: in std_logic;
	addr:in std_logic_vector(ADDR_WIDTH-1 downto 0); 
	din:in std_logic_vector(DATA_WIDTH-1 downto 0); 
	dout:out std_logic_vector(DATA_WIDTH-1 downto 0)); 
end chip_memory;


architecture beh_arch of chip_memory is 

	type ram_type is array (2**ADDR_WIDTH-1 downto 0)of std_logic_vector (DATA_WIDTH-1 downto 0);
	signal ram: ram_type;
	signal addr_reg: std_logic_vector(ADDR_WIDTH-1 downto 0);

begin

process (clk)
begin
   if (clk'event and clk = '1') then
      if (ram_enable = '1') then 
         if (we = '1') then
            ram(to_integer(unsigned(addr))) <= din;
         else
            dout <= ram(to_integer(unsigned(addr)));
         end if;
      end if;
   end if;
end process;

end beh_arch;