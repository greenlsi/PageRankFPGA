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
				found := 0;
			
			WHEN 2 =>
				start_edge_machine := '1';
				found := 0;
			
			WHEN 3 =>
				start_update_machine := '1';
				found := 0;
			
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
						vertices(1) := 87381; 
						vertices(2) := 1;
						vertices(3) := 7;
						vertices(4) := 87381;
						vertices(5) := 2;
						vertices(6) := 8;
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
				app_rd_data_valid <= '1';
				app_rd_data_end <= '1';
			elsif ((app_en = '1') and (app_cmd = "000") and (app_wdf_wren = '1') and (app_wdf_wren = '1')) then
				vertex_set(partition, PARTITION_INIT_VERTEX_ARRAY(partition) - to_integer(unsigned(addr))) := data_fromcontrol;
			else
				data_tocontrol <= (others => 'Z');
			end if;
			
			start_vertex_machine := '0';
			found := 0;
		
		elsif (start_edge_machine = '1') then
		
			CASE partition is
			
				WHEN 0 =>
						edges(0) := 1;
						edges(1) := 0;
						edges(2) := 2; 
						edges(3) := 0; 
						edges(4) := 0;
						edges(5) := 1;
						edges(6) := 5;
						edges(7) := 1;
						edges(8) := 0;
						edges(9) := 2;
						edges(10) := 3;
						edges(11) := 2;
						edges(12) := 5;
						edges(13) := 2;
						edges(14) := 1; 
						edges(15) := 3; 
						edges(16) := 5;
						edges(17) := 3;
						edges(18) := 2; 
						edges(19) := 5;
				
				WHEN 1 =>
						edges(0) := 7;
						edges(1) := 6;
						edges(2) := 8;
						edges(3) := 6;
						edges(4) := 6;
						edges(5) := 7;
						edges(6) := 8;
						edges(7) := 7;
						edges(8) := 7; 
						edges(9) := 8; 
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
				if ((PARTITION_INIT_EDGE_ARRAY(partition) - to_integer(unsigned(addr))) = addr_anterior) then
					counter2(partition) := counter2(partition) + 1;
				else
					counter2(partition) := 1;
				end if;
				if (counter2(partition) < 2) then
					data_tocontrol <= std_logic_vector(to_unsigned(edges(PARTITION_INIT_EDGE_ARRAY(partition) - to_integer(unsigned(addr))),DATA_WIDTH));
					addr_anterior := PARTITION_INIT_EDGE_ARRAY(partition) - to_integer(unsigned(addr));
				else
					data_tocontrol <= (others => 'Z');
				end if;
				app_rd_data_valid <= '1';
				app_rd_data_end <= '1';
			else
				data_tocontrol <= (others => 'Z');
			end if;
			
			start_edge_machine := '0';
			found := 0;
		
		elsif (start_update_machine = '1') then
		
			if ((app_en = '1') and (app_cmd = "000") and (app_wdf_wren = '1') and (app_wdf_wren = '1')) then
				update_set(partition, PARTITION_INIT_UPDATE_ARRAY(partition) - to_integer(unsigned(addr))) := data_fromcontrol;
				app_rd_data_valid <= '0';
				app_rd_data_end <= '0';
			elsif ((app_cmd = "001") and (app_en = '1')) then	
				data_tocontrol <= update_set(partition, PARTITION_INIT_UPDATE_ARRAY(partition) - to_integer(unsigned(addr)));
				app_rd_data_valid <= '1';
				app_rd_data_end <= '1';
			else
				data_tocontrol <= (others => 'Z');
			end if;
			
			start_update_machine := '0';
			found := 0;
			
		else
		
			data_tocontrol <= (others => 'Z');
			
		end if;
		
		
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
		
		reference(0,0) := std_logic_vector(to_unsigned(60006,DATA_WIDTH));
		reference(0,1) := std_logic_vector(to_unsigned(44953,DATA_WIDTH));
		reference(0,2) := std_logic_vector(to_unsigned(77727,DATA_WIDTH));
		reference(0,3) := std_logic_vector(to_unsigned(38558,DATA_WIDTH));
		reference(0,4) := std_logic_vector(to_unsigned(40900,DATA_WIDTH));
		reference(1,0) := std_logic_vector(to_unsigned(87381,DATA_WIDTH));
		reference(1,1) := std_logic_vector(to_unsigned(113442,DATA_WIDTH));
		reference(1,2) := std_logic_vector(to_unsigned(61320,DATA_WIDTH));
		
		for i in 0 to NUM_PARTITIONS-1 loop
			for j in 0 to PARTITION_SIZE_VERTEX(i)-1 loop
				if (vertex_set(i,j*3+1) = empty) then
					couter_reference := couter_reference + 1;
				elsif((unsigned(reference(i,j)) - unsigned(vertex_set(i,j*3+1))) > to_unsigned(14,DATA_WIDTH)) then
					couter_reference := couter_reference + 1;
				end if;
			end loop;
		end loop;
		
		if (couter_reference = 0) then
			valid <= '1';
		else
			valid <= '0';
		end if;
		couter_reference := 0;
	
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
		app_rdy <= '1';
		app_wdf_rdy <= '1';
		

      wait;
   end process;

END;