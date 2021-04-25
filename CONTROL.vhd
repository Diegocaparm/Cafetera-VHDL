library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity CONTROL is -- Entradads y salidas de entidad
    generic ( 
        CLK_FREQ    : positive;                          -- Frecuencia de reloj
        TMR_WIDTH   : positive                           -- Número de bits contador retardo
    );
    port (
        CLK         : in  std_logic;                     -- Reloj a 1 MHz
        RST_N       : in  std_logic;                     -- Reset asíncrono
        CMFRM_EDGE  : in  std_logic;                     -- Confirmación usuario
        LARGO_EDGE  : in  std_logic;                     -- Marca selección café largo
        LECHE_EDGE  : in  std_logic;                     -- Marca añadir leche
        LED         : out std_logic_vector (7 downto 0)  -- Salida a los 8 primeros leds de la placa
    );
end entity CONTROL;

architecture STRUCTURAL of CONTROL is

    component FLAG_REGISTER is
        generic (
            WIDTH : positive
        );
        port (
            CLK   : in  std_logic;      -- Reloj a 1 MHz
            CE    : in  std_logic;      -- Registro que habilita la selección de modo
            RESET : in  std_logic;      -- Reset proviniente de la máquina de estados 
            EDGE  : in  std_logic_vector(WIDTH - 1 downto 0);   -- Vector de entrada con (LECHE_EDGE y LARGO_EDGE)
            FLAG  : out std_logic_vector(WIDTH - 1 downto 0)    -- Vector de salida hacia MILK_LED y LONG_LED
        );
    end component FLAG_REGISTER;

    component CONTADOR is
        generic ( 
            WIDTH   : positive
        );
        port (
            CLK     : in  std_logic;    -- Reloj a 1 MHz
            RESET   : in  std_logic;    -- Reset proviniente de la máquina de estados
            LOAD    : in  std_logic;    -- Registro que habilita la carga de una cuenta
            DELAY   : in  unsigned(WIDTH - 1 downto 0); -- Cuenta a cargar
            TIMEOUT : out std_logic     -- Registro de que la cuenta ha finalizado
        );
    end component CONTADOR;

    component MAQUINA_ESTADOS is
        generic (
            CLK_FREQ    : positive;                          -- Frecuencia del reloj de la máquina de estados
            TMR_WIDTH   : positive                           -- Número de git contador retardo
        );
        port (
            CLK         : in  std_logic;                     -- Reloj a 10 Hz
            RST_N       : in  std_logic;                     -- Reset asíncrono
            BOTON_CMFRM : in  std_logic;                     -- Confirmación usuario
            MARCA_LARGO : in  std_logic;                     -- Marca selección café largo
            MARCA_LECHE : in  std_logic;                     -- Marca añadir leche
            TMR_TIMEOUT : in  std_logic;                     -- Registro que indicará si el contador ha terminado
            SLAVE_RESET : out std_logic;                     -- Señal que reseteará la entidad flag register
            FLAG_CE     : out std_logic;                     -- Señal que permitirá al flag register tomar nuevos valorer
            TMR_LOAD    : out std_logic;                     -- Registro que cargará una cuenta en el contador
            TMR_DELAY   : out unsigned(TMR_WIDTH - 1 downto 0); -- Cuenta atrás a cargar en contador
            LED         : out std_logic_vector(5 downto 0)   -- Salida a los 6 primeros leds de la placa
        );
    end component MAQUINA_ESTADOS;

    signal flag_in       : std_logic_vector(1 downto 0);    -- Entrada al selector de modos desde el conditioner
    signal flag_out      : std_logic_vector(1 downto 0);    -- Salida a los leds desde el selector de modos

    signal slave_reset   : std_logic;   -- Reset desde la máquina de estados al contador y el selector

    signal timer_timeout : std_logic;   -- Señal desde el contador a la máquina de estados con información sobre el final de la cuenta
    signal timer_load    : std_logic;   -- Señal desde la máquina de estados al contador con información sobre si hay que cargar una nueva cuenta
    signal timer_delay   : unsigned(TMR_WIDTH - 1 downto 0); -- Cuenta a cargar en el contador

    signal flag_ce     : std_logic;     -- Señal desde la máquina de estados al selector de modos que habilita una nueva selección
    
begin
    flag_in <= (LECHE_EDGE, LARGO_EDGE); -- Introducimos las salidas del conditioner al selector de modos
    -- Instaciamos las 3 entidades asignando puertos y señales
    freg: FLAG_REGISTER
        generic map (
            WIDTH => flag_in'length
        )
        port map (
            CLK   => CLK,
            CE    => flag_ce,
            RESET => slave_reset,
            EDGE  => flag_in,
            FLAG  => flag_out
        );

    led(7 downto 6) <= flag_out; -- Enlazamos LONG_LED y MILK_LED con la salida del selector de modos

    timer: CONTADOR
        generic map ( 
            WIDTH   => TMR_WIDTH
        )
        port map (
            CLK     => CLK,
            RESET   => slave_reset,
            LOAD    => timer_load,
            DELAY   => timer_delay,
            TIMEOUT => timer_timeout
        );

    fsm: MAQUINA_ESTADOS
        generic map ( 
            CLK_FREQ    => CLK_FREQ,
            TMR_WIDTH   => TMR_WIDTH
        )
        port map(
            CLK         => CLK,
            RST_N       => RST_N,
            BOTON_CMFRM => CMFRM_EDGE,
            MARCA_LARGO => flag_out(0),
            MARCA_LECHE => flag_out(1),
            TMR_TIMEOUT => timer_timeout,
            SLAVE_RESET => slave_reset,
            FLAG_CE     => FLAG_CE,
            TMR_LOAD    => timer_load,
            TMR_DELAY   => timer_delay,
	        LED         => LED(5 downto 0)
        );                   
end architecture STRUCTURAL;
