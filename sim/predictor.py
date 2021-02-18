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
# File name     : predictor.py
# Author        : Jose R Garcia
# Created       : 2020/11/05 20:08:35
# Last modified : 2021/02/18 15:52:51
# Project Name  : ORCs
# Module Name   : predictor
# Description   : Non Time Consuming R32I model.
#
# Additional Comments:
#
#################################################################################
import cocotb
from cocotb.triggers import *
from uvm.base import *
from uvm.comps import *
from uvm.tlm1 import *
from uvm.macros import *
from externals.Wishbone_Standard_Master.wb_standard_master_seq import *
from externals.Wishbone_Standard_Slave.wb_standard_slave_seq import *

class predictor(UVMSubscriber):
    """         
       Class: Predictor
        
       Definition: Contains functions, tasks and methods of this predictor.
    """

    def __init__(self, name, parent=None):
        super().__init__(name, parent)
        """         
           Function: new
          
           Definition: R32I Predictor constructor.

           Args:
             name: This component's name.
             parent: NONE
        """
        self.ap = None
        self.num_items = 0
        self.tag = "predictor" + name


    def build_phase(self, phase):
        super().build_phase(phase)
        """         
           Function: build_phase
          
           Definition: Brings this agent's virtual interface.

           Args:
             phase: build_phase
        """
        self.ap = UVMAnalysisPort("ap", self)

   
    def write(self, t):
        """         
           Function: write
          
           Definition: This function immediately receives the transaction sent to
             the UUT by the agent. Decodes the instruction and generates a response
             sent to the scoreboard. 

           Args:
             t: wb_standard_master_seq (Sequence Item)
        """
        dividend = t.data_in - 4294967295
        divisor  = 4294967295 - t.data_in
        result = dividend/divisor

        uvm_info(self.tag, sv.sformatf("\n    DIV Result:  %d\n", result), UVM_LOW)

        self.create_response(result)

   
    def create_response(self, result):
        """         
           Function: create_response
          
           Definition: Creates a response transaction and updates the pc counter. 

           Args:
             t: wb_standard_master_seq (Sequence Item)
        """

        write_seq0 = wb_slave_write_single_sequence("write_seq0")
        write_seq0.data_in           = result
        write_seq0.stall             = 0 
        write_seq0.response_data_tag = 0 
        write_seq0.acknowledge       = 1
        write_seq0.transmit_delay    = 0 
        
        tr = []
        tr = write_seq0
        self.ap.write(tr)
 

uvm_component_utils(predictor)
