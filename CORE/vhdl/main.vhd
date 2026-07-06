----------------------------------------------------------------------------------
-- MiSTer2MEGA65 Framework
--
-- Wrapper for the MiSTer core that runs exclusively in the core's clock domanin
--
-- MiSTer2MEGA65 done by sy2002 and MJoergen in 2022 and licensed under GPL v3
----------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;
use work.video_modes_pkg.all;

entity main is
   generic (
      G_VDNUM                 : natural                     -- amount of virtual drives
   );
   port (
      clk_main_i              : in  std_logic;
      reset_soft_i            : in  std_logic;
      reset_hard_i            : in  std_logic;
      pause_i                 : in  std_logic;

      -- MiSTer core main clock speed:
      -- Make sure you pass very exact numbers here, because they are used for avoiding clock drift at derived clocks
      clk_main_speed_i        : in  natural;

      -- Video output
      video_ce_o              : out std_logic;
      video_ce_ovl_o          : out std_logic;
      video_red_o             : out std_logic_vector(3 downto 0);
      video_green_o           : out std_logic_vector(3 downto 0);
      video_blue_o            : out std_logic_vector(3 downto 0);
      video_vs_o              : out std_logic;
      video_hs_o              : out std_logic;
      video_hblank_o          : out std_logic;
      video_vblank_o          : out std_logic;

      -- Audio output (Signed PCM)
      audio_left_o            : out signed(15 downto 0);
      audio_right_o           : out signed(15 downto 0);

      -- M2M Keyboard interface
      kb_key_num_i            : in  integer range 0 to 79;    -- cycles through all MEGA65 keys
      kb_key_pressed_n_i      : in  std_logic;                -- low active: debounced feedback: is kb_key_num_i pressed right now?

      -- MEGA65 joysticks and paddles/mouse/potentiometers
      joy_1_up_n_i            : in  std_logic;
      joy_1_down_n_i          : in  std_logic;
      joy_1_left_n_i          : in  std_logic;
      joy_1_right_n_i         : in  std_logic;
      joy_1_fire_n_i          : in  std_logic;

      joy_2_up_n_i            : in  std_logic;
      joy_2_down_n_i          : in  std_logic;
      joy_2_left_n_i          : in  std_logic;
      joy_2_right_n_i         : in  std_logic;
      joy_2_fire_n_i          : in  std_logic;

      pot1_x_i                : in  std_logic_vector(7 downto 0);
      pot1_y_i                : in  std_logic_vector(7 downto 0);
      pot2_x_i                : in  std_logic_vector(7 downto 0);
      pot2_y_i                : in  std_logic_vector(7 downto 0);
      
      -- Dipswitches
      dsw_a_i                 : in  std_logic_vector(7 downto 0);
      dsw_b_i                 : in  std_logic_vector(7 downto 0);
      dsw_c_i                 : in  std_logic_vector(7 downto 0);
      dn_clk_i                : in  std_logic;
      dn_addr_i               : in  std_logic_vector(24 downto 0);
      dn_data_i               : in  std_logic_vector(7 downto 0);
      dn_wr_i                 : in  std_logic;
      
      qnice_dev_id_o          : out std_logic_vector(15 downto 0);
      osm_control_i           : in  std_logic_vector(255 downto 0)
       
   );
end entity main;


architecture synthesis of main is

signal keyboard_n        : std_logic_vector(79 downto 0);
signal pause_cpu         : std_logic;
signal status            : signed(31 downto 0);
signal flip              : std_logic := '0';
signal video_rotated     : std_logic;
signal direct_video      : std_logic;
signal forced_scandoubler: std_logic;
signal gamma_bus         : std_logic_vector(21 downto 0);
signal options           : std_logic_vector(1 downto 0);
signal reset             : std_logic  := reset_hard_i or reset_soft_i;

signal PCLK_EN           : std_logic;
signal HPOS,VPOS         : std_logic_vector(8 downto 0);
signal POUT              : std_logic_vector(11 downto 0);
signal oRGB              : std_logic_vector(11 downto 0);
signal HOFFS             : std_logic_vector(4 downto 0);
signal VOFFS             : std_logic_vector(2 downto 0);

-- Game player inputs
constant m65_1           : integer := 56; --Player 1 Start
constant m65_2           : integer := 59; --Player 2 Start
constant m65_5           : integer := 16; --Insert coin 1
constant m65_6           : integer := 19; --Insert coin 2

-- Offer some keyboard controls in addition to Joy 1 Controls
constant m65_a           : integer := 10; -- Player fire
constant m65_s           : integer := 13; --Service Button ( inserts credits )
constant m65_left_crsr   : integer := 74; -- cursor left
constant m65_horz_crsr   : integer := 2;  -- means cursor right in C64 terminology
constant m65_up_crsr     : integer := 73; -- cursor up
constant m65_vert_crsr   : integer := 7;  -- means cursor down in C64 terminology
constant m65_help        : integer := 67; --Help key

