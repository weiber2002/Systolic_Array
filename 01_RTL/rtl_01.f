
-P /usr/cad/synopsys/verdi/cur/share/PLI/VCS/LINUX64/novas.tab
/usr/cad/synopsys/verdi/cur/share/PLI/VCS/LINUX64/pli.a
+libext+.v+.sv+.vlib
-y /usr/cad/synopsys/synthesis/cur/dw/sim_ver 
+incdir+/usr/cad/synopsys/synthesis/cur/dw/sim_ver/+


// Testbench
./test.sv

// Design files
./top.sv
./systolic.sv
// If SRAMs are used, add this flag
+notimingcheck
