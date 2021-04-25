library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std .all;

entity MAQUINA_ESTADOS is
    generic ( 
        CLK_FREQ    : positive;       -- Frecuencia del reloj de la máquina de estados
        TMR_WIDTH   : positive        -- Número de bits del contador
    );
	port (
        CLK         : in  std_logic;  -- Reloj interno de 1 MHz
        RST_N       : in  std_logic;  -- Reset asíncrono negado
        BOTON_CMFRM : in  std_logic;  -- Confirmación usuario
        MARCA_LARGO : in  std_logic;  -- Marca selección café largo
        MARCA_LECHE : in  std_logic;  -- Marca añadir leche
        TMR_TIMEOUT : in  std_logic;  -- Marca cuenta finalizada
        SLAVE_RESET : out std_logic;  -- Registro que reincia el contador y el selector de modos
        FLAG_CE     : out std_logic;  -- Registro que habilita los cambios de selección
        TMR_LOAD    : out std_logic;  -- Registro que carga una cuenta en el contador
        TMR_DELAY   : out unsigned(TMR_WIDTH - 1 downto 0); -- Cuenta a cargar en el contador
        LED         : out std_logic_vector (5 downto 0)  -- Salida a los 6 primeros leds de la placa
    );
end entity MAQUINA_ESTADOS;

architecture BEHAVIORAL of MAQUINA_ESTADOS is

    constant SHORT_DELAY : time :=  5 sec;  -- Cuenta de 5 segundos para el modo café corto
    constant LONG_DELAY  : time := 10 sec;  -- Cuenta de 10 segundos para el modo café largo
    constant MILK_DELAY  : time :=  3 sec;  -- Cuenta de 3 segundos para el modo leche
    constant GRIND_DELAY : time := 4 sec;   -- Cuenta de 4 segundos mientras molemos el café
    constant HEAT_DELAY : time := 6 sec;    -- Cuenta de 6 segundos mientras calentamos la leche
    
    constant SHORT_DELAY_TICKS : unsigned := to_unsigned(  -- Constante que pasa SHORT_DELAY de segundos a ciclos de reloj
        CLK_FREQ * SHORT_DELAY / 1 sec - 1, TMR_WIDTH
    );
    constant LONG_DELAY_TICKS : unsigned :=  to_unsigned(  -- Constante que pasa LONG_DELAY de segundos a ciclos de reloj
        CLK_FREQ * LONG_DELAY  / 1 sec - 1, TMR_WIDTH
    );
    constant MILK_DELAY_TICKS : unsigned :=  to_unsigned(  -- Constante que pasa MILK_DELAY de segundos a ciclos de reloj
        CLK_FREQ * MILK_DELAY  / 1 sec - 1, TMR_WIDTH
    );
    constant GRIND_DELAY_TICKS : unsigned :=  to_unsigned( -- Constante que pasa GRIND_DELAY de segundos a ciclos de reloj
        CLK_FREQ * GRIND_DELAY  / 1 sec - 1, TMR_WIDTH
    );
    constant HEAT_DELAY_TICKS : unsigned :=  to_unsigned(  -- Constante que pasa HEAT_DELAY de segundos a ciclos de reloj
        CLK_FREQ * HEAT_DELAY  / 1 sec - 1, TMR_WIDTH
    );
    
    type STATE is (
        S0,  -- Reinicio selección usuario
        S1,  -- Selección (corto/largo, no leche/leche)
        S2,  -- Inicio moliendo
        S3,  -- Moliendo café
        S4,  -- Comienzo servicio café corto
        S5,  -- Comienzo servicio café largo
        S6,  -- Esperar fin servicio café
        S7,  -- Inicio de calentar la leche
        S8,  -- Calentando la leche
        S9,  -- Comienzo servicio leche
        S10   -- Esperar fin servicio leche
    );
    signal estado_actual    : STATE;  -- Creamos una señal para el estado en el que estamos
    signal siguiente_estado : STATE;  -- Creamos una señal para el estado al que vamos a pasar

