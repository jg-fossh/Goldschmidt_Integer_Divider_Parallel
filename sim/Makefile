SIM = verilator
TOPLEVEL_LANG = verilog
EXTRA_ARGS += --trace --trace-structs
VERILOG_SOURCES = $(shell pwd)/../source/Goldschmidt_Integer_Divider_2CPS.v ./GID_TOP.v

PLUSARGS=+UVM_VERBOSITY=UVM_LOW +UVM_NO_RELNOTES
ifneq ($(UVM_TEST),)
  PLUSARGS += +UVM_TESTNAME=$(UVM_TEST)
else
  PLUSARGS += +UVM_TESTNAME=reg_test 
endif

TOPLEVEL := GID_TOP
MODULE   ?= top

include $(shell cocotb-config --makefiles)/Makefile.sim
