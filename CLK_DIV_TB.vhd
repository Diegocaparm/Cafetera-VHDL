library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.numeric_std.all;

entity CLK_DIV_TB is
end CLK_DIV_TB;

architecture TEST of CLK_DIV_TB is

    component CLK_DIV is
        generic (
            FACTOR  : positive
        );
        port(
            RST_N   : in  std_logic;
            CLK_IN  : in  std_logic;
            CLK_OUT : out std_logic
        );
    end component CLK_DIV;

    --Entradas
    signal RST_N   : std_logic;
    signal CLK_IN  : std_logic;

    --Salidas
    signal CLK_OUT : std_logic;

    constant CLK_IN_PERIOD : time := 10 ns;
    constant FACTOR : positive := 10;
    
begin
    uut: CLK_DIV
        generic map (
            FACTOR  => FACTOR
        )
        port map (
            RST_N   => RST_N,
            CLK_IN  => CLK_IN,
            CLK_OUT => CLK_OUT
        );

    clockgen: process
    begin
        CLK_IN <= '0';
        wait for 0.5 * CLK_IN_PERIOD;
        CLK_IN <= '1';
        wait for 0.5 * CLK_IN_PERIOD;
    end process;
    
    stimuli: process
        variable t_ref : time;
    begin
        RST_N <= '0' after 0.25 * CLK_IN_PERIOD, '1' after 0.75 * CLK_IN_PERIOD;
        wait until RST_N = '1';
        assert CLK_OUT = '0'
            report "[FAILED]: RST_N malfunction."
            severity failure; 

        wait until CLK_OUT = '1' for FACTOR * CLK_IN_PERIOD * 0.6;
        assert CLK_OUT = '1'
            report "[FAILED]: CLK_DIV stalled."
            severity failure; 
        t_ref := now;
        wait until CLK_OUT = '1' for FACTOR * CLK_IN_PERIOD * 1.1;
        assert CLK_OUT = '1'
            report "[FAILED]: CLK_DIV stalled."
            severity failure; 
        assert now - t_ref = FACTOR * CLK_IN_PERIOD
            report "[FAILED]: Bad ratio."
            severity failure; 

        wait for 2 * CLK_IN_PERIOD;
        assert false
            report "[SUCCESS]: simulation finished."
            severity failure; 
    end process;
end architecture TEST;
