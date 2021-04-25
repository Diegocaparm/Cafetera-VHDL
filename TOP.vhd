library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity TOP is
    generic (
        CLK_FREQ : positive := 100_000_000             -- Frecuencia de la FPGA
    );
    port (
        CLK100MHZ  : in  std_logic;                    -- Reloj interno a 100 Mhz
        CPU_RESETN : in  std_logic;                    -- Reset negado de la placa
        BTNL       : in  std_logic;                    -- Botón izquierdo (corto)
        BTNC       : in  std_logic;                    -- Botón central (largo)
        BTNR       : in  std_logic;                    -- Botón derecho (leche)
        LED        : out std_logic_vector(7 downto 0)  -- Fila de leds de la placa
    );
end entity TOP;

architecture STRUCTURAL of TOP is

    constant CLKSYS_FREQ : positive := 100;     -- Creamos una constante entre la que dividir la frecuencia de la FPGA
    constant TIMER_BITS  : positive :=  16;     -- Creamos una constante que será el número de bits de la cuenta

    component CLK_DIV
        generic (
            FACTOR  : positive       -- Ahora mismo es de 100_000_000 / 100 = 1_000_000 = 1 MHz
        );
        port (
            RST_N   : in  std_logic; -- Reset negado de la placa
            CLK_IN  : in  std_logic; -- Entrada desde el reloj interno a 100 MHz   
            CLK_OUT : out std_logic  -- Salida hacia resto del sistema a 1 MHz  
        );
    end component;

    component CONDITIONER is
        generic (
            WIDTH : positive    -- Genérico con el número de entradas mediante pulsadores (3)
        );
        port (
            CLK      : in  std_logic;   -- Reloj interno de 1 MHz
            ASYNC_IN : in  std_logic_vector(WIDTH - 1 downto 0);    -- Vector de entrada con el valor de los botones en sus dígitos
            EDGE_OUT : out std_logic_vector(WIDTH - 1 downto 0)     -- Vector de salida con el valor de los botones (sincronizados) en sus dígitos
        );
    end component CONDITIONER;

    component CONTROL is
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
    end component CONTROL;

    signal sys_clk     : std_logic;  -- Reloj del sistema

    signal async_input : std_logic_vector(2 downto 0);          -- Señal vectorial que entrará a la entidad conditioner
    signal input_edge  : std_logic_vector(async_input'range);   -- Señal vectorial que irá del conditioner a control

    alias CMFRM_BTN : std_logic is BTNL;
    alias LONG_BTN  : std_logic is BTNC;
    alias MILK_BTN  : std_logic is BTNR;

begin
    async_input <= (MILK_BTN, LONG_BTN, CMFRM_BTN); -- Introducimos las botones a una señal vectorial
    -- Instaciamos todas las entidades uniendo puertos a los pines de la placa y a las señales creadas
    prescaler: CLK_DIV
        generic map (
            FACTOR     => CLK_FREQ / CLKSYS_FREQ
        )
        port map (
            RST_N      => CPU_RESETN,
            CLK_IN     => CLK100MHZ,
            CLK_OUT    => sys_clk
        );

    cndtnr: CONDITIONER
        generic map (
            WIDTH      => async_input'length
        )
        port map (
            CLK        => sys_clk,
            ASYNC_IN   => async_input,
            EDGE_OUT   => input_edge
        );

    ctrl: CONTROL
        generic map (
            CLK_FREQ   => CLKSYS_FREQ,
            TMR_WIDTH  => TIMER_BITS
        )
        port map (
            CLK        => sys_clk,
            RST_N      => CPU_RESETN,
            CMFRM_EDGE => input_edge(0),
            LARGO_EDGE => input_edge(1),
            LECHE_EDGE => input_edge(2),
	        LED        => LED
        );
end architecture STRUCTURAL;
