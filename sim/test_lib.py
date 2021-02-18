#################################################################################
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
#################################################################################
# File name     : test_lib.py
# Author        : Jose R Garcia
# Created       : 2020/11/05 19:26:21
# Last modified : 2021/02/17 22:32:01
# Project Name  : ORCs
# Module Name   : test_lib
# Description   : ORC_R32I Test Library
#
# Additional Comments:
#   Contains the test base and tests.
#################################################################################
import cocotb
from cocotb.triggers import Timer

from uvm import *
from externals.Wishbone_Standard_Master.wb_standard_master_seq import *
from externals.Wishbone_Standard_Master.wb_standard_master_agent import *
from externals.Wishbone_Standard_Master.wb_standard_master_config import *
from externals.Wishbone_Standard_Slave.wb_standard_slave_seq import *
from externals.Wishbone_Standard_Slave.wb_standard_slave_agent import *
from externals.Wishbone_Standard_Slave.wb_standard_slave_config import *
from tb_env_config import *
from tb_env import *
from predictor import *

class test_base(UVMTest):
    """         
       Class: IIR Filter Test Base
        
       Definition: Contains functions, tasks and methods.
    """

    def __init__(self, name="test_base", parent=None):
        super().__init__(name, parent)
        self.test_pass = True
        self.tb_env = None
        self.tb_env_config = None
        self.wb_master_agent_cfg = None
        self.printer = None

    def build_phase(self, phase):
        super().build_phase(phase)
        # Enable transaction recording for everything
        UVMConfigDb.set(self, "*", "recording_detail", UVM_FULL)
        # create this test test bench environment config
        self.tb_env_config = tb_env_config.type_id.create("tb_env_config", self)
        self.tb_env_config.has_scoreboard = True
        self.tb_env_config.has_predictor = True
        self.tb_env_config.has_functional_coverage = False
        # Create the instruction agent
        self.wb_master_agent_cfg = wb_standard_master_config.type_id.create("wb_master_agent_cfg", self)
        arr = []
        # Get the instruction interface created at top
        if UVMConfigDb.get(None, "*", "vif_master", arr) is True:
            UVMConfigDb.set(self, "*", "vif_master", arr[0])
            # Make this agent's interface the interface connected at top
            self.wb_master_agent_cfg.vif         = arr[0]
            self.wb_master_agent_cfg.has_driver  = 0
            self.wb_master_agent_cfg.has_monitor = 1
        else:
            uvm_fatal("NOVIF", "Could not get vif_master from config DB")

        # Create the Mem Read agent
        self.wb_slave_agent_cfg = wb_standard_master_config.type_id.create("wb_slave_agent_cfg", self)
        arr = []
        # Get the instruction interface created at top
        if UVMConfigDb.get(None, "*", "vif_slave", arr) is True:
            UVMConfigDb.set(self, "*", "vif_slave", arr[0])
            # Make this agent's interface the interface connected at top
            self.wb_slave_agent_cfg.vif         = arr[0]
            self.wb_slave_agent_cfg.has_driver  = 1
            self.wb_slave_agent_cfg.has_monitor = 1
        else:
            uvm_fatal("NOVIF", "Could not get vif_slave from config DB")

        # Make this instruction agent the test bench config agent
        self.tb_env_config.wb_master_agent_cfg = self.wb_master_agent_cfg
        self.tb_env_config.wb_slave_agent_cfg = self.wb_slave_agent_cfg
        UVMConfigDb.set(self, "*", "tb_env_config", self.tb_env_config)
        # Create the test bench environment 
        self.tb_env = tb_env.type_id.create("tb_env", self)
        # Create a specific depth printer for printing the created topology
        self.printer = UVMTablePrinter()
        self.printer.knobs.depth = 3


    def end_of_elaboration_phase(self, phase):
        # Print topology
        uvm_info(self.get_type_name(),
            sv.sformatf("Printing the test topology :\n%s", self.sprint(self.printer)), UVM_LOW)


    def report_phase(self, phase):
        if self.test_pass:
            uvm_info(self.get_type_name(), "** UVM TEST PASSED **", UVM_NONE)
        else:
            uvm_fatal(self.get_type_name(), "** UVM TEST FAIL **\n" +
                self.err_msg)


uvm_component_utils(test_base)


class reg_test(test_base):


    def __init__(self, name="reg_test", parent=None):
        super().__init__(name, parent)
        self.hex_instructions = []
        self.fetched_instruction = None
        self.count = 4294967295 # 32 ones


    async def run_phase(self, phase):
        cocotb.fork(self.stimulate_read_intfc())

    
    async def stimulate_read_intfc(self):
        mem_read_sqr = self.tb_env.wb_slave_agent.sqr
        
        #  Create seq0
        mem_read_seq0 = wb_slave_write_single_sequence("mem_read_seq0")
        mem_read_seq0.data = 0 #
        #
        while True:
            await mem_read_seq0.start(mem_read_sqr)
            self.count = self.count + 1
            mem_read_seq0 = wb_slave_write_single_sequence("mem_read_seq0")
            mem_read_seq0.data = self.count


uvm_component_utils(reg_test)
