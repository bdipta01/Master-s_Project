###############################################################################
# Constraints File for ChipTop (Chipyard RISC-V SoC)
# Technology : FreePDK45 / NangateOpenCellLibrary
# Created for: Design Vision / Design Compiler Power Analysis
#
# IMPORTANT: Default clock frequency is 100 MHz (10ns period)
#            Change the period values if your target frequency is different:
#            - 500 MHz  → period = 2
#            - 1 GHz    → period = 1
###############################################################################

###############################################################################
# 1. OPERATING CONDITIONS
###############################################################################
set_operating_conditions "typical" -library "NangateOpenCellLibrary_typical_ccs"

###############################################################################
# 2. CLOCK DEFINITIONS
###############################################################################

# --- Main uncore clock (100 MHz = 10ns period) ---
create_clock -period 10 \
             -name   clk_uncore \
             -waveform {0 5} \
             [get_ports clock_uncore]

# --- Serial TileLink clock (50 MHz = 20ns, half of main clock) ---
create_clock -period 20 \
             -name   clk_serial \
             -waveform {0 10} \
             [get_ports serial_tl_0_clock_in]

# --- AXI4 memory clock is an OUTPUT (driven by chip, not input) ---
# No create_clock needed for axi4_mem_0_clock

###############################################################################
# 3. CLOCK UNCERTAINTY & TRANSITION
###############################################################################
set_clock_uncertainty 0.1 [get_clocks clk_uncore]
set_clock_uncertainty 0.1 [get_clocks clk_serial]

set_clock_transition  0.05 [get_clocks clk_uncore]
set_clock_transition  0.05 [get_clocks clk_serial]

###############################################################################
# 4. RESET & BOOT INPUT DELAYS
###############################################################################
set_input_delay 2.0 -clock clk_uncore [get_ports reset_io]

# custom_boot is a static config pin - treat as async (false path)
set_false_path -from [get_ports custom_boot]

###############################################################################
# 5. UART PORT DELAYS
###############################################################################
set_input_delay  2.0 -clock clk_uncore [get_ports uart_0_rxd]
set_output_delay 2.0 -clock clk_uncore [get_ports uart_0_txd]

###############################################################################
# 6. AXI4 MEMORY INTERFACE DELAYS
#    Inputs  = signals coming INTO ChipTop from memory
#    Outputs = signals going OUT of ChipTop to memory
###############################################################################

# AXI4 Write Address Channel (AW) - outputs
set_output_delay 2.0 -clock clk_uncore [get_ports axi4_mem_0_bits_aw_valid]
set_output_delay 2.0 -clock clk_uncore [get_ports axi4_mem_0_bits_aw_bits_*]
set_input_delay  2.0 -clock clk_uncore [get_ports axi4_mem_0_bits_aw_ready]

# AXI4 Write Data Channel (W) - outputs
set_output_delay 2.0 -clock clk_uncore [get_ports axi4_mem_0_bits_w_valid]
set_output_delay 2.0 -clock clk_uncore [get_ports axi4_mem_0_bits_w_bits_*]
set_input_delay  2.0 -clock clk_uncore [get_ports axi4_mem_0_bits_w_ready]

# AXI4 Write Response Channel (B) - inputs
set_input_delay  2.0 -clock clk_uncore [get_ports axi4_mem_0_bits_b_valid]
set_input_delay  2.0 -clock clk_uncore [get_ports axi4_mem_0_bits_b_bits_*]
set_output_delay 2.0 -clock clk_uncore [get_ports axi4_mem_0_bits_b_ready]

# AXI4 Read Address Channel (AR) - outputs
set_output_delay 2.0 -clock clk_uncore [get_ports axi4_mem_0_bits_ar_valid]
set_output_delay 2.0 -clock clk_uncore [get_ports axi4_mem_0_bits_ar_bits_*]
set_input_delay  2.0 -clock clk_uncore [get_ports axi4_mem_0_bits_ar_ready]

# AXI4 Read Data Channel (R) - inputs
set_input_delay  2.0 -clock clk_uncore [get_ports axi4_mem_0_bits_r_valid]
set_input_delay  2.0 -clock clk_uncore [get_ports axi4_mem_0_bits_r_bits_*]
set_output_delay 2.0 -clock clk_uncore [get_ports axi4_mem_0_bits_r_ready]

# AXI4 clock output
set_output_delay 2.0 -clock clk_uncore [get_ports axi4_mem_0_clock]

###############################################################################
# 7. SERIAL TILELINK INTERFACE DELAYS
###############################################################################
# Serial TL IN channel (inputs into chip)
set_input_delay  2.0 -clock clk_serial \
    [get_ports serial_tl_0_in_valid]
set_input_delay  2.0 -clock clk_serial \
    [get_ports serial_tl_0_in_bits_phit]
set_output_delay 2.0 -clock clk_serial \
    [get_ports serial_tl_0_in_ready]

# Serial TL OUT channel (outputs from chip)
set_output_delay 2.0 -clock clk_serial \
    [get_ports serial_tl_0_out_valid]
set_output_delay 2.0 -clock clk_serial \
    [get_ports serial_tl_0_out_bits_phit]
set_input_delay  2.0 -clock clk_serial \
    [get_ports serial_tl_0_out_ready]

###############################################################################
# 8. JTAG INTERFACE DELAYS (async - use false path)
###############################################################################
set_false_path -from [get_ports jtag_TCK]
set_false_path -from [get_ports jtag_TDI]
set_false_path -from [get_ports jtag_TMS]
set_false_path -to   [get_ports jtag_TDO]

###############################################################################
# 9. DRIVE STRENGTH & LOAD (typical assumptions)
###############################################################################
set_driving_cell -lib_cell BUF_X4 -library NangateOpenCellLibrary_typical_ccs \
    [all_inputs]
set_load 0.05 [all_outputs]

###############################################################################
# 10. TIMING EXCEPTIONS - Clock domain crossings
###############################################################################
# Paths between uncore clock and serial clock are async
set_false_path -from [get_clocks clk_uncore] -to [get_clocks clk_serial]
set_false_path -from [get_clocks clk_serial] -to [get_clocks clk_uncore]

###############################################################################
# END OF CONSTRAINTS
###############################################################################
