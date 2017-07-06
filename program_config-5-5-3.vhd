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
use IEEE.numeric_std.all;

package program_config is

------------------------------------- DATOS A INTRODUCIR POR EL USUARIO --------------------------------------
--------------------------------------------------------------------------------------------------------------

-- Número de particiones --
constant NUM_PARTITIONS : integer := 3; 

-- NO CAMBIAR --
type partition_array is array (0 to NUM_PARTITIONS-1) of integer;
----------------

-- Número de bits necesarios para contabilizar NUM_PARTITIONS+1 --
constant bits_num_partitions : integer := 2; -- 1 numero mas del que necesitamos por si nos pasamos -> son 2 partitiones <=> 1 bit, pero preveemos que contaremos hasta 3 <=> 2 bits
	
-- Número de bits necesarios para contabilizar el máximo de updates que puede recibir una partición, que es equivalente a la suma de todos los edges de todas las particiones --
constant bits_num_updates : integer := 5; -- 1 numero maximo de updates que puede recibir una particion <=> suma de todos los updates: en este caso, el maximo es 15 updates <=> 4 bits

-- Número de iteraciones a realizar por el programa --
constant NUM_ITERATIONS : integer := 30;

-- Dirección de inicio del primer Vertex set en la DRAM --
constant PARTITION_INIT_VERTEX : integer := 65535;

-- Número de bits dedicados a las direcciones --
constant ADDR_WIDTH: integer := 16;

-- Precisión de los datos --
constant BITS_PRECISION: integer := 18; -- 0.0.18

-- Factor de amortiguación (x100) --
constant damping_factor: integer := 85;

-- Ciclos de retardo en el acceso aleatorio a la DRAM --
constant NUM_DELAY : integer := 50;

-- Tamaño del Vertex set de cada partición --
constant PARTITION_SIZE_VERTEX : partition_array :=
(
	5,
	5,
	3
);

-- Último nodo del Vertex set de cada partición --
constant PARTITION_LAST_VERTEX : partition_array :=
(
	5,
	10,
	13
);

-- Tamaño del Edge set de cada partición --
constant PARTITION_SIZE_EDGE : partition_array :=
(
	10,
	10,
	5
);
--------------------------------------------------------------------------------------------------------------
--------------------------------------------------------------------------------------------------------------


constant DATA_WIDTH: integer := BITS_PRECISION; -- Número de bits para los datos
constant d: integer := (2**BITS_PRECISION)*damping_factor/100; -- d in BITS_PRECISION
constant up_dividend : integer := (2**BITS_PRECISION)*(100-damping_factor)/100; -- 1-d in BITS_PRECISION

type size_array is array (0 to 2) of integer;

constant values_per_vertex : integer := 3;
constant values_per_edge : integer := 2;
constant values_per_update : integer := 2;

function max (constant size : in partition_array) return integer;
function max_partition (constant all_sizes : in size_array) return integer;
function sum (constant size : in partition_array) return integer;
function size_updates (constant size : in partition_array) return partition_array;
function init_arrays (constant first_address : in integer; constant size : in partition_array; constant values_per_sample : in integer) return partition_array;

constant PARTITION_SIZE_UPDATE : partition_array := size_updates(PARTITION_SIZE_EDGE);

constant MAX_PARTITION_SIZE_VERTEX : integer := max(PARTITION_SIZE_VERTEX);
constant MAX_PARTITION_SIZE_EDGE : integer := max(PARTITION_SIZE_EDGE);
constant MAX_PARTITION_SIZE_UPDATE : integer := max(PARTITION_SIZE_UPDATE);

constant PARTITION_SIZES : size_array :=
(
	values_per_vertex*MAX_PARTITION_SIZE_VERTEX,
	values_per_edge*MAX_PARTITION_SIZE_EDGE,
	values_per_update*MAX_PARTITION_SIZE_UPDATE
);

constant MAX_PARTITION_SIZE : integer := max_partition(PARTITION_SIZES);

constant PARTITION_INIT_VERTEX_ARRAY : partition_array := init_arrays(PARTITION_INIT_VERTEX, PARTITION_SIZE_VERTEX, values_per_vertex);
constant PARTITION_INIT_EDGE_ARRAY   : partition_array := init_arrays(PARTITION_INIT_VERTEX_ARRAY(NUM_PARTITIONS-1)-PARTITION_SIZE_VERTEX(NUM_PARTITIONS-1)*values_per_vertex, PARTITION_SIZE_EDGE, values_per_edge);
constant PARTITION_INIT_UPDATE_ARRAY : partition_array := init_arrays(PARTITION_INIT_EDGE_ARRAY(NUM_PARTITIONS-1)-PARTITION_SIZE_EDGE(NUM_PARTITIONS-1)*values_per_edge, PARTITION_SIZE_UPDATE, values_per_update);

procedure Run (signal finished: in std_logic; signal Enable:out std_logic);

end program_config;

package body program_config is

  function init_arrays (constant first_address : in integer; constant size : in partition_array; constant values_per_sample : in integer) return partition_array is
    variable result   : partition_array;
	 variable last_address	: integer;
  begin
	 result(0) := first_address;
    last_address := first_address;
    for i in 1 to NUM_PARTITIONS-1 loop
	   result(i) := last_address - size(i-1)*values_per_sample;
	   last_address := result(i);
	 end loop;
    return result; 
  end init_arrays;
  
  function max (constant size : in partition_array) return integer is
  variable maximum   : integer;
  begin
	 maximum := size(0);		
    for i in 1 to NUM_PARTITIONS-1 loop
	   if (size(i) > maximum) then
			maximum := size(i);
		end if;
	 end loop;
    return maximum; 
  end max;
  
  function max_partition (constant all_sizes : in size_array) return integer is
  variable maximum_partition   : integer;
  begin
	 maximum_partition := all_sizes(0);		
    for i in 1 to 2 loop
	   if (all_sizes(i) > maximum_partition) then
			maximum_partition := all_sizes(i);
		end if;
	 end loop;
    return maximum_partition; 
  end max_partition;
  
  function sum (constant size : in partition_array) return integer is
  variable addition   : integer := 0;
  begin		
    for i in 0 to NUM_PARTITIONS-1 loop
	   addition := addition + size(i);
	 end loop;
    return addition; 
  end sum;
  
  function size_updates (constant size : in partition_array) return partition_array is
	 variable sizes   : partition_array;
	 variable max_size_edges : integer;
  begin
    max_size_edges := sum(size);
    for i in 0 to NUM_PARTITIONS-1 loop
	   sizes(i) := max_size_edges;
	 end loop;
    return sizes; 
  end size_updates;

  procedure Run (signal finished: in std_logic; signal Enable:out std_logic) is
  begin
    if (finished = '1') then
		Enable <= '0';
    else 
		Enable <= '1';
	 end if;
  end procedure Run;

end program_config;