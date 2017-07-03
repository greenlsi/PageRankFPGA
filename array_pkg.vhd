--
--	Package File Template
--
--	Purpose: This package defines supplemental types, subtypes, 
--		 constants, and functions 
--
--   To use any of the example code shown below, uncomment the lines and modify as necessary
--

library IEEE;
use IEEE.STD_LOGIC_1164.all;

USE work.program_config.all;

package array_pkg is
  type vector is array (natural range <>) of integer;
  type vector_std is array (natural range <>) of std_logic_vector(DATA_WIDTH-1 downto 0);
  type array_std is array (natural range <>,natural range <>) of std_logic_vector(DATA_WIDTH-1 downto 0);
end array_pkg;

package body array_pkg is
 
end array_pkg;
