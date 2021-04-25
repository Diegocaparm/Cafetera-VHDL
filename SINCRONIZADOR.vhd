library IEEE;
use IEEE.std_logic_1164.all;

entity SINCRONIZADOR is
    port (
        CLK      : in  std_logic;       -- Reloj interno a 1 MHz
        ASYNC_IN : in  std_logic;       -- Entrada asíncrona
        SYNC_OUT : out std_logic        -- Salida síncrona con el reloj
    );
end entity SINCRONIZADOR;

architecture BEHAVIORAL of SINCRONIZADOR is
	signal SYNC : std_logic_vector(1 downto 0);    -- Creamos una señal vectorial con una punta y una cola
begin
	process (CLK)
	begin
		if rising_edge(CLK) then              -- A cada flanco de subida del reloj
			SYNC_OUT <= SYNC(1);              -- Igualamos la salida a la punta del vector
			SYNC     <= SYNC(0) & ASYNC_IN;   -- Y actualizamos este pasando la cola a la punta y el valor de la entrada a la cola
		end if;
	end process;
end BEHAVIORAL;
