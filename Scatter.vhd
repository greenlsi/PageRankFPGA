----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date:    18:01:06 06/08/2017 
-- Design Name: 
-- Module Name:    Scatter - Behavioral 
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
use ieee.numeric_std.all;
use std.textio.all;

-- Uncomment the following library declaration if instantiating
-- any Xilinx primitives in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

USE work.array_pkg.all;
USE work.program_config.all;

entity Scatter is
PORT (
	Clk: in  STD_LOGIC; -- Reloj del sistema
	reset: in std_logic; -- Reset activo a '0'
	enable_program: in std_logic;
	------------------------------------ senales con el control unit -----------------------------------
	another_iteration: in std_logic; 
	control_signal : in std_logic_vector(1 downto 0); 
	Ready_fromcontrol_rx: in std_logic; 
   data_from_control: in std_logic_vector(DATA_WIDTH-1 downto 0); 
	en_pipe: in std_logic; 
	n_partition: out std_logic_vector(bits_num_partitions-1 downto 0); 
	Phase: out std_logic_vector(2 downto 0); 
	data_to_control: out std_logic_vector(DATA_WIDTH-1 downto 0); 
	Ready_rx: out std_logic; 
	Ready_tx: out std_logic; 
	Received: out std_logic; 
	vertexset_received: out std_logic; 
	----------------------------------------------------------------------------------------------------
	-------------------------------------- senales con el divisor -------------------------------------
	quotient: in std_logic_vector(DATA_WIDTH-1 downto 0); 
	dividend: out std_logic_vector(DATA_WIDTH-1 downto 0); 
	divisor: out std_logic_vector(DATA_WIDTH-1 downto 0); 
	sclr_scatter: out std_logic; 
	----------------------------------------------------------------------------------------------------
	---------------------------------------- senales con la BRAM --------------------------------------
	data_from_chip: in std_logic_vector(DATA_WIDTH-1 downto 0); 
	write_enable: out std_logic; 
	ram_enable: out std_logic;
	data_to_chip: out std_logic_vector(DATA_WIDTH-1 downto 0); 
	----------------------------------------------------------------------------------------------------
	addr: out std_logic_vector(ADDR_WIDTH-1 downto 0)); 
end Scatter;

architecture Behavioral of Scatter is
	-- estados
	TYPE estados IS (Idle, Tx, Main, Address_vertex, Rx, STOP);
	SIGNAL last_current_state, current_state: estados;
	
	TYPE main_estados IS (Main_WAIT, Main_LOAD_DIVIDER, Main_WAIT_1_CYCLE, Main_RESULT_DIVIDER, Main_RESET);
	SIGNAL main_state: main_estados;
	
	TYPE address_estados IS (Address_WAIT, Address_SET, Address_WAIT_1_CYCLE1, Address_WAIT_1_CYCLE2, Address_CHECK, Address_LI, Address_RESET);
	SIGNAL address_state: address_estados;
	
	TYPE rx_estados IS (Rx_WAIT, Rx_EDGE, Rx_VERTEX, Rx_RESET);
	SIGNAL rx_state: rx_estados;
	
	TYPE tx_estados IS (Tx_WAIT, Tx_INCREASE_INDEX, Tx_SEND);
	SIGNAL tx_state: tx_estados;

	signal store, edge_received, start_main_machine, finish_main_machine, start_address_machine, finish_address_machine, start_rx_machine, finish_rx_machine, start_tx_machine, finish_tx_machine : std_logic := '0';
	signal array_edges : vector_std(0 to 1);
	signal update, Li : std_logic_vector(DATA_WIDTH-1 downto 0) := (others => 'Z');
	signal num_edges_rx : integer range 0 to MAX_PARTITION_SIZE_EDGE;
	signal num_partitions_processed : integer range 0 to NUM_PARTITIONS;
	signal index_address_vertex, index_vertex : integer range 0 to (3*MAX_PARTITION_SIZE_VERTEX):= 0;
	signal addr_update : std_logic_vector(ADDR_WIDTH-1 downto 0);
	signal P : integer range 0 to 1 := 0;
	signal index_update : integer range 0 to 2 := 0;
	signal receiving : std_logic_vector (1 downto 0);
	signal tx_scatter, first_iteration, actual_state_Main, actual_state_Idle:  std_logic; 
	
	constant initial_address : std_logic_vector(ADDR_WIDTH-1 downto 0) := (others => '1'); 
	constant null_signal : std_logic_vector(DATA_WIDTH-1 downto 0) := (others => 'Z'); 

begin

