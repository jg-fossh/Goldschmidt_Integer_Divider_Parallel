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
# File name     : wb_standard_master_agent.py
# Author        : Jose R Garcia
# Created       : 2020/11/09 21:43:54
# Last modified : 2021/01/10 11:40:42
# Project Name  : UVM-Python Verification Library
# Module Name   : wb_standard_master_agent
# Description   : Wishbone Bus Master Verification Component Agent.
#
# Additional Comments:
#   The agent's components instantiations and connections.
##################################################################################################
from uvm import *
from wb_standard_master_if import *
from wb_standard_master_driver import *
from wb_standard_master_sequencer import *
from wb_standard_master_monitor import *

class wb_standard_master_agent(UVMAgent):
    """         
       Class: Wishbone Bus Verification Component Agent
        
       Definition: Contains the instantiations and connections of this agents components.
    """
    
    def __init__(self, name, parent=None):
        """         
           Function: new
          
           Definition: Agent constructor.

           Args:
             name: This agents name.
             parent: NONE
        """
        super().__init__(name, parent)
        self.cfg = None  # agent_config
        self.sqr = None  # agent_sequencer
        self.drv = None  # agent (driver)
        self.mon = None  # agent_monitor
        self.ap  = UVMAnalysisPort("ap", self) # analysis port for the monitor


    def build_phase(self, phase):
        super().build_phase(phase)
        """         
           Function: build_phase
          
           Definition: Create a new read slave agent with all its components.

           Args:
             phase: build_phase
        """
        #  arr = []
        #  if (not UVMConfigDb.get(self, "*", "cfg", arr)):
        #      uvm_fatal("wb_standard_master_agent", "No config")
        #  self.cfg = arr[0]
        
        if (self.cfg.has_driver == 1):
            self.drv = wb_standard_master_driver.type_id.create("drv", self)
            # self.sqr = wb_standard_master_agent_sequencer.type_id.create("sqr", self)
            self.sqr = UVMSequencer.type_id.create("sqr", self)
       
        if (self.cfg.has_monitor == 1):
            self.mon = wb_standard_master_monitor.type_id.create("mon", self)


    def connect_phase(self, phase):
        """         
           Function: connect_phase
          
           Definition: Connects the analysis port and sequence item export. 

           Args:
             phase: connect_phase
        """
        if (self.cfg.has_monitor):
            self.mon.vif = self.cfg.vif
            self.mon.ap.connect(self.ap)
       
        if (self.cfg.has_driver):
            self.drv.seq_item_port.connect(self.sqr.seq_item_export) # Driver Connection
            self.drv.vif = self.cfg.vif


uvm_component_utils(wb_standard_master_agent)
