# rebuild.tcl  -  optional one-step "rebuild + simulate" from inside Vivado
#
# In the Vivado Tcl console:
#     source C:/rv32_project/rebuild.tcl        (use your own folder path)
#
# It calls build.py through WSL (updating imem.v and tb_riscv_top.v),
# then relaunches the behavioral simulation and runs it to completion.

set proj_dir [file normalize [file dirname [info script]]]
set wsl_dir  [string trim [exec wsl.exe wslpath -a $proj_dir]]

if {[catch {exec wsl.exe python3 "$wsl_dir/build.py"} out]} {
    puts "build.py failed (imem.v / testbench NOT changed):"
    puts $out
    return
}
puts $out

catch {close_sim}
launch_simulation
run all
