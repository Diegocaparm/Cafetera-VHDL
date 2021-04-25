library IEEE;
use IEEE.std_logic_1164.all;

entity CONDITIONER is
    generic (
        WIDTH : positive    -- Genérico con el número de entradas mediante pulsadores (3)
    );
    port (
        CLK      : in  std_logic;   -- Reloj interno de 1 MHz
        ASYNC_IN : in  std_logic_vector(WIDTH - 1 downto 0);    -- Vector de entrada con el valor de los botones en sus dígitos
        EDGE_OUT : out std_logic_vector(WIDTH - 1 downto 0)     -- Vector de salida con el valor de los botones (sincronizados) en sus dígitos
    );
end entity CONDITIONER;

architecture STRUCTURAL of CONDITIONER is

    component SINCRONIZADOR is
        port (
            CLK      : in  std_logic;       -- Reloj interno a 1 MHz
            ASYNC_IN : in  std_logic;       -- Entrada asíncrona
            SYNC_OUT : out std_logic        -- Salida síncrona con el reloj
        );
    end component SINCRONIZADOR;

    component FALSEPULSE is
        port (
            CLK    : in  std_logic;  -- Entrada de reloj a 1 MHz
            FP_IN  : in  std_logic;  -- Entrada desde el sincronizador
            FP_OUT : out std_logic   -- Salida hacia la entidad control
        );
    end component FALSEPULSE;

begin
    inputs: for i in ASYNC_IN'range generate    -- Creamos tantos conjuntos Sincro-FP como entradas haya (3)
        signal syncd_input : std_logic;     -- Creamos una señal que una enlace la salida del sincronizador con la entrada del FP
    begin
    -- Instanciamos ambas entidades y asignamos sus puertos a las entradas y salidas de la entidad, así como a la señal 
        sincro_i: SINCRONIZADOR
            port map(
                CLK       => CLK,           
                ASYNC_IN  => ASYNC_IN(i),
                SYNC_OUT  => syncd_input
            );

        falsepulse_i: FALSEPULSE
            port map (
                CLK       => CLK,
                FP_IN     => syncd_input,
                FP_OUT    => EDGE_OUT(i)
            );
    end generate;
end architecture STRUCTURAL;