process(clk)

	begin
	
			
		if clk'event and clk='1' then
			if (reset = '0') then
				current_state <= Idle;
				Ready_rx <= 'Z';
				Ready_tx <= 'Z';
				n_partition <= (others => 'Z');
				first_iteration <= '1';
				start_main_machine <= '0';
				start_address_machine <= '0';
				start_rx_machine <= '0';
				start_tx_machine <= '0';
				num_partitions_processed <= 0;
				num_edges_rx <= 0;
				Tx_Scatter <= '0';
				actual_state_Main <= '0';
				actual_state_Idle <= '1';
				store <= '0';
				
			else
			
				if ((en_pipe = '0') and (current_state /= STOP)) then
					last_current_state <= current_state;
					current_state <= STOP;
				elsif (enable_program = '0') then
					current_state <= Idle;
				else
					CASE current_state IS
										
						WHEN Idle => 
									if (first_iteration = '1') then
										first_iteration <= '0';
										Phase <= "111"; 
									else
										Phase <= "ZZZ";
									end if;
									num_edges_rx <= 0;
									Ready_rx <= 'Z';
									Ready_tx <= 'Z';
									actual_state_Idle <= '1';
									n_partition <= (others => 'Z');
									num_partitions_processed <= 0;
									if (another_iteration = '1') then	
										store <= '1'; 
										n_partition <= (others => '0');
										actual_state_Idle <= '0';
										actual_state_Main <= '1';
										current_state <= Main;
									end if;		
				
						WHEN Main =>
									Phase <= "101";
									Ready_tx <= '0'; 
									actual_state_Main <= '1';
									if ((store = '1') and (num_partitions_processed < NUM_PARTITIONS)) then 
										current_state <= Rx;
										actual_state_Main <= '0';
									else								
										if ((num_edges_rx < PARTITION_SIZE_EDGE(num_partitions_processed)) and (num_partitions_processed < NUM_PARTITIONS)) then 
											if (edge_received = '0') then 
												actual_state_Main <= '0';
												current_state <= Rx;
											elsif (edge_received = '1') then 
												start_main_machine <= '1';
												if (finish_main_machine = '1') then 
													current_state <= Tx;
													start_main_machine <= '0';
													Tx_Scatter <= '1'; 
													actual_state_Main <= '0';
												end if;
											end if;
										elsif (num_partitions_processed+1 < NUM_PARTITIONS) then 
											num_partitions_processed <= num_partitions_processed+1;
											store <= '1';
											num_edges_rx <= 0; 
										else 
											num_partitions_processed <= num_partitions_processed+1;
											Phase <= "111";
											actual_state_Main <= '0';
											actual_state_Idle <= '1';
											current_state <= Idle;
										end if;
									end if;
									
						WHEN Address_vertex => 
									Ready_rx <= '0'; 
									Phase <= "101";
									start_address_machine <= '1';
									if (finish_address_machine = '1') then
										start_address_machine <= '0';
										actual_state_Main <= '1';
										current_state <= Main;
									end if;

									
						WHEN Rx =>		
									n_partition <= std_logic_vector(to_unsigned(num_partitions_processed,bits_num_partitions)); 
									if (store = '1') then
										Phase <= "000";
									else
										Phase <= "001";
									end if;	
									Ready_rx <= '1'; 
									start_rx_machine <= '1';
									if (finish_rx_machine = '1') then
										if (receiving = "10") then	
											current_state <= Address_vertex;
										elsif (receiving = "01") then
											actual_state_Main <= '1';
											current_state <= Main;
										end if;
										store <= '0';
										start_rx_machine <= '0';
									end if; 
													
													
						WHEN Tx =>
									Phase <= "010";
									Ready_tx <= '1'; 
									start_tx_machine <= '1';
									if (finish_tx_machine = '1') then
										start_tx_machine <= '0';
										Tx_Scatter <= '0';
										num_edges_rx <= num_edges_rx+1;
										actual_state_Main <= '1';
										current_state <= Main;
									end if;
									
									
						WHEN STOP => 
									current_state <= last_current_state;
					end case;
				end if;
				
			end if;
		end if;
end process;

