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
# File name     : test_lib.py
# Author        : Jose R Garcia
# Created       : 2020/11/05 19:26:21
# Last modified : 2021/09/26 09:37:54
# Project Name  : Goldschmidt Integer Divider
# Module Name   : test_lib
# Description   : Collection of tests available for this module.
#
# Additional Comments:
#   Contains the test base and tests.
##################################################################################################
# Framework Libs
import cocotb
from cocotb.triggers import Timer
# UVM Libs
from uvm import *
from wb4s_seq import *
from wb4s_agent import *
from wb4s_config import *
from tb_env_config import *
from tb_env import *
from predictor import *
# General Python Libs
import math

class test_base(UVMTest):
    """
       Class: Test Base

       Definition: Contains functions, tasks and methods.
    """

    def __init__(self, name="test_base", parent=None):
        super().__init__(name, parent)
        self.test_pass = True
        self.err_msg = ""
        self.tb_env = None
        self.tb_env_config = None
        self.wb4s_agent_cfg = None
        self.printer = None

    def build_phase(self, phase):
        super().build_phase(phase)
        # Enable transaction recording for everything
        UVMConfigDb.set(self, "*", "recording_detail", UVM_FULL)

        # create this test test bench environment config
        arr = []
        if UVMConfigDb.get(None, "dut", "DUT_SLAVE_DATA_IN_LENGTH", arr) is True:
            UVMConfigDb.set(None, "*", "DUT_SLAVE_DATA_IN_LENGTH", arr[0])

        self.tb_env_config = tb_env_config.type_id.create("tb_env_config", self)
        self.tb_env_config.has_scoreboard           = True
        self.tb_env_config.has_predictor            = True
        self.tb_env_config.has_functional_coverage  = False
        self.tb_env_config.DUT_SLAVE_DATA_IN_LENGTH = arr[0]
        self.tb_env_config.data_bins_range          = [50000, 50030]

        # Create the Mem Read agent
        self.wb4s_agent_cfg = wb4s_config.type_id.create("wb4s_agent_cfg", self)
        arr = []
        # Get the instruction interface created at top
        if UVMConfigDb.get(None, "*", "vif_slave", arr) is True:
            UVMConfigDb.set(self, "*", "vif_slave", arr[0])
            # Make this agent's interface the interface connected at top
            self.wb4s_agent_cfg.vif         = arr[0]
            self.wb4s_agent_cfg.has_driver  = 1
            self.wb4s_agent_cfg.has_monitor = 1
        else:
            uvm_fatal("NOVIF", "Could not get vif_slave from config DB")

        # Make this instruction agent the test bench config agent
        self.tb_env_config.wb4s_agent_cfg = self.wb4s_agent_cfg

        # Place the tn_env_config in the Db. The tb_env will fetch this in its build phase .
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


    def extract_phase(self, phase):
        if(self.tb_env.scoreboard.m_mismatches == 0):
           self.test_pass = True
        else:
           self.test_pass = False
           self.err_msg += '\nMatches : ' + str(self.tb_env.scoreboard.m_matches)
           self.err_msg += '\nMismatches : ' + str(self.tb_env.scoreboard.m_mismatches)


    def report_phase(self, phase):
        if self.test_pass:
            uvm_info(self.get_type_name(),
                sv.sformatf("\n\n-----------------------------------\n    UVM Test   : %s\n    Matches    : %d\n    Mismatches : %d\n    Pass/Fail  : Pass\n-----------------------------------\n", self.get_type_name(), self.tb_env.scoreboard.m_matches, self.tb_env.scoreboard.m_mismatches), UVM_NONE)
        else:
            uvm_fatal(self.get_type_name(), "UVM TEST FAIL\n" +
                self.err_msg)

        cov_print = 0 # 
        # Coverage Report
        if (cov_print == 1):
            # Print coverage bins at the end of the sim
            coverage.coverage_db.report_coverage(print, bins=False)
            coverage.coverage_db.report_coverage(print, bins=True)

        if (self.tb_env_config.has_functional_coverage):
            coverage.coverage_db.export_to_yaml(filename="coverage_result.yml")


uvm_component_utils(test_base)


