----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date:    18:01:19 06/08/2017 
-- Design Name: 
-- Module Name:    Gather - Behavioral 
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

entity Gather is
PORT (
	Clk: in  STD_LOGIC; -- Reloj del sistema
	reset: in std_logic; -- Reset activo a '0'
	enable_program: in std_logic;
	------------------------------------ senales con el control unit -----------------------------------
	control_signal : in std_logic_vector(1 downto 0); 
	num_updates: in std_logic_vector(bits_num_updates-1 downto 0); 
	Ready_fromcontrol_rx: in std_logic; 
   data_from_control: in std_logic_vector(DATA_WIDTH-1 downto 0);
	en_pipe: in std_logic; 
	gather_start : in std_logic;
	n_partition: out std_logic_vector(bits_num_partitions-1 downto 0); 
	State: out std_logic; 
	Phase: out std_logic_vector(2 downto 0); 
	data_to_control: out std_logic_vector(DATA_WIDTH-1 downto 0); 
	Ready_rx: out std_logic; 
	Ready_tx: out std_logic; 
	Received: out std_logic; 
	valid: out std_logic; 
	vertexset_received: out std_logic; 
	----------------------------------------------------------------------------------------------------
	-------------------------------------- senales con el divisor -------------------------------------
	quotient: in std_logic_vector(DATA_WIDTH-1 downto 0); 
	dividend: out std_logic_vector(DATA_WIDTH-1 downto 0); 
	divisor: out std_logic_vector(DATA_WIDTH-1 downto 0); 
	sclr_gather: out std_logic; 
	----------------------------------------------------------------------------------------------------
	---------------------------------------- senales con la BRAM --------------------------------------
	data_from_chip: in std_logic_vector(DATA_WIDTH-1 downto 0); 
	write_enable: out std_logic; 
	ram_enable: out std_logic;
	data_to_chip: out    std_logic_vector(DATA_WIDTH-1 downto 0); 
	----------------------------------------------------------------------------------------------------
	addr: out std_logic_vector(ADDR_WIDTH-1 downto 0)); 
end Gather;

architecture Behavioral of Gather is
	-- estados
	TYPE estados IS (Idle, Tx, Main, Store_BRAM, Rx, STOP);
	SIGNAL last_current_state, current_state: estados;
	
	TYPE main_estados IS (Main_WAIT, Main_SET_INDEX, Main_ADD_UPDATE);
	SIGNAL main_state: main_estados;
	
	TYPE store_estados IS (Store_WAIT, Store_LOAD_ADDRESS_BRAM, Store_SET_ADDRESS_UPDATE_1, Store_SET_ADDRESS_UPDATE_2, Store_DIVISION, Store_CALCULATION, Store_PAGERANK, Store_RESET);
	SIGNAL store_state: store_estados;
	
	TYPE rx_estados IS (Rx_WAIT, Rx_UPDATE, Rx_VERTEX, Rx_RESET);
	SIGNAL rx_state: rx_estados;
	
	TYPE tx_estados IS (Tx_WAIT, Tx_SET_ADDRESS, Tx_CHECK_INDEX, Tx_SEND, Tx_RESET);
	SIGNAL tx_state: tx_estados;

	signal store, update_received, start_main_machine, finish_main_machine, start_rx_machine, finish_rx_machine, start_tx_machine, finish_tx_machine, start_store_machine, finish_store_machine : std_logic := '0';
	signal array_updates : vector_std(0 to 1);
	signal num_updates_rx : std_logic_vector(bits_num_updates-1 downto 0);
	signal num_partitions_processed : integer range 0 to NUM_PARTITIONS;
	signal index_vertex_rx, index_vertex_tx : integer range 0 to (3*MAX_PARTITION_SIZE_VERTEX):= 0;
	signal index_store, counter_edge_src : integer range 0 to MAX_PARTITION_SIZE_VERTEX;
	signal all_updates, all_dst : vector_std(0 to (MAX_PARTITION_SIZE_VERTEX-1)) := (others => std_logic_vector(to_signed(0,DATA_WIDTH))); 
	signal addr_PR : std_logic_vector(ADDR_WIDTH-1 downto 0);
	signal Q : integer range 0 to 1 := 0;
	signal op1, op3 : std_logic_vector(DATA_WIDTH-1 downto 0) := (others => '0'); 
	signal op2 : unsigned(2*DATA_WIDTH-1 downto 0) := (others => '0');
	signal next_src, tx_gather, actual_state_Store, actual_state_Idle, actual_state_Main : std_logic;
	signal index_src : integer range 0 to MAX_PARTITION_SIZE_VERTEX-1;
	signal index_bram : integer range 0 to (3*MAX_PARTITION_SIZE_VERTEX+1);
	signal index_i : integer range 0 to MAX_PARTITION_SIZE_VERTEX;
	
	constant initial_address : std_logic_vector(ADDR_WIDTH-1 downto 0) := (others => '1'); 
	constant null_signal : std_logic_vector(DATA_WIDTH-1 downto 0) := (others => 'Z');
	