UPDATE_CALCULATION: process(clk)
begin
if clk'event and clk='1' then
	if (reset = '0') then
		sclr_scatter <= '1';
		dividend <= (others => 'Z');
		divisor <= (others => 'Z');
		finish_main_machine <= '0';
		update <= (others => '0');
		ram_enable <= 'Z';
		addr <= (others => 'Z');
		main_state <= Main_WAIT;
	else
		finish_main_machine <= '0';
		addr <= (others => 'Z');
		ram_enable <= 'Z';
		dividend <= (others => 'Z');
		divisor <= (others => 'Z');
		sclr_scatter <= '1';
		
		CASE main_state IS			
			WHEN Main_WAIT =>
						if (start_main_machine = '1') then
							addr <= std_logic_vector(unsigned(addr_update) - to_unsigned(1, ADDR_WIDTH)); 
							ram_enable <= '1';
							main_state <= Main_WAIT_1_CYCLE;
						end if;		
			WHEN Main_WAIT_1_CYCLE => 
						addr <= std_logic_vector(unsigned(addr_update) - to_unsigned(1, ADDR_WIDTH)); 
						ram_enable <= '1';
						main_state <= Main_LOAD_DIVIDER;
			WHEN Main_LOAD_DIVIDER =>
						addr <= std_logic_vector(unsigned(addr_update) - to_unsigned(1, ADDR_WIDTH)); 
						ram_enable <= '1';
						sclr_scatter <= '0';
						dividend <= data_from_chip; 
						divisor <= Li; 
						main_state <= Main_RESULT_DIVIDER;
			WHEN Main_RESULT_DIVIDER =>
						addr <= std_logic_vector(unsigned(addr_update) - to_unsigned(1, ADDR_WIDTH)); 
						ram_enable <= '1';
						sclr_scatter <= '0';
						dividend <= data_from_chip; 
						divisor <= Li; 
						if (quotient > std_logic_vector(to_unsigned(0,DATA_WIDTH))) then 
							update <= quotient; 
							finish_main_machine <= '1';
							main_state <= Main_RESET;
						end if;
			WHEN Main_RESET =>
						dividend <= (others => '0'); 
						divisor <= (others => '0');
						ram_enable <= '0'; 
						main_state <= Main_WAIT;
		end case;
	end if;
end if;
end process;

FIND_ADDRESS: process(clk)
begin
if clk'event and clk='1' then
	if (reset = '0') then
		finish_address_machine <= '0';
		addr_update <= (others => '0');
		Li <= (others => '0');
		index_address_vertex <= 0;
		address_state <= Address_WAIT;
	else				
		finish_address_machine <= '0';
		addr <= (others => 'Z');
		ram_enable <= 'Z';
								
		CASE address_state IS
			WHEN Address_WAIT =>
						if ((unsigned(addr_update) = to_unsigned(0,ADDR_WIDTH)) and (start_address_machine = '1')) then 
							ram_enable <= '1'; 
							address_state <= Address_SET;
						end if;
						index_address_vertex <= 0;
			WHEN Address_SET =>
						ram_enable <= '1'; 
						if (index_address_vertex < 3*PARTITION_SIZE_VERTEX(num_partitions_processed) + 1) then
							addr <= std_logic_vector(unsigned(initial_address) - to_unsigned(index_address_vertex,ADDR_WIDTH)); 
							address_state <= Address_WAIT_1_CYCLE1;
						else
							address_state <= Address_RESET;
						end if;
			WHEN Address_WAIT_1_CYCLE1 =>
						ram_enable <= '1'; 
						addr <= std_logic_vector(unsigned(initial_address) - to_unsigned(index_address_vertex,ADDR_WIDTH)); 
						address_state <= Address_CHECK;
			WHEN Address_CHECK =>
						ram_enable <= '1'; 
						addr <= std_logic_vector(unsigned(initial_address) - to_unsigned(index_address_vertex,ADDR_WIDTH)); 
						if (array_edges(0) = data_from_chip) then 
							addr_update <= std_logic_vector(unsigned(initial_address) - to_unsigned(index_address_vertex,ADDR_WIDTH)); 
							addr <= std_logic_vector(unsigned(initial_address) - to_unsigned(index_address_vertex,ADDR_WIDTH) - to_unsigned(2,ADDR_WIDTH)); 
							address_state <= Address_WAIT_1_CYCLE2;
						else
							index_address_vertex <= index_address_vertex + 3;
							address_state <= Address_SET;
						end if;
			WHEN Address_WAIT_1_CYCLE2 =>
						ram_enable <= '1'; 
						addr <= std_logic_vector(unsigned(initial_address) - to_unsigned(index_address_vertex,ADDR_WIDTH) - to_unsigned(2,ADDR_WIDTH)); 
						address_state <= Address_LI;
			WHEN Address_LI => 
						ram_enable <= '1'; 
						addr <= std_logic_vector(unsigned(initial_address) - to_unsigned(index_address_vertex,ADDR_WIDTH) - to_unsigned(2,ADDR_WIDTH)); 
						Li <= data_from_chip;
						finish_address_machine <= '1';
						address_state <= Address_RESET;
			WHEN Address_RESET => 
						ram_enable <= '0'; 
						address_state <= Address_WAIT;
		end case;
		if (finish_tx_machine = '1') then
			addr_update <= (others => '0');
		end if;
	end if;
