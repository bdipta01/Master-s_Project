# 1. LIBRARY SETUP
###############################################################################
set library_path "/usrf07/home/agids/stu/s_ids118/0_FreePDK45/LIB/"
set library_name "NangateOpenCellLibrary_typical_ccs.db"

set_app_var target_library    $library_name
set_app_var link_library      [concat $library_name dw_foundation.sldb "*"]
set_app_var search_path       [concat $library_path [get_app_var search_path]]
set_app_var synthetic_library [list dw_foundation.sldb]
set_app_var symbol_library    [list class.sdb]
set_app_var vhdlout_use_packages { ieee.std_logic_1164.all NangateOpenCellLibrary.Components.all }
set_app_var vhdlout_write_components FALSE

echo "### STEP 1 DONE: Libraries loaded"

# 2. READ RTL FILES (excluding memory modules)
###############################################################################
set all_sv  [glob ../rtl/*.sv]
set all_v   [glob ../rtl/*.v]
set all_rtl [concat $all_sv $all_v]

set rtl_files {}
foreach f $all_rtl {
    set fname [file tail $f]
    if {[regexp {^ram_} $fname]            ||
        [regexp {^cc_banks_} $fname]       ||
        [regexp {^cc_dir} $fname]          ||
        [regexp {dcache_data} $fname]      ||
        [regexp {dcache_tag} $fname]       ||
        [regexp {icache_data} $fname]      ||
        [regexp {icache_tag} $fname]       ||
        [regexp {DCacheDataArray} $fname]  ||
        [regexp {TwoPortSyncMem} $fname]   ||
        [regexp {regfile_32x65} $fname]    ||
        [regexp {rf_31x64} $fname]         ||
        [regexp {table_512x1} $fname]      ||
        [regexp {ScratchpadBank_4} $fname] ||
        [regexp {^mem_} $fname]            } {
        echo "  SKIPPING (memory): $fname"
    } else {
        lappend rtl_files $f
    }
}

echo "### Keeping [llength $rtl_files] RTL files (memories excluded)"
read_file -format sverilog $rtl_files

# 3. ELABORATE & BLACK-BOX MEMORIES & CHECK
###############################################################################
elaborate ChipTop
current_design ChipTop

# Black-box all excluded memory modules so DC knows they exist but won't synthesize them
set memory_modules {
    ram_2x550 ram_data_3x128 ram_12x110 ram_2x115 ram_6x8
    ram_2x265 ram_2x147 ram_2x173 ram_2x257 ram_6x382
    ram_2x625 ram_2x192 ram_2x84 ram_2x80 ram_2x60
    ram_2x83 ram_2x145 ram_flit_8x32 ram_2x177 ram_2x274
    ram_2x382 ram_8x8 ram_2x116 ram_2x148 ram_2x191
    ram_2x189 ram_2x111 ram_2x81 ram_2x69 ram_5x88
    ram_5x258 ram_5x189 ram_8x246 ram_2x105 ram_2x118
    ram_2x119 ram_2x120 ram_2x10 ram_sink_2x4 ram_sink_2x3
    cc_banks_0 cc_banks_1 cc_banks_2 cc_banks_3
    cc_banks_4 cc_banks_5 cc_banks_6 cc_banks_7
    cc_dir
    rockettile_icache_data_arrays_0 rockettile_icache_data_arrays_1
    rockettile_icache_data_arrays_2 rockettile_icache_data_arrays_3
    rockettile_icache_tag_array
    rockettile_dcache_data_arrays_0 rockettile_dcache_data_arrays_1
    rockettile_dcache_tag_array
    DCacheDataArray TwoPortSyncMem regfile_32x65
    rf_31x64 table_512x1 ScratchpadBank_4 mem_1
}

foreach mem $memory_modules {
    if {[sizeof_collection [get_designs -quiet $mem]] > 0} {
        set_dont_touch [get_designs $mem]
        echo "  Black-boxed: $mem"
    }
}

check_design
link

echo "### STEP 3 DONE: Design elaborated, memories black-boxed, linked"

# 4. APPLY CONSTRAINTS
###############################################################################
read_sdc ./ChipTop_constraints.sdc

echo "### STEP 4 DONE: Constraints applied"

# 5. SYNTHESIZE (faster now - memories excluded)
###############################################################################
echo "### Starting synthesis - memories excluded so this should be faster..."
set_max_optimization_time 3600
compile -map_effort low -no_design_rule

echo "### STEP 5 DONE: Synthesis complete"

# 6. SAVE SYNTHESIZED NETLIST
###############################################################################
write -format verilog -hierarchy -output ./netlist_ChipTop.v
write_sdc ./ChipTop_post_synth.sdc

echo "### STEP 6 DONE: Netlist saved to netlist_ChipTop.v"

###############################################################################
# 7. ANNOTATE SAIF SWITCHING ACTIVITY
###############################################################################
read_saif -input ./ChipTop.saif \
          -instance_name TOP/TestDriver/testHarness/chiptop0 \
          -auto_map_names

echo "### STEP 7 DONE: SAIF annotated"

# Check what is MISSING (coverage gaps)
report_saif -missing > ./reports/saif_missing.txt

# Check what was SUCCESSFULLY annotated
report_saif -annotated > ./reports/saif_annotated.txt

# Show switching activity at RTL level
report_saif -rtl > ./reports/saif_rtl.txt

echo "### SAIF Reports saved:"
echo "   ./reports/saif_missing.txt    - nets NOT annotated"
echo "   ./reports/saif_annotated.txt  - nets successfully annotated"
echo "   ./reports/saif_rtl.txt        - RTL level switching activity"
###############################################################################
# 8. POWER ANALYSIS & REPORTS
###############################################################################
echo "### Running power analysis..."
mkdir -p ./reports

report_power                  > ./reports/power_summary.txt
report_power -hierarchy       > ./reports/power_hierarchy.txt
report_timing                 > ./reports/timing_report.txt
report_area                   > ./reports/area_report.txt

echo "### STEP 8 DONE: Reports saved"
echo ""
echo "============================================"
echo " POWER ANALYSIS COMPLETE"
echo " Check these files for results:"
echo "   ./reports/power_summary.txt"
echo "   ./reports/power_hierarchy.txt"
echo "   ./reports/timing_report.txt"
echo "   ./reports/area_report.txt"
echo "============================================"
