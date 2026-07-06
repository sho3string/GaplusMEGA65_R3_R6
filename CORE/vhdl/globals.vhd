----------------------------------------------------------------------------------
-- MiSTer2MEGA65 Framework
--
-- Global constants
--
-- MiSTer2MEGA65 done by sy2002 and MJoergen in 2022 and licensed under GPL v3
----------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

library work;
use work.qnice_tools.all;
use work.video_modes_pkg.all;

package globals is

----------------------------------------------------------------------------------------------------------
-- QNICE Firmware
----------------------------------------------------------------------------------------------------------

-- QNICE Firmware: Use the regular QNICE "operating system" called "Monitor" while developing and
-- debugging the firmware/ROM itself. If you are using the M2M ROM (the "Shell") as provided by the
-- framework, then always use the release version of the M2M firmware: QNICE_FIRMWARE_M2M
--
-- Hint: You need to run QNICE/tools/make-toolchain.sh to obtain "monitor.rom" and
-- you need to run CORE/m2m-rom/make_rom.sh to obtain the .rom file
constant QNICE_FIRMWARE_MONITOR   : string  := "../../../M2M/QNICE/monitor/monitor.rom";    -- debug/development
constant QNICE_FIRMWARE_M2M       : string  := "../../../CORE/m2m-rom/m2m-rom.rom";         -- release

-- Select firmware here
constant QNICE_FIRMWARE           : string  := QNICE_FIRMWARE_M2M;

----------------------------------------------------------------------------------------------------------
-- Clock Speed(s)
--
-- Important: Make sure that you use very exact numbers - down to the actual Hertz - because some cores
-- rely on these exact numbers. By default M2M supports one core clock speed. In case you need more,
-- then add all the clocks speeds here by adding more constants.
----------------------------------------------------------------------------------------------------------

-- @TODO: Your core's clock speed 
constant CORE_CLK_SPEED       : natural := 49_147_727;   -- @TODO YOURCORE expects 54 MHz

-- System clock speed (crystal that is driving the FPGA) and QNICE clock speed
-- !!! Do not touch !!!
constant BOARD_CLK_SPEED      : natural := 100_000_000;
constant QNICE_CLK_SPEED      : natural := 50_000_000;   -- a change here has dependencies in qnice_globals.vhd

----------------------------------------------------------------------------------------------------------
-- Video Mode
----------------------------------------------------------------------------------------------------------

-- Rendering constants (in pixels)
--    VGA_*   size of the core's target output post scandoubler
--    If in doubt, use twice the values found in this link:
--    https://mister-devel.github.io/MkDocs_MiSTer/advanced/nativeres/#arcade-core-default-native-resolutions
constant VGA_DX               : natural := 576;
constant VGA_DY               : natural := 448;

--    FONT_*  size of one OSM character
constant FONT_FILE            : string  := "../font/Anikki-16x16-m2m.rom";
constant FONT_DX              : natural := 16;
constant FONT_DY              : natural := 16;

-- Constants for the OSM screen memory
constant CHARS_DX             : natural := VGA_DX / FONT_DX;
constant CHARS_DY             : natural := VGA_DY / FONT_DY;
constant CHAR_MEM_SIZE        : natural := CHARS_DX * CHARS_DY;
constant VRAM_ADDR_WIDTH      : natural := f_log2(CHAR_MEM_SIZE);

----------------------------------------------------------------------------------------------------------
-- HyperRAM memory map (in units of 4kW)
----------------------------------------------------------------------------------------------------------

constant C_HMAP_M2M           : std_logic_vector(15 downto 0) := x"0000";     -- Reserved for the M2M framework
constant C_HMAP_DEMO          : std_logic_vector(15 downto 0) := x"0200";     -- Start address reserved for core

----------------------------------------------------------------------------------------------------------
-- Virtual Drive Management System
----------------------------------------------------------------------------------------------------------

-- example virtual drive handler, which is connected to nothing and only here to demo
-- the file- and directory browsing capabilities of the firmware
constant C_DEV_DEMO_VD        : std_logic_vector(15 downto 0) := x"0101";
constant C_DEV_DEMO_NOBUFFER  : std_logic_vector(15 downto 0) := x"AAAA";

