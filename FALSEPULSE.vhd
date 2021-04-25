library IEEE;
use IEEE.std_logic_1164.all;

entity FALSEPULSE is
    port (
        CLK    : in  std_logic;  -- Entrada de reloj a 1 MHz
        FP_IN  : in  std_logic;  -- Entrada desde el sincronizador
        FP_OUT : out std_logic   -- Salida con cada pulso
    );
end entity FALSEPULSE;

architecture BEHAVIORAL of FALSEPULSE is
	signal FP : std_logic_vector(2 downto 0);  -- Vector de 3 dígitos
begin
    process (clk)
    begin
        if rising_edge(clk) then               -- A cada flanco de subida
            fp <= fp(1 downto 0) & FP_IN;      -- Actualizamos el vector registrando la entrada actual a la cola del vector
        end if;
    end process;

    FP_OUT <= '1' when fp = "011" else         -- Activamos la salida cuando recibamos un pulso que se repita durante dos flancos
              '0';                             -- De repetirse más tiempo no seguimos activando o  de no repetirse, no activamos la salida
end architecture BEHAVIORAL;
