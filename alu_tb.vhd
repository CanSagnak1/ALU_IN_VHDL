--------------------------------------------------------------------------------
-- File        : alu_tb.vhd
-- Project     : Professional 32-bit ALU
-- Description : Comprehensive testbench for ALU verification. Tests all 
--               operations, boundary conditions, and flag generation.
-- Author      : Professional VHDL Design
-- Version     : 1.0
-- Created     : 2024
--------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

library WORK;
use WORK.alu_pkg.ALL;

entity alu_tb is
end entity alu_tb;

architecture behavioral of alu_tb is

    constant CLK_PERIOD : time := 10 ns;
    constant DATA_W     : integer := 32;
    
    signal clk           : std_logic := '0';
    signal rst_n         : std_logic := '0';
    signal enable        : std_logic := '0';
    signal operand_a     : std_logic_vector(DATA_W-1 downto 0) := (others => '0');
    signal operand_b     : std_logic_vector(DATA_W-1 downto 0) := (others => '0');
    signal opcode        : std_logic_vector(OPCODE_WIDTH-1 downto 0) := (others => '0');
    signal shift_amt     : std_logic_vector(SHIFT_WIDTH-1 downto 0) := (others => '0');
    signal result        : std_logic_vector(DATA_W-1 downto 0);
    signal result_hi     : std_logic_vector(DATA_W-1 downto 0);
    signal flag_zero     : std_logic;
    signal flag_carry    : std_logic;
    signal flag_overflow : std_logic;
    signal flag_negative : std_logic;
    signal flag_parity   : std_logic;
    signal valid_out     : std_logic;
    
    signal test_passed   : integer := 0;
    signal test_failed   : integer := 0;
    
    component alu is
        generic (
            G_DATA_WIDTH : integer := DATA_WIDTH
        );
        port (
            clk           : in  std_logic;
            rst_n         : in  std_logic;
            enable        : in  std_logic;
            operand_a     : in  std_logic_vector(G_DATA_WIDTH-1 downto 0);
            operand_b     : in  std_logic_vector(G_DATA_WIDTH-1 downto 0);
            opcode        : in  std_logic_vector(OPCODE_WIDTH-1 downto 0);
            shift_amt     : in  std_logic_vector(SHIFT_WIDTH-1 downto 0);
            result        : out std_logic_vector(G_DATA_WIDTH-1 downto 0);
            result_hi     : out std_logic_vector(G_DATA_WIDTH-1 downto 0);
            flag_zero     : out std_logic;
            flag_carry    : out std_logic;
            flag_overflow : out std_logic;
            flag_negative : out std_logic;
            flag_parity   : out std_logic;
            valid_out     : out std_logic
        );
    end component alu;
    
    procedure check_result(
        signal passed      : inout integer;
        signal failed      : inout integer;
        constant test_name : in string;
        constant expected  : in std_logic_vector;
        constant actual    : in std_logic_vector
    ) is
    begin
        if expected = actual then
            report test_name & " PASSED" severity note;
            passed <= passed + 1;
        else
            report test_name & " FAILED - Expected: " & 
                   integer'image(to_integer(unsigned(expected))) &
                   " Actual: " & 
                   integer'image(to_integer(unsigned(actual)))
                   severity error;
            failed <= failed + 1;
        end if;
    end procedure;