begin

process(clk)
	variable i : integer := 0;

	begin
	
			
		if clk'event and clk='1' then
			if (reset = '0') then
				current_state <= Idle;
				State <= 'Z';
				index_store <= 0;
				Ready_rx <= 'Z';
				Ready_tx <= 'Z';
				n_partition <= (others => 'Z');
				start_main_machine <= '0';
				start_rx_machine <= '0';
				start_tx_machine <= '0';
				start_store_machine <= '0';
				num_updates_rx <= (others => '0');
				num_partitions_processed <= 0;
				actual_state_Store <= '0';
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
								Phase <= "ZZZ"; 
								State <= '0';
								n_partition <= (others => 'Z');
								Ready_rx <= 'Z';
								Ready_tx <= 'Z';
								num_updates_rx <= (others => '0');
								num_partitions_processed <= 0;
								actual_state_Idle <= '1';
								if (gather_start = '1') then	
									current_state <= Main;
									n_partition <= (others => '0');
									store <= '1';	
									actual_state_Main <= '1';
									actual_state_Idle <= '0';
								end if;		
								
								
						WHEN Main =>

								Ready_rx <= '0'; 
								Phase <= "101";
								Ready_tx <= '0'; 
								actual_state_Main <= '1';
								if ((store = '1') and (num_partitions_processed < NUM_PARTITIONS)) then 
									current_state <= Rx;
									actual_state_Main <= '0';
								else
									if ((num_updates_rx < num_updates) and (num_partitions_processed < NUM_PARTITIONS)) then 
										if (update_received = '0') then 
											current_state <= Rx;
											actual_state_Main <= '0';
										elsif (update_received = '1') then 
											start_main_machine <= '1';
											if (finish_main_machine = '1') then
												start_main_machine <= '0';
												num_updates_rx <= std_logic_vector((unsigned(num_updates_rx)+to_unsigned(1,bits_num_updates)));
											end if;
										end if;
									elsif (num_partitions_processed < NUM_PARTITIONS) then 
										current_state <= Store_BRAM;
										actual_state_Store <= '1';
										actual_state_Main <= '0';
										Tx_Gather <= '1';
									else
										current_state <= Idle;
										actual_state_Idle <= '1';
										actual_state_Main <= '0';
										State <= '1';
									end if;
								end if;
																
								
						WHEN Store_BRAM => 
								Phase <= "101";
								actual_state_Store <= '1';
								if (index_store < MAX_PARTITION_SIZE_VERTEX) then
										start_store_machine <= '1';
										if (finish_store_machine = '1') then
											start_store_machine <= '0';
											index_store <= index_store + 1;
										end if;
								else
									if ((op1=std_logic_vector(to_signed(0,DATA_WIDTH))) and (op2=to_unsigned(0,2*DATA_WIDTH)) and (op3=std_logic_vector(to_unsigned(0,DATA_WIDTH)))) then 
										index_store <= 0;
										actual_state_Store <= '0';
										current_state <= Tx;
									end if;
								end if;
								
								
						WHEN Rx =>		
								n_partition <= std_logic_vector(to_unsigned(num_partitions_processed,bits_num_partitions)); 
								if (store = '1') then
									num_updates_rx <= (others => '0');
									Phase <= "000";
								else
									Phase <= "011";
								end if;	
								Ready_rx <= '1'; 
								start_rx_machine <= '1';
								if (finish_rx_machine = '1') then
									current_state <= Main;
									actual_state_Main <= '1';
									start_rx_machine <= '0';
									store <= '0';
								end if;
												
												
						WHEN Tx =>
								Phase <= "100";
								Ready_tx <= '1'; 
								start_tx_machine <= '1';
								if (finish_tx_machine = '1') then
									start_tx_machine <= '0';
									Tx_Gather <= '0';
									store <= '1';
									actual_state_Main <= '1';
									num_partitions_processed <= num_partitions_processed+1;
									current_state <= Main;
								end if;
						WHEN STOP => 
							current_state <= last_current_state;
					end case;
				end if;
			end if;
		end if;
