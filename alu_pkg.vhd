library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

package alu_pkg is
    constant DATA_WIDTH     : integer := 32;
    constant OPCODE_WIDTH   : integer := 4;
    constant SHIFT_WIDTH    : integer := 5;
    constant OP_ADD  : std_logic_vector(OPCODE_WIDTH-1 downto 0) := "0000";
    constant OP_SUB  : std_logic_vector(OPCODE_WIDTH-1 downto 0) := "0001";
    constant OP_AND  : std_logic_vector(OPCODE_WIDTH-1 downto 0) := "0010";
    constant OP_OR   : std_logic_vector(OPCODE_WIDTH-1 downto 0) := "0011";
    constant OP_XOR  : std_logic_vector(OPCODE_WIDTH-1 downto 0) := "0100";
    constant OP_NOT  : std_logic_vector(OPCODE_WIDTH-1 downto 0) := "0101";
    constant OP_NAND : std_logic_vector(OPCODE_WIDTH-1 downto 0) := "0110";
    constant OP_NOR  : std_logic_vector(OPCODE_WIDTH-1 downto 0) := "0111";
    constant OP_SLL  : std_logic_vector(OPCODE_WIDTH-1 downto 0) := "1000";
    constant OP_SRL  : std_logic_vector(OPCODE_WIDTH-1 downto 0) := "1001";
    constant OP_SRA  : std_logic_vector(OPCODE_WIDTH-1 downto 0) := "1010";
    constant OP_ROL  : std_logic_vector(OPCODE_WIDTH-1 downto 0) := "1011";
    constant OP_ROR  : std_logic_vector(OPCODE_WIDTH-1 downto 0) := "1100";
    constant OP_INC  : std_logic_vector(OPCODE_WIDTH-1 downto 0) := "1101";
    constant OP_DEC  : std_logic_vector(OPCODE_WIDTH-1 downto 0) := "1110";
    constant OP_CMP  : std_logic_vector(OPCODE_WIDTH-1 downto 0) := "1111";
    
    type alu_flags_t is record
        zero     : std_logic;
        carry    : std_logic;
        overflow : std_logic;
        negative : std_logic;
        parity   : std_logic;
    end record alu_flags_t;
    
    constant FLAGS_RESET : alu_flags_t := (
        zero     => '0',
        carry    => '0',
        overflow => '0',
        negative => '0',
        parity   => '0'
    );
    
    function calculate_parity(data : std_logic_vector) return std_logic;
    
    function barrel_shift_left(
        data   : std_logic_vector;
        amount : integer
    ) return std_logic_vector;
    
    function barrel_shift_right(
        data   : std_logic_vector;
        amount : integer
    ) return std_logic_vector;
    
    function arithmetic_shift_right(
        data   : std_logic_vector;
        amount : integer
    ) return std_logic_vector;
    
    function rotate_left(
        data   : std_logic_vector;
        amount : integer
    ) return std_logic_vector;
    
    function rotate_right(
        data   : std_logic_vector;
        amount : integer
    ) return std_logic_vector;

end package alu_pkg;

package body alu_pkg is

    function calculate_parity(data : std_logic_vector) return std_logic is
        variable parity : std_logic := '0';
    begin
        for i in data'range loop
            parity := parity xor data(i);
        end loop;
        return parity;
    end function calculate_parity;
    
    function barrel_shift_left(
        data   : std_logic_vector;
        amount : integer
    ) return std_logic_vector is
        variable result : std_logic_vector(data'range);
        variable shift  : integer;
    begin
        shift := amount mod data'length;
        if shift = 0 then
            result := data;
        else
            result := data(data'high - shift downto data'low) & 
                      (shift - 1 downto 0 => '0');
        end if;
        return result;
    end function barrel_shift_left;
    
    function barrel_shift_right(
        data   : std_logic_vector;
        amount : integer
    ) return std_logic_vector is
        variable result : std_logic_vector(data'range);
        variable shift  : integer;
    begin
        shift := amount mod data'length;
        if shift = 0 then
            result := data;
        else
            result := (shift - 1 downto 0 => '0') & 
                      data(data'high downto data'low + shift);
        end if;
        return result;
    end function barrel_shift_right;
    
    function arithmetic_shift_right(
        data   : std_logic_vector;
        amount : integer
    ) return std_logic_vector is
        variable result  : std_logic_vector(data'range);
        variable shift   : integer;
        variable sign    : std_logic;
    begin
        shift := amount mod data'length;
        sign := data(data'high);
        if shift = 0 then
            result := data;
        else
            result := (shift - 1 downto 0 => sign) & 
                      data(data'high downto data'low + shift);
        end if;
        return result;
    end function arithmetic_shift_right;

    function rotate_left(
        data   : std_logic_vector;
        amount : integer
    ) return std_logic_vector is
        variable result : std_logic_vector(data'range);
        variable rot    : integer;
    begin
        rot := amount mod data'length;
        if rot = 0 then
            result := data;
        else
            result := data(data'high - rot downto data'low) & 
                      data(data'high downto data'high - rot + 1);
        end if;
        return result;
    end function rotate_left;

    function rotate_right(
        data   : std_logic_vector;
        amount : integer
    ) return std_logic_vector is
        variable result : std_logic_vector(data'range);
        variable rot    : integer;
    begin
        rot := amount mod data'length;
        if rot = 0 then
            result := data;
        else
            result := data(data'low + rot - 1 downto data'low) & 
                      data(data'high downto data'low + rot);
        end if;
        return result;
    end function rotate_right;

end package body alu_pkg;
