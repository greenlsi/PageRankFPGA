----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date:    11:29:44 04/10/2017 
-- Design Name: 
-- Module Name:    control_module - Behavioral 
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

entity control_module is
PORT (
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
	finish_program : out std_logic;
	addr: out std_logic_vector(ADDR_WIDTH-1 downto 0)); 

end control_module;

architecture hierarchical of control_module is

component control_unit is
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
	--------------------------------------------------------------------------------------------------
	finish_program : out std_logic;
	addr: out std_logic_vector(ADDR_WIDTH-1 downto 0)); 
end component;

COMPONENT FIFO_DATA
  PORT (
    clk : IN STD_LOGIC;
    srst : IN STD_LOGIC;
    din : IN STD_LOGIC_VECTOR(DATA_WIDTH-1 DOWNTO 0);
    wr_en : IN STD_LOGIC;
    rd_en : IN STD_LOGIC;
    dout : OUT STD_LOGIC_VECTOR(DATA_WIDTH-1 DOWNTO 0);
    full : OUT STD_LOGIC;
    empty : OUT STD_LOGIC
  );
END COMPONENT;

COMPONENT FIFO_ADDRESS
  PORT (
    clk : IN STD_LOGIC;
    srst : IN STD_LOGIC;
    din : IN STD_LOGIC_VECTOR(ADDR_WIDTH-1 DOWNTO 0);
    wr_en : IN STD_LOGIC;
    rd_en : IN STD_LOGIC;
    dout : OUT STD_LOGIC_VECTOR(ADDR_WIDTH-1 DOWNTO 0);
    full : OUT STD_LOGIC;
    empty : OUT STD_LOGIC
  );
END COMPONENT;

 ------------------------------------------------------------------------
  -- Internal Signals
  ------------------------------------------------------------------------
  signal data_in_s1 : STD_LOGIC_VECTOR(DATA_WIDTH-1 DOWNTO 0);
  signal wr_en_s1 : STD_LOGIC;
  signal rd_en_s1 : STD_LOGIC;
  signal data_out_s1 : STD_LOGIC_VECTOR(DATA_WIDTH-1 DOWNTO 0);
  signal full_s1 : STD_LOGIC;
  signal empty_s1 : STD_LOGIC;
  signal data_in_s2 : STD_LOGIC_VECTOR(ADDR_WIDTH-1 DOWNTO 0);
  signal wr_en_s2 : STD_LOGIC;
  signal rd_en_s2 : STD_LOGIC;
  signal data_out_s2 : STD_LOGIC_VECTOR(ADDR_WIDTH-1 DOWNTO 0);
  signal full_s2 : STD_LOGIC;
  signal empty_s2 : STD_LOGIC;
  signal srst : std_logic;
  
begin

U1 : control_unit
 port map (
	clk => clk,
	reset =>  reset, 
	enable_program => enable_program,
	finish_program => finish_program,
	en_pipe => en_pipe,
	gather_start => gather_start,
	app_rdy => app_rdy,
	n_partition => n_partition ,
	app_rd_data_valid => app_rd_data_valid,
	app_rd_data_end => app_rd_data_end,
	Ready_frompipe_rx => Ready_frompipe_rx ,
	Ready_frompipe_tx => Ready_frompipe_tx ,
	data_frommem => data_frommem,
	data_frompipe => data_frompipe,
	Received_pipe => Received_pipe,
	vertexset_received => vertexset_received ,
	State => State ,
	Phase => Phase ,
	valid => valid ,
	control_signal => control_signal,
	app_wdf_end => app_wdf_end,
	app_wdf_wren => app_wdf_wren,
	app_wdf_rdy => app_wdf_rdy,
	num_updates => num_updates ,
	another_iteration => another_iteration ,
	Ready_rx => Ready_rx ,
	app_en => app_en,
	app_cmd => app_cmd,
	addr => addr,
	data_topipe => data_topipe ,
	data_in1 => data_out_s1,
   full1 => full_s1,
   empty1 => empty_s1,
   data_in2 => data_out_s2, 
   full2 => full_s2,
   empty2 => empty_s2,
	data_out1 => data_in_s1, 
   wr_en1 => wr_en_s1,
   rd_en1 => rd_en_s1,
   data_out2 => data_in_s2, 
   wr_en2 => wr_en_s2,
   rd_en2 => rd_en_s2,
	srst => srst,
	data_tomem => data_tomem
);

U2 : FIFO_DATA
 port map(
    clk => clk,
    srst => srst,
    din => data_in_s1,
    wr_en => wr_en_s1,
    rd_en => rd_en_s1,
    dout => data_out_s1,
    full => full_s1,
    empty => empty_s1
);

U3 : FIFO_ADDRESS
 port map(
    clk => clk,
    srst => srst,
    din => data_in_s2,
    wr_en => wr_en_s2,
    rd_en => rd_en_s2,
    dout => data_out_s2,
    full => full_s2,
    empty => empty_s2
);

end hierarchical;