-- Virtual drive management system (handled by vdrives.vhd and the firmware)
-- If you are not using virtual drives, make sure that:
--    C_VDNUM        is 0
--    C_VD_DEVICE    is x"EEEE"
--    C_VD_BUFFER    is (x"EEEE", x"EEEE")
-- Otherwise make sure that you wire C_VD_DEVICE in the qnice_ramrom_devices process and that you
-- have as many appropriately sized RAM buffers for disk images as you have drives
type vd_buf_array is array(natural range <>) of std_logic_vector;
constant C_VDNUM              : natural := 3;                                          -- amount of virtual drives; maximum is 15
constant C_VD_DEVICE          : std_logic_vector(15 downto 0) := C_DEV_DEMO_VD;        -- device number of vdrives.vhd device
constant C_VD_BUFFER          : vd_buf_array := (  C_DEV_DEMO_NOBUFFER,
                                                   C_DEV_DEMO_NOBUFFER,
                                                   C_DEV_DEMO_NOBUFFER,
                                                   x"EEEE");                           -- Always finish the array using x"EEEE"

----------------------------------------------------------------------------------------------------------
-- System for handling simulated cartridges and ROM loaders
----------------------------------------------------------------------------------------------------------

type crtrom_buf_array is array(natural range<>) of std_logic_vector;
constant ENDSTR : character := character'val(0);

-- Cartridges and ROMs can be stored into QNICE devices, HyperRAM and SDRAM
constant C_CRTROMTYPE_DEVICE     : std_logic_vector(15 downto 0) := x"0000";
constant C_CRTROMTYPE_HYPERRAM   : std_logic_vector(15 downto 0) := x"0001";
constant C_CRTROMTYPE_SDRAM      : std_logic_vector(15 downto 0) := x"0002";           -- @TODO/RESERVED for future R4 boards

-- Types of automatically loaded ROMs:
-- If a mandatory file is missing, then the core outputs the missing file and goes fatal
constant C_CRTROMTYPE_MANDATORY  : std_logic_vector(15 downto 0) := x"0003";
constant C_CRTROMTYPE_OPTIONAL   : std_logic_vector(15 downto 0) := x"0004";


-- Manually loadable ROMs and cartridges as defined in config.vhd
-- If you are not using this, then make sure that:
--    C_CRTROM_MAN_NUM    is 0
--    C_CRTROMS_MAN       is (x"EEEE", x"EEEE", x"EEEE")
-- Each entry of the array consists of two constants:
--    1) Type of CRT or ROM: Load to a QNICE device, load into HyperRAM, load into SDRAM
--    2) If (1) = QNICE device, then this is the device ID
--       else it is a 4k window in HyperRAM or in SDRAM
-- In case we are loading to a QNICE device, then the control and status register is located at the 4k window 0xFFFF.
-- @TODO: See @TODO for more details about the control and status register
constant C_CRTROMS_MAN_NUM       : natural := 0;                                       -- amount of manually loadable ROMs and carts; maximum is 16
constant C_CRTROMS_MAN           : crtrom_buf_array := ( x"EEEE", x"EEEE",
                                                         x"EEEE");                     -- Always finish the array using x"EEEE"

-- Automatically loaded ROMs: These ROMs are loaded before the core starts
--
-- Works similar to manually loadable ROMs and cartridges and each line item has two additional parameters:
--    1) and 2) see above
--    3) Mandatory or optional ROM
--    4) Start address of ROM file name within C_CRTROM_AUTO_NAMES
-- If you are not using this, then make sure that:
--    C_CRTROMS_AUTO_NUM  is 0
--    C_CRTROMS_AUTO      is (x"EEEE", x"EEEE", x"EEEE", x"EEEE", x"EEEE")
-- How to pass the filenames of the ROMs to the framework:
--    C_CRTROMS_AUTO_NAMES is a concatenation of all filenames (see config.vhd's WHS_DATA for an example of how to concatenate)
--    The start addresses of the filename can be determined similarly to how it is done in config.vhd's HELP_x_START
--    using a concatenated addition and VHDL's string length operator.
--    IMPORTANT: a) The framework is not doing any consistency or error check when it comes to C_CRTROMS_AUTO_NAMES, so you
--                  need to be extra careful that the string itself plus the start position of the namex are correct.
--               b) Don't forget to zero-terminate each of your substrings of C_CRTROMS_AUTO_NAMES by adding "& ENDSTR;"
--               c) Don't forget to finish the C_CRTROMS_AUTO array with x"EEEE"

