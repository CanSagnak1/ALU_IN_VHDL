library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

library WORK;
use WORK.alu_pkg.ALL;

entity alu is
    generic (
        G_DATA_WIDTH : integer := DATA_WIDTH
    );
    port (
        clk         : in  std_logic;
        rst_n       : in  std_logic;
        enable      : in  std_logic;
        
        operand_a   : in  std_logic_vector(G_DATA_WIDTH-1 downto 0);
        operand_b   : in  std_logic_vector(G_DATA_WIDTH-1 downto 0);
        opcode      : in  std_logic_vector(OPCODE_WIDTH-1 downto 0);
        shift_amt   : in  std_logic_vector(SHIFT_WIDTH-1 downto 0);
        
        result      : out std_logic_vector(G_DATA_WIDTH-1 downto 0);
        result_hi   : out std_logic_vector(G_DATA_WIDTH-1 downto 0);
        
        flag_zero     : out std_logic;
        flag_carry    : out std_logic;
        flag_overflow : out std_logic;
        flag_negative : out std_logic;
        flag_parity   : out std_logic;
        
        valid_out   : out std_logic
    );
end entity alu;

architecture behavioral of alu is

    signal result_internal    : std_logic_vector(G_DATA_WIDTH-1 downto 0);
    signal result_hi_internal : std_logic_vector(G_DATA_WIDTH-1 downto 0);
    signal flags_internal     : alu_flags_t;
    
    signal add_result     : unsigned(G_DATA_WIDTH downto 0);
    signal sub_result     : unsigned(G_DATA_WIDTH downto 0);
    signal a_unsigned     : unsigned(G_DATA_WIDTH-1 downto 0);
    signal b_unsigned     : unsigned(G_DATA_WIDTH-1 downto 0);
    signal a_signed       : signed(G_DATA_WIDTH-1 downto 0);
    signal b_signed       : signed(G_DATA_WIDTH-1 downto 0);
    
