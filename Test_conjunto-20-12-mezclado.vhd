--------------------------------------------------------------------------------
-- Company: 
-- Engineer:
--
-- Create Date:   11:36:41 05/01/2017
-- Design Name:   
-- Module Name:   C:/Users/martu/Ise_projects/PageRank4/Test_conjunto.vhd
-- Project Name:  PageRank4
-- Target Device:  
-- Tool versions:  
-- Description:   
-- 
-- VHDL Test Bench Created by ISE for module: Conjunto
-- 
-- Dependencies:
-- 
-- Revision:
-- Revision 0.01 - File Created
-- Additional Comments:
--
-- Notes: 
-- This testbench has been automatically generated using types std_logic and
-- std_logic_vector for the ports of the unit under test.  Xilinx recommends
-- that these types always be used for the top-level I/O of a design in order
-- to guarantee that the testbench will bind correctly to the post-implementation 
-- simulation model.
--------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use ieee.numeric_std.all;
use std.textio.all;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx primitives in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

USE work.array_pkg.all;
USE work.program_config.all;

ENTITY Test_conjunto IS
END Test_conjunto;
 
ARCHITECTURE behavior OF Test_conjunto IS 
 
    -- Component Declaration for the Unit Under Test (UUT)
 
    COMPONENT Conjunto
    PORT(
         clk : IN  std_logic;
         reset : IN  std_logic;
			enable_program: IN std_logic;
         app_rdy : IN  std_logic;
         app_rd_data_valid : IN  std_logic;
         app_rd_data_end : IN  std_logic;
         data_tocontrol : IN  std_logic_vector(DATA_WIDTH-1 downto 0);
			app_wdf_rdy : IN std_logic;
         app_en : OUT  std_logic;
			app_wdf_end : OUT  std_logic;
			app_wdf_wren : OUT  std_logic;
         app_cmd : OUT  std_logic_vector(2 downto 0);
         addr : OUT  std_logic_vector(ADDR_WIDTH-1 downto 0);
			finish_program : OUT std_logic;
         data_fromcontrol : OUT  std_logic_vector(DATA_WIDTH-1 downto 0)
        );
    END COMPONENT;
    

   --Inputs
   signal clk : std_logic := '0';
   signal reset : std_logic := '0';
	signal enable_program : std_logic := '1';
   signal app_rdy : std_logic := '0';
	signal app_wdf_rdy : std_logic := '0';
   signal app_rd_data_valid : std_logic := '0';
   signal app_rd_data_end : std_logic := '0';
   signal data_tocontrol : std_logic_vector(DATA_WIDTH-1 downto 0) := (others => '0');

 	--Outputs
   signal app_en : std_logic;
	signal app_wdf_end : std_logic;
	signal app_wdf_wren : std_logic;
   signal app_cmd : std_logic_vector(2 downto 0);
   signal addr : std_logic_vector(ADDR_WIDTH-1 downto 0);
	signal finish_program : std_logic;
   signal data_fromcontrol : std_logic_vector(DATA_WIDTH-1 downto 0);
	
	signal valid : std_logic;

	signal found_s : integer range 0 to 3 := 0;
	signal partition_s : integer range -1 to NUM_PARTITIONS-1 := -1;

   -- Clock period definitions
   constant clk_period : time := 10 ns;
 