class default_test(test_base):
    """
       Class: Default Test

       Definition: Contains functions, tasks and methods.
    """

    def __init__(self, name="default_test", parent=test_base):
        super().__init__(name, parent)
        # This class' variables initial state.
        self.count       = 0
        self.stall       = 1
        self.acknowledge = 0


    async def run_phase(self, phase):
        phase.raise_objection(self, "default_test raise objection")

        # Call and fork the methods that create sequences to feed the sequencers
        slave_proc  = cocotb.fork(self.stimulate_slave_intfc())

        await Timer(16, "NS") # Allow some clocks for evething to settle
        await sv.fork_join_any([slave_proc])

        phase.drop_objection(self, "default_test drop objection")


    async def stimulate_slave_intfc(self):
        #
        self.count = int(pow(2, (self.tb_env.cfg.DUT_SLAVE_DATA_IN_LENGTH)/2)-1)
        data_inc   = 2
        stop_count = self.count + (self.tb_env.cfg.data_bins_range[1] - self.tb_env.cfg.data_bins_range[0])/data_inc

        #
        wb4s_sqr = self.tb_env.wb4s_agent.sqr

        # Create transactions to stimulate the slave interface (calc division)
        increment_sum_seq          = wb4s_single_write_seq("increment_sum_seq")
        increment_sum_seq.data     = self.count * 2
        increment_sum_seq.strobe   = 1
        increment_sum_seq.cycle    = 1
        increment_sum_seq.cycle_tag = 0

        while self.count < stop_count:
            await increment_sum_seq.start(wb4s_sqr)
            # Count decrement data for next sequence.
            self.count += 1
            increment_sum_seq          = wb4s_single_write_seq("increment_sum_seq")
            increment_sum_seq.cycle    = 1
            increment_sum_seq.strobe   = 1
            increment_sum_seq.cycle_tag = 0
            increment_sum_seq.data     = ((self.count * data_inc) + self.tb_env.cfg.data_bins_range[0]) << round(data_inc/2)
            #increment_sum_seq.data     = self.count * data_inc
            data_inc += 1

        
        await increment_sum_seq.start(wb4s_sqr)


        # Re-start the count
        self.count = int(pow(2, (self.tb_env.cfg.DUT_SLAVE_DATA_IN_LENGTH)/2))

        # Create transactions to stimulate the slave interface (calc remainder)
        increment_sum_seq          = wb4s_single_write_seq("increment_sum_seq")
        increment_sum_seq.data     = self.count * 2
        increment_sum_seq.strobe   = 1
        increment_sum_seq.cycle    = 1
        increment_sum_seq.cycle_tag = 1

        while self.count < stop_count:
            await increment_sum_seq.start(wb4s_sqr)
            # Count decrement data for next sequence.
            self.count += 1
            increment_sum_seq          = wb4s_single_write_seq("increment_sum_seq")
            increment_sum_seq.cycle    = 1
            increment_sum_seq.strobe   = 1
            increment_sum_seq.cycle_tag = 1
            increment_sum_seq.data     = (self.count * data_inc)+1


        await increment_sum_seq.start(wb4s_sqr)

        # Re-start the count
        self.count = int(pow(2, (self.tb_env.cfg.DUT_SLAVE_DATA_IN_LENGTH)/2)+1)

        # Create transactions to stimulate the slave interface (calc remainder)
        increment_sum_seq          = wb4s_single_write_seq("increment_sum_seq")
        increment_sum_seq.data     = self.count * 2
        increment_sum_seq.strobe   = 1
        increment_sum_seq.cycle    = 1
        increment_sum_seq.cycle_tag = 2

        while self.count < stop_count:
            await increment_sum_seq.start(wb4s_sqr)
            # Count decrement data for next sequence.
            self.count += 1
            increment_sum_seq          = wb4s_single_write_seq("increment_sum_seq")
            increment_sum_seq.cycle    = 1
            increment_sum_seq.strobe   = 1
            increment_sum_seq.cycle_tag = 2
            increment_sum_seq.data     = (self.count * data_inc)+1


        await increment_sum_seq.start(wb4s_sqr)

        # Re-start the count
        self.count = int(pow(2, (self.tb_env.cfg.DUT_SLAVE_DATA_IN_LENGTH)/2)+4)

        # Create transactions to stimulate the slave interface (calc remainder)
        increment_sum_seq          = wb4s_single_write_seq("increment_sum_seq")
        increment_sum_seq.data     = self.count * 2
        increment_sum_seq.strobe   = 1
        increment_sum_seq.cycle    = 1
        increment_sum_seq.cycle_tag = 3

        while self.count < stop_count:
            await increment_sum_seq.start(wb4s_sqr)
            # Count decrement data for next sequence.
            self.count += 1
            increment_sum_seq          = wb4s_single_write_seq("increment_sum_seq")
            increment_sum_seq.cycle    = 1
            increment_sum_seq.strobe   = 1
            increment_sum_seq.cycle_tag = 3
            increment_sum_seq.data     = (self.count * data_inc)+1


        await increment_sum_seq.start(wb4s_sqr)

        # de-assert the CYC and STB signals
        increment_sum_seq          = wb4s_single_write_seq("increment_sum_seq")
        increment_sum_seq.cycle    = 0
        increment_sum_seq.strobe   = 0
        increment_sum_seq.data_tag = 0
        increment_sum_seq.data     = 51966 #0xCAFE

        await increment_sum_seq.start(wb4s_sqr)


uvm_component_utils(default_test)
