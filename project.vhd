library IEEE;
use IEEE.STD_LOGIC_1164.all;

entity project_reti_logiche is
  port (
    i_clk : in std_logic;
    i_rst : in std_logic;
    i_start : in std_logic;
    i_w : in std_logic;
    o_z0 : out std_logic_vector(7 downto 0);
    o_z1 : out std_logic_vector(7 downto 0);
    o_z2 : out std_logic_vector(7 downto 0);
    o_z3 : out std_logic_vector(7 downto 0);
    o_done : out std_logic;
    o_mem_addr : out std_logic_vector(15 downto 0);
    i_mem_data : in std_logic_vector(7 downto 0);
    o_mem_we : out std_logic;
    o_mem_en : out std_logic
  );
end project_reti_logiche;

architecture Behavioral of project_reti_logiche is
  component datapath_1 is
    port (
      i_clk : in std_logic; --Ingressi
      i_rst : in std_logic;
      i_w : in std_logic;
      bit_ctrl : in std_logic_vector(1 downto 0);
      ---------------------
      o_mem_addr : out std_logic_vector(15 downto 0);
      out_sel : out std_logic_vector(1 downto 0)
      ---------------------
    );
  end component;

  component datapath_2 is
    port (
      i_clk : in std_logic; --Ingressi
      i_rst : in std_logic;
      i_mem_data : in std_logic_vector(7 downto 0); -- valore proveniente dalla memoria
      out_sel : in std_logic_vector(1 downto 0); -- selettore che mi dice in quale delle quattro uscite farlo andare
      show_out : in std_logic; --mi dice se mostrare le uscite
      read_sel : in std_logic; -- mi dice se posso leggere i_mem_data o meno
      --------------------- Uscite
      o_z0 : out std_logic_vector(7 downto 0);
      o_z1 : out std_logic_vector(7 downto 0);
      o_z2 : out std_logic_vector(7 downto 0);
      o_z3 : out std_logic_vector(7 downto 0)
      ---------------------
    );
  end component;

  signal bit_ctrl : std_logic_vector(1 downto 0);
  signal out_sel : std_logic_vector(1 downto 0);
  signal show_out : std_logic;
  signal read_sel : std_logic;
  ----------------------------
  type S is (S0, S1, S2, S3, S4, S5, S6, S7);
  signal cur_state, next_state : S;

begin
  DATAPATH1 : datapath_1 port map(
    i_clk,
    i_rst,
    i_w,
    bit_ctrl,
    o_mem_addr,
    out_sel
  );

  DATAPATH2 : datapath_2 port map(
    i_clk,
    i_rst,
    i_mem_data,
    out_sel,
    show_out,
    read_sel,
    o_z0,
    o_z1,
    o_z2,
    o_z3
  );
  process (i_clk, i_rst)
  begin
    if i_rst = '1' then
      cur_state <= S0;
    elsif rising_edge(i_clk) then
      cur_state <= next_state;
    end if;
  end process;

  process (cur_state, i_start)
  begin
    next_state <= cur_state;
    case cur_state is
      when S0 =>
        if i_start = '1' then
          next_state <= S1;
        end if;
      when S1 =>
        next_state <= S2;
      when S2 =>
        next_state <= S3;
      when S3 =>
        if i_start = '0' then
          next_state <= S4;
        end if;
      when S4 =>
        next_state <= S5;
      when S5 =>
        next_state <= S6;
      when S6 =>
        next_state <= S7;
      when S7 =>
        next_state <= S0;
    end case;
  end process;

  process (cur_state)
  begin
    bit_ctrl <= "00";
    o_mem_en <= '0';
    o_done <= '0';
    o_mem_we <= '0';
    o_mem_en <= '0';
    show_out <= '0';
    read_sel <= '0';

    case cur_state is
      when S0 =>
      when S1 =>
        bit_ctrl <= "00";
      when S2 =>
        bit_ctrl <= "01";
      when S3 =>
        bit_ctrl <= "10";
      when S4 =>
        o_mem_en <= '1';
        bit_ctrl <= "11";
      when S5 =>
        bit_ctrl <= "11";
        read_sel <= '1';
      when S6 =>
        bit_ctrl <= "11";
        show_out <= '1';
      when S7 =>
        o_done <= '1';
    end case;
  end process;
end Behavioral;