begin

    a_unsigned <= unsigned(operand_a);
    b_unsigned <= unsigned(operand_b);
    a_signed   <= signed(operand_a);
    b_signed   <= signed(operand_b);
    
    add_result <= ('0' & a_unsigned) + ('0' & b_unsigned);
    sub_result <= ('0' & a_unsigned) - ('0' & b_unsigned);

    alu_process : process(clk, rst_n)
        variable v_result     : std_logic_vector(G_DATA_WIDTH-1 downto 0);
        variable v_result_hi  : std_logic_vector(G_DATA_WIDTH-1 downto 0);
        variable v_flags      : alu_flags_t;
        variable v_shift      : integer range 0 to G_DATA_WIDTH-1;
        variable v_add_temp   : unsigned(G_DATA_WIDTH downto 0);
        variable v_sub_temp   : unsigned(G_DATA_WIDTH downto 0);
        variable v_overflow_add : std_logic;
        variable v_overflow_sub : std_logic;
    begin
        if rst_n = '0' then
            result_internal    <= (others => '0');
            result_hi_internal <= (others => '0');
            flags_internal     <= FLAGS_RESET;
            valid_out          <= '0';
            
        elsif rising_edge(clk) then
            valid_out <= '0';
            
            if enable = '1' then
                v_result    := (others => '0');
                v_result_hi := (others => '0');
                v_flags     := FLAGS_RESET;
                v_shift     := to_integer(unsigned(shift_amt));
                
                v_overflow_add := (not operand_a(G_DATA_WIDTH-1) and 
                                   not operand_b(G_DATA_WIDTH-1) and 
                                   add_result(G_DATA_WIDTH-1)) or
                                  (operand_a(G_DATA_WIDTH-1) and 
                                   operand_b(G_DATA_WIDTH-1) and 
                                   not add_result(G_DATA_WIDTH-1));
                                   
                v_overflow_sub := (operand_a(G_DATA_WIDTH-1) and 
                                   not operand_b(G_DATA_WIDTH-1) and 
                                   not sub_result(G_DATA_WIDTH-1)) or
                                  (not operand_a(G_DATA_WIDTH-1) and 
                                   operand_b(G_DATA_WIDTH-1) and 
                                   sub_result(G_DATA_WIDTH-1));
                
                case opcode is

                    when OP_ADD =>
                        v_result := std_logic_vector(add_result(G_DATA_WIDTH-1 downto 0));
                        v_flags.carry := add_result(G_DATA_WIDTH);
                        v_flags.overflow := v_overflow_add;
                        
                    when OP_SUB =>
                        v_result := std_logic_vector(sub_result(G_DATA_WIDTH-1 downto 0));
                        v_flags.carry := sub_result(G_DATA_WIDTH);
                        v_flags.overflow := v_overflow_sub;
                        
                    when OP_INC =>
                        v_add_temp := ('0' & a_unsigned) + 1;
                        v_result := std_logic_vector(v_add_temp(G_DATA_WIDTH-1 downto 0));
                        v_flags.carry := v_add_temp(G_DATA_WIDTH);
                        v_flags.overflow := (not operand_a(G_DATA_WIDTH-1)) and 
                                            v_result(G_DATA_WIDTH-1);
                        
                    when OP_DEC =>
                        v_sub_temp := ('0' & a_unsigned) - 1;
                        v_result := std_logic_vector(v_sub_temp(G_DATA_WIDTH-1 downto 0));
                        v_flags.carry := v_sub_temp(G_DATA_WIDTH);
                        v_flags.overflow := operand_a(G_DATA_WIDTH-1) and 
                                            (not v_result(G_DATA_WIDTH-1));
                    
                    when OP_AND =>
                        v_result := operand_a and operand_b;
                        
                    when OP_OR =>
                        v_result := operand_a or operand_b;
                        
                    when OP_XOR =>
                        v_result := operand_a xor operand_b;
                        
                    when OP_NOT =>
                        v_result := not operand_a;
                        
                    when OP_NAND =>
                        v_result := operand_a nand operand_b;
                        
                    when OP_NOR =>
                        v_result := operand_a nor operand_b;
                    
                    when OP_SLL =>
                        v_result := barrel_shift_left(operand_a, v_shift);
                        if v_shift > 0 then
                            v_flags.carry := operand_a(G_DATA_WIDTH - v_shift);
                        end if;
                        
                    when OP_SRL =>
                        v_result := barrel_shift_right(operand_a, v_shift);
                        if v_shift > 0 then
                            v_flags.carry := operand_a(v_shift - 1);
                        end if;
                        
                    when OP_SRA =>
                        v_result := arithmetic_shift_right(operand_a, v_shift);
                        if v_shift > 0 then
                            v_flags.carry := operand_a(v_shift - 1);
                        end if;
                    
                    when OP_ROL =>
                        v_result := rotate_left(operand_a, v_shift);
                        if v_shift > 0 then
                            v_flags.carry := operand_a(G_DATA_WIDTH - v_shift);
                        end if;
                        
                    when OP_ROR =>
                        v_result := rotate_right(operand_a, v_shift);
                        if v_shift > 0 then
                            v_flags.carry := operand_a(v_shift - 1);
                        end if;
                    
                    when OP_CMP =>
                        v_result := std_logic_vector(sub_result(G_DATA_WIDTH-1 downto 0));
                        v_flags.carry := sub_result(G_DATA_WIDTH);
                        v_flags.overflow := v_overflow_sub;
                        v_result := operand_a;
                        
                    when others =>
                        v_result := (others => '0');
                        
                end case;
                
                v_flags.zero := '1' when v_result = (v_result'range => '0') else '0';
                v_flags.negative := v_result(G_DATA_WIDTH-1);
                v_flags.parity := calculate_parity(v_result);
                
                result_internal    <= v_result;
                result_hi_internal <= v_result_hi;
                flags_internal     <= v_flags;
                valid_out          <= '1';
                
            end if;
        end if;
    end process alu_process;
    
    result        <= result_internal;
    result_hi     <= result_hi_internal;
    flag_zero     <= flags_internal.zero;
    flag_carry    <= flags_internal.carry;
    flag_overflow <= flags_internal.overflow;
    flag_negative <= flags_internal.negative;
    flag_parity   <= flags_internal.parity;

end architecture behavioral;