begin

    uut : alu
        generic map (
            G_DATA_WIDTH => DATA_W
        )
        port map (
            clk           => clk,
            rst_n         => rst_n,
            enable        => enable,
            operand_a     => operand_a,
            operand_b     => operand_b,
            opcode        => opcode,
            shift_amt     => shift_amt,
            result        => result,
            result_hi     => result_hi,
            flag_zero     => flag_zero,
            flag_carry    => flag_carry,
            flag_overflow => flag_overflow,
            flag_negative => flag_negative,
            flag_parity   => flag_parity,
            valid_out     => valid_out
        );
    
    clk_process : process
    begin
        clk <= '0';
        wait for CLK_PERIOD / 2;
        clk <= '1';
        wait for CLK_PERIOD / 2;
    end process clk_process;
    
    stim_process : process
        variable expected_result : std_logic_vector(DATA_W-1 downto 0);
    begin
        report "========================================" severity note;
        report "    ALU Testbench Started" severity note;
        report "========================================" severity note;
        
        rst_n <= '0';
        enable <= '0';
        wait for CLK_PERIOD * 5;
        rst_n <= '1';
        wait for CLK_PERIOD * 2;
        
        ------------------------------------------------------------------------
        -- Test ADD Operation
        ------------------------------------------------------------------------
        report "Testing ADD operation..." severity note;
        
        operand_a <= x"00000005";
        operand_b <= x"00000003";
        opcode <= OP_ADD;
        enable <= '1';
        wait for CLK_PERIOD;
        enable <= '0';
        wait for CLK_PERIOD;
        expected_result := x"00000008";
        check_result(test_passed, test_failed, "ADD 5+3=8", expected_result, result);
        
        operand_a <= x"FFFFFFFF";
        operand_b <= x"00000001";
        opcode <= OP_ADD;
        enable <= '1';
        wait for CLK_PERIOD;
        enable <= '0';
        wait for CLK_PERIOD;
        expected_result := x"00000000";
        check_result(test_passed, test_failed, "ADD overflow", expected_result, result);
        assert flag_carry = '1' report "Carry flag should be set" severity error;
        assert flag_zero = '1' report "Zero flag should be set" severity error;
        
        operand_a <= x"7FFFFFFF";
        operand_b <= x"00000001";
        opcode <= OP_ADD;
        enable <= '1';
        wait for CLK_PERIOD;
        enable <= '0';
        wait for CLK_PERIOD;
        expected_result := x"80000000";
        check_result(test_passed, test_failed, "ADD signed overflow", expected_result, result);
        assert flag_overflow = '1' report "Overflow flag should be set" severity error;
        assert flag_negative = '1' report "Negative flag should be set" severity error;
        
        ------------------------------------------------------------------------
        -- Test SUB Operation
        ------------------------------------------------------------------------
        report "Testing SUB operation..." severity note;
        
        operand_a <= x"0000000A";
        operand_b <= x"00000003";
        opcode <= OP_SUB;
        enable <= '1';
        wait for CLK_PERIOD;
        enable <= '0';
        wait for CLK_PERIOD;
        expected_result := x"00000007";
        check_result(test_passed, test_failed, "SUB 10-3=7", expected_result, result);
        
        operand_a <= x"00000003";
        operand_b <= x"00000003";
        opcode <= OP_SUB;
        enable <= '1';
        wait for CLK_PERIOD;
        enable <= '0';
        wait for CLK_PERIOD;
        expected_result := x"00000000";
        check_result(test_passed, test_failed, "SUB 3-3=0", expected_result, result);
        assert flag_zero = '1' report "Zero flag should be set" severity error;
        
        ------------------------------------------------------------------------
        -- Test AND Operation
        ------------------------------------------------------------------------
        report "Testing AND operation..." severity note;
        
        operand_a <= x"F0F0F0F0";
        operand_b <= x"FF00FF00";
        opcode <= OP_AND;
        enable <= '1';
        wait for CLK_PERIOD;
        enable <= '0';
        wait for CLK_PERIOD;
        expected_result := x"F000F000";
        check_result(test_passed, test_failed, "AND test", expected_result, result);
        
        ------------------------------------------------------------------------
        -- Test OR Operation
        ------------------------------------------------------------------------
        report "Testing OR operation..." severity note;
        
        operand_a <= x"F0F0F0F0";
        operand_b <= x"0F0F0F0F";
        opcode <= OP_OR;
        enable <= '1';
        wait for CLK_PERIOD;
        enable <= '0';
        wait for CLK_PERIOD;
        expected_result := x"FFFFFFFF";
        check_result(test_passed, test_failed, "OR test", expected_result, result);
        
        ------------------------------------------------------------------------
        -- Test XOR Operation
        ------------------------------------------------------------------------
        report "Testing XOR operation..." severity note;
        
        operand_a <= x"AAAAAAAA";
        operand_b <= x"55555555";
        opcode <= OP_XOR;
        enable <= '1';
        wait for CLK_PERIOD;
        enable <= '0';
        wait for CLK_PERIOD;
        expected_result := x"FFFFFFFF";
        check_result(test_passed, test_failed, "XOR test", expected_result, result);
        
        operand_a <= x"12345678";
        operand_b <= x"12345678";
        opcode <= OP_XOR;
        enable <= '1';
        wait for CLK_PERIOD;
        enable <= '0';
        wait for CLK_PERIOD;
        expected_result := x"00000000";
        check_result(test_passed, test_failed, "XOR self=0", expected_result, result);
        
        ------------------------------------------------------------------------
        -- Test NOT Operation
        ------------------------------------------------------------------------
        report "Testing NOT operation..." severity note;
        
        operand_a <= x"00000000";
        opcode <= OP_NOT;
        enable <= '1';
        wait for CLK_PERIOD;
        enable <= '0';
        wait for CLK_PERIOD;
        expected_result := x"FFFFFFFF";
        check_result(test_passed, test_failed, "NOT 0", expected_result, result);
        
        operand_a <= x"FFFFFFFF";
        opcode <= OP_NOT;
        enable <= '1';
        wait for CLK_PERIOD;
        enable <= '0';
        wait for CLK_PERIOD;
        expected_result := x"00000000";
        check_result(test_passed, test_failed, "NOT all 1s", expected_result, result);
        
        ------------------------------------------------------------------------
        -- Test NAND Operation
        ------------------------------------------------------------------------
        report "Testing NAND operation..." severity note;
        
        operand_a <= x"FFFFFFFF";
        operand_b <= x"FFFFFFFF";
        opcode <= OP_NAND;
        enable <= '1';
        wait for CLK_PERIOD;
        enable <= '0';
        wait for CLK_PERIOD;
        expected_result := x"00000000";
        check_result(test_passed, test_failed, "NAND test", expected_result, result);
        
        ------------------------------------------------------------------------
        -- Test NOR Operation
        ------------------------------------------------------------------------
        report "Testing NOR operation..." severity note;
        
        operand_a <= x"00000000";
        operand_b <= x"00000000";
        opcode <= OP_NOR;
        enable <= '1';
        wait for CLK_PERIOD;
        enable <= '0';
        wait for CLK_PERIOD;
        expected_result := x"FFFFFFFF";
        check_result(test_passed, test_failed, "NOR test", expected_result, result);
        
        ------------------------------------------------------------------------
        -- Test SLL Operation
        ------------------------------------------------------------------------
        report "Testing SLL operation..." severity note;
        
        operand_a <= x"00000001";
        shift_amt <= "00100";
        opcode <= OP_SLL;
        enable <= '1';
        wait for CLK_PERIOD;
        enable <= '0';
        wait for CLK_PERIOD;
        expected_result := x"00000010";
        check_result(test_passed, test_failed, "SLL by 4", expected_result, result);
        
        ------------------------------------------------------------------------
        -- Test SRL Operation
        ------------------------------------------------------------------------
        report "Testing SRL operation..." severity note;
        
        operand_a <= x"80000000";
        shift_amt <= "00100";
        opcode <= OP_SRL;
        enable <= '1';
        wait for CLK_PERIOD;
        enable <= '0';
        wait for CLK_PERIOD;
        expected_result := x"08000000";
        check_result(test_passed, test_failed, "SRL by 4", expected_result, result);
        
        ------------------------------------------------------------------------
        -- Test SRA Operation
        ------------------------------------------------------------------------
        report "Testing SRA operation..." severity note;
        
        operand_a <= x"80000000";
        shift_amt <= "00100";
        opcode <= OP_SRA;
        enable <= '1';
        wait for CLK_PERIOD;
        enable <= '0';
        wait for CLK_PERIOD;
        expected_result := x"F8000000";
        check_result(test_passed, test_failed, "SRA by 4 (sign extend)", expected_result, result);
        
        operand_a <= x"40000000";
        shift_amt <= "00100";
        opcode <= OP_SRA;
        enable <= '1';
        wait for CLK_PERIOD;
        enable <= '0';
        wait for CLK_PERIOD;
        expected_result := x"04000000";
        check_result(test_passed, test_failed, "SRA by 4 (positive)", expected_result, result);
        
        ------------------------------------------------------------------------
        -- Test ROL Operation
        ------------------------------------------------------------------------
        report "Testing ROL operation..." severity note;
        
        operand_a <= x"80000001";
        shift_amt <= "00001";
        opcode <= OP_ROL;
        enable <= '1';
        wait for CLK_PERIOD;
        enable <= '0';
        wait for CLK_PERIOD;
        expected_result := x"00000003";
        check_result(test_passed, test_failed, "ROL by 1", expected_result, result);
        
        ------------------------------------------------------------------------
        -- Test ROR Operation
        ------------------------------------------------------------------------
        report "Testing ROR operation..." severity note;
        
        operand_a <= x"00000003";
        shift_amt <= "00001";
        opcode <= OP_ROR;
        enable <= '1';
        wait for CLK_PERIOD;
        enable <= '0';
        wait for CLK_PERIOD;
        expected_result := x"80000001";
        check_result(test_passed, test_failed, "ROR by 1", expected_result, result);
        
        ------------------------------------------------------------------------
        -- Test INC Operation
        ------------------------------------------------------------------------
        report "Testing INC operation..." severity note;
        
        operand_a <= x"00000005";
        opcode <= OP_INC;
        enable <= '1';
        wait for CLK_PERIOD;
        enable <= '0';
        wait for CLK_PERIOD;
        expected_result := x"00000006";
        check_result(test_passed, test_failed, "INC 5", expected_result, result);
        
        operand_a <= x"FFFFFFFF";
        opcode <= OP_INC;
        enable <= '1';
        wait for CLK_PERIOD;
        enable <= '0';
        wait for CLK_PERIOD;
        expected_result := x"00000000";
        check_result(test_passed, test_failed, "INC overflow", expected_result, result);
        assert flag_carry = '1' report "Carry flag should be set on INC overflow" severity error;
        
        ------------------------------------------------------------------------
        -- Test DEC Operation
        ------------------------------------------------------------------------
        report "Testing DEC operation..." severity note;
        
        operand_a <= x"00000005";
        opcode <= OP_DEC;
        enable <= '1';
        wait for CLK_PERIOD;
        enable <= '0';
        wait for CLK_PERIOD;
        expected_result := x"00000004";
        check_result(test_passed, test_failed, "DEC 5", expected_result, result);
        
        operand_a <= x"00000000";
        opcode <= OP_DEC;
        enable <= '1';
        wait for CLK_PERIOD;
        enable <= '0';
        wait for CLK_PERIOD;
        expected_result := x"FFFFFFFF";
        check_result(test_passed, test_failed, "DEC underflow", expected_result, result);
        
        ------------------------------------------------------------------------
        -- Test CMP Operation
        ------------------------------------------------------------------------
        report "Testing CMP operation..." severity note;
        
        operand_a <= x"00000005";
        operand_b <= x"00000003";
        opcode <= OP_CMP;
        enable <= '1';
        wait for CLK_PERIOD;
        enable <= '0';
        wait for CLK_PERIOD;
        assert flag_zero = '0' report "Zero flag should not be set (A > B)" severity error;
        assert flag_negative = '0' report "Negative should not be set (A > B)" severity error;
        
        operand_a <= x"00000003";
        operand_b <= x"00000003";
        opcode <= OP_CMP;
        enable <= '1';
        wait for CLK_PERIOD;
        enable <= '0';
        wait for CLK_PERIOD;
        
        ------------------------------------------------------------------------
        -- Test Summary
        ------------------------------------------------------------------------
        wait for CLK_PERIOD * 5;
        
        report "========================================" severity note;
        report "    ALU Testbench Completed" severity note;
        report "    Passed: " & integer'image(test_passed) severity note;
        report "    Failed: " & integer'image(test_failed) severity note;
        report "========================================" severity note;
        
        if test_failed = 0 then
            report "ALL TESTS PASSED!" severity note;
        else
            report "SOME TESTS FAILED!" severity error;
        end if;
        
        wait;
    end process stim_process;

end architecture behavioral;
