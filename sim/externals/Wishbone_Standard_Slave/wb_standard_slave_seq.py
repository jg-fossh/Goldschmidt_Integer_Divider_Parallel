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
# File name     : wb_standard_slave_seq.py
# Author        : Jose R Garcia
# Created       : 2020/11/22 10:24:13
# Last modified : 2021/01/10 11:42:57
# Project Name  : UVM Python Verification Library
# Module Name   : wb_standard_slave_seq, wb_standard_slave_base_sequence
# Description   : Wishbone Bus Sequence Item and Sequences.
#
# Additional Comments:
#   Create a a read or write transaction.
##################################################################################################
from uvm import *

class wb_standard_slave_seq(UVMSequenceItem):
    """         
       Class: Wishbone Master Sequence Item
        
       Definition: Contains functions, tasks and methods of this
    """

    def __init__(self, name="wb_standard_slave_seq"):
        super().__init__(name)
        self.data_in           = 0 
        self.data_out          = 0 
        self.addr              = 0 
        self.stall             = 0 
        self.response_data_tag = 0 
        self.acknowledge       = 1
        self.transmit_delay    = 0 
        

    def do_copy(self, rhs):
        self.data_in           = rhs.data_in
        self.data_out          = rhs.data_out
        self.addr              = rhs.addr
        self.stall             = rhs.stall
        self.response_data_tag = rhs.response_data_tag
        self.acknowledge       = rhs.acknowledge
        self.transmit_delay    = rhs.transmit_delay


    def do_clone(self):
        new_obj = wb_standard_slave_seq()
        new_obj.copy(self)
        return new_obj


    def convert2string(self):
        return sv.sformatf("\n =================================== \n    ACK_i : %d \n    TDG_i : 0x%0h \n   DATA_i : 0x%0h \n    Delay : %d  clocks \n =================================== \n ",
                self.acknowledge, self.response_data_tag, self.data_in, self.transmit_delay)


uvm_object_utils(wb_standard_slave_seq)


class wb_standard_slave_base_sequence(UVMSequence):

    def __init__(self, name="wb_standard_slave_base_sequence"):
        super().__init__(name)
        self.set_automatic_phase_objection(1)
        self.req = wb_standard_slave_seq()
        self.rsp = wb_standard_slave_seq()

uvm_object_utils(wb_standard_slave_base_sequence)


class wb_slave_read_single_sequence(wb_standard_slave_base_sequence):
    """         
       Class: Wishbone Read Sequence
        
       Definition: Contains functions, tasks and methods
    """
    def __init__(self, name="read_single_sequence"):
        wb_standard_slave_base_sequence.__init__(self, name)
        self.data              = 0
        self.addr              = 0
        self.stall             = 0
        self.transmit_delay    = 0
        self.response_data_tag = 0
        self.acknowledge       = 1

    async def body(self):
        # Build the sequence item
        self.req.data_in           = self.data
        self.req.addr              = self.addr
        self.req.stall             = self.stall
        self.req.response_data_tag = self.response_data_tag
        self.req.acknowledge       = self.acknowledge
        self.req.transmit_delay    = self.transmit_delay

        await uvm_do_with(self, self.req) # start_item 


uvm_object_utils(wb_slave_read_single_sequence)


class wb_slave_write_single_sequence(wb_standard_slave_base_sequence):
    """         
       Class: Wishbone Write Sequence
        
       Definition: Contains functions, tasks and methods
    """
    def __init__(self, name="write_single_sequence"):
        wb_standard_slave_base_sequence.__init__(self, name)
        self.data              = 0
        self.addr              = 0
        self.stall             = 0
        self.transmit_delay    = 0
        self.response_data_tag = 0
        self.acknowledge       = 1


    async def body(self):
        # Build the sequence item
        self.req.data_in           = self.data
        self.req.addr              = self.addr
        self.req.stall             = self.stall
        self.req.response_data_tag = self.response_data_tag
        self.req.acknowledge       = self.acknowledge
        self.req.transmit_delay    = self.transmit_delay

        await uvm_do_with(self, self.req) # start_item 


uvm_object_utils(wb_slave_write_single_sequence)