constant C_DEV_GALP_CPU_ROM1         : std_logic_vector(15 downto 0) := x"0100";    -- gp2-4.8d
constant C_DEV_GALP_CPU_ROM2         : std_logic_vector(15 downto 0) := x"0101";    -- gp2-3b.8c
constant C_DEV_GALP_CPU_ROM3         : std_logic_vector(15 downto 0) := x"0102";    -- gp2-2b.8b
constant C_DEV_GALP_SUB2_ROM1        : std_logic_vector(15 downto 0) := x"0103";    -- gp2-1.4b
constant C_DEV_GALP_SUB_ROM1         : std_logic_vector(15 downto 0) := x"0104";    -- gp2-8.11d
constant C_DEV_GALP_SUB_ROM2         : std_logic_vector(15 downto 0) := x"0105";    -- gp2-7.11c
constant C_DEV_GALP_SUB_ROM3         : std_logic_vector(15 downto 0) := x"0106";    -- gp2-6.11b
constant C_DEV_GALP_GFX2_ROM1        : std_logic_vector(15 downto 0) := x"0107";    -- gp2-11.11p
constant C_DEV_GALP_GFX2_ROM2        : std_logic_vector(15 downto 0) := x"0108";    -- gp2-10.11n
constant C_DEV_GALP_GFX2_ROM3        : std_logic_vector(15 downto 0) := x"0109";    -- gp2-12.11r
constant C_DEV_GALP_GFX2_ROM4        : std_logic_vector(15 downto 0) := x"010A";    -- gp2-9.11m
constant C_DEV_GALP_GFX1_ROM1        : std_logic_vector(15 downto 0) := x"010B";    -- gp2-5.8
constant C_DEV_GALP_BANG             : std_logic_vector(15 downto 0) := x"010C";    -- bang_24ku8m.snd
constant C_DEV_GALP_PROM_SPRL        : std_logic_vector(15 downto 0) := x"010D";    -- gp2-6.6p
constant C_DEV_GALP_PROM_SPRH        : std_logic_vector(15 downto 0) := x"010E";    -- gp2-5.6n
constant C_DEV_GALP_PROM_CHAR        : std_logic_vector(15 downto 0) := x"010F";    -- gp2-7.6s
constant C_DEV_GALP_PROM_RED         : std_logic_vector(15 downto 0) := x"0110";    -- gp2-3.1p
constant C_DEV_GALP_PROM_GREEN       : std_logic_vector(15 downto 0) := x"0111";    -- gp2-1.1n
constant C_DEV_GALP_PROM_BLUE        : std_logic_vector(15 downto 0) := x"0112";    -- gp2-2.2n
constant C_DEV_GALP_PROM_WAVE        : std_logic_vector(15 downto 0) := x"0113";    -- gp2-4.3f