constant C_MENU_FLIP       : natural := 9;
constant C_MENU_GAPLUS_H1  : integer := 32;
constant C_MENU_GAPLUS_H2  : integer := 33;
constant C_MENU_GAPLUS_H4  : integer := 34;
constant C_MENU_GAPLUS_H8  : integer := 35;
constant C_MENU_GAPLUS_H16 : integer := 36;
constant C_MENU_GAPLUS_V1  : integer := 42;
constant C_MENU_GAPLUS_V2  : integer := 43;
constant C_MENU_GAPLUS_V4  : integer := 44;

-- Game inputs
signal m_start2  : std_logic := not keyboard_n(m65_2);
signal m_start1  : std_logic := not keyboard_n(m65_1);
signal m_coin1   : std_logic := not keyboard_n(m65_5);
signal m_coin2   : std_logic := not keyboard_n(m65_6);
signal m_trig11  : std_logic := not joy_1_fire_n_i or not keyboard_n(m65_a);
signal m_down1   : std_logic := not joy_1_down_n_i or not keyboard_n(m65_vert_crsr);
signal m_up1     : std_logic := not joy_1_up_n_i or not keyboard_n(m65_up_crsr);
signal m_right1  : std_logic := not joy_1_right_n_i or not keyboard_n(m65_horz_crsr);
signal m_left1   : std_logic := not joy_1_left_n_i or not keyboard_n(m65_left_crsr);
signal m_trig21  : std_logic := not joy_2_fire_n_i or not keyboard_n(m65_a);
signal m_down2   : std_logic := not joy_2_down_n_i or not keyboard_n(m65_vert_crsr);
signal m_up2     : std_logic := not joy_2_up_n_i or not keyboard_n(m65_up_crsr);
signal m_right2  : std_logic := not joy_2_right_n_i or not keyboard_n(m65_horz_crsr);
signal m_left2   : std_logic := not joy_2_left_n_i or not keyboard_n(m65_left_crsr);

signal INP0      : std_logic_vector(4 downto 0) := m_trig11 & m_left1 & m_down1 & m_right1 & m_up1;
signal INP1      : std_logic_vector(4 downto 0) := m_trig21 & m_left2 & m_down2 & m_right2 & m_up2;
signal INP2      : std_logic_vector(2 downto 0) := (m_coin1 or m_coin2) & m_start2 & m_start1;

signal oSND      : std_logic_vector(7 downto 0);
signal AOUT      : std_logic_vector(15 downto 0);

begin

    flip <= osm_control_i(C_MENU_FLIP);
    
    AOUT <= oSND & "00000000";
    audio_left_o(15) <= not AOUT(15);
    audio_left_o(14 downto 0) <= signed(AOUT(14 downto 0));
    audio_right_o(15) <= audio_left_o(15);
    audio_right_o(14 downto 0) <= audio_left_o(14 downto 0);
  
     -- video
    PCLK_EN     <=  video_ce_o;
    oRGB        <=  video_blue_o & video_green_o & video_red_o;

     -- video VGA offsets
    HOFFS <=   osm_control_i(C_MENU_GAPLUS_H16)  &
               osm_control_i(C_MENU_GAPLUS_H8)   &
               osm_control_i(C_MENU_GAPLUS_H4)   &
               osm_control_i(C_MENU_GAPLUS_H2)   &
               osm_control_i(C_MENU_GAPLUS_H1);
               
    VOFFS <=   osm_control_i(C_MENU_GAPLUS_V4)   &
               osm_control_i(C_MENU_GAPLUS_V2)   &
               osm_control_i(C_MENU_GAPLUS_V1);
    
    i_hvgen : entity work.hvgen
      port map (
         HPOS       => HPOS,
         VPOS       => VPOS,
         PCLK       => PCLK_EN,
         iRGB       => POUT,
         oRGB       => oRGB,
         HBLK       => video_hblank_o,
         VBLK       => video_vblank_o,
         HSYN       => video_hs_o,
         VSYN       => video_vs_o
     );
     
     Gamecore : entity work.fpga_gaplus
     port map (
     
        RESET   => reset,
        MCLK    => clk_main_i,
        PH      => HPOS,
        PV      => VPOS,
        PCLK    => PCLK_EN,
        POUT    => POUT,
        SOUT    => oSND,
        INP0    => INP0,
	    INP1    => INP1,
	    INP2    => INP2,
	    DSW0    => dsw_a_i,
	    DSW1    => dsw_b_i,
	    DSW2    => dsw_c_i,
	    ROMCL   => dn_clk_i,
	    ROMAD   => dn_addr_i(17 downto 0),
	    ROMDT   => dn_data_i,
	    ROMEN   => dn_wr_i
	    
     );

    i_keyboard : entity work.keyboard
      port map (
         clk_main_i           => clk_main_i,
    
         -- Interface to the MEGA65 keyboard
         key_num_i            => kb_key_num_i,
         key_pressed_n_i      => kb_key_pressed_n_i,
    
         -- @TODO: Create the kind of keyboard output that your core needs
         -- "example_n_o" is a low active register and used by the demo core:
         --    bit 0: Space
         --    bit 1: Return
         --    bit 2: Run/Stop
         example_n_o          => keyboard_n
      ); -- i_keyboard
      
end architecture synthesis;