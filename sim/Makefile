SIM = verilator
TOPLEVEL_LANG = verilog
EXTRA_ARGS += --trace --trace-structs
VERILOG_SOURCES = $(shell pwd)/../source/Goldschmidt_Integer_Divider_2CPS.v ./GID_TOP.v
TOPLEVEL = GID_TOP
MODULE = top

include $(shell cocotb-config --makefiles)/Makefile.sim
