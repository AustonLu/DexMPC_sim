
onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate -format Logic /tbench/clk_reset_if/clk

add wave -noupdate -divider sSpi
add wave -noupdate -format Literal /tbench/sSpi/AWID
add wave -noupdate -format Literal /tbench/sSpi/AWQV
add wave -noupdate -format Logic /tbench/sSpi/AWVALID
add wave -noupdate -format Logic /tbench/sSpi/AWREADY
add wave -noupdate -format Literal /tbench/sSpi/WID
add wave -noupdate -format Logic /tbench/sSpi/WVALID
add wave -noupdate -format Logic /tbench/sSpi/WREADY
add wave -noupdate -format Logic /tbench/sSpi/WLAST
add wave -noupdate -format Literal /tbench/sSpi/BID
add wave -noupdate -format Logic /tbench/sSpi/BVALID
add wave -noupdate -format Logic /tbench/sSpi/BREADY

add wave -noupdate -divider sD2dData
add wave -noupdate -format Literal /tbench/sD2dData/AWID
add wave -noupdate -format Literal /tbench/sD2dData/AWQV
add wave -noupdate -format Logic /tbench/sD2dData/AWVALID
add wave -noupdate -format Logic /tbench/sD2dData/AWREADY
add wave -noupdate -format Literal /tbench/sD2dData/WID
add wave -noupdate -format Logic /tbench/sD2dData/WVALID
add wave -noupdate -format Logic /tbench/sD2dData/WREADY
add wave -noupdate -format Logic /tbench/sD2dData/WLAST
add wave -noupdate -format Literal /tbench/sD2dData/BID
add wave -noupdate -format Logic /tbench/sD2dData/BVALID
add wave -noupdate -format Logic /tbench/sD2dData/BREADY

add wave -noupdate -divider sIrisBridge
add wave -noupdate -format Literal /tbench/sIrisBridge/AWID
add wave -noupdate -format Literal /tbench/sIrisBridge/AWQV
add wave -noupdate -format Logic /tbench/sIrisBridge/AWVALID
add wave -noupdate -format Logic /tbench/sIrisBridge/AWREADY
add wave -noupdate -format Literal /tbench/sIrisBridge/WID
add wave -noupdate -format Logic /tbench/sIrisBridge/WVALID
add wave -noupdate -format Logic /tbench/sIrisBridge/WREADY
add wave -noupdate -format Logic /tbench/sIrisBridge/WLAST
add wave -noupdate -format Literal /tbench/sIrisBridge/BID
add wave -noupdate -format Logic /tbench/sIrisBridge/BVALID
add wave -noupdate -format Logic /tbench/sIrisBridge/BREADY

add wave -noupdate -divider mGauxCore
add wave -noupdate -format Literal /tbench/mGauxCore/AWID
add wave -noupdate -format Literal /tbench/mGauxCore/AWQV
add wave -noupdate -format Literal /tbench/mGauxCore/AWVALID
add wave -noupdate -format Logic /tbench/mGauxCore/AWREADY
add wave -noupdate -format Literal /tbench/mGauxCore/WID
add wave -noupdate -format Logic /tbench/mGauxCore/WVALID
add wave -noupdate -format Logic /tbench/mGauxCore/WREADY
add wave -noupdate -format Logic /tbench/mGauxCore/WLAST
add wave -noupdate -format Literal /tbench/mGauxCore/BID
add wave -noupdate -format Logic /tbench/mGauxCore/BVALID
add wave -noupdate -format Logic /tbench/mGauxCore/BREADY

add wave -noupdate -divider mDexmpcCore
add wave -noupdate -format Literal /tbench/mDexmpcCore/AWID
add wave -noupdate -format Literal /tbench/mDexmpcCore/AWQV
add wave -noupdate -format Literal /tbench/mDexmpcCore/AWVALID
add wave -noupdate -format Logic /tbench/mDexmpcCore/AWREADY
add wave -noupdate -format Literal /tbench/mDexmpcCore/WID
add wave -noupdate -format Logic /tbench/mDexmpcCore/WVALID
add wave -noupdate -format Logic /tbench/mDexmpcCore/WREADY
add wave -noupdate -format Logic /tbench/mDexmpcCore/WLAST
add wave -noupdate -format Literal /tbench/mDexmpcCore/BID
add wave -noupdate -format Logic /tbench/mDexmpcCore/BVALID
add wave -noupdate -format Logic /tbench/mDexmpcCore/BREADY

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

