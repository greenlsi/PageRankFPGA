----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date:    11:29:44 04/10/2017 
-- Design Name: 
-- Module Name:    Conjunto - Behavioral 
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

USE work.program_config.all;

entity Conjunto is
PORT (
	clk: in std_logic; -- Reloj del sistema
	reset: in std_logic; -- Reset activo a '0'
	enable_program: in std_logic;
	app_rdy: in std_logic; 
	app_rd_data_valid: in std_logic; 
	app_rd_data_end: in std_logic; 
	data_tocontrol: in  std_logic_vector(DATA_WIDTH-1 downto 0); 
	app_wdf_rdy: in std_logic; 
	app_en: out std_logic; 
	app_wdf_end: out std_logic; 
	app_wdf_wren: out std_logic; 
	app_cmd: out std_logic_vector(2 downto 0); 
	addr: out std_logic_vector(ADDR_WIDTH-1 downto 0); 
	finish_program : out std_logic;
	data_fromcontrol: out std_logic_vector(DATA_WIDTH-1 downto 0)); 

end Conjunto;

architecture hierarchical of Conjunto is

component control_module is
PORT (
	clk: in std_logic; 
	reset: in std_logic; 
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
	finish_program : out std_logic;
	addr: out std_logic_vector(ADDR_WIDTH-1 downto 0));
end component;

component processing_pipeline is
PORT (
	Clk: in  STD_LOGIC; 
	reset: in std_logic; 
	enable_program: in std_logic;
	------------------------------------ senales con el control unit -----------------------------------
	another_iteration: in std_logic; 
	control_signal : in std_logic_vector(1 downto 0); 
	gather_start : in std_logic;
	num_updates: in std_logic_vector(bits_num_updates-1 downto 0); 
	Ready_fromcontrol_rx: in std_logic; 
   data_from_control: in std_logic_vector(DATA_WIDTH-1 downto 0); 
	en_pipe: in std_logic; 
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
	-------------------------------------- senales con el divisor --------------------------------------
	quotient: in std_logic_vector(DATA_WIDTH-1 downto 0); 
	dividend: out std_logic_vector(DATA_WIDTH-1 downto 0); 
	divisor: out std_logic_vector(DATA_WIDTH-1 downto 0); 
	sclr: out std_logic; 
	----------------------------------------------------------------------------------------------------
	---------------------------------------- senales con la BRAM ---------------------------------------
	data_from_chip: in std_logic_vector(DATA_WIDTH-1 downto 0); 
	write_enable: out std_logic; 
	ram_enable: out std_logic;
	data_to_chip: out    std_logic_vector(DATA_WIDTH-1 downto 0);
	----------------------------------------------------------------------------------------------------
	addr: out std_logic_vector(ADDR_WIDTH-1 downto 0)); 
end component;

component chip_memory is
 port(
	clk:in std_logic; 
	we:in std_logic; 
	addr:in std_logic_vector(ADDR_WIDTH-1 downto 0); 
	din:in std_logic_vector(DATA_WIDTH-1 downto 0); 
	ram_enable: in std_logic;
	dout:out std_logic_vector(DATA_WIDTH-1 downto 0)); 
end component;

component Divider is
	port (
	clk: in std_logic; 
	sclr: in std_logic; 
	rfd: out std_logic;
	dividend: in std_logic_vector(DATA_WIDTH-1 downto 0); 
	divisor: in std_logic_vector(DATA_WIDTH-1 downto 0); 
	quotient: out std_logic_vector(DATA_WIDTH-1 downto 0); 
	fractional: out std_logic_vector(DATA_WIDTH-1 downto 0));
