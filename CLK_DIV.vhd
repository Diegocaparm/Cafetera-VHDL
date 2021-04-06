library IEEE;
use IEEE.std_logic_1164.all;

entity CLK_DIV is
    generic (
        FACTOR  : positive       -- Ahora mismo es de 100_000_000 / 100 = 1_000_000 = 1 MHz
    );
    port (
        RST_N   : in  std_logic; -- Reset negado de la placa
        CLK_IN  : in  std_logic; -- Entrada desde el reloj interno a 100 MHz   
        CLK_OUT : out std_logic  -- Salida hacia resto del sistema a 1 MHz  
    );
end CLK_DIV;

architecture BEHAVIORAL of CLK_DIV is
    signal clk_out_i : std_logic; -- Señal 
begin
    divisorfrec: process(CLK_IN, RST_N)
        subtype cuenta_t is integer range 0 to FACTOR / 2 - 1; -- Creamos un tipo de variables que sean enteros                             
        variable cuenta : cuenta_t;  -- de 0 a 499_999 de rango de valores y creamos una variable de ese tipo
    begin
        if RST_N = '0' then                 -- En caso de que se active el reset negado
            cuenta := cuenta_t'high;        -- La cuenta vuelve a su valor más alto
            clk_out_i <= '0';               -- El valor de la señal se vuelve 0
        elsif rising_edge(CLK_IN) then      -- Si el reset no está activo, a cada flanco de subida en el reloj entrate
            if cuenta /= 0 then             -- Si la cuenta es distinta de 0
                cuenta := cuenta - 1;       -- Vamos restando valores de 1 en 1 a la cuenta 
            else                            -- Cuando lleguemos a 0
                cuenta := cuenta_t'high;    -- Reiniciamos la cuenta a su valor más alto    
                clk_out_i <= not clk_out_i; -- Invertimos el valor que tenga la señal en ese momento
            end if;
        end if;
    end process;
    CLK_OUT <= clk_out_i;                   -- Igualamos el valor de la salida al que tenga la señal
end architecture BEHAVIORAL;
