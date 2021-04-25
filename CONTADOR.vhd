library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity CONTADOR is
    generic (
        WIDTH   : positive        -- Creamos una variable que contenga el programa inicial para cada botón
    );
    port (
        CLK     : in  std_logic;                     -- Reloj a 1 MHz
        RESET   : in  std_logic;                     -- Reset síncrono
        LOAD    : in  std_logic;                     -- Carga de la cuenta
        DELAY   : in  unsigned(WIDTH - 1 downto 0);  -- Valor de la cuenta a cargar en pulsos de reloj
        TIMEOUT : out std_logic                      -- Hemos terminado de contar
    );
end entity CONTADOR;

architecture BEHAVIORAL of CONTADOR is
    signal count : unsigned(DELAY'range);    -- Creamos una señal con el rango de la cuenta   
begin
    process (CLK)
    begin
        if rising_edge(CLK) then
            if RESET = '1' then              -- Si pulsamos el reset
                count <= (others => '0');    -- Reiniciamos la cuenta inicial
            elsif LOAD = '1' then            -- Si se activa la carga de la cuenta
                count <= DELAY;              -- Cargamos el valor de la cuenta en la señal
            elsif count /= 0 then            -- Mientras la cuenta no haya llegado a 0
                count <= count - 1;          -- Vamos restandole valores a la señal
            end if;
        end if;
    end process;

    TIMEOUT <= '0' when count /= 0 else      -- Mientras no sea 0 el valor de la cuenta no hemos termiando de contar
               '1';                          -- Cuando sea así avisamos de haber terminado
end architecture BEHAVIORAL;
