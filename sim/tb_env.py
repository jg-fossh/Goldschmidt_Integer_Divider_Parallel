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
# File name     : tb_env.py
# Author        : Jose R Garcia
# Created       : 2020/11/05 20:08:35
# Last modified : 2021/02/16 09:31:02
# Project Name  : UVM Python Verification Library
# Module Name   : tb_env
# Description   : Memory Slave Interface  monitor.
#
# Additional Comments:
#
#################################################################################
import cocotb
from uvm.base import *
from uvm.comps import *
from uvm.macros import uvm_component_utils
from externals.Wishbone_Standard_Master.wb_standard_master_agent import *
from externals.Wishbone_Standard_Slave.wb_standard_slave_agent import *
from predictor import *
# from scoreboard_simple import *

class tb_env(UVMEnv):
    """         
       Class: Test Bench Environment 
        
       Definition: Contains functions, tasks and methods.
    """

    def __init__(self, name, parent=None):
        super().__init__(name, parent)
        """         
           Function: new
          
           Definition: Constructor.

           Args:
             name: This agents name.
             parent: NONE
        """
        self.wb_master_agent = None # WB Instruction agent
        self.wb_slave_agent = None  # WB Instruction agent
        self.cfg = None             # tb_env_config
        self.scoreboard = None      # scoreboard
        self.predictor = None       # passive
        self.f_cov = None           # functional coverage
        self.tag = "tb_env"         #


    def build_phase(self, phase):
        super().build_phase(phase)
        """         
           Function: build_phase
          
           Definition: Gets configurations from the UVM Db and creates components.

           Args:
             phase: build_phase
        """
        arr = []
        if (not UVMConfigDb.get(self, "", "tb_env_config", arr)):
            uvm_fatal("TB_ENV/NoTbEnvConfig", "Test Bench config not found")
        
        self.cfg = arr[0]

        self.wb_master_agent = wb_standard_master_agent.type_id.create("wb_master_agent", self)
        self.wb_master_agent.cfg = self.cfg.wb_master_agent_cfg

        self.wb_slave_agent = wb_standard_slave_agent.type_id.create("wb_slave_agent", self)
        self.wb_slave_agent.cfg = self.cfg.wb_slave_agent_cfg
        
        self.predictor = predictor.type_id.create("predictor", self)
        
        if (self.cfg.has_scoreboard):
            self.scoreboard = UVMInOrderBuiltInComparator.type_id.create("scoreboard", self)

    
    def connect_phase(self, phase):
        super().connect_phase(phase)
        """         
           Function: connect_phase
          
           Definition: Connects the analysis port and sequence item export. 

           Args:
             phase: connect_phase
        """

        if (self.cfg.has_scoreboard):
            self.wb_master_agent.ap.connect(self.scoreboard.before_export)
            self.predictor.ap.connect(self.scoreboard.after_export)
        

        if (self.cfg.has_predictor):
            self.wb_master_agent.ap.connect(self.predictor.analysis_export)

uvm_component_utils(tb_env)