BEGIN
 
	-- Instantiate the Unit Under Test (UUT)
   uut: Conjunto PORT MAP (
          clk => clk,
          reset => reset,
			 enable_program => enable_program,
          app_rdy => app_rdy,
          app_rd_data_valid => app_rd_data_valid,
          app_rd_data_end => app_rd_data_end,
          data_tocontrol => data_tocontrol,
			 app_wdf_end => app_wdf_end,
			 app_wdf_wren => app_wdf_wren,
			 app_wdf_rdy => app_wdf_rdy,
          app_en => app_en,
          app_cmd => app_cmd,
          addr => addr,
			 finish_program => finish_program,
          data_fromcontrol => data_fromcontrol
        );

   -- Clock process definitions
   clk_process :process
   begin
		clk <= '0';
		wait for clk_period/2;
		clk <= '1';
		wait for clk_period/2;
   end process;
 
	-- Simulacin de DRAM
   test_process :process
		variable edges : vector(0 to values_per_edge*MAX_PARTITION_SIZE_EDGE-1);
		variable vertices : vector(0 to values_per_vertex*MAX_PARTITION_SIZE_VERTEX-1);
		variable vertex_set : array_std(0 to NUM_PARTITIONS-1, 0 to values_per_vertex*MAX_PARTITION_SIZE_VERTEX-1);
		variable update_set : array_std(0 to NUM_PARTITIONS-1, 0 to values_per_update*MAX_PARTITION_SIZE_UPDATE-1);
		variable addr_anterior : integer range 0 to MAX_PARTITION_SIZE-1:= 0;
		variable counter1, counter2 : vector(0 to NUM_PARTITIONS-1);
		variable found : integer range 0 to 3 := 0;
		variable partition : integer range -1 to NUM_PARTITIONS-1;
		variable start_vertex_machine : std_logic := '0';
		variable start_edge_machine : std_logic := '0';
		variable start_update_machine : std_logic := '0';
		variable reference : array_std(0 to NUM_PARTITIONS-1, 0 to 7);
		variable couter_reference : integer := 0;
		variable empty : std_logic_vector(DATA_WIDTH-1 downto 0) := (others => 'Z');
		variable first_time : std_logic := '1';
		variable delay : integer := 0;
   begin
	
	if ((clk='0') and (first_time = '0')) then
	
		Run(finish_program, enable_program);
		
		---- VERIFICAMOS SI ES UN VERTEX SET => FOUND=1 ----
		if (found = 0) then 
			for i in 0 to NUM_PARTITIONS-1 loop
				if ((i<NUM_PARTITIONS-1) and (found = 0)) then
					if ((to_integer(unsigned(addr))<= PARTITION_INIT_VERTEX_ARRAY(i)) and (to_integer(unsigned(addr)) > PARTITION_INIT_VERTEX_ARRAY(i+1))) then
						found := 1;
						partition := i;
					else
						found := 0;
						partition := -1;
					end if;
				elsif ((i=NUM_PARTITIONS-1) and (found = 0)) then
					if ((to_integer(unsigned(addr))<= PARTITION_INIT_VERTEX_ARRAY(i)) and (to_integer(unsigned(addr)) > PARTITION_INIT_EDGE_ARRAY(0))) then
						found := 1;
						partition := i;
					else
						found := 0;
						partition := -1;
					end if;
				end if;
			end loop;
		end if;
		
		---- VERIFICAMOS SI ES UN EDGE SET => FOUND=2 ----
		if (found = 0) then 
			for i in 0 to NUM_PARTITIONS-1 loop
				if ((i<NUM_PARTITIONS-1) and (found = 0)) then
					if ((to_integer(unsigned(addr))<= PARTITION_INIT_EDGE_ARRAY(i)) and (to_integer(unsigned(addr)) > PARTITION_INIT_EDGE_ARRAY(i+1))) then
						found := 2;
						partition := i;
					else
						found := 0;
						partition := -1;
					end if;
				elsif ((i=NUM_PARTITIONS-1) and (found = 0)) then
					if ((to_integer(unsigned(addr))<= PARTITION_INIT_EDGE_ARRAY(i)) and (to_integer(unsigned(addr)) > PARTITION_INIT_UPDATE_ARRAY(0))) then
						found := 2;
						partition := i;
					else
						found := 0;
						partition := -1;
					end if;
				end if;
			end loop;
		end if;
		
		---- VERIFICAMOS SI ES UN UPDATE SET => FOUND=3 ----
		if (found = 0) then 
			for i in 0 to NUM_PARTITIONS-1 loop
				if ((i<NUM_PARTITIONS-1) and (found = 0)) then
					if ((to_integer(unsigned(addr))<= PARTITION_INIT_UPDATE_ARRAY(i)) and (to_integer(unsigned(addr)) > PARTITION_INIT_UPDATE_ARRAY(i+1))) then
						found := 3;
						partition := i;
					else
						found := 0;
						partition := -1;
					end if;
				elsif ((i=NUM_PARTITIONS-1) and (found = 0)) then
					if ((to_integer(unsigned(addr))<= PARTITION_INIT_UPDATE_ARRAY(i)) and (to_integer(unsigned(addr)) > (PARTITION_INIT_UPDATE_ARRAY(NUM_PARTITIONS-1) - values_per_update*PARTITION_SIZE_UPDATE(NUM_PARTITIONS-1)))) then
						found := 3;
						partition := i;
					else
						found := 0;
						partition := -1;
					end if;
				end if;
			end loop;
		end if;
					
		CASE found IS
			
			WHEN 1 =>
				start_vertex_machine := '1';
			
			WHEN 2 =>
				start_edge_machine := '1';
			
			WHEN 3 =>
				start_update_machine := '1';
			
			WHEN others =>
				start_vertex_machine := '0';
				start_edge_machine := '0';
				start_update_machine := '0';
				found := 0;
			
		end case;
		
		if (start_vertex_machine = '1') then
		
			CASE partition is
			
				WHEN 0 =>
						vertices(0) := 0;
						vertices(1) := 13107; 
						vertices(2) := 4;
						vertices(3) := 1;
						vertices(4) := 13107;
						vertices(5) := 4;
						vertices(6) := 2;
						vertices(7) := 13107;
						vertices(8) := 1;
						vertices(9) := 3;
						vertices(10) := 13107;
						vertices(11) := 4;
						vertices(12) := 4;
						vertices(13) := 13107;
						vertices(14) := 1;
						vertices(15) := 5;
						vertices(16) := 13107;
						vertices(17) := 4;
						vertices(18) := 6;
						vertices(19) := 13107;
						vertices(20) := 2;
						vertices(21) := 7;
						vertices(22) := 13107;
						vertices(23) := 3;
						vertices(24) := 8;
						vertices(25) := 13107;
						vertices(26) := 2;
						vertices(27) := 9;
						vertices(28) := 13107;
						vertices(29) := 2;
						vertices(30) := 10;
						vertices(31) := 13107;
						vertices(32) := 1;
						vertices(33) := 11;
						vertices(34) := 13107;
						vertices(35) := 1;
						vertices(36) := 12;
						vertices(37) := 13107;
						vertices(38) := 0;
						vertices(39) := 13;
						vertices(40) := 13107;
						vertices(41) := 2;
						vertices(42) := 14;
						vertices(43) := 13107;
						vertices(44) := 1;
						vertices(45) := 15;
						vertices(46) := 13107;
						vertices(47) := 2;
						vertices(48) := 16;
						vertices(49) := 13107;
						vertices(50) := 0;
						vertices(51) := 17;
						vertices(52) := 13107;
						vertices(53) := 2;
						vertices(54) := 18;
						vertices(55) := 13107;
						vertices(56) := 2;
						vertices(57) := 19;
						vertices(58) := 13107;
						vertices(59) := 2;
				
				WHEN 1 =>
						vertices(0) := 20;
						vertices(1) := 21845; 
						vertices(2) := 3;
						vertices(3) := 21;
						vertices(4) := 21845;
						vertices(5) := 2;
						vertices(6) := 22;
						vertices(7) := 21845;
						vertices(8) := 1;
						vertices(9) := 23;
						vertices(10) := 21845;
						vertices(11) := 2;
						vertices(12) := 24;
						vertices(13) := 21845;
						vertices(14) := 2;
						vertices(15) := 25;
						vertices(16) := 21845;
						vertices(17) := 2;
						vertices(18) := 26;
						vertices(19) := 21845;
						vertices(20) := 2;
						vertices(21) := 27;
						vertices(22) := 21845;
						vertices(23) := 2;
						vertices(24) := 28;
						vertices(25) := 21845;
						vertices(26) := 2;
						vertices(27) := 29;
						vertices(28) := 21845;
						vertices(29) := 2;
						vertices(30) := 30;
						vertices(31) := 21845;
						vertices(32) := 3;
						vertices(33) := 31;
						vertices(34) := 21845;
						vertices(35) := 1;
						vertices(36) := 0;
						vertices(37) := 0;
						vertices(38) := 0;
						vertices(39) := 0;
						vertices(40) := 0;
						vertices(41) := 0;
						vertices(42) := 0;
						vertices(43) := 0;
						vertices(44) := 0;
						vertices(45) := 0;
						vertices(46) := 0;
						vertices(47) := 0;
						vertices(48) := 0;
						vertices(49) := 0;
						vertices(50) := 0;
						vertices(51) := 0;
						vertices(52) := 0;
						vertices(53) := 0;
						vertices(54) := 0;
						vertices(55) := 0;
						vertices(56) := 0;
						vertices(57) := 0;
						vertices(58) := 0;
						vertices(59) := 0;
						
				WHEN others =>
						vertices(0) := -1;
						vertices(1) := -1;
						vertices(2) := -1;
						vertices(3) := -1;
						vertices(4) := -1;
						vertices(5) := -1;
						vertices(6) := -1;
						vertices(7) := -1;
						vertices(8) := -1;
						vertices(9) := -1;
						vertices(10) := -1;
						vertices(11) := -1;
						vertices(12) := -1;
						vertices(13) := -1;
						vertices(14) := -1;
						vertices(14) := -1;
						vertices(15) := -1;
						vertices(16) := -1;
						vertices(17) := -1;
						vertices(18) := -1;
						vertices(19) := -1;
						vertices(20) := -1;
						vertices(21) := -1;
						vertices(22) := -1;
						vertices(23) := -1;
						vertices(24) := -1;
						vertices(25) := -1;
						vertices(26) := -1;
						vertices(27) := -1;
						vertices(28) := -1;
						vertices(29) := -1;
						vertices(30) := -1;
						vertices(31) := -1;
						vertices(32) := -1;
						vertices(33) := -1;
						vertices(34) := -1;
						vertices(35) := -1;
						vertices(36) := -1;
						vertices(37) := -1;
						vertices(38) := -1;
						vertices(39) := -1;
						vertices(40) := -1;
						vertices(41) := -1;
						vertices(42) := -1;
						vertices(43) := -1;
						vertices(44) := -1;
						vertices(45) := -1;
						vertices(46) := -1;
						vertices(47) := -1;
						vertices(48) := -1;
						vertices(49) := -1;
						vertices(50) := -1;
						vertices(51) := -1;
						vertices(52) := -1;
						vertices(53) := -1;
						vertices(54) := -1;
						vertices(55) := -1;
						vertices(56) := -1;
						vertices(57) := -1;
						vertices(58) := -1;
						vertices(59) := -1;
				
			end case;
	
			if ((app_cmd = "001") and (app_en = '1')) then
				if ((PARTITION_INIT_VERTEX_ARRAY(partition) - to_integer(unsigned(addr))) = addr_anterior) then
					counter1(partition) := counter1(partition) + 1;
				else
					counter1(partition) := 1;
				end if;
				if (counter1(partition) < 2) then
					if (vertex_set(partition, 0) = "ZZZZZZZZZZZZZZZZZZ") then
						data_tocontrol <= std_logic_vector(to_unsigned(vertices(PARTITION_INIT_VERTEX_ARRAY(partition) - to_integer(unsigned(addr))),DATA_WIDTH));
					else
						data_tocontrol <= vertex_set(partition, PARTITION_INIT_VERTEX_ARRAY(partition) - to_integer(unsigned(addr)));
					end if;
					addr_anterior := PARTITION_INIT_VERTEX_ARRAY(partition) - to_integer(unsigned(addr));
				else
					data_tocontrol <= (others => 'Z');
				end if;
				if delay = 0 then
					if found_s = found and partition_s = partition then
						app_rd_data_valid <= '1';
						app_rd_data_end <= '1';
					else
						delay := NUM_DELAY;
					end if;
				end if;
			elsif ((app_en = '1') and (app_cmd = "000") and (app_wdf_wren = '1') and (app_wdf_wren = '1')) then
				vertex_set(partition, PARTITION_INIT_VERTEX_ARRAY(partition) - to_integer(unsigned(addr))) := data_fromcontrol;
				if delay = 0 then
					if found_s /= found or partition_s /= partition then
						delay := NUM_DELAY;
					end if;
				end if;
			else
				data_tocontrol <= (others => 'Z');
			end if;
			
		
		elsif (start_edge_machine = '1') then
		
			CASE partition is
			
				WHEN 0 =>
						edges(0) := 1;
						edges(1) := 0;
						edges(2) := 3; 
						edges(3) := 1; 
						edges(4) := 19;
						edges(5) := 2;
						edges(6) := 0;
						edges(7) := 3;
						edges(8) := 15;
						edges(9) := 4;
						edges(10) := 0;
						edges(11) := 5;
						edges(12) := 7;
						edges(13) := 6;
						edges(14) := 5; 
						edges(15) := 8; 
						edges(16) := 11;
						edges(17) := 9;
						edges(18) := 2; 
						edges(19) := 10;
						edges(20) := 1;
						edges(21) := 11;
						edges(22) := 9;
						edges(23) := 12;
						edges(24) := 3;
						edges(25) := 13;
						edges(26) := 5;
						edges(27) := 14;
						edges(28) := 0;
						edges(29) := 15;
						edges(30) := 6;
						edges(31) := 16;
						edges(32) := 7;
						edges(33) := 17;
						edges(34) := 18;
						edges(35) := 17;
						edges(36) := 3;
						edges(37) := 19;
						edges(38) := 17;
						edges(39) := 19;
						edges(40) := 5;
						edges(41) := 20;
						edges(42) := 9;
						edges(43) := 20;
						edges(44) := 17;
						edges(45) := 20;
						edges(46) := 0;
						edges(47) := 21;
						edges(48) := 1;
						edges(49) := 22;
						edges(50) := 13;
						edges(51) := 22;
						edges(52) := 1;
						edges(53) := 23;
						edges(54) := 4;
						edges(55) := 24;
						edges(56) := 8;
						edges(57) := 25;
						edges(58) := 13;
						edges(59) := 25;
						edges(60) := 14;
						edges(61) := 26;
						edges(62) := 15;
						edges(63) := 26;
						edges(64) := 19;
						edges(65) := 27;
						edges(66) := 3;
						edges(67) := 28;
						edges(68) := 5;
						edges(69) := 29;
						edges(70) := 6;
						edges(71) := 29;
						edges(72) := 7;
						edges(73) := 29;
						edges(74) := 8;
						edges(75) := 30;
						edges(76) := 10;
						edges(77) := 31;
						edges(78) := 18;
						edges(79) := 31;
				
				WHEN 1 =>
						edges(0) := 21;
						edges(1) := 0;
						edges(2) := 30;
						edges(3) := 1;
						edges(4) := 20;
						edges(5) := 3;
						edges(6) := 25;
						edges(7) := 6;
						edges(8) := 26; 
						edges(9) := 6; 
						edges(10) := 24;
						edges(11) := 7;
						edges(12) := 20;
						edges(13) := 12;
						edges(14) := 21;
						edges(15) := 13;
						edges(16) := 20;
						edges(17) := 15;
						edges(18) := 27;
						edges(19) := 17;
						edges(20) := 23;
						edges(21) := 18;
						edges(22) := 28;
						edges(23) := 18;
						edges(24) := 29;
						edges(25) := 20;
						edges(26) := 30;
						edges(27) := 21;
						edges(28) := 31;
						edges(29) := 22;
						edges(30) := 22;
						edges(31) := 23;
						edges(32) := 23;
						edges(33) := 24;
						edges(34) := 24;
						edges(35) := 25;
						edges(36) := 25;
						edges(37) := 26;
						edges(38) := 26;
						edges(39) := 27;
						edges(40) := 27;
						edges(41) := 28;
						edges(42) := 28;
						edges(43) := 29;
						edges(44) := 29;
						edges(45) := 30;
						edges(46) := 30;
						edges(47) := 31;
						edges(48) := 0;
						edges(49) := 0;
						edges(50) := 0;
						edges(51) := 0;
						edges(52) := 0;
						edges(53) := 0;
						edges(54) := 0;
						edges(55) := 0;
						edges(56) := 0;
						edges(57) := 0;
						edges(58) := 0;
						edges(59) := 0;
						edges(60) := 0;
						edges(61) := 0;
						edges(62) := 0;
						edges(63) := 0;
						edges(64) := 0;
						edges(65) := 0;
						edges(66) := 0;
						edges(67) := 0;
						edges(68) := 0;
						edges(69) := 0;
						edges(70) := 0;
						edges(71) := 0;
						edges(72) := 0;
						edges(73) := 0;
						edges(74) := 0;
						edges(75) := 0;
						edges(76) := 0;
						edges(77) := 0;
						edges(78) := 0;
						edges(79) := 0;
						
				WHEN others =>
						edges(0) := -1;
						edges(1) := -1;
						edges(2) := -1;
						edges(3) := -1;
						edges(4) := -1;
						edges(5) := -1;
						edges(6) := -1;
						edges(7) := -1;
						edges(8) := -1; 
						edges(9) := -1; 
						edges(10) := -1;
						edges(11) := -1;
						edges(12) := -1;
						edges(13) := -1;
						edges(14) := -1;
						edges(15) := -1;
						edges(16) := -1;
						edges(17) := -1;
						edges(18) := -1;
						edges(19) := -1;
						edges(20) := -1;
						edges(21) := -1;
						edges(22) := -1;
						edges(23) := -1;
						edges(24) := -1;
						edges(25) := -1;
						edges(26) := -1;
						edges(27) := -1;
						edges(28) := -1;
						edges(29) := -1;
						edges(30) := -1;
						edges(31) := -1;
						edges(32) := -1;
						edges(33) := -1;
						edges(34) := -1;
						edges(35) := -1;
						edges(36) := -1;
						edges(37) := -1;
						edges(38) := -1;
						edges(39) := -1;
						edges(40) := -1;
						edges(41) := -1;
						edges(42) := -1;
						edges(43) := -1;
						edges(44) := -1;
						edges(45) := -1;
						edges(46) := -1;
						edges(47) := -1;
						edges(48) := -1;
						edges(49) := -1;
						edges(50) := -1;
						edges(51) := -1;
						edges(52) := -1;
						edges(53) := -1;
						edges(54) := -1;
						edges(55) := -1;
						edges(56) := -1;
						edges(57) := -1;
						edges(58) := -1;
						edges(59) := -1;
						edges(60) := -1;
						edges(61) := -1;
						edges(62) := -1;
						edges(63) := -1;
						edges(64) := -1;
						edges(65) := -1;
						edges(66) := -1;
						edges(67) := -1;
						edges(68) := -1;
						edges(69) := -1;
						edges(70) := -1;
						edges(71) := -1;
						edges(72) := -1;
						edges(73) := -1;
						edges(74) := -1;
						edges(75) := -1;
						edges(76) := -1;
						edges(77) := -1;
						edges(78) := -1;
						edges(79) := -1;
				
			end case;
			
			if ((app_cmd = "001") and (app_en = '1')) then
				if (counter2(partition) < 2) then
					data_tocontrol <= std_logic_vector(to_unsigned(edges(PARTITION_INIT_EDGE_ARRAY(partition) - to_integer(unsigned(addr))),DATA_WIDTH));
					addr_anterior := PARTITION_INIT_EDGE_ARRAY(partition) - to_integer(unsigned(addr));
				else
					data_tocontrol <= (others => 'Z');
				end if;
				if delay = 0 then
					if found_s = found and partition_s = partition then
						if ((PARTITION_INIT_EDGE_ARRAY(partition) - to_integer(unsigned(addr))) = addr_anterior) then
							counter2(partition) := counter2(partition) + 1;
						else
							counter2(partition) := 1;
						end if;
						app_rd_data_valid <= '1';
						app_rd_data_end <= '1';
					else
						delay := NUM_DELAY;
						app_rd_data_valid <= '0';
						app_rd_data_end <= '0';
					end if;
				end if;
			else
				data_tocontrol <= (others => 'Z');
			end if;
			
		
		elsif (start_update_machine = '1') then
		
			if ((app_en = '1') and (app_cmd = "000") and (app_wdf_wren = '1') and (app_wdf_wren = '1')) then
				update_set(partition, PARTITION_INIT_UPDATE_ARRAY(partition) - to_integer(unsigned(addr))) := data_fromcontrol;
				if delay = 0 then
					if found_s /= found or partition_s /= partition then
						delay := NUM_DELAY;
					end if;
				end if;
				app_rd_data_valid <= '0';
				app_rd_data_end <= '0';
			elsif ((app_cmd = "001") and (app_en = '1')) then	
				data_tocontrol <= update_set(partition, PARTITION_INIT_UPDATE_ARRAY(partition) - to_integer(unsigned(addr)));
				if delay = 0 then
					if found_s = found and partition_s = partition then
						app_rd_data_valid <= '1';
						app_rd_data_end <= '1';
					else
						app_rd_data_valid <= '0';
						app_rd_data_end <= '0';
						delay := NUM_DELAY;
					end if;
				end if;
			else
				data_tocontrol <= (others => 'Z');
			end if;
			
			found_s <= found;
			partition_s <= partition;	
			
		else
		
			data_tocontrol <= (others => 'Z');
			
		end if;
		
		app_rdy <= '1';
		app_wdf_rdy <= '1';

		if (delay <= 1) then
		   delay := 0;
			if (found /= 0) then
				found_s <= found;
				partition_s <= partition;
			end if;
		else
			delay := delay - 1;
			app_rdy <= '0';
			app_wdf_rdy <= '0';
		end if;

		start_vertex_machine := '0';
		start_edge_machine := '0';
		start_update_machine := '0';
		found := 0;
		
		if (reset = '0') then
			for i in 0 to NUM_PARTITIONS-1 loop
				for j in 0 to values_per_vertex*MAX_PARTITION_SIZE_VERTEX-1 loop
					vertex_set(i,j) := (others => 'Z');
				end loop;
				for k in 0 to values_per_update*MAX_PARTITION_SIZE_UPDATE-1 loop
					update_set(i,k) := (others => 'Z');
				end loop;
			end loop;
		end if;
		
	end if;
	
	first_time := '0';
	wait for clk_period/2;
	
	end process;
	
   -- Stimulus process
   stim_proc: process
   begin		
      -- hold reset state for 100 ns.
      wait for 100 ns;	
		
      wait for clk_period*10;
		reset <= '1';
		
      -- insert stimulus here 
		

      wait;
   end process;

END;