-- Galplus core specific ROMs
constant ROM1_MAIN_CPU1              : string  := "arcade/gaplus/gp2-4.8d"          & ENDSTR;  -- 6809 - main cpu
constant ROM2_MAIN_CPU1              : string  := "arcade/gaplus/gp2-3b.8c"         & ENDSTR;  -- 6809 - main cpu
constant ROM3_MAIN_CPU1              : string  := "arcade/gaplus/gp2-2b.8b"         & ENDSTR;  -- 6809 - main cpu
constant ROM1_SUB_CPU2               : string  := "arcade/gaplus/gp2-1.4b"          & ENDSTR;  -- 6809 - sub cpu 2
constant ROM1_SUB_CPU                : string  := "arcade/gaplus/gp2-8.11d"         & ENDSTR;  -- 6809 - sub cpu
constant ROM2_SUB_CPU                : string  := "arcade/gaplus/gp2-7.11c"         & ENDSTR;  -- 6809 - sub cpu
constant ROM3_SUB_CPU                : string  := "arcade/gaplus/gp2-6.11b"         & ENDSTR;  -- 6809 - sub cpu
constant ROM1_GFX2                   : string  := "arcade/gaplus/gp2-11.11p"        & ENDSTR;  -- Gfx 2
constant ROM2_GFX2                   : string  := "arcade/gaplus/gp2-10.11n"        & ENDSTR;  -- Gfx 2
constant ROM3_GFX2                   : string  := "arcade/gaplus/gp2-12.11r"        & ENDSTR;  -- Gfx 2
constant ROM4_GFX2                   : string  := "arcade/gaplus/gp2-9.11m"         & ENDSTR;  -- Gfx 2
constant ROM1_GFX1                   : string  := "arcade/gaplus/gp2-5.8s"          & ENDSTR;  -- Gfx 1
constant ROM_BANG                    : string  := "arcade/gaplus/bang_24ku8m.snd"   & ENDSTR;  -- Bang!
constant PROM_SPRITE_L               : string  := "arcade/gaplus/gp2-6.6p"          & ENDSTR;  -- Sprite color ROM - lower 4 bits
constant PROM_SPRITE_H               : string  := "arcade/gaplus/gp2-5.6n"          & ENDSTR;  -- Sprite color ROM - upper 4 bits
constant PROM_CHAR                   : string  := "arcade/gaplus/gp2-7.6s"          & ENDSTR;  -- Character color ROM
constant PROM_RED                    : string  := "arcade/gaplus/gp2-3.1p"          & ENDSTR;  -- Red palette prom 4 bits
constant PROM_GREEN                  : string  := "arcade/gaplus/gp2-1.1n"          & ENDSTR;  -- Green palette prom 4 bits
constant PROM_BLUE                   : string  := "arcade/gaplus/gp2-2.2n"          & ENDSTR;  -- Blue palette prom 4 bits
constant PROM_WAVE                   : string  := "arcade/gaplus/gp2-4.3f"          & ENDSTR;  -- Sound prom

