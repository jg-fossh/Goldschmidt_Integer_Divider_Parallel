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
# File name     : wb_standard_master_if.py
# Author        : Jose R Garcia
# Created       : 2020/11/22 10:20:00
# Last modified : 2021/02/16 12:20:05
# Project Name  : UVM-Python Verification Library
# Module Name   : wb_standard_master_if
# Description   : Wishbone master virtual interface
#
# Additional Comments:
#    Used to connect the agent and the UUT's bus.
##################################################################################################
import cocotb
from cocotb.triggers import *
from uvm.base.sv import sv_if

class wb_standard_master_if(sv_if):
    """         
       Class: Memory Interface Read Slave Interface
        
       Definition: Contains functions, tasks and methods of this agent's virtual interface.
    """


    def __init__(self, dut, bus_map=None):
        """         
           Function: new
          
           Definition: Read slave interface constructor.

           Args:
             dut: The dut it connects to. Passed in by cocotb top.
             bus_map: Naming of the bus signals.
        """
        if bus_map is None:
            #  If NONE then create the default.
            bus_map = {"clk_i": "clk_i", 
                       "rst_i": "rst_i",
                       "adr_i": "adr_i", 
                       "dat_i": "dat_i",
                       "dat_o": "dat_o", 
                       "we_i": "we_i",
                       "sel_o": "sel_o",
                       "stb_o": "stb_o",
                       "ack_i": "ack_i",
                       "cyc_o": "cyc_o",
                       "stall_i": "stall_i",
                       "tga_i": "tga_i",
                       "tgd_i": "tgd_i",
                       "tgd_o": "tgd_o",
                       "tgc_o": "tgc_o"}
        super().__init__(dut, "",bus_map)
        #self.rst = dut.i_reset_sync

    
    async def start(self):
        await Timer(0, "NS")
