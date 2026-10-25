----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 09/21/2026 11:28:23 AM
-- Design Name: 
-- Module Name: TopModule - Behavioral
-- Project Name: 
-- Target Devices: 
-- Tool Versions: 
-- Description: 
-- 
-- Dependencies: 
-- 
-- Revision:
-- Revision 0.01 - File Created
-- Additional Comments:
-- 
----------------------------------------------------------------------------------


library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity TopModule is
    Port ( 
           clock : in STD_LOGIC;
           reset : in STD_LOGIC;
           inputSignal : in std_logic_vector (13 downto 0);
           referenceSignal : in std_logic_vector (13 downto 0);
           outputAmplitude : out std_logic_vector (13 downto 0);
           outputPhaseDiff : out std_logic_vector (13 downto 0)
           );
end TopModule;

architecture Behavioral of TopModule is

----------------------------------Components--------------------------------------
COMPONENT DDS
  PORT (
    aclk : IN STD_LOGIC;
    aresetn : IN STD_LOGIC;
    m_axis_data_tvalid : OUT STD_LOGIC;
    m_axis_data_tdata : OUT STD_LOGIC_VECTOR(31 DOWNTO 0);
    m_axis_phase_tvalid : OUT STD_LOGIC;
    m_axis_phase_tdata : OUT STD_LOGIC_VECTOR(23 DOWNTO 0)
  );
END COMPONENT;

COMPONENT CIC_Filter
  PORT (
    aclk : IN STD_LOGIC;
    aresetn : IN STD_LOGIC;
    s_axis_data_tdata : IN STD_LOGIC_VECTOR(15 DOWNTO 0);
    s_axis_data_tvalid : IN STD_LOGIC;
    s_axis_data_tready : OUT STD_LOGIC;
    m_axis_data_tdata : OUT STD_LOGIC_VECTOR(31 DOWNTO 0);
    m_axis_data_tvalid : OUT STD_LOGIC
  );
END COMPONENT;

COMPONENT CORDIC
  PORT (
    aclk : IN STD_LOGIC;
    aresetn : IN STD_LOGIC;
    s_axis_cartesian_tvalid : IN STD_LOGIC;
    s_axis_cartesian_tdata : IN STD_LOGIC_VECTOR(63 DOWNTO 0);
    m_axis_dout_tvalid : OUT STD_LOGIC;
    m_axis_dout_tdata : OUT STD_LOGIC_VECTOR(63 DOWNTO 0)
  );
END COMPONENT;
--------------------------------------------------------------------------------
constant number_1 : signed (13 downto 0) := to_signed(4295, 14); -- +1.048576 with 12 fractional bits (s.1.12)
--signal input_buf : signed (13 downto 0) := (others =>'0');
signal notReset : std_logic;
signal amplitudeBuf : signed (38 downto 0) := (others =>'0');
signal DDS_output_data : std_logic_vector (31 downto 0) := (others =>'0');
signal cos_DDS : signed (13 downto 0) := (others =>'0');
signal sin_DDS : signed (13 downto 0) := (others =>'0');
signal DDS_Output_Valid : std_logic;
signal mixer_signal_i : signed (27 downto 0) := (others =>'0');
signal mixer_signal_q : signed (27 downto 0) := (others =>'0');
signal mixer_signal_i_scaled : signed (13 downto 0) := (others =>'0');
signal mixer_signal_q_scaled : signed (13 downto 0) := (others =>'0');
signal mixer_ref_i : signed (27 downto 0) := (others =>'0');
signal mixer_ref_q : signed (27 downto 0) := (others =>'0');
signal mixer_ref_i_scaled : signed (13 downto 0) := (others =>'0');
signal mixer_ref_q_scaled : signed (13 downto 0) := (others =>'0');

signal cic_sig_i_in  : std_logic_vector (15 downto 0) := (others =>'0');
signal cic_sig_i_out : std_logic_vector (31 downto 0) := (others =>'0');
signal cic_sig_i_valid : std_logic;
signal cic_sig_q_in  : std_logic_vector (15 downto 0) := (others =>'0');
signal cic_sig_q_out : std_logic_vector (31 downto 0) := (others =>'0');
signal cic_sig_q_valid : std_logic;
signal cic_ref_i_in  : std_logic_vector (15 downto 0) := (others =>'0');
signal cic_ref_i_out : std_logic_vector (31 downto 0) := (others =>'0');
signal cic_ref_i_valid : std_logic;
signal cic_ref_q_in  : std_logic_vector (15 downto 0) := (others =>'0');
signal cic_ref_q_out : std_logic_vector (31 downto 0) := (others =>'0');
signal cic_ref_q_valid : std_logic;

signal cordic_sig_input : std_logic_vector (63 downto 0) := (others =>'0');
signal cordic_sig_output : std_logic_vector (63 downto 0) := (others =>'0');
signal cordic_sig_out_valid : std_logic;
signal cordic_sig_in_valid : std_logic;
signal cordic_ref_input : std_logic_vector (63 downto 0) := (others =>'0');
signal cordic_ref_output : std_logic_vector (63 downto 0) := (others =>'0');
signal cordic_ref_out_valid : std_logic;
signal cordic_ref_in_valid : std_logic;

signal phaseSignal : signed (30 downto 0) := (others =>'0');
signal phaseRef : signed (30 downto 0) := (others =>'0');

signal inputSignal_Buf : signed (13 downto 0) := (others =>'0');
signal referenceSignal_Buf : signed (13 downto 0) := (others =>'0');


begin