end process;

ACCUMULATE_UPDATES: process(clk)
begin
if clk'event and clk='1' then
	if (reset = '0') then
		finish_main_machine <= '0';
		next_src <= '0';
		index_i <= 0;
		index_src <= 0;
		for i in 0 to (MAX_PARTITION_SIZE_VERTEX-1) loop
			all_dst(i) <= std_logic_vector(to_signed(-1,DATA_WIDTH));
			all_updates(i) <= std_logic_vector(to_signed(-1,DATA_WIDTH));
		end loop;
		counter_edge_src <= 0;
		main_state <= Main_WAIT;
	else
		finish_main_machine <= '0';
	
		CASE main_state IS			
			WHEN Main_WAIT =>
					if ((next_src = '0') and (start_main_machine = '1')) then
						main_state <= Main_SET_INDEX;
					end if;
			WHEN Main_SET_INDEX =>
					if (index_i < MAX_PARTITION_SIZE_VERTEX) then
						if (all_dst(index_i) = array_updates(0)) then 
							next_src <= '1';
							index_src <= index_i;
							main_state <= Main_ADD_UPDATE;
						else
							index_i <= index_i + 1;
						end if;
					else
						index_src <= counter_edge_src;
						counter_edge_src <= counter_edge_src + 1;
						next_src <= '1';
						main_state <= Main_ADD_UPDATE;
					end if;
			WHEN Main_ADD_UPDATE =>
					if (to_integer(signed(all_updates(index_src))) >= 0) then 
						all_updates(index_src) <= std_logic_vector(unsigned(all_updates(index_src)) + unsigned(array_updates(1))); 
					else
						all_updates(index_src) <= array_updates(1); 
					end if;
					all_dst(index_src) <= array_updates(0);
					finish_main_machine <= '1';
					main_state <= Main_WAIT;
		end case;
		if ((current_state = Main) and (update_received = '0')) then
			next_src <= '0';
			index_i <= 0;
		end if;
		if (finish_tx_machine = '1') then
			index_src <= 0;
			counter_edge_src <= 0;
		end if;
		if (((actual_state_Store = '1') and (index_store >= MAX_PARTITION_SIZE_VERTEX)) or (actual_state_Idle = '1')) then
			for i in 0 to (MAX_PARTITION_SIZE_VERTEX-1) loop
				all_dst(i) <= std_logic_vector(to_signed(-1,DATA_WIDTH));
				all_updates(i) <= std_logic_vector(to_signed(-1,DATA_WIDTH));
			end loop;
		end if;
	end if;
end if;
end process;

