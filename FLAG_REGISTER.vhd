library IEEE;
use IEEE.std_logic_1164.all;

entity FLAG_REGISTER is
    generic (
        WIDTH : positive
    );
    port (
        CLK   : in  std_logic;  -- Reloj interno a 1 MHz
        CE    : in  std_logic;  -- Habilitación para la selección de modo
        RESET : in  std_logic;  -- Reset enviado desde la máquina de estados
        EDGE  : in  std_logic_vector(WIDTH - 1 downto 0);   -- Entrada con LARGO_EDGE y LECHE_EDGE
        FLAG  : out std_logic_vector(WIDTH - 1 downto 0)    -- Salida hacia MILK_LED y LONG_LED
    );
end entity FLAG_REGISTER;

architecture BEHAVIORAL of FLAG_REGISTER is
    signal reg : std_logic_vector(FLAG'range);  -- Creamos un vector donde grabar y tomar información de cada modo
begin
    process (CLK)
    begin
        if rising_edge(CLK) then                -- A cada flanco de subida del reloj
            if CE = '1' then                    -- Si está habilitada la selección de modo
                for i in reg'range loop         -- Para todos los valores del vector EDGE
                    if RESET = '1' then         -- Si la máquina manda un reset
                        reg(i) <= '0';          -- Iniciar los valores a 0
                    elsif EDGE(i) = '1' then    -- Si no hay reset y si hay un edge 
                        reg(i) <= not reg(i);   -- Invertir el valor actual del dígito correspondiente
                    end if;
                end loop;
            end if;
        end if;
    end process;

    FLAG <= reg;   -- Igualamos la salida hacia los leds con el vector creado                     
end architecture BEHAVIORAL;