------------------------------instantiations----------------------------------------
DDS_1 : DDS
  PORT MAP (
    aclk => clock,
    aresetn => notReset,
    m_axis_data_tvalid => DDS_Output_Valid,
    m_axis_data_tdata => DDS_output_data,
    m_axis_phase_tvalid => open,
    m_axis_phase_tdata => open
  );


CIC_1 : CIC_Filter
  PORT MAP (
    aclk => clock,
    aresetn =>notReset,
    s_axis_data_tdata => cic_sig_i_in,
    s_axis_data_tvalid => DDS_Output_Valid,
    s_axis_data_tready => open,
    m_axis_data_tdata => cic_sig_i_out,
    m_axis_data_tvalid => cic_sig_i_valid
  );

CIC_2 : CIC_Filter
  PORT MAP (
    aclk => clock,
    aresetn =>notReset,
    s_axis_data_tdata => cic_sig_q_in,
    s_axis_data_tvalid => DDS_Output_Valid,
    s_axis_data_tready => open,
    m_axis_data_tdata => cic_sig_q_out,
    m_axis_data_tvalid => cic_sig_q_valid
  );

CIC_3 : CIC_Filter
  PORT MAP (
    aclk => clock,
    aresetn =>notReset,
    s_axis_data_tdata => cic_ref_i_in,
    s_axis_data_tvalid => DDS_Output_Valid,
    s_axis_data_tready => open,
    m_axis_data_tdata => cic_ref_i_out,
    m_axis_data_tvalid => cic_ref_i_valid
  );

CIC_4 : CIC_Filter
  PORT MAP (
    aclk => clock,
    aresetn =>notReset,
    s_axis_data_tdata => cic_ref_q_in,
    s_axis_data_tvalid => DDS_Output_Valid,
    s_axis_data_tready => open,
    m_axis_data_tdata => cic_ref_q_out,
    m_axis_data_tvalid => cic_ref_q_valid
  );


CORDIC_1 : CORDIC
  PORT MAP (
    aclk => clock,
    aresetn =>notReset,
    s_axis_cartesian_tvalid => cordic_sig_in_valid,
    s_axis_cartesian_tdata => cordic_sig_input,
    m_axis_dout_tvalid => cordic_sig_out_valid,
    m_axis_dout_tdata => cordic_sig_output
  );

CORDIC_2 : CORDIC
  PORT MAP (
    aclk => clock,
    aresetn =>notReset,
    s_axis_cartesian_tvalid => cordic_ref_in_valid,
    s_axis_cartesian_tdata => cordic_ref_input,
    m_axis_dout_tvalid => cordic_ref_out_valid,
    m_axis_dout_tdata => cordic_ref_output
  );
--------------------------------------------------------------------------------

notReset <= not reset;
cos_DDS               <= signed(DDS_output_data(13 downto 0));
sin_DDS               <= signed(DDS_output_data(29 downto 16));
mixer_signal_i_scaled <= mixer_signal_i (26 downto 13);
mixer_signal_q_scaled <= mixer_signal_q (26 downto 13);
mixer_ref_i_scaled    <= mixer_ref_i (26 downto 13);
mixer_ref_q_scaled    <= mixer_ref_q (26 downto 13);
cic_sig_i_in          <= std_logic_vector(resize(mixer_signal_i_scaled,16));
cic_sig_q_in          <= std_logic_vector(resize(mixer_signal_q_scaled,16));
cic_ref_i_in          <= std_logic_vector(resize(mixer_ref_i_scaled,16));
cic_ref_q_in          <= std_logic_vector(resize(mixer_ref_q_scaled,16));
cordic_sig_input      <= cic_sig_q_out & cic_sig_i_out;
cordic_ref_input      <= cic_ref_q_out & cic_ref_i_out;
cordic_sig_in_valid   <= cic_sig_i_valid and cic_sig_q_valid;
cordic_ref_in_valid   <= cic_ref_i_valid and cic_ref_q_valid;






process (clock) begin
if rising_edge (clock) then
if (reset='1') then
    mixer_signal_i<=(others =>'0');
    mixer_signal_q<=(others =>'0');
    mixer_ref_i<=(others =>'0');
    mixer_ref_q<=(others =>'0');
    amplitudeBuf<=(others =>'0');
    phaseSignal<=(others =>'0');
    phaseRef<=(others =>'0');
    outputPhaseDiff<=(others =>'0');
    outputAmplitude<=(others =>'0');
    inputSignal_Buf <= (others =>'0');
    referenceSignal_Buf <= (others =>'0');
else
    inputSignal_Buf <= signed(inputSignal);
    referenceSignal_Buf <= signed(referenceSignal);
    outputPhaseDiff <= std_logic_vector(phaseSignal(30 downto 17) - phaseRef(30 downto 17));
    outputAmplitude <= std_logic_vector(amplitudeBuf(35 downto 22));
    mixer_signal_i <=  inputSignal_Buf     * cos_DDS;
    mixer_signal_q <=-(inputSignal_Buf     * sin_DDS); 
    mixer_ref_i    <=  referenceSignal_Buf * cos_DDS;
    mixer_ref_q    <=-(referenceSignal_Buf * sin_DDS);

    if (cordic_sig_out_valid = '1') then
        phaseSignal     <= signed(cordic_sig_output(62 downto 32));
        amplitudeBuf    <= signed(cordic_sig_output(30 downto 6)) * number_1;
    end if;

    if (cordic_ref_out_valid = '1') then
        phaseRef        <= signed(cordic_ref_output(62 downto 32));
    end if;

 
end if;
end if;
end process;
    

end Behavioral;