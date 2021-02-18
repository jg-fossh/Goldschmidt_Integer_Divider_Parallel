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
# File name     : scoreboard_simple.py
# Author        : Jose R Garcia
# Created       : 2020/12/08 13:42:32
# Last modified : 2021/02/16 09:30:38
# Project Name  : ORCs
# Module Name   : scoreboard_simple
# Description   : Scoreboard.
#
# Additional Comments:
#
#################################################################################

from uvm.base import *
from uvm.comps import *
from uvm.tlm1 import *
from uvm.macros import *
from externals.Wishbone_Standard_Master.wb_standard_master_seq import *
from externals.Wishbone_Standard_Slave.wb_standard_slave_seq import *

class scoreboard_simple(UVMScoreboard):
    """         
       Class: Scoreboard, Simple
        
       Definition: Contains functions, tasks and methods of this Scoreboard.
    """

    def __init__(self, name, parent):
        """         
           Function: __init__, new
          
           Definition: Class constructor.

           Args:
             phase: 
        """
        UVMScoreboard.__init__(self, name, parent)
        self.num_received = 0
        self.num_writes = 0
        self.num_init_reads = 0
        self.num_uninit_reads = 0
        self.sbd_error = False
        self.m_mem_expected = {}
        self.expected_trans = []
        self.received_trans = []
        self.tag = "scoreboard_simple" + name


    def build_phase(self, phase):
        super().build_phase(phase)
        """         
           Function: build_phase
          
           Definition: .

           Args:
             phase: build_phase
        """
        self.received_export = UVMAnalysisImp("received_export", self)

   
    def write(self, t):
        """         
           Function: write
          
           Definition: This function immediately receives the transaction sent to
             the UUT by the agent. Decodes the instruction and generates a response
             sent to the scoreboard. 

           Args:
             t: wb_standard_master_seq (Sequence Item)
        """
        #  Convert data_in from integer into a string array of binary characters.
        #  Index 0 in the array is the MSB index 32 is the LSB.
        self.received_trans = t
        self.num_received = self.num_received + 1
        #uvm_info(self.tag, t.convert2string(), UVM_LOW)
 

uvm_component_utils(scoreboard_simple)