end if;
end process;

RECEPTION: process(clk)
begin
if clk'event and clk='1' then
	if (reset = '0') then
		finish_rx_machine <= '0';
		receiving <= "00";
		index_vertex <= 0;
		P <= 0;
		array_edges(0) <= (others => 'Z');
		array_edges(1) <= (others => 'Z');
		edge_received <= '0';
		Received <= 'Z';
		vertexset_received <= 'Z';
		data_to_chip <= (others => 'Z');
		write_enable <= 'Z';
		rx_state <= Rx_WAIT;
	else				
		finish_rx_machine <= '0';
		addr <= (others => 'Z');
		ram_enable <= 'Z';
		Received <= 'Z';
		vertexset_received <= 'Z';
		data_to_chip <= (others => 'Z');
		write_enable <= 'Z';
		
		CASE rx_state IS
			WHEN Rx_WAIT => 
						if ((control_signal="00") and (start_rx_machine = '1')) then	
							receiving <= "10";
							vertexset_received <= '1';
							rx_state <= Rx_EDGE;
						elsif ((control_signal = "10") and (start_rx_machine = '1')) then	
							receiving <= "01";
							vertexset_received <= '0';
							rx_state <= Rx_VERTEX;
						end if;
						P <= 0;
						index_vertex <= 0;
			WHEN Rx_EDGE => 
						if ((to_integer(unsigned(data_from_control)) >= 0) and (data_from_control /= null_signal)) then
							if (P = 0) then 
								rx_state <= Rx_EDGE;
								array_edges(P) <= data_from_control; 
								P <= P + 1;
							elsif ((P = 1) and (array_edges(0) /= data_from_control)) then 
								array_edges(P) <= data_from_control; 
								finish_rx_machine <= '1';
								edge_received <= '1';
								Received <= '1';
								rx_state <= Rx_RESET;
							end if;
						end if;
			WHEN Rx_RESET => 
						vertexset_received <= '1';
						ram_enable <= '0';
						write_enable <= '0';	
						rx_state <= Rx_WAIT;
			WHEN Rx_VERTEX =>
						if ((index_vertex < 3*PARTITION_SIZE_VERTEX(num_partitions_processed)) and (store = '1') and (to_integer(unsigned(data_from_control)) >= 0) and (data_from_control /= null_signal)) then	
							ram_enable <= '1';
							vertexset_received <= '0';
							write_enable <= '1';	
							data_to_chip <= data_from_control; 
							addr <= std_logic_vector(unsigned(initial_address) - to_unsigned(index_vertex,ADDR_WIDTH));
							index_vertex <= index_vertex + 1;
						elsif (index_vertex = 3*PARTITION_SIZE_VERTEX(num_partitions_processed)) then 
							vertexset_received <= '1';
							finish_rx_machine <= '1';
							rx_state <= Rx_RESET;
						end if;	
		end case;
		if (finish_main_machine = '1') then 
			Received <= '0';
			edge_received <= '0';
		end if;
		if (finish_tx_machine = '1') then
			edge_received <= '0';
		end if;
		if (actual_state_Main = '1') then
			Received <= '0';
		end if;
		if ((store = '1') and (index_vertex /= 3*PARTITION_SIZE_VERTEX(num_partitions_processed))) then
			vertexset_received <= '0';
		elsif (actual_state_Idle = '0') then
			vertexset_received <= '1';
		end if;
	end if;
end if;
end process;

TRANSMISSION: process(clk)
begin
if clk'event and clk='1' then
	if (reset = '0') then
		finish_tx_machine <= '0';
		index_update <= 0;
		data_to_control <= (others => 'Z');
		tx_state <= Tx_WAIT;
	else				
		finish_tx_machine <= '0';
		
		CASE tx_state IS
				WHEN Tx_WAIT =>
							if ((Ready_fromcontrol_rx = '1') and (Tx_Scatter = '1') and (start_tx_machine = '1')) then
								tx_state <= Tx_SEND;
							end if;
							data_to_control <= (others => 'Z');
							index_update <= 0;
				WHEN Tx_INCREASE_INDEX => 
							index_update <= index_update + 1;
							tx_state <= Tx_SEND;
				WHEN Tx_SEND =>
							if (index_update < 2) then
								if (index_update = 1) then
									data_to_control <= update; 
								else
									data_to_control <= array_edges(1); 
								end if;
								tx_state <= Tx_INCREASE_INDEX;
							else 
								finish_tx_machine <= '1';
								tx_state <= Tx_WAIT;
							end if;	
		end case;
		if (actual_state_Idle = '1') then
			data_to_control <= (others => 'Z');
		end if;
	end if;
end if;
end process;
end Behavioral;