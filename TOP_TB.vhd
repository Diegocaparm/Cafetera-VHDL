library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use ieee.numeric_std.all;

entity TOP_TB is
end TOP_TB;

architecture BEHAVIORAL of TOP_TB is

    procedure wait_for_n_ticks(ticks : positive; signal clk : std_logic) is
    begin
        for i in 1 to ticks loop
            wait until clk = '1';
        end loop;
    end procedure;

    procedure pulse_for(signal s : inout std_logic; duration : time; delay : time := 0 ns; negated : boolean := false) is
        variable s_prv : std_logic;
    begin
        wait for delay;
        s_prv := s;
        if negated then
            s <= '0';
        else 
            s <= '1';
        end if;
        wait for duration;
        s <= s_prv;
    end procedure;

    component TOP
        generic (
            CLK_FREQ : positive 
        );
        port (
            CLK100MHZ  : in  std_logic;
            CPU_RESETN : in  std_logic;
            BTNL       : in  std_logic;
            BTNC       : in  std_logic;
            BTNR       : in  std_logic;
            LED        : out std_logic_vector(7 downto 0)
        );
    end component TOP;

    -- Inputs
    signal CLK100MHZ  : std_logic;
    signal CPU_RESETN : std_logic;
    signal CMFRM_BTN  : std_logic;
    signal LONG_BTN   : std_logic;
    signal MILK_BTN   : std_logic;

    -- Outputs
    signal LED1       : std_logic;
    signal LED2       : std_logic;
    signal LED3       : std_logic;
    signal LED4       : std_logic;
    signal LED5       : std_logic;
    signal LED6       : std_logic;
    signal LONG_LED   : std_logic;
    signal MILK_LED   : std_logic;

    signal LED        : std_logic_vector(7 downto 0);

    constant CLKIN_FREQ   : positive := 400;  -- Hz
    constant CLKIN_PERIOD : time := 1 sec / CLKIN_FREQ;

begin
    (MILK_LED, LONG_LED, LED6, LED5, LED4, LED3, LED2, LED1) <= LED;

    uut: TOP
        generic map (
            CLK_FREQ => CLKIN_FREQ
        )
        port map(
            CLK100MHZ       => CLK100MHZ,
            CPU_RESETN      => CPU_RESETN,
            BTNL            => CMFRM_BTN,
            BTNC            => LONG_BTN,
            BTNR            => MILK_BTN,
            LED             => LED
        );

    clocking: process
    begin
        CLK100MHZ <= '0';
        wait for 0.5 * CLKIN_PERIOD;
        CLK100MHZ <= '1';
        wait for 0.5 * CLKIN_PERIOD;
    end process;

    stimulus: process
    begin
        -- Reset
        CPU_RESETN <= '1';
        pulse_for(CPU_RESETN, 10 ms, 10 ms, true);

        -- Signal initialization
        wait until CPU_RESETN = '1';
        CMFRM_BTN <= '0';
        LONG_BTN  <= '0';
        MILK_BTN  <= '0';

        -- Pedido café corto
        pulse_for(LONG_BTN, 100 ms, 50 ms);   -- ¿Largo? 
        pulse_for(LONG_BTN, 100 ms, 50 ms);   -- No, mejor corto 
        pulse_for(CMFRM_BTN, 100 ms, 50 ms);  -- Confirmar
        wait for 10100 ms;

        -- Pedido café largo con leche
        pulse_for(LONG_BTN, 100 ms, 50 ms);   -- Largo
        pulse_for(MILK_BTN, 100 ms, 50 ms);   --Leche
        pulse_for(CMFRM_BTN, 100 ms, 50 ms);  -- Confirmar
        wait for 25100 ms;

        wait_for_n_ticks(50, CLK100MHZ);

        assert false
            report "[SUCCESS]: simulation finished."
            severity failure;
    end process;
end BEHAVIORAL;
