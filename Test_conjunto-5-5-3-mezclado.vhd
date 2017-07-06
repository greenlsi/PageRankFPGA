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
 
	-- Simulación de DRAM
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
						vertices(1) := 52429; 
						vertices(2) := 2;
						vertices(3) := 1;
						vertices(4) := 52429;
						vertices(5) := 2;
						vertices(6) := 2;
						vertices(7) := 52429;
						vertices(8) := 2;
						vertices(9) := 3;
						vertices(10) := 52429;
						vertices(11) := 1;
						vertices(12) := 5;
						vertices(13) := 52429;
						vertices(14) := 3;
						
				WHEN 1 =>
						vertices(0) := 6;
						vertices(1) := 52429; 
						vertices(2) := 2;
						vertices(3) := 7;
						vertices(4) := 52429;
						vertices(5) := 2;
						vertices(6) := 8;
						vertices(7) := 52429;
						vertices(8) := 2;
						vertices(9) := 9;
						vertices(10) := 52429;
						vertices(11) := 2;
						vertices(12) := 10;
						vertices(13) := 52429;
						vertices(14) := 2;
				
				WHEN 2 =>
						vertices(0) := 11;
						vertices(1) := 87381; 
						vertices(2) := 2;
						vertices(3) := 12;
						vertices(4) := 87381;
						vertices(5) := 1;
						vertices(6) := 13;
						vertices(7) := 87381;
						vertices(8) := 2;
						vertices(9) := 0;
						vertices(10) := 0;
						vertices(11) := 0;
						vertices(12) := 0;
						vertices(13) := 0;
						vertices(14) := 0;
						
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
						edges(2) := 2; 
						edges(3) := 1; 
						edges(4) := 0;
						edges(5) := 2;
						edges(6) := 5;
						edges(7) := 3;
						edges(8) := 0;
						edges(9) := 5;
						edges(10) := 3;
						edges(11) := 6;
						edges(12) := 5;
						edges(13) := 7;
						edges(14) := 1; 
						edges(15) := 8; 
						edges(16) := 5;
						edges(17) := 12;
						edges(18) := 2; 
						edges(19) := 13;
						
				WHEN 1 =>
						edges(0) := 9;
						edges(1) := 3;
						edges(2) := 10; 
						edges(3) := 5; 
						edges(4) := 8;
						edges(5) := 6;
						edges(6) := 10;
						edges(7) := 7;
						edges(8) := 6;
						edges(9) := 8;
						edges(10) := 9;
						edges(11) := 8;
						edges(12) := 6;
						edges(13) := 10;
						edges(14) := 7; 
						edges(15) := 12; 
						edges(16) := 8;
						edges(17) := 13;
						edges(18) := 7; 
						edges(19) := 13;

				
				WHEN 2 =>
						edges(0) := 11;
						edges(1) := 0;
						edges(2) := 13;
						edges(3) := 2;
						edges(4) := 11;
						edges(5) := 9;
						edges(6) := 12;
						edges(7) := 11;
						edges(8) := 13; 
						edges(9) := 12; 
						edges(10) := 0;
						edges(11) := 0;
						edges(12) := 0;
						edges(13) := 0;
						edges(14) := 0;
						edges(15) := 0;
						edges(16) := 0;
						edges(17) := 0;
						edges(18) := 0;
						edges(19) := 0;
						
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