constant CPU_ROM1_MAIN_START      : std_logic_vector(15 downto 0) := X"0000";
constant CPU_ROM2_MAIN_START      : std_logic_vector(15 downto 0) := std_logic_vector(to_unsigned(to_integer(unsigned(CPU_ROM1_MAIN_START)) + ROM1_MAIN_CPU1'length, 16));
constant CPU_ROM3_MAIN_START      : std_logic_vector(15 downto 0) := std_logic_vector(to_unsigned(to_integer(unsigned(CPU_ROM2_MAIN_START)) + ROM2_MAIN_CPU1'length, 16));
constant SUB2_ROM1_MAIN_START     : std_logic_vector(15 downto 0) := std_logic_vector(to_unsigned(to_integer(unsigned(CPU_ROM3_MAIN_START)) + ROM3_MAIN_CPU1'length, 16));
constant SUB_ROM1_MAIN_START      : std_logic_vector(15 downto 0) := std_logic_vector(to_unsigned(to_integer(unsigned(SUB2_ROM1_MAIN_START))+ ROM1_SUB_CPU2'length, 16));
constant SUB_ROM2_MAIN_START      : std_logic_vector(15 downto 0) := std_logic_vector(to_unsigned(to_integer(unsigned(SUB_ROM1_MAIN_START)) + ROM1_SUB_CPU'length, 16));
constant SUB_ROM3_MAIN_START      : std_logic_vector(15 downto 0) := std_logic_vector(to_unsigned(to_integer(unsigned(SUB_ROM2_MAIN_START)) + ROM2_SUB_CPU'length, 16));
constant GFX2_ROM1_MAIN_START     : std_logic_vector(15 downto 0) := std_logic_vector(to_unsigned(to_integer(unsigned(SUB_ROM3_MAIN_START))+  ROM3_SUB_CPU'length, 16));
constant GFX2_ROM2_MAIN_START     : std_logic_vector(15 downto 0) := std_logic_vector(to_unsigned(to_integer(unsigned(GFX2_ROM1_MAIN_START))+ ROM1_GFX2'length, 16));
constant GFX2_ROM3_MAIN_START     : std_logic_vector(15 downto 0) := std_logic_vector(to_unsigned(to_integer(unsigned(GFX2_ROM2_MAIN_START))+ ROM2_GFX2'length, 16));
constant GFX2_ROM4_MAIN_START     : std_logic_vector(15 downto 0) := std_logic_vector(to_unsigned(to_integer(unsigned(GFX2_ROM3_MAIN_START))+ ROM3_GFX2'length, 16));
constant GFX1_ROM1_MAIN_START     : std_logic_vector(15 downto 0) := std_logic_vector(to_unsigned(to_integer(unsigned(GFX2_ROM4_MAIN_START))+ ROM4_GFX2'length, 16));
constant BANG_START               : std_logic_vector(15 downto 0) := std_logic_vector(to_unsigned(to_integer(unsigned(GFX1_ROM1_MAIN_START))+ ROM1_GFX1'length, 16));
constant SPRITEL_PROM_START       : std_logic_vector(15 downto 0) := std_logic_vector(to_unsigned(to_integer(unsigned(BANG_START))          + ROM_BANG'length, 16));
constant SPRITEH_PROM_START       : std_logic_vector(15 downto 0) := std_logic_vector(to_unsigned(to_integer(unsigned(SPRITEL_PROM_START))  + PROM_SPRITE_L'length, 16));
constant CHAR_PROM_START          : std_logic_vector(15 downto 0) := std_logic_vector(to_unsigned(to_integer(unsigned(SPRITEH_PROM_START))  + PROM_SPRITE_H'length, 16));
constant RED_PROM_START           : std_logic_vector(15 downto 0) := std_logic_vector(to_unsigned(to_integer(unsigned(CHAR_PROM_START))     + PROM_CHAR 'length, 16));
constant GREEN_PROM_START         : std_logic_vector(15 downto 0) := std_logic_vector(to_unsigned(to_integer(unsigned(RED_PROM_START))      + PROM_RED'length, 16));
constant BLUE_PROM_START          : std_logic_vector(15 downto 0) := std_logic_vector(to_unsigned(to_integer(unsigned(GREEN_PROM_START))    + PROM_GREEN'length, 16));
constant WAVE_PROM_START          : std_logic_vector(15 downto 0) := std_logic_vector(to_unsigned(to_integer(unsigned(BLUE_PROM_START))     + PROM_BLUE'length, 16));

-- M2M framework constants
constant C_CRTROMS_AUTO_NUM      : natural := 20; -- Amount of automatically loadable ROMs and carts, if more tha    n 3: also adjust CRTROM_MAN_MAX in M2M/rom/shell_vars.asm, Needs to be in sync with config.vhd. Maximum is 16
constant C_CRTROMS_AUTO_NAMES    : string  := ROM1_MAIN_CPU1 & ROM2_MAIN_CPU1 & ROM3_MAIN_CPU1 & 
                                              ROM1_SUB_CPU2 &
                                              ROM1_SUB_CPU & ROM2_SUB_CPU & ROM3_SUB_CPU &
                                              ROM1_GFX2 & ROM2_GFX2 & ROM3_GFX2 & ROM4_GFX2 &
                                              ROM1_GFX1 &
                                              ROM_BANG &
                                              PROM_SPRITE_L & PROM_SPRITE_H &
                                              PROM_CHAR &
                                              PROM_RED & PROM_GREEN & PROM_BLUE &
                                              PROM_WAVE &
                                              ENDSTR;

constant C_CRTROMS_AUTO          : crtrom_buf_array := ( 
      C_CRTROMTYPE_DEVICE, C_DEV_GALP_CPU_ROM1, C_CRTROMTYPE_MANDATORY, CPU_ROM1_MAIN_START,
      C_CRTROMTYPE_DEVICE, C_DEV_GALP_CPU_ROM2, C_CRTROMTYPE_MANDATORY, CPU_ROM2_MAIN_START,
      C_CRTROMTYPE_DEVICE, C_DEV_GALP_CPU_ROM3, C_CRTROMTYPE_MANDATORY, CPU_ROM3_MAIN_START,
      C_CRTROMTYPE_DEVICE, C_DEV_GALP_SUB2_ROM1,C_CRTROMTYPE_MANDATORY, SUB2_ROM1_MAIN_START,
      C_CRTROMTYPE_DEVICE, C_DEV_GALP_SUB_ROM1, C_CRTROMTYPE_MANDATORY, SUB_ROM1_MAIN_START,
      C_CRTROMTYPE_DEVICE, C_DEV_GALP_SUB_ROM2, C_CRTROMTYPE_MANDATORY, SUB_ROM2_MAIN_START,
      C_CRTROMTYPE_DEVICE, C_DEV_GALP_SUB_ROM3, C_CRTROMTYPE_MANDATORY, SUB_ROM3_MAIN_START,
      C_CRTROMTYPE_DEVICE, C_DEV_GALP_GFX2_ROM1,C_CRTROMTYPE_MANDATORY, GFX2_ROM1_MAIN_START,  
      C_CRTROMTYPE_DEVICE, C_DEV_GALP_GFX2_ROM2,C_CRTROMTYPE_MANDATORY, GFX2_ROM2_MAIN_START,  
      C_CRTROMTYPE_DEVICE, C_DEV_GALP_GFX2_ROM3,C_CRTROMTYPE_MANDATORY, GFX2_ROM3_MAIN_START,  
      C_CRTROMTYPE_DEVICE, C_DEV_GALP_GFX2_ROM4,C_CRTROMTYPE_MANDATORY, GFX2_ROM4_MAIN_START,
      C_CRTROMTYPE_DEVICE, C_DEV_GALP_GFX1_ROM1,C_CRTROMTYPE_MANDATORY, GFX1_ROM1_MAIN_START,      
      C_CRTROMTYPE_DEVICE, C_DEV_GALP_BANG,     C_CRTROMTYPE_MANDATORY, BANG_START,    
      C_CRTROMTYPE_DEVICE, C_DEV_GALP_PROM_SPRL,C_CRTROMTYPE_MANDATORY, SPRITEL_PROM_START,
      C_CRTROMTYPE_DEVICE, C_DEV_GALP_PROM_SPRH,C_CRTROMTYPE_MANDATORY, SPRITEH_PROM_START,
      C_CRTROMTYPE_DEVICE, C_DEV_GALP_PROM_CHAR,C_CRTROMTYPE_MANDATORY, CHAR_PROM_START,  
      C_CRTROMTYPE_DEVICE, C_DEV_GALP_PROM_RED, C_CRTROMTYPE_MANDATORY, RED_PROM_START,
      C_CRTROMTYPE_DEVICE, C_DEV_GALP_PROM_GREEN,C_CRTROMTYPE_MANDATORY,GREEN_PROM_START,
      C_CRTROMTYPE_DEVICE, C_DEV_GALP_PROM_BLUE,C_CRTROMTYPE_MANDATORY, BLUE_PROM_START,  
      C_CRTROMTYPE_DEVICE, C_DEV_GALP_PROM_WAVE,C_CRTROMTYPE_MANDATORY, WAVE_PROM_START,
                                                         x"EEEE");                     -- Always finish the array using x"EEEE"

----------------------------------------------------------------------------------------------------------
-- Audio filters
--
-- If you use audio filters, then you need to copy the correct values from the MiSTer core
-- that you are porting: sys/sys_top.v
----------------------------------------------------------------------------------------------------------

-- Sample values from the C64: @TODO: Adjust to your needs
constant audio_flt_rate : std_logic_vector(31 downto 0) := std_logic_vector(to_signed(7056000, 32));
constant audio_cx       : std_logic_vector(39 downto 0) := std_logic_vector(to_signed(4258969, 40));
constant audio_cx0      : std_logic_vector( 7 downto 0) := std_logic_vector(to_signed(3, 8));
constant audio_cx1      : std_logic_vector( 7 downto 0) := std_logic_vector(to_signed(2, 8));
constant audio_cx2      : std_logic_vector( 7 downto 0) := std_logic_vector(to_signed(1, 8));
constant audio_cy0      : std_logic_vector(23 downto 0) := std_logic_vector(to_signed(-6216759, 24));
constant audio_cy1      : std_logic_vector(23 downto 0) := std_logic_vector(to_signed( 6143386, 24));
constant audio_cy2      : std_logic_vector(23 downto 0) := std_logic_vector(to_signed(-2023767, 24));
constant audio_att      : std_logic_vector( 4 downto 0) := "00000";
constant audio_mix      : std_logic_vector( 1 downto 0) := "00"; -- 0 - no mix, 1 - 25%, 2 - 50%, 3 - 100% (mono)

end package globals;