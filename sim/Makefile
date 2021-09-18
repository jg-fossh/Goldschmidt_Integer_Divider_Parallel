NPROCS = 2 # To run this sim a processor with at least to threads is required
NUM1   = 1 # Define the integer 1 for general purpose
NUM2   = 2 # Amount of threads to be used by verilators trace, 2 is the max.

# Check if the OS is Linux or Mac or BSD and detect the amount of threads aviable
OS := $(shell uname -s)
ifeq ($(OS),Linux)
  NPROCS := $(shell grep -c ^processor /proc/cpuinfo)
else ifeq ($(OS),Darwin)
  NPROCS := $(shell system_profiler | awk '/Number of CPUs/ {print $$4}{next;}')
endif # $(OS)
# Select one threads less than the amount avialable, leave one thread for the rest of the system
THREADS := $(shell expr $(NPROCS) - $(NUM1))

# Set argument for the compiler
SIM = verilator
TOPLEVEL_LANG = verilog
EXTRA_ARGS += --default-language 1364-2005 --trace-fst --trace-structs --trace-max-array 1024 --trace-threads $(NUM2) --threads $(THREADS)
ifneq ($(DUTSELECT),)
  VERILOG_SOURCES = $(shell pwd)/../source/Goldschmidt_Integer_Divider_$(DUTSELECT)CPS.v ./TB_TOP.v
else
  VERILOG_SOURCES = $(shell pwd)/../source/Goldschmidt_Integer_Divider_2CPS.v ./TB_TOP.v
endif

# UVM Config/parameters
PLUSARGS=+UVM_VERBOSITY=UVM_LOW +UVM_NO_RELNOTES
ifneq ($(UVM_TEST),)
  PLUSARGS += +UVM_TESTNAME=$(UVM_TEST)
else
  PLUSARGS += +UVM_TESTNAME=default_test
endif
TOPLEVEL := TB_TOP
MODULE   ?= top
# Call on cocotb, uvm-python dependency
include $(shell cocotb-config --makefiles)/Makefile.sim
