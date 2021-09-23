##################################################################################################
# BSD 3-Clause License
#
# Copyright (c) 2020, Jose R. Garcia
# All rights reserved.
#
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions are met:
#
# 1. Redistributions of source code must retain the above copyright notice, this
#    list of conditions and the following disclaimer.
#
# 2. Redistributions in binary form must reproduce the above copyright notice,
#    this list of conditions and the following disclaimer in the documentation
#    and/or other materials provided with the distribution.
#
# 3. Neither the name of the copyright holder nor the names of its
#    contributors may be used to endorse or promote products derived from
#    this software without specific prior written permission.
#
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
# AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
# IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
# DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE
# FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
# DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
# SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
# CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
# OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
# OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
#
##################################################################################################
# File name     : top.py
# Author        : Jose R Garcia
# Created       : 2020/11/05 19:26:21
# Last modified : 2021/06/24 17:35:57
# Project Name  : Goldschmidt Integer Divider
# Module Name   : top
# Description   : Goldschmidt_Integer_Divider Test Top. Wraps the design units
#                 into the test environment.
#
# Additional Comments:
#
##################################################################################################
import random
import cocotb
import sys
# Add the Wisbone Verification Agents directories.
sys.path.append('../externals/uvm_python_Wishbone_Pipeline_Master/')
sys.path.append('../externals/uvm_python_Wishbone_Pipeline_Slave/')
# Import cocotb clock and timers
from cocotb.triggers import Timer
from cocotb.clock import Clock
from cocotb_coverage.coverage import *
# Import uvm-python base items
from uvm.base import run_test, UVMDebug
from uvm.base.uvm_phase import UVMPhase
from uvm.seq import UVMSequence
# Import the Wisbone Verification Agents directories.
from wb4_master_if import *
from wb4_slave_if import *
# Import test bench files
from tb_env_config import *
from tb_env import *
from test_lib import *


async def initial_run_test(dut, vif_master, vif_slave):
    """
       Description: Places the virtual interfaces into the Config DB and await
       for the test to finish.
    """
    from uvm.base import UVMCoreService
    cs_ = UVMCoreService.get()
    UVMConfigDb.set(None, "*", "vif_master", vif_master)
    UVMConfigDb.set(None, "*", "vif_slave", vif_slave)
    UVMConfigDb.set(None, "dut", "DUT_SLAVE_DATA_IN_LENGTH", len(dut.i_wb4_slave_data))
    await run_test()


async def initial_reset(vif_master, vif_slave, dut):
    """
       Description: Perform power on reset. Toggle reset signals and fork the
       test routines.
    """
    #await Timer(0, "NS")
    vif_master.rst_i <= 1
    await Timer(33, "NS")
    vif_master.rst_i <= 0


@cocotb.test()
async def top(dut):
    """ Adder Bus signals definition """

    # Map the signals in the DUT to the verification agents interfaces
    slave_bus_map = { "clk_i": "i_clk",
                      "rst_i": "i_reset_sync",
                      "cyc_i": "cyc_i",
                      "stb_i": "i_wb4_slave_stb",
                      "dat_i": "i_wb4_slave_data",
                      "dat_o": "dat_o",
                      "adr_i": "adr_i",
                      "we_i": "we_i",
                      "sel_i": "sel_i",
                      "stall_o": "o_wb4_slave_stall",
                      "ack_o": "o_wb4_slave_ack",
                      "tga_o": "tga_o",
                      "tgd_i": "i_wb4_slave_tgd",
                      "tgd_o": "tgd_o",
                      "tgc_o": "tgc_o" }

    master_bus_map = { "clk_i": "i_clk",
                       "rst_i": "i_reset_sync",
                       "adr_i": "adr_o",
                       "dat_i": "dat_i",
                       "dat_o": "o_wb4_master_data",
                       "we_o": "we_o",
                       "sel_o": "sel_o",
                       "stb_o": "o_wb4_master_stb",
                       "ack_i": "i_wb4_master_ack",
                       "cyc_o": "cyc_o",
                       "stall_i": "i_wb4_master_stall",
                       "tga_o": "tga_o",
                       "tgd_i": "tgd_i",
                       "tgd_o": "tgd_o",
                       "tgc_o": "tgc_o" }

    vif_master = wb4_master_if(dut, master_bus_map)
    vif_slave = wb4_slave_if(dut, slave_bus_map)

    # Create a 1000Mhz clock
    clock = Clock(dut.i_clk, 1, units="ns")
    proc_clk = cocotb.fork(clock.start((256+33+4), True))  # Start the clock
    proc_reset = cocotb.fork(initial_reset(vif_master, vif_slave, dut))
    proc_run_test = cocotb.fork(initial_run_test(dut, vif_master, vif_slave))

    await sv.fork_join([proc_run_test, proc_reset, proc_clk])