STORE_PAGERANKinBRAM: process(clk)
begin
if clk'event and clk='1' then
	if (reset = '0') then
		addr_PR <= (others => '0');
		index_bram <= 0;
		write_enable <= 'Z';
		ram_enable <= 'Z';
		sclr_gather<= '1';
		divisor <= (others => 'Z');
		dividend <= (others => 'Z');
		data_to_chip <= (others => 'Z');
		op1 <= std_logic_vector(to_unsigned(0,DATA_WIDTH));
		op2 <= to_unsigned(0,2*DATA_WIDTH);
		op3 <= std_logic_vector(to_unsigned(0,DATA_WIDTH));
		addr <= (others => 'Z');
		store_state <= Store_WAIT;
	else
		write_enable <= 'Z';
		addr <= (others => 'Z');
		ram_enable <= 'Z';
		data_to_chip <= (others => 'Z');
		finish_store_machine <= '0';
		
		CASE store_state IS
			WHEN Store_WAIT =>
				sclr_gather<= '1';
				index_bram <= 0;
				divisor <= (others => 'Z');
				dividend <= (others => 'Z');
				if (start_store_machine = '1') then
					ram_enable <= '1';
					write_enable <= '0';
					sclr_gather <= '0';
					dividend <= std_logic_vector(to_unsigned(up_dividend,DATA_WIDTH));
					divisor <= std_logic_vector(to_unsigned(PARTITION_SIZE_VERTEX(num_partitions_processed), DATA_WIDTH));
					store_state <= Store_LOAD_ADDRESS_BRAM;
				end if;
			WHEN Store_LOAD_ADDRESS_BRAM =>
				ram_enable <= '1';
				write_enable <= '0';	
				addr <= std_logic_vector(unsigned(initial_address) - to_unsigned(index_bram,ADDR_WIDTH));
				store_state <= Store_SET_ADDRESS_UPDATE_1;
			WHEN Store_SET_ADDRESS_UPDATE_1 => 
				ram_enable <= '1';
				write_enable <= '0';					
				addr <= std_logic_vector(unsigned(initial_address) - to_unsigned(index_bram,ADDR_WIDTH));
				store_state <= Store_SET_ADDRESS_UPDATE_2;
				if (not (index_bram < (3*PARTITION_SIZE_VERTEX(num_partitions_processed)+1))) then
					finish_store_machine <= '1';
					store_state <= Store_RESET;
				end if;
			WHEN Store_SET_ADDRESS_UPDATE_2 => 
				store_state <= Store_SET_ADDRESS_UPDATE_1;
				ram_enable <= '1';
				write_enable <= '0';
				addr <= std_logic_vector(unsigned(initial_address) - to_unsigned(index_bram,ADDR_WIDTH));
				if (all_dst(index_store) = data_from_chip) then 
					addr_PR <= std_logic_vector(unsigned(initial_address) - to_unsigned(index_bram,ADDR_WIDTH)); 
					op2 <= to_unsigned(d,DATA_WIDTH)*unsigned(all_updates(index_store)); 
					if (op1 = std_logic_vector(to_unsigned(0,DATA_WIDTH))) then
						store_state <= Store_DIVISION;
					else 
						store_state <= Store_CALCULATION;
					end if;
				else
					index_bram <= index_bram + 3;
					store_state <= Store_LOAD_ADDRESS_BRAM;
				end if;
			WHEN Store_DIVISION =>
				ram_enable <= '1';
				write_enable <= '0';	
				if (quotient > std_logic_vector(to_unsigned(0,DATA_WIDTH))) then
					op1 <= quotient;
					store_state <= Store_CALCULATION;
				end if;
			WHEN Store_CALCULATION =>
				write_enable <= '0';	
				op3 <= std_logic_vector(unsigned(op1) + op2(2*DATA_WIDTH-1 downto DATA_WIDTH)); 
				store_state <= Store_PAGERANK;
			WHEN Store_PAGERANK =>
				ram_enable <= '1';
				write_enable <= '1';	
				data_to_chip <= op3; 
				addr <= std_logic_vector(unsigned(addr_PR) - to_unsigned(1,ADDR_WIDTH));
				addr_PR <= (others => '0');
				dividend <= (others => '0');
				divisor <= (others => '0');
				finish_store_machine <= '1';
				op2 <= to_unsigned(0,2*DATA_WIDTH);
				op3 <= std_logic_vector(to_unsigned(0,DATA_WIDTH));
				store_state <= Store_RESET;
			WHEN Store_RESET =>
				write_enable <= '0';	
				ram_enable <= '0';
				index_bram <= 0;
				op1 <= std_logic_vector(to_unsigned(0,DATA_WIDTH)); 
				store_state <= Store_WAIT;			
		end case;
	end if;
end if;
end process;

