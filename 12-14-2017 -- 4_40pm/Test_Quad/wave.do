onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate /QuadCopter_tb/TX
add wave -noupdate /QuadCopter_tb/SS_n
add wave -noupdate /QuadCopter_tb/SS_A2D_n
add wave -noupdate /QuadCopter_tb/SET_YAW
add wave -noupdate /QuadCopter_tb/SET_THRST
add wave -noupdate /QuadCopter_tb/SET_ROLL
add wave -noupdate /QuadCopter_tb/SET_PTCH
add wave -noupdate /QuadCopter_tb/send_cmd
add wave -noupdate /QuadCopter_tb/SCLK_A2D
add wave -noupdate /QuadCopter_tb/SCLK
add wave -noupdate /QuadCopter_tb/RX
add wave -noupdate /QuadCopter_tb/RST_n
add wave -noupdate /QuadCopter_tb/rght_ESC
add wave -noupdate /QuadCopter_tb/resp_rdy
add wave -noupdate /QuadCopter_tb/resp
add wave -noupdate /QuadCopter_tb/REQ_BATT
add wave -noupdate /QuadCopter_tb/MTRS_OFF
add wave -noupdate /QuadCopter_tb/MOSI_A2D
add wave -noupdate /QuadCopter_tb/MOSI
add wave -noupdate /QuadCopter_tb/MISO_A2D
add wave -noupdate /QuadCopter_tb/MISO
add wave -noupdate /QuadCopter_tb/left_ESC
add wave -noupdate /QuadCopter_tb/INT
add wave -noupdate /QuadCopter_tb/frnt_ESC
add wave -noupdate /QuadCopter_tb/frm_sent
add wave -noupdate /QuadCopter_tb/EMER_LAND
add wave -noupdate /QuadCopter_tb/data
add wave -noupdate /QuadCopter_tb/cmd_to_copter
add wave -noupdate /QuadCopter_tb/cmd_sent
add wave -noupdate /QuadCopter_tb/clr_resp_rdy
add wave -noupdate /QuadCopter_tb/clk
add wave -noupdate /QuadCopter_tb/CALIBRATE
add wave -noupdate /QuadCopter_tb/back_ESC
TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 1} {1367143790 ns} 0}
quietly wave cursor active 1
configure wave -namecolwidth 231
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
configure wave -timelineunits ns
update
WaveRestoreZoom {1554172571 ns} {1554175792 ns}
