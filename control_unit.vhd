----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date:    13:08:18 04/28/2017 
-- Design Name: 
-- Module Name:    control_unit - Behavioral 
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
LIBRARY ieee;
USE ieee.std_logic_1164.all;
USE ieee.numeric_std.all;
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

entity control_unit is
PORT(
	clk: in std_logic; -- Reloj del sistema
	reset: in std_logic; -- Reset activo a '0'
	enable_program: in std_logic;
	-------------------------------- senales con el processing pipeline --------------------------------
	n_partition: in std_logic_vector(bits_num_partitions-1 downto 0); 
	State: in std_logic; 
	Phase: in std_logic_vector(2 downto 0); 
	data_frompipe: in std_logic_vector(DATA_WIDTH-1 downto 0); 
	Ready_frompipe_rx: in std_logic; 
	Ready_frompipe_tx: in std_logic; 
	Received_pipe: in std_logic; 
	vertexset_received: in std_logic; 
	valid: in std_logic; 
	control_signal: out std_logic_vector(1 downto 0); 
	num_updates: out std_logic_vector(bits_num_updates-1 downto 0); 
	another_iteration: out std_logic; 
	Ready_rx: out std_logic; 
	data_topipe: out std_logic_vector(DATA_WIDTH-1 downto 0); 
	en_pipe: out std_logic; 
	gather_start : out std_logic;
	----------------------------------------------------------------------------------------------------
	---------------------------------------- senales con la DRAM ---------------------------------------
	app_rdy: in std_logic; 
	app_rd_data_valid: in std_logic; 
	app_rd_data_end: in std_logic; 
	data_frommem: in std_logic_vector(DATA_WIDTH-1 downto 0); 
	app_wdf_rdy: in std_logic; 
	app_en: out std_logic;
	app_wdf_end: out std_logic; 
	app_wdf_wren: out std_logic;
	app_cmd: out std_logic_vector(2 downto 0); 
	data_tomem: out std_logic_vector(DATA_WIDTH-1 downto 0);
	----------------------------------------------------------------------------------------------------
	---------------------------------------- senales con la FIFO ---------------------------------------
   data_in1 : in STD_LOGIC_VECTOR(DATA_WIDTH-1 DOWNTO 0);
   full1 : in STD_LOGIC;
   empty1 : in STD_LOGIC;
   data_in2 : in STD_LOGIC_VECTOR(ADDR_WIDTH-1 DOWNTO 0);
   full2 : in STD_LOGIC;
   empty2 : in STD_LOGIC;
	data_out1 : out STD_LOGIC_VECTOR(DATA_WIDTH-1 DOWNTO 0);
   wr_en1 : out STD_LOGIC;
   rd_en1 : out STD_LOGIC;
   data_out2 : out STD_LOGIC_VECTOR(ADDR_WIDTH-1 DOWNTO 0);
   wr_en2 : out STD_LOGIC;
   rd_en2 : out STD_LOGIC;
	srst : out std_logic;
	----------------------------------------------------------------------------------------------------
	finish_program : out std_logic;
	addr: out std_logic_vector(ADDR_WIDTH-1 downto 0)); 
end control_unit;

architecture Behavioral of control_unit is

	TYPE control_estados IS (Control_WAIT, Control_SCATTER, Control_GATHER);
	SIGNAL control_state: control_estados;
	
	TYPE vertexTX_estados IS (VertexTX_WAIT, VertexTX_CHECK_MEM, VertexTX_SET_ADDRESS, VertexTX_SEND);
	SIGNAL vertexTX_state: vertexTX_estados;
	
	TYPE edge_estados IS (Edge_WAIT, Edge_CHECK_MEM, Edge_CHECK_INDEX, Edge_SEND, Edge_CHECK_RECEPTION, Edge_WAIT_1_CYCLE, Edge_RESET);
	SIGNAL edge_state: edge_estados;
	
	TYPE updateTX_estados IS (UpdateTX_WAIT, UpdateTX_CHECK_MEM, UpdateTX_CHECK_INDEX, UpdateTX_SEND, UpdateTX_CHECK_RECEPTION, Update_WAIT_1_CYCLE, UpdateTX_RESET);
	SIGNAL updateTX_state: updateTX_estados;
	
	TYPE updateRX_estados IS (UpdateRX_WAIT, UpdateRX_CHECK_INDEX, UpdateRX_CHECK_FIFO, UpdateRX_STORE_ADDRESS1, UpdateRX_STORE_ADDRESS2, UpdateRX_RESET);
	SIGNAL updateRX_state: updateRX_estados;
	
	TYPE vertexRX_estados IS (VertexRX_WAIT, VertexRX_CHECK_MEM, VertexRX_CHECK_INDEX, VertexRX_SEND, VertexRX_RESET);
	SIGNAL vertexRX_state: vertexRX_estados;
	
	TYPE FIFO_estados IS (FIFO_WAIT, FIFO_CHECK, FIFO_CHECK_MEM, FIFO_READ, FIFO_READ_EXTRA_CYCLE);
	SIGNAL FIFO_state: FIFO_estados;
	