end component;

 ------------------------------------------------------------------------
  -- Internal Signals
  ------------------------------------------------------------------------
  signal Ready_frompipe_rx_s: std_logic;
  signal Ready_frompipe_tx_s: std_logic;
  signal data_frompipe_s: std_logic_vector(DATA_WIDTH-1 downto 0);
  signal vertexset_received_s: std_logic;
  signal State_s: std_logic; 
  signal Phase_s: std_logic_vector(2 downto 0);
  signal control_signal_s: std_logic_vector(1 downto 0);
  signal num_updates_s: std_logic_vector(bits_num_updates-1 downto 0);
  signal another_iteration_s: std_logic;
  signal Ready_rx_s: std_logic;
  signal data_topipe_s: std_logic_vector(DATA_WIDTH-1 downto 0);
  signal valid_s: std_logic;
  signal data_from_chip_s: std_logic_vector(DATA_WIDTH-1 downto 0);
  signal data_to_chip_s: std_logic_vector(DATA_WIDTH-1 downto 0);
  signal addr_s: std_logic_vector(ADDR_WIDTH-1 downto 0);
  signal write_enable_s: std_logic;
  signal Received_frompipe_tocontrol_s: std_logic;
  signal n_partition_s: std_logic_vector(bits_num_partitions-1 downto 0);
  signal	dividend_s: STD_LOGIC_VECTOR ( DATA_WIDTH-1 downto 0 );  
  signal	divisor_s: STD_LOGIC_VECTOR ( DATA_WIDTH-1 downto 0 );
  signal	quotient_s: STD_LOGIC_VECTOR ( DATA_WIDTH-1 downto 0 );
  signal sclr_s : std_logic;
  signal ram_enable_s: std_logic;
  signal en_pipe_s: std_logic;
  signal gather_start_s : std_logic;
  
begin

U1 : control_module
 port map (
	clk => clk,
	reset =>  reset, 
	enable_program => enable_program,
	finish_program => finish_program,
	en_pipe => en_pipe_s,
	app_rdy => app_rdy,
	gather_start => gather_start_s,
	n_partition => n_partition_s,
	app_rd_data_valid => app_rd_data_valid,
	app_rd_data_end => app_rd_data_end,
	Ready_frompipe_rx => Ready_frompipe_rx_s,
	Ready_frompipe_tx => Ready_frompipe_tx_s,
	data_frommem => data_tocontrol,
	data_frompipe => data_frompipe_s,
	Received_pipe => Received_frompipe_tocontrol_s,
	vertexset_received => vertexset_received_s,
	State => State_s,
	Phase => Phase_s,
	valid => valid_s,
	control_signal => control_signal_s,
	app_wdf_end => app_wdf_end,
	app_wdf_wren => app_wdf_wren,
	app_wdf_rdy => app_wdf_rdy,
	num_updates => num_updates_s,
	another_iteration => another_iteration_s,
	Ready_rx => Ready_rx_s,
	app_en => app_en,
	app_cmd => app_cmd,
	addr => addr,
	data_topipe => data_topipe_s,
	data_tomem => data_fromcontrol
);

U2 : chip_memory
 port map(
	clk => clk,
	we => write_enable_s,
	addr => addr_s,
	din => data_to_chip_s,
	ram_enable => ram_enable_s,
	dout => data_from_chip_s
);

U3 : Processing_pipeline
 port map (
	Clk => Clk,
	reset => reset,
	enable_program => enable_program,
	another_iteration => another_iteration_s,
   control_signal  => control_signal_s,
	n_partition => n_partition_s,
	en_pipe => en_pipe_s,
	gather_start => gather_start_s,
	num_updates => num_updates_s,
	Ready_fromcontrol_rx => Ready_rx_s,
   data_from_control  => data_topipe_s,
	data_from_chip  => data_from_chip_s,
	Received => Received_frompipe_tocontrol_s,
	addr => addr_s,
	valid => valid_s,
	write_enable => write_enable_s,
	ram_enable => ram_enable_s,
	Ready_rx => Ready_frompipe_rx_s,
	Ready_tx => Ready_frompipe_tx_s,
	vertexset_received => vertexset_received_s,
	State => State_s,
	Phase => Phase_s,
	dividend => dividend_s,
	divisor => divisor_s,
	sclr => sclr_s,
	quotient => quotient_s,
	data_to_control => data_frompipe_s,
	data_to_chip => data_to_chip_s
);

U4 : Divider
 port map(
 	clk => clk,
	sclr => sclr_s,
	rfd => open,
	dividend => dividend_s,
	divisor => divisor_s,
	quotient => quotient_s,
	fractional => open
);

end hierarchical;