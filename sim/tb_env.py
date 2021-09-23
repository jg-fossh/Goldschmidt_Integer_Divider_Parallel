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
# File name     : tb_env.py
# Author        : Jose R Garcia
# Created       : 2020/11/05 20:08:35
# Last modified : 2021/06/24 23:19:01
# Project Name  : Goldschmidt Integer Divider
# Module Name   : tb_env
# Description   : Test Bench Environment.
#
# Additional Comments:
#
##################################################################################################
import cocotb
from cocotb_coverage.coverage import *

from uvm.base import *
from uvm.comps import *
from uvm.macros import uvm_component_utils

from wb4_master_agent import *
from wb4_slave_agent import *

from predictor import *
from f_cov import *

class tb_env(UVMEnv):
    """
       Class: Test Bench Environment

       Definition: Contains functions, tasks and methods.
    """

    def __init__(self, name, parent=UVMEnv):
        super().__init__(name, parent)
        """
           Function: new

           Definition: Constructor.

           Args:
             name: This agents name.
             parent: NONE
        """
        self.wb4_master_agent = None # WB Instruction agent
        self.wb4_slave_agent  = None # WB Instruction agent
        self.cfg              = None # tb_env_config
        self.scoreboard       = None # scoreboard
        self.predictor        = None # passive
        self.f_cov            = None # functional coverage
        self.tag              = name #


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

        self.wb4_master_agent     = wb4_master_agent.type_id.create("wb4_master_agent", self)
        self.wb4_master_agent.cfg = self.cfg.wb4_master_agent_cfg

        self.wb4_slave_agent     = wb4_slave_agent.type_id.create("wb4_slave_agent", self)
        self.wb4_slave_agent.cfg = self.cfg.wb4_slave_agent_cfg

        self.predictor = predictor.type_id.create("predictor", self)
        self.f_cov = f_cov.type_id.create("f_cov", self)

        if (self.cfg.has_scoreboard):
            self.scoreboard = UVMInOrderClassComparator.type_id.create("scoreboard", self)


    def connect_phase(self, phase):
        super().connect_phase(phase)
        """
           Function: connect_phase

           Definition: Connects the analysis port and sequence item export.

           Args:
             phase: connect_phase
        """


        if (self.cfg.has_scoreboard):
            self.wb4_master_agent.ap.connect(self.scoreboard.after_export)

        if (self.cfg.has_predictor):
            self.predictor.data_length = self.cfg.DUT_SLAVE_DATA_IN_LENGTH
            self.wb4_slave_agent.ap.connect(self.predictor.analysis_export)
            self.predictor.ap.connect(self.scoreboard.before_export)

        if (self.cfg.has_functional_coverage):
            self.f_cov.data_length = self.cfg.DUT_SLAVE_DATA_IN_LENGTH
            self.f_cov.data_bins_range = self.cfg.data_bins_range
            self.wb4_slave_agent.ap.connect(self.f_cov.analysis_export)

uvm_component_utils(tb_env)