signal index_vertices_rx, index_vertices_tx : integer range 0 to (3*MAX_PARTITION_SIZE_VERTEX);
signal index_edges : integer range 0 to 2*MAX_PARTITION_SIZE_EDGE;
signal index_updates : integer range 0 to 2*MAX_PARTITION_SIZE_UPDATE;
signal index_updates_rx : integer range 0 to 3;
signal counter_iterations : integer range 0 to NUM_ITERATIONS;
signal counter_number_updates_transmitted : integer range 0 to (MAX_PARTITION_SIZE_UPDATE+1);
signal counter_number_edges_transmitted : integer range 0 to (MAX_PARTITION_SIZE_EDGE+1);
signal first_iteration, take, send_fifo, updates_valid : std_logic;
signal array_updates_sent : vector_std(0 to NUM_PARTITIONS-1);
signal index_array : integer range 0 to NUM_PARTITIONS-1;
signal address_scr : std_logic_vector(ADDR_WIDTH-1 downto 0);
signal reg_partition : integer range 0 to NUM_PARTITIONS;
signal start_vertexTX_machine, finish_vertexTX_machine, start_edge_machine, finish_edge_machine, start_updateTX_machine, finish_updateTX_machine, start_updateRX_machine, finish_updateRX_machine, start_vertexRX_machine, finish_vertexRX_machine, start_FIFO_machine, finish_FIFO_machine : std_logic;

constant StateRESET : std_logic := '1';
constant PhaseIDLE : std_logic_vector(2 downto 0) := "111"; 
constant PhaseRXvertex : std_logic_vector(2 downto 0) := "000";
constant PhaseRXedges : std_logic_vector(2 downto 0) := "001"; 
constant PhaseRXupdates : std_logic_vector(2 downto 0) := "011";
constant PhaseTXupdates : std_logic_vector(2 downto 0) := "010";
constant PhaseTXvertex : std_logic_vector(2 downto 0) := "100";

constant null_partition : std_logic_vector(bits_num_partitions-1 downto 0) := (others => 'Z');
constant null_signal : std_logic_vector(DATA_WIDTH-1 downto 0) := (others => 'Z');

begin

MAIN_PROGRAM: process (clk)

variable i : integer := 0;

begin

