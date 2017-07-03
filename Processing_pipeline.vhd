----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date:    11:18:46 04/10/2017 
-- Design Name: 
-- Module Name:    processing_pipeline - Behavioral 
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

USE work.program_config.all;

entity processing_pipeline is
PORT (
	Clk: in  STD_LOGIC; -- Reloj del sistema
	reset: in std_logic; -- Reset activo a '0'
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
end processing_pipeline;

architecture hierarchical of processing_pipeline is

component Scatter is
PORT (
	Clk: in  STD_LOGIC; 
	reset: in std_logic; 
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
	data_to_chip: out    std_logic_vector(DATA_WIDTH-1 downto 0); 
	----------------------------------------------------------------------------------------------------
	addr: out std_logic_vector(ADDR_WIDTH-1 downto 0)); 
end component;

component Gather is
PORT (
	Clk: in  STD_LOGIC; 
	reset: in std_logic; 
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
end component;

component reset_Divider is
Port(
	clk : in std_logic;
	reset : in std_logic;
	sclr_scatter : in std_logic;
	sclr_gather : in std_logic;
	sclr : out std_logic
);
end component;

 ------------------------------------------------------------------------
  -- Internal Signals
  ------------------------------------------------------------------------
	signal sclr_scatter_s : std_logic;
	signal sclr_gather_s : std_logic;
  
begin

U1 : Scatter
 port map (
	Clk => Clk,
	reset => reset,
	enable_program => enable_program,
	another_iteration => another_iteration,
	control_signal => control_signal,
	Ready_fromcontrol_rx => Ready_fromcontrol_rx,
   data_from_control => data_from_control,
	en_pipe => en_pipe,
	n_partition => n_partition,
	Phase => Phase,
	data_to_control => data_to_control,
	Ready_rx => Ready_rx,
	Ready_tx => Ready_tx,
	Received => Received,
	vertexset_received => vertexset_received,
	quotient => quotient,
	dividend => dividend,
	divisor => divisor,
	sclr_scatter => sclr_scatter_s,
	data_from_chip => data_from_chip,
	write_enable => write_enable,
	ram_enable => ram_enable,
	data_to_chip => data_to_chip,
	addr => addr 
);

U2 : Gather
 port map(
	Clk => Clk,
	reset => reset,
	enable_program => enable_program,
	control_signal => control_signal,
	num_updates => num_updates,
	Ready_fromcontrol_rx => Ready_fromcontrol_rx,
   data_from_control => data_from_control,
	en_pipe => en_pipe,
	gather_start => gather_start,
	n_partition => n_partition,
	State => State,
	Phase => Phase,
	data_to_control => data_to_control,
	Ready_rx => Ready_rx,
	Ready_tx => Ready_tx,
	Received => Received,
	valid => valid,
	vertexset_received => vertexset_received,
	quotient => quotient,
	dividend => dividend,
	divisor => divisor,
	sclr_gather => sclr_gather_s,
	data_from_chip => data_from_chip,
	write_enable => write_enable,
	ram_enable => ram_enable,
	data_to_chip => data_to_chip,
	addr => addr
);

U3 : reset_Divider
 port map(
	clk => clk,
	reset => reset,
	sclr_scatter => sclr_scatter_s,
	sclr_gather => sclr_gather_s,
	sclr => sclr
);

end hierarchical;