begin
    state_register: process (RST_N, CLK)
    begin
        if RST_N = '0' then         -- En caso de pulsarse el reset
            estado_actual <= S0;    -- Pasamos al estado de reinicio
        end if;
        if rising_edge(CLK) then    -- A cada pulso de reloj
            estado_actual <= siguiente_estado;  -- Actualizamos el estado
        end if;
    end process;

    nextstate_decod: process (estado_actual, BOTON_CMFRM, MARCA_LARGO, MARCA_LECHE, TMR_TIMEOUT)
    begin
        siguiente_estado <= estado_actual;          -- Igualamos el siguiente estado al que estemos 
        case estado_actual is
            when S0 =>                              -- Cuando estemos en estado de reinicio
                siguiente_estado <= S1;             -- Pasamos a S1

            when S1 =>                              -- Cuando estemos esperando confirmación
                if BOTON_CMFRM = '1' then           -- Si usuario confirma
                siguiente_estado <= S2;             -- Pasamos al estado S2
                end if;
                
            when S2 =>                              -- Cuando iniciemos cuenta atrás para moler café
                siguiente_estado <= S3;             -- Pasamos al estado S3 

            when S3 =>                              -- Cuando estemos esperando el fin del molido
                if TMR_TIMEOUT = '1' then           -- Si hemos terminado de moler
                    if MARCA_LARGO = '1' then       -- Si está solicitado café largo
                        siguiente_estado <= S5;     -- Pasamos a S5 (Largo)
                    else                            -- Si no
                        siguiente_estado <= S4;     -- Pasamos a S4 (Corto)
                    end if;
                end if;

            when S4 =>                              -- Inicia cuenta atrás corto         
                    siguiente_estado <= S6;         -- Y pasamos a S6
                
            when S5 =>                              -- Inicia cuanta atrás largo
                     siguiente_estado <= S6;        -- Y pasamos a S6
                
            when S6 =>                              -- Mientras esperamos fin de servir café
                if TMR_TIMEOUT = '1' then           -- Cuando acabemos
                      if MARCA_LECHE = '1' then     -- Si hemos solicitado leche
                            siguiente_estado <= S7; -- Pasamos a S7
                      else                          -- Si no la hemos pedido
                      siguiente_estado <= S0;       -- Volvemos a S0
                 end if;
                end if;
                
           when S7 =>                               -- Iniciamos la cuenta atrás calentando leche
                    siguiente_estado <= S8;         -- Y pasamos a S8
                    
           when S8 =>                               -- Mientras esperamos que se caliente la leche
               if TMR_TIMEOUT = '1' then            -- Cuando acabe
                    siguiente_estado <= S9;         -- Pasamos al estado S9
               end if;  
               
           when S9 =>                               -- Iniciamos cuenta atrás de servir leche
                    siguiente_estado <= S10;        -- Pasamos a S10
             
           when S10 =>                              -- Mientras servimos leche
                if TMR_TIMEOUT = '1' then           -- Cuando acabe
                        siguiente_estado <= S0;     -- Volvemos al estado S0
                end if;

            when others =>                          -- En cualquier otra situación
                siguiente_estado <= S0;             -- Volvemos a S0
        end case;
    end process;
    
	output_decod: process (estado_actual)
    begin
        LED <= "000000"; -- De inicio apagamos los 6 leds (Leche,Café,Calentando,Moliendo,Selección,Encendido)
        case estado_actual is
            when S0 =>                             -- Modo reinicio
                SLAVE_RESET <= '1';                -- Reinicia contador y la selección de modo
                FLAG_CE     <= '1';                -- Y habilitamos esta última
                TMR_LOAD    <= '0';                -- No cargamos ninguna cuenta al contador
                TMR_DELAY   <= (others => '0');    -- Y el valor de esta será 0
                LED         <= "000001";           -- Encendemos el led de encendido (LED[0])

            when S1 =>                             -- Modo selección
                SLAVE_RESET <= '0';                -- No reiniciamos las demás entidades
                FLAG_CE     <= '1';                -- Permite cambiar opciones
                TMR_LOAD    <= '0';                -- No cargamos ninguna cuenta al contador
                TMR_DELAY   <= (others => '0');    -- Y el valor de esta será 0
                LED         <= "000011";           -- Encendemos también el led de selección (LED[1]) 

            when S2 =>                             -- Inicio moliendo          
                SLAVE_RESET <= '0';                -- No reiniciamos las demás entidades
                FLAG_CE     <= '0';                -- No permite cambiar opciones
                TMR_LOAD    <= '1';                -- Lanza temporizador
                TMR_DELAY   <= GRIND_DELAY_TICKS;  -- Cargamos a la cuenta el tiempo de molido
            	LED         <= "000101";           -- Apagamos el led selección de modo y encendemos el led moliendo (LED[2])

            when S3 =>                             -- Moliendo café
                SLAVE_RESET <= '0';                -- No reiniciamos las demás entidades
                FLAG_CE     <= '0';                -- No permite cambiar opciones
                TMR_LOAD    <= '0';                -- Permite cuenta atrás del contador
                TMR_DELAY   <= (others => '0');    -- No introducimos nueva cuenta pero la cambiamos a 0
            	LED         <= "000101";           -- Encendemos el led moliendo (LED[2])

            when S4 =>                             -- Comienzo café corto
                SLAVE_RESET <= '0';                -- No reiniciamos las demás entidades
                FLAG_CE     <= '0';                -- No permite cambiar opciones
                TMR_LOAD    <= '1';                -- Lanza temporizador
                TMR_DELAY   <= SHORT_DELAY_TICKS;  -- Cargamos a la cuenta el tiempo de servicio corto
            	LED         <= "010001";           -- Encendemos el led sacando café (LED[4])
            	
             when S5 =>                            -- Comienzo café largo
                SLAVE_RESET <= '0';                -- No reiniciamos las demás entidades
                FLAG_CE     <= '0';                -- No permite cambiar opciones
                TMR_LOAD    <= '1';                -- Lanza temporizador
                TMR_DELAY   <= LONG_DELAY_TICKS;   -- Cargamos a la cuenta el tiempo de servicio largo
            	LED         <= "010001";           -- Encendemos el led sacando café (LED[4])
            
            when S6 =>                             -- Esperar fin servicio café
                SLAVE_RESET <= '0';                -- No reiniciamos las demás entidades
                FLAG_CE     <= '0';                -- No permite cambiar opciones
                TMR_LOAD    <= '0';                -- Permite cuenta atrás del contador
                TMR_DELAY   <= (others => '0');    -- No introducimos nueva cuenta pero la cambiamos a 0
            	LED         <= "010001";           -- Encendemos el led sacando café (LED[4])    
            	
            when S7 =>                             -- Comienzo calentar leche
                SLAVE_RESET <= '0';                -- No reiniciamos las demás entidades
                FLAG_CE     <= '0';                -- No permite cambiar opciones
                TMR_LOAD    <= '1';                -- Lanza temporizador
                TMR_DELAY   <= HEAT_DELAY_TICKS;   -- Cargamos a la cuenta el tiempo de calentar leche
            	LED         <= "001001";           -- Encendemos el led calentado leche (LED[3])
            	
            when S8 =>                             -- Calentando leche
                SLAVE_RESET <= '0';                -- No reiniciamos las demás entidades
                FLAG_CE     <= '0';                -- No permite cambiar opciones
                TMR_LOAD    <= '0';                -- Permite cuenta atrás del contador
                TMR_DELAY   <= (others => '0');    -- No introducimos nueva cuenta pero la cambiamos a 0
            	LED         <= "001001";           -- Encendemos el led calentado leche (LED[3])
            
            when S9 =>                             -- Comienzo servir leche
                SLAVE_RESET <= '0';                -- No reiniciamos las demás entidades
                FLAG_CE     <= '0';                -- No permite cambiar opciones
                TMR_LOAD    <= '1';                -- Lanza temporizador
                TMR_DELAY   <= MILK_DELAY_TICKS;   -- Cargamos a la cuenta el tiempo de servicio leche
            	LED         <= "100001";           -- Encendemos el led sacando leche (LED[5])
            
            when S10 =>                            -- Sirviendo leche
                SLAVE_RESET <= '0';                -- No reiniciamos las demás entidades
                FLAG_CE     <= '0';                -- No permite cambiar opciones
                TMR_LOAD    <= '0';                -- Permite cuenta atrás del contador
                TMR_DELAY   <= (others => '0');    -- No introducimos nueva cuenta pero la cambiamos a 0
            	LED         <= "100001";           -- Encendemos el led sacando leche (LED[5])

            when others =>                         -- Si estamos en otro estado no especificado (error)
                SLAVE_RESET <= '1';                -- Reiniciamos las demás entidades
                FLAG_CE     <= '1';                -- Habilitamos el cambio de selección
                TMR_LOAD    <= '0';                -- No cargamos nuevas cuentas
                TMR_DELAY   <= (others => '0');    -- No introducimos nueva cuenta y la cambiamos a 0
                LED         <= "000000";           -- Apagamos todos los leds
        end case;
    end process;	            
end architecture BEHAVIORAL;
