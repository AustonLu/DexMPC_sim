
onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate -format Logic /tbench/clk_reset_if/clk
   
add wave -noupdate -divider sSpi
add wave -noupdate -format Literal /tbench/sSpi/ARID
add wave -noupdate -format Literal /tbench/sSpi/ARQV
add wave -noupdate -format Logic /tbench/sSpi/ARVALID
add wave -noupdate -format Logic /tbench/sSpi/ARREADY
add wave -noupdate -format Literal /tbench/sSpi/RID
add wave -noupdate -format Logic /tbench/sSpi/RVALID
add wave -noupdate -format Logic /tbench/sSpi/RREADY
add wave -noupdate -format Logic /tbench/sSpi/RLAST

add wave -noupdate -divider sD2dData
add wave -noupdate -format Literal /tbench/sD2dData/ARID
add wave -noupdate -format Literal /tbench/sD2dData/ARQV
add wave -noupdate -format Logic /tbench/sD2dData/ARVALID
add wave -noupdate -format Logic /tbench/sD2dData/ARREADY
add wave -noupdate -format Literal /tbench/sD2dData/RID
add wave -noupdate -format Logic /tbench/sD2dData/RVALID
add wave -noupdate -format Logic /tbench/sD2dData/RREADY
add wave -noupdate -format Logic /tbench/sD2dData/RLAST

add wave -noupdate -divider sIrisBridge
add wave -noupdate -format Literal /tbench/sIrisBridge/ARID
add wave -noupdate -format Literal /tbench/sIrisBridge/ARQV
add wave -noupdate -format Logic /tbench/sIrisBridge/ARVALID
add wave -noupdate -format Logic /tbench/sIrisBridge/ARREADY
add wave -noupdate -format Literal /tbench/sIrisBridge/RID
add wave -noupdate -format Logic /tbench/sIrisBridge/RVALID
add wave -noupdate -format Logic /tbench/sIrisBridge/RREADY
add wave -noupdate -format Logic /tbench/sIrisBridge/RLAST

add wave -noupdate -divider mGauxCore
add wave -noupdate -format Literal /tbench/mGauxCore/ARID
add wave -noupdate -format Literal /tbench/mGauxCore/ARQV
add wave -noupdate -format Literal /tbench/mGauxCore/ARVALID
add wave -noupdate -format Logic /tbench/mGauxCore/ARREADY
add wave -noupdate -format Literal /tbench/mGauxCore/RID
add wave -noupdate -format Logic /tbench/mGauxCore/RVALID
add wave -noupdate -format Logic /tbench/mGauxCore/RREADY
add wave -noupdate -format Logic /tbench/mGauxCore/RLAST

add wave -noupdate -divider mDexmpcCore
add wave -noupdate -format Literal /tbench/mDexmpcCore/ARID
add wave -noupdate -format Literal /tbench/mDexmpcCore/ARQV
add wave -noupdate -format Literal /tbench/mDexmpcCore/ARVALID
add wave -noupdate -format Logic /tbench/mDexmpcCore/ARREADY
add wave -noupdate -format Literal /tbench/mDexmpcCore/RID
add wave -noupdate -format Logic /tbench/mDexmpcCore/RVALID
add wave -noupdate -format Logic /tbench/mDexmpcCore/RREADY
add wave -noupdate -format Logic /tbench/mDexmpcCore/RLAST

TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 1} {0 ps} 0}
configure wave -namecolwidth 402
configure wave -valuecolwidth 100
configure wave -justifyvalue left
configure wave -signalnamewidth 0
configure wave -snapdistance 10
configure wave -datasetprefix 0
configure wave -rowmargin 4
configure wave -childrowmargin 2
configure wave -gridoffset 0
configure wave -gridperiod 1
configure wave -griddelta 40
configure wave -timeline 0
update
WaveRestoreZoom {0 ps} {5000 ns}

