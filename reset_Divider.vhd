----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date:    16:46:39 06/09/2017 
-- Design Name: 
-- Module Name:    reset_Divisor - Behavioral 
-- Project Name: 
-- Target Devices: 
-- Tool versions: 
-- Description: 
--
-- Dependencies: 
--
-- Revision: 
-- Revision 0.01 - File Created
-- Additional Comments: 
--
----------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx primitives in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity reset_Divider is
Port(
	clk : in std_logic;
	reset : in std_logic;
	sclr_scatter : in std_logic;
	sclr_gather : in std_logic;
	sclr : out std_logic
);
end reset_Divider;

architecture Behavioral of reset_Divider is

begin

process(clk)
begin

	if clk'event and clk='1' then
		
		if (reset = '0') then
			sclr <= '1';
		else
			sclr <= not(sclr_scatter xor sclr_gather);
		end if;

	end if;
	
end process;
	
end Behavioral;