if (clk'event AND clk='1') then

	if (reset = '0') then
		srst <= '1';
		send_fifo <= '0';
		updates_valid <= '0';
		counter_iterations <= 0;
		first_iteration <= '1';
		start_vertexTX_machine <= '0';
		start_vertexRX_machine <= '0';
		start_edge_machine <= '0';
		start_updateTX_machine <= '0';
		start_updateRX_machine <= '0';
		start_FIFO_machine <= '0';
		reg_partition <= 0;
		finish_program <= '0';
		another_iteration <= '0';
		gather_start <= '0';
		control_state <= Control_WAIT;
	else
		
		num_updates <= std_logic_vector(resize(unsigned(array_updates_sent(reg_partition)(DATA_WIDTH-1 downto 1)), bits_num_updates));
		srst <= '0';
		
		if (n_partition /= null_partition) then
			reg_partition <= to_integer(unsigned(n_partition));
		end if;
		
		if (((full1 = '1') and (full2 = '1') and (empty1 = '0') and (empty2 = '0')) or (send_fifo = '1')) then
			send_fifo <= '1';
			en_pipe <= '0';
			start_FIFO_machine <= '1';
			if (finish_FIFO_machine = '1') then
				start_FIFO_machine <= '0';
				send_fifo <= '0';
				updates_valid <= '1';
			end if;
			finish_program <= '0';
		else
			en_pipe <= '1';
			finish_program <= '0';
		end if;
				
		if (enable_program = '0') then
			finish_program <= '1';
			control_state <= Control_WAIT;			
		else
			CASE control_state IS
				WHEN Control_WAIT =>
							if (State = StateRESET) then 
								counter_iterations <= counter_iterations + 1; 
								updates_valid <= '0';
								another_iteration <= '1'; 
								control_state <= Control_SCATTER;
							elsif ((Phase = PhaseIDLE) and (first_iteration = '1')) then 
								another_iteration <= '1'; 
								first_iteration <= '0';
								control_state <= Control_SCATTER;
							else
								control_state <= Control_WAIT;
							end if;
							if ((counter_iterations + 1) >= NUM_ITERATIONS) then 
								counter_iterations <= NUM_ITERATIONS;
								another_iteration <= '0'; 
								finish_program <= '1';
								control_state <= Control_WAIT;
							end if;
				WHEN Control_SCATTER =>
							if (Ready_frompipe_rx = '1') then 
								Ready_rx <= '0';
								if ((vertexset_received = '0') and (Phase = PhaseRXvertex) and (Ready_frompipe_rx = '1')) then
									another_iteration <= '0';
									start_vertexTX_machine <= '1';
									if (finish_vertexTX_machine = '1') then
										start_vertexTX_machine <= '0';
									end if;
								elsif (Phase = PhaseRXedges) then 
									start_edge_machine <= '1';
									if (finish_edge_machine = '1') then
										start_edge_machine <= '0';
									end if;
								else 
									start_vertexTX_machine <= '0';
									start_edge_machine <= '0';
								end if;
							elsif (Ready_frompipe_tx = '1') then 
								Ready_rx <= '1'; 
								if ((Phase = PhaseTXupdates) and (Ready_frompipe_tx = '1')) then 
									start_updateRX_machine <= '1';
									if (finish_updateRX_machine = '1') then
										start_updateRX_machine <= '0';
									end if;
								end if;
							else
								start_updateRX_machine <= '0';
							end if;
							if ((Phase = PhaseIDLE) and (first_iteration = '0')) then
								control_state <= Control_GATHER;
								gather_start <= '1'; 
							else
								control_state <= Control_SCATTER;
							end if;
				WHEN Control_GATHER =>
							control_state <= Control_GATHER;
							if (Ready_frompipe_rx = '1') then 
								Ready_rx <= '0';
								gather_start <= '0'; 
								if ((vertexset_received = '0') and (Phase = PhaseRXvertex) and (Ready_frompipe_rx = '1')) then
									another_iteration <= '0';
									start_vertexTX_machine <= '1';
									if (finish_vertexTX_machine = '1') then
										start_vertexTX_machine <= '0';
									end if;
								elsif (Phase = PhaseRXupdates) then 	
									if (updates_valid = '0') then
										send_fifo <= '1'; 
									else
										start_updateTX_machine <= '1';
										if (finish_updateTX_machine = '1') then
											start_updateTX_machine <= '0';
										end if;
									end if;
								else 
									start_vertexTX_machine <= '0';
									start_updateTX_machine <= '0';
								end if;
							elsif (Ready_frompipe_tx = '1') then 
								Ready_rx <= '1'; 
								if (Phase = PhaseTXvertex) then 
									start_vertexRX_machine <= '1';
									if (finish_vertexRX_machine = '1') then
										start_vertexRX_machine <= '0';
										if (reg_partition = (NUM_PARTITIONS-1)) then
											control_state <= Control_WAIT;
										end if;
									end if;
								end if;
							else
								start_vertexRX_machine <= '0';
							end if;
			END CASE;
		end if;
	end if;
end if;
end process;


TRANSMIT_VERTEX: process (clk)
begin
if (clk'event AND clk='1') then
	if (reset = '0') then
		control_signal <= "ZZ";
		addr <= (others => 'Z');
		app_cmd <= "ZZZ";
		app_en <= 'Z';
		data_topipe <= (others => 'Z');
		index_vertices_tx <= 0;
		finish_vertexTX_machine <= '0';
		vertexTX_state <= VertexTX_WAIT;
	else 
		CASE vertexTX_state IS
			WHEN VertexTX_WAIT =>
						if ((start_vertexTX_machine = '1') and (finish_vertexTX_machine = '0')) then
							vertexTX_state <= VertexTX_CHECK_MEM;
						else
							control_signal <= "ZZ"; 
							addr <= (others => 'Z'); 
							index_vertices_tx <= 0;
							data_topipe <= (others => 'Z'); 
							app_cmd <= "ZZZ"; 
							app_en <= 'Z';
							finish_vertexTX_machine <= '0';
						end if;
			WHEN VertexTX_CHECK_MEM =>
						if (app_rdy = '1') then 
							app_en <= '1';
							app_cmd <= "001"; 
							control_signal <= "10";
							vertexTX_state <= VertexTX_SET_ADDRESS;
						end if;
			WHEN VertexTX_SET_ADDRESS => 
						addr <= std_logic_vector(to_unsigned(PARTITION_INIT_VERTEX_ARRAY(reg_partition),ADDR_WIDTH) - to_unsigned(index_vertices_tx,ADDR_WIDTH));
						data_topipe <= (others => 'Z');
						if (index_vertices_tx = 3*PARTITION_SIZE_VERTEX(reg_partition)) then
							addr <= (others => 'Z');
							app_en <= '0';
							finish_vertexTX_machine <= '1';
							vertexTX_state <= VertexTX_WAIT;	
						else
							vertexTX_state <= VertexTX_SEND;
						end if;
			WHEN VertexTX_SEND =>
						if ((app_rd_data_valid = '1') and (app_rd_data_end = '1') and (data_frommem /= null_signal)) then
							data_topipe <= data_frommem; 
							index_vertices_tx <= index_vertices_tx + 1;
							vertexTX_state <= VertexTX_SET_ADDRESS;
						end if;
		end case;
	end if;		
end if;	
end process;


TRANSMIT_EDGES: process (clk)
begin
if (clk'event AND clk='1') then
	if (reset = '0') then
		counter_number_edges_transmitted <= 1;
		index_edges <= 0;
		finish_edge_machine <= '0';
		edge_state <= Edge_WAIT;
	else 
		CASE edge_state IS
			WHEN Edge_WAIT =>
						if (start_edge_machine = '1') then
							edge_state <= Edge_CHECK_MEM;
						else
							control_signal <= "ZZ";
							addr <= (others => 'Z');
							app_en <= 'Z';
							data_topipe <= (others => 'Z');
							app_cmd <= "ZZZ";
							finish_edge_machine <= '0';
						end if;
			WHEN Edge_CHECK_MEM =>
						if (app_rdy = '1') then 
							app_cmd <= "001"; 
							control_signal <= "00";
							edge_state <= Edge_CHECK_INDEX;
						end if;
			WHEN Edge_CHECK_INDEX =>
						addr <= std_logic_vector(to_unsigned(PARTITION_INIT_EDGE_ARRAY(reg_partition),ADDR_WIDTH) - to_unsigned(index_edges,ADDR_WIDTH));
						if (index_edges < 2*counter_number_edges_transmitted) then 
							edge_state <= Edge_SEND;
							app_en <= '1';
						elsif (counter_number_edges_transmitted< (PARTITION_SIZE_EDGE(reg_partition)+1)) then 
							edge_state <= Edge_CHECK_RECEPTION;
						else
							edge_state <= Edge_RESET;
						end if;
			WHEN Edge_SEND =>
						if ((app_rd_data_valid = '1') and (app_rd_data_end = '1') and (data_frommem /= null_signal)) then
							data_topipe <= data_frommem; 
							index_edges <= index_edges + 1;
							app_en <= '0';
							edge_state <= Edge_CHECK_INDEX;
						else
							data_topipe <= (others => 'Z');
						end if;
			WHEN Edge_CHECK_RECEPTION =>
						if (Received_pipe = '1') then 
							counter_number_edges_transmitted <= counter_number_edges_transmitted + 1;
							finish_edge_machine <= '1';
							if (counter_number_edges_transmitted >= PARTITION_SIZE_EDGE(reg_partition)) then 
								edge_state <= Edge_RESET;
							else
								edge_state <= Edge_WAIT_1_CYCLE;
							end if;
						end if;
			WHEN Edge_WAIT_1_CYCLE =>
						edge_state <= Edge_WAIT;
			WHEN Edge_RESET =>
						index_edges <= 0; 
						counter_number_edges_transmitted <= 1;
						finish_edge_machine <= '1';
						edge_state <= Edge_WAIT;
		end case;
	end if;
end if;
end process;


TRANSMIT_UPDATES: process (clk)
begin
if (clk'event AND clk='1') then
	if (reset = '0') then
		counter_number_updates_transmitted <= 1;
		index_updates <= 0;
		updateTX_state <= UpdateTX_WAIT;
	else 
		CASE updateTX_state IS
			WHEN UpdateTX_WAIT =>
						if ((start_updateTX_machine = '1') and (updates_valid = '1')) then
							updateTX_state <= UpdateTX_CHECK_MEM;
						else
							control_signal <= "ZZ";
							addr <= (others => 'Z');
							app_en <= 'Z';
							data_topipe <= (others => 'Z');
							app_cmd <= "ZZZ";
							finish_updateTX_machine <= '0';
						end if;
			WHEN UpdateTX_CHECK_MEM =>
						if (app_rdy = '1') then 
							app_cmd <= "001"; 
							control_signal <= "01";
							updateTX_state <= UpdateTX_CHECK_INDEX;
						end if;
			WHEN UpdateTX_CHECK_INDEX =>
						addr <= std_logic_vector(to_unsigned(PARTITION_INIT_UPDATE_ARRAY(reg_partition),ADDR_WIDTH) - to_unsigned(index_updates,ADDR_WIDTH));
						data_topipe <= (others => 'Z');
						if (index_updates < 2*counter_number_updates_transmitted) and (counter_number_updates_transmitted<to_integer(unsigned(array_updates_sent(reg_partition)(DATA_WIDTH-1 downto 1))+to_unsigned(1,bits_num_updates))) then
							updateTX_state <= UpdateTX_SEND;
							app_en <= '1';
						elsif ((index_updates >= 2*counter_number_updates_transmitted) and (counter_number_updates_transmitted<to_integer(unsigned(array_updates_sent(reg_partition)(DATA_WIDTH-1 downto 1))+to_unsigned(1,bits_num_updates)))) then 
							updateTX_state <= UpdateTX_CHECK_RECEPTION;
						else
							updateTX_state <= UpdateTX_RESET;
						end if;
			WHEN UpdateTX_SEND =>
						if ((app_rd_data_valid = '1') and (app_rd_data_end = '1') and (data_frommem /= null_signal)) then
							data_topipe <= data_frommem; 
							index_updates <= index_updates + 1;
							app_en <= '0';
							updateTX_state <= UpdateTX_CHECK_INDEX;
						else
							data_topipe <= (others => 'Z');
						end if;
			WHEN UpdateTX_CHECK_RECEPTION =>
						if (Received_pipe = '1') then 
							counter_number_updates_transmitted <= counter_number_updates_transmitted + 1;
							finish_updateTX_machine <= '1';
							if (counter_number_updates_transmitted >= to_integer(unsigned(array_updates_sent(reg_partition)(DATA_WIDTH-1 downto 1)))) then 
								updateTX_state <= UpdateTX_RESET;
							else
								updateTX_state <= Update_WAIT_1_CYCLE;
							end if;
						end if;
			WHEN Update_WAIT_1_CYCLE =>
						updateTX_state <= UpdateTX_WAIT;
			WHEN UpdateTX_RESET =>
						index_updates <= 0;
						counter_number_updates_transmitted <= 1;
						finish_updateTX_machine <= '1';
						updateTX_state <= UpdateTX_WAIT;
		end case;
	end if;
end if;
end process;


RECEIVE_UPDATES_inFIFO: process (clk)
begin
if (clk'event AND clk='1') then
	if (reset = '0') then
		wr_en1 <= '0';
		wr_en2 <= '0';
		take <= '0';
		index_array <= 0;
		for i in 0 to (NUM_PARTITIONS-1) loop
			array_updates_sent(i) <= std_logic_vector(to_unsigned(0,DATA_WIDTH));
		end loop;
		index_updates_rx <= 0;
		address_scr <= (others => '0');
		finish_updateRX_machine <= '0';
		updateRX_state <= UpdateRX_WAIT;
	else 
		CASE updateRX_state IS
			WHEN UpdateRX_WAIT =>
						if (start_updateRX_machine = '1') then
							updateRX_state <= UpdateRX_CHECK_INDEX;
						else
							wr_en1 <= '0';
							wr_en2 <= '0';
							finish_updateRX_machine <= '0';
						end if;
			WHEN UpdateRX_CHECK_INDEX =>
						wr_en1 <= '0';
						wr_en2 <= '1';
						if (index_updates_rx < 2) then
							updateRX_state <= UpdateRX_CHECK_FIFO;
							if (index_updates_rx = 0) then
								wr_en1 <= '0';
								wr_en2 <= '0';
							end if;
						else
							finish_updateRX_machine <= '1';
							updateRX_state <= UpdateRX_RESET;
						end if;
			WHEN UpdateRX_CHECK_FIFO =>
						if ((full1 = '0') and (full2 = '0') and (data_frompipe /= null_signal)) then
							data_out1 <= data_frompipe;
							index_updates_rx <= index_updates_rx + 1;
							if (take = '0') then
								updateRX_state <= UpdateRX_STORE_ADDRESS1;
							else
								updateRX_state <= UpdateRX_STORE_ADDRESS2;
							end if;
						end if;
						wr_en1 <= '1';
						wr_en2 <= '0';	
			WHEN UpdateRX_STORE_ADDRESS1 => 
						for i in 0 to (NUM_PARTITIONS-1) loop
							if (((i=0) and (unsigned(data_frompipe) <= to_unsigned(PARTITION_LAST_VERTEX(i),DATA_WIDTH))) or ((i>0) and (unsigned(data_frompipe) <= to_unsigned(PARTITION_LAST_VERTEX(i),DATA_WIDTH)) and (unsigned(data_frompipe) > to_unsigned(PARTITION_LAST_VERTEX(i-1),DATA_WIDTH)))) then
								take <= not(take);
								wr_en1 <= '1';
								wr_en2 <= '1';
								data_out2 <= std_logic_vector(to_unsigned(PARTITION_INIT_UPDATE_ARRAY(i),ADDR_WIDTH) - to_unsigned(to_integer(unsigned(array_updates_sent(i))),ADDR_WIDTH));
								array_updates_sent(i) <= std_logic_vector(unsigned(array_updates_sent(i)) + to_unsigned(1,DATA_WIDTH));
								address_scr <= std_logic_vector(to_unsigned(PARTITION_INIT_UPDATE_ARRAY(i),ADDR_WIDTH) - to_unsigned(to_integer(unsigned(array_updates_sent(i))) + 1,ADDR_WIDTH));
								index_array <= i;
							end if;
						end loop;
						updateRX_state <= UpdateRX_CHECK_INDEX;
			WHEN UpdateRX_STORE_ADDRESS2 =>
						take <= not(take);
						wr_en1 <= '1';
						wr_en2 <= '1';
						data_out2 <= address_scr;
						array_updates_sent(index_array) <= std_logic_vector(unsigned(array_updates_sent(index_array)) + to_unsigned(1,DATA_WIDTH));
						updateRX_state <= UpdateRX_CHECK_INDEX;
			WHEN UpdateRX_RESET =>
						finish_updateRX_machine <= '0';
						index_updates_rx <= 0;
						wr_en1 <= '0';
						wr_en2 <= '0';	
						updateRX_state <= UpdateRX_WAIT;
		end case;
		if (State = StateRESET) then
			for i in 0 to (NUM_PARTITIONS-1) loop
				array_updates_sent(i) <= std_logic_vector(to_signed(0,DATA_WIDTH));
			end loop;
		end if;
	end if;
end if;
end process;


TRANSMIT_VERTEX_toDRAM: process (clk)
begin
if (clk'event AND clk='1') then
	if (reset = '0') then
		index_vertices_rx <= 0;
		app_wdf_wren <= 'Z';
		app_wdf_end <= 'Z';
		vertexRX_state <= VertexRX_WAIT;
		finish_vertexRX_machine <= '0';
	else 
		CASE vertexRX_state IS
			WHEN VertexRX_WAIT =>
						if (start_vertexRX_machine = '1') then
							vertexRX_state <= VertexRX_CHECK_INDEX;
						else
							app_wdf_wren <= 'Z';
							app_wdf_end <= 'Z';
							addr <= (others => 'Z');
							data_tomem <= (others => 'Z');
							app_cmd <= "ZZZ";
							app_en <= 'Z';
							finish_vertexRX_machine <= '0';
						end if;
			WHEN VertexRX_CHECK_INDEX => 
						if (index_vertices_rx < 3*PARTITION_SIZE_VERTEX(reg_partition)) then
							app_en <= '1';
							app_cmd <= "000"; 
							addr <= std_logic_vector(to_unsigned(PARTITION_INIT_VERTEX_ARRAY(reg_partition),ADDR_WIDTH) - to_unsigned(index_vertices_rx,ADDR_WIDTH));
							vertexRX_state <= VertexRX_CHECK_MEM;
						else
							vertexRX_state <= VertexRX_RESET;
							finish_vertexRX_machine <= '1';
						end if;
			WHEN VertexRX_CHECK_MEM =>
						if ((app_wdf_rdy = '1')  and (data_frompipe /= null_signal) and (valid = '1')) then
							vertexRX_state <= VertexRX_SEND;
						else
							app_wdf_wren <= '0';
							app_wdf_end <= '0';
							data_tomem <= (others => 'Z');
							vertexRX_state <= VertexRX_CHECK_INDEX;
						end if;
			WHEN VertexRX_SEND =>
						app_wdf_wren <= '1';
						app_wdf_end <= '1';
						data_tomem <= data_frompipe; 
						index_vertices_rx <= index_vertices_rx + 1;
						vertexRX_state <= VertexRX_CHECK_INDEX;
			WHEN VertexRX_RESET =>
						app_wdf_wren <= '0';
						app_wdf_end <= '0';
						app_en <= '0';
						index_vertices_rx <= 0;
						finish_vertexRX_machine <= '0';
						vertexRX_state <= VertexRX_WAIT;
		end case;
	end if;
end if;
end process;


TRANSMIT_UPDATES_toDRAM: process (clk)
begin
	if (clk'event AND clk='1') then
		if (reset = '0') then
			finish_FIFO_machine <= '0';
			rd_en1 <= '0';
			rd_en2 <= '0';
			fifo_state <= FIFO_WAIT;
		else
			CASE fifo_state IS
				WHEN FIFO_WAIT =>
					if (start_FIFO_machine = '1') then
						fifo_state <= FIFO_CHECK;
					else
						app_wdf_wren <= 'Z';
						app_wdf_end <= 'Z';
						rd_en1 <= '0';
						rd_en2 <= '0';
						addr <= (others => 'Z');
						data_tomem <= (others => 'Z');
						app_cmd <= "ZZZ";
						app_en <= 'Z';
						finish_FIFO_machine <= '0';
					end if;
				WHEN FIFO_CHECK =>
					if (empty1 = '1') then
						fifo_state <= FIFO_READ_EXTRA_CYCLE;
					else
						fifo_state <= FIFO_CHECK_MEM;
					end if;
					rd_en1 <= '0';
					rd_en2 <= '0';
				WHEN FIFO_CHECK_MEM =>
					if (app_wdf_rdy = '1') then
						app_en <= '1';
						app_cmd <= "000"; 
						fifo_state <= FIFO_READ;
					end if;
					rd_en1 <= '0';
					rd_en2 <= '0';
				WHEN FIFO_READ =>
					app_wdf_wren <= '1';
					app_wdf_end <= '1';
					addr <= data_in2;
					data_tomem <= data_in1; 
					rd_en1 <= '1';
					rd_en2 <= '1';
					fifo_state <= FIFO_CHECK;
				WHEN FIFO_READ_EXTRA_CYCLE =>
					finish_FIFO_machine <= '1';
					app_en <= '0';
					fifo_state <= FIFO_WAIT;
			end case;
		end if;
	end if;
end process;

end Behavioral;