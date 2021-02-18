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
# File name     : wb_standard_master_driver.py
# Author        : Jose R Garcia
# Created       : 2020/11/22 12:45:43
# Last modified : 2021/01/10 11:40:49
# Project Name  : UVM-Python Verification Library
# Module Name   : wb_standard_master_driver
# Description   : Wishbone Bus Interface Driver.
#
# Additional Comments:
#   This driver drives the signals to respond to a WB Master.
##################################################################################################
import cocotb
from cocotb.triggers import *

from uvm import *
from uvm.base import *
from uvm.comps import UVMDriver
from uvm.macros import uvm_component_utils, uvm_info

from wb_standard_master_seq import *
from wb_standard_master_if import *

class wb_standard_master_driver(UVMDriver):
    """         
       Class: Wishbone Bus Interface Driver
        
       Definition: Contains functions, tasks and methods to drive the read interface
                   signals in response to the DUT. This is the stimulus generator.
    """

    def __init__(self, name, parent=None):
        super().__init__(name,parent)
        """         
           Function: new
          
           Definition: Read slave agent constructor.

           Args:
             name: This agents name.
             parent: NONE
        """
        self.seq_item_port
        self.vif  = wb_standard_master_if
        self.trig = Event("trans_exec")  # event
        self.tag  = "wb_standard_master_driver" + name
        self.data = 0
        self.cfg  = None


    def build_phase(self, phase):
        super().build_phase(phase)
        """         
           Function: build_phase
          
           Definition: Gets this agent's interface.

           Args:
             phase: build_phase
        """

    
    async def run_phase(self, phase):
        """         
           Function: run_phase
          
           Definition: Task executed during run phase. Drives the signals in
                       response to a UUT requests. 

           Args:
             phase: run_phase
        """
        while True:
    
            await RisingEdge(self.vif.clk_i)

            if (self.vif.stb_o == 1):
                await self.get_and_drive(phase)


    async def feed_data(self, tr):
        # Feed the read data
        count = 0
        while (count < tr.transmit_delay):
            # Simulate back preassure
            count = count+1
            await RisingEdge(self.vif.clk_i)
        
        # Stimulate the bus.
        self.vif.dat_i   <= tr.data_in
        self.vif.ack_i   <= tr.acknowledge
        self.vif.stall_i <= tr.stall
        self.vif.tgd_i   <= tr.response_data_tag
        await RisingEdge(self.vif.clk_i)


    async def get_and_drive(self, phase):
        tr = []
        # Drives signals with sequences
        await self.seq_item_port.get_next_item(tr)
        phase.raise_objection(self, self.tag + "objection")
        tr = tr[0]
        await self.feed_data(tr)
        self.seq_item_port.item_done()
        phase.drop_objection(self, "wb_standard_master_driver drop objection")

        self.vif.ack_i <= 0
        self.trig.set()


    async def reset_signals(self):
        # Hold signals low while reset
        self.vif.ack_i <= 0
        await RisingEdge(self.vif.clk_i)


    async def trans_executed(self, tr):
        # uvm_info(self.tag, "Finished Memory Interface read to address : " + str(tr.addr.value), UVM_MEDIUM)
        tr.convert2string
        await Timer(0, "NS")

uvm_component_utils(wb_standard_master_driver)