RECEPTION: process(clk)
begin
if clk'event and clk='1' then
	if (reset = '0') then
		finish_rx_machine <= '0';
		array_updates(0) <= (others => 'Z');
		array_updates(1) <= (others => 'Z');
		Q <= 0;
		vertexset_received <= 'Z';
		update_received <= '0';
		index_vertex_rx <= 0;
		rx_state <= Rx_WAIT;
	else
		Received <= 'Z';
		addr <= (others => 'Z');
		ram_enable <= 'Z';
		write_enable <= 'Z';
		data_to_chip <= (others => 'Z');
		finish_rx_machine <= '0';
		vertexset_received <= 'Z';
		
		CASE rx_state IS
			WHEN Rx_WAIT =>
						if ((control_signal="01") and (start_rx_machine = '1')) then	
							rx_state <= Rx_UPDATE;
						elsif ((control_signal = "10") and (start_rx_machine = '1')) then
							rx_state <= Rx_VERTEX;
						end if;
						Q <= 0;
						index_vertex_rx <= 0;
			WHEN Rx_UPDATE => 
						if ((to_integer(unsigned(data_from_control)) >= 0) and (data_from_control /= null_signal)) then
							if (Q = 0) then 
								rx_state <= Rx_UPDATE;
								array_updates(Q) <= data_from_control;
								Q <= Q + 1;
							elsif ((Q = 1) and (array_updates(0) /= null_signal) and (data_from_control > std_logic_vector(to_unsigned(0,DATA_WIDTH)))) then 
								array_updates(Q) <= data_from_control;
								finish_rx_machine <= '1';
								update_received <= '1';
								Received <= '1';
								rx_state <= Rx_RESET;
							end if;
						else
							rx_state <= Rx_UPDATE;
						end if;	
			WHEN Rx_RESET => 
						Received <= '1';
						ram_enable <= '0';
						vertexset_received <= '1';
						write_enable <= '0';	
						rx_state <= Rx_WAIT;
			WHEN Rx_VERTEX =>
						if ((index_vertex_rx < 3*PARTITION_SIZE_VERTEX(num_partitions_processed)) and (store = '1') and (data_from_control /= null_signal)) then	
							ram_enable <= '1';
							vertexset_received <= '0';
							write_enable <= '1';	
							data_to_chip <= data_from_control;
							addr <= std_logic_vector(unsigned(initial_address) - to_unsigned(index_vertex_rx,ADDR_WIDTH));
							index_vertex_rx <= index_vertex_rx + 1;
						elsif (index_vertex_rx = 3*PARTITION_SIZE_VERTEX(num_partitions_processed)) then 
							vertexset_received <= '1';
							finish_rx_machine <= '1';
							rx_state <= Rx_RESET;
						end if;		
		end case;
		if (actual_state_Store = '1') then
			array_updates(0) <= (others => 'Z');
			array_updates(1) <= (others => 'Z');
		end if;
		if ((finish_tx_machine = '1') or (finish_main_machine = '1')) then
			update_received <= '0';
		end if;
		if (actual_state_Main = '1') then
			Received <= '0';
		end if;
		if (store = '1') then
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
		index_vertex_tx <= 0;
		valid <= '0';
		data_to_control <= (others => 'Z');
		tx_state <= Tx_WAIT;
	else
		finish_tx_machine <= '0';
		addr <= (others => 'Z');
		ram_enable <= 'Z';
		data_to_control <= (others => 'Z');
		
		CASE tx_state IS
			WHEN Tx_WAIT =>
						if ((Ready_fromcontrol_rx = '1') and (Tx_Gather = '1') and (start_tx_machine = '1')) then
							ram_enable <= '1';
							addr <= std_logic_vector(unsigned(initial_address) - to_unsigned(index_vertex_tx,ADDR_WIDTH));
							tx_state <= Tx_SET_ADDRESS;
						end if;
						index_vertex_tx <= 0;
			WHEN Tx_SET_ADDRESS =>
						ram_enable <= '1';
						addr <= std_logic_vector(unsigned(initial_address) - to_unsigned(index_vertex_tx,ADDR_WIDTH));
						valid <= '0'; 
						data_to_control <= data_from_chip; 
						tx_state <= Tx_CHECK_INDEX;
			WHEN Tx_CHECK_INDEX =>
						ram_enable <= '1';	
						valid <= '0'; 						
						addr <= std_logic_vector(unsigned(initial_address) - to_unsigned(index_vertex_tx,ADDR_WIDTH));
						tx_state <= Tx_SEND;
						if (not (index_vertex_tx < 3*PARTITION_SIZE_VERTEX(num_partitions_processed))) then
							finish_tx_machine <= '1';
							tx_state <= Tx_RESET;
						end if;
			WHEN Tx_SEND =>
						ram_enable <= '1';
						addr <= std_logic_vector(unsigned(initial_address) - to_unsigned(index_vertex_tx,ADDR_WIDTH));
						index_vertex_tx <= index_vertex_tx + 1;
						valid <= '1'; 
						data_to_control <= data_from_chip; 
						tx_state <= Tx_SET_ADDRESS;
			WHEN Tx_RESET => 
						ram_enable <= '0';
						tx_state <= Tx_WAIT;	
		end case;
	end if;
end if;
end process;

end Behavioral;