import random
import cocotb
import sys
# insert at 1, 0 is the script path (or '' in REPL)
sys.path.append('externals/Wishbone_Standard_Master/')
sys.path.append('externals/Wishbone_Standard_Slave/')
from cocotb.triggers import Timer
from cocotb.clock import Clock
from uvm.base import run_test, UVMDebug
from uvm.base.uvm_phase import UVMPhase
from uvm.seq import UVMSequence
from externals.Wishbone_Standard_Master.wb_standard_master_if import *
from externals.Wishbone_Standard_Slave.wb_standard_slave_if import *
from tb_env_config import *
from tb_env import *
from test_lib import *

async def initial_run_test(dut, vif_master, vif_slave):
    from uvm.base import UVMCoreService
    cs_ = UVMCoreService.get()
    UVMConfigDb.set(None, "*", "vif_master", vif_master)
    UVMConfigDb.set(None, "*", "vif_slave", vif_slave)
    await run_test("reg_test")


async def initial_reset(vif_master, vif_slave, dut):
    await Timer(0, "NS")
    vif_master.rst_i <= 1
    await Timer(33, "NS") 
    vif_master.rst_i <= 0
    cocotb.fork(initial_run_test(dut, vif_master, vif_slave))


@cocotb.test()
async def top(dut):
    """ Goldschmidt Integer Divider (2 Clocks Per Step) Test Bench """

    # Map the signals in the DUT to the verification agents interfaces
    bus_map = {"clk_i": "i_clk", 
               "rst_i": "i_reset_sync",
               "adr_i": "i_slave_addr", 
               "dat_i": "i_slave_div_read_data",
               "dat_o": "dat_o", 
               "we_o": "we_o",
               "sel_o": "sel_o",
               "stb_o": "i_slave_stb",
               "ack_i": "o_master_div_write_stb",
               "cyc_o": "cyc_o",
               "stall_i": "stall_i",
               "tga_o": "i_slave_tga",
               "tgd_i": "tgd_i",
               "tgd_o": "tgd_o",
               "tgc_o": "tgc_o"}

    bus_map_write = {"clk_i": "i_clk", 
                     "rst_i": "i_reset_sync",
                     "adr_o": "o_master_div_write_addr", 
                     "dat_i": "dat_i",
                     "dat_o": "o_master_div_write_data", 
                     "we_o": "we_o",
                     "sel_o": "sel_o",
                     "stb_o": "o_master_div_write_stb",
                     "ack_i": "ack_i",
                     "cyc_o": "cyc_o",
                     "stall_i": "stall_i",
                     "tga_o": "tga_o",
                     "tgd_i": "tgd_i",
                     "tgd_o": "tgd_o",
                     "tgc_o": "tgc_o"}
 
    vif_master = wb_standard_master_if(dut, bus_map_write)
    vif_slave = wb_standard_slave_if(dut, bus_map)

    # Create a 1000Mhz clock
    clock = Clock(dut.i_clk, 1, units="ns") 
    cocotb.fork(clock.start())  # Start the clock
    cocotb.fork(initial_reset(vif_master, vif_slave, dut))
    #cocotb.fork(initial_run_test(dut, vif))

    await Timer(2, "US")