-----------------------------
--**************************-
-----------------------------

----------------------------
-- DATAPATH 1
----------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.all;
use IEEE.STD_LOGIC_UNSIGNED.all;

entity datapath_1 is
  port (
    i_clk : in std_logic; --Ingressi
    i_rst : in std_logic;
    i_w : in std_logic;
    bit_ctrl : in std_logic_vector(1 downto 0); -- La flag che mi dice se bit Zn o address (00 primo bit, 01 secondo, 10 address)
    ---------------------
    o_mem_addr : out std_logic_vector(15 downto 0);
    out_sel : out std_logic_vector(1 downto 0)
    ---------------------
  );
end datapath_1;

architecture Behavioral of datapath_1 is

  signal z_selector : std_logic_vector(1 downto 0); -- Ciò che mi seleziona tra Z0, Z1, Z2, Z3
  signal z_address : std_logic_vector(15 downto 0); -- I bit che poi estendo di segno
  signal tmp_i_w : std_logic;
begin
  -- Lettura dell'input i_w

  process(i_clk, i_rst)
  begin
    if (i_rst = '1') then
        tmp_i_w <= '0';
      elsif rising_edge(i_clk) then
        tmp_i_w <= i_w;
      end if;
  end process;
  
  process (i_clk, i_rst)
  begin
    if (i_rst = '1') then
      z_selector <= (others => '0');
      z_address <= (others => '0');

    elsif rising_edge(i_clk) then
      if (bit_ctrl = "00") then
        z_selector(1) <= tmp_i_w;
      elsif (bit_ctrl = "01") then
            z_selector(0) <= tmp_i_w;
      elsif (bit_ctrl = "10") then
          z_address(15 downto 1) <= z_address(14 downto 0);
          z_address(0) <= tmp_i_w;
      elsif (bit_ctrl = "11") then
          z_address <= (others => '0');
      end if;
    end if;

    out_sel <= z_selector;
    o_mem_addr <= z_address;

  end process;
end Behavioral;
----------------------------
-- DATAPATH 2
----------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.all;
use IEEE.STD_LOGIC_UNSIGNED.all;

entity datapath_2 is
  port (
    i_clk : in std_logic; --Ingressi
    i_rst : in std_logic;
    i_mem_data : in std_logic_vector(7 downto 0); -- valore proveniente dalla memoria
    out_sel : in std_logic_vector(1 downto 0); -- selettore che mi dice in quale delle quattro uscite farlo andare
    show_out : in std_logic;
    read_sel : in std_logic;
    --------------------- Uscite
    o_z0 : out std_logic_vector(7 downto 0);
    o_z1 : out std_logic_vector(7 downto 0);
    o_z2 : out std_logic_vector(7 downto 0);
    o_z3 : out std_logic_vector(7 downto 0)
    ---------------------
  );
end datapath_2;

architecture Behavioral of datapath_2 is
  signal s_z0 : std_logic_vector(7 downto 0);
  signal s_z1 : std_logic_vector(7 downto 0);
  signal s_z2 : std_logic_vector(7 downto 0);
  signal s_z3 : std_logic_vector(7 downto 0);

begin
  process (i_clk, i_rst)
  begin
    if i_rst = '1' then
      s_z0 <= (others => '0');
      s_z1 <= (others => '0');
      s_z2 <= (others => '0');
      s_z3 <= (others => '0');
      o_z0 <= (others => '0');
      o_z1 <= (others => '0');
      o_z2 <= (others => '0');
      o_z3 <= (others => '0');
    elsif rising_edge(i_clk) then
        if read_sel = '1' then
            if (out_sel = "00") then
                s_z0 <= i_mem_data;
            elsif (out_sel = "01") then
                s_z1 <= i_mem_data;
            elsif (out_sel = "10") then
                s_z2 <= i_mem_data;
            elsif (out_sel = "11") then
                s_z3 <= i_mem_data;
            end if;
        elsif show_out = '1' then
            o_z0 <= s_z0;
            o_z1 <= s_z1;
            o_z2 <= s_z2;
            o_z3 <= s_z3;
        else
            o_z0 <= (others => '0');
            o_z1 <= (others => '0');
            o_z2 <= (others => '0');
            o_z3 <= (others => '0');
        end if;
    end if;

  end process;
end Behavioral;