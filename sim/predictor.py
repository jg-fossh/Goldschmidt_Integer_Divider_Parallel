##################################################################################################
# BSD 3-Clause License
#
# Copyright (c) 2022, Jose R. Garcia
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
# File name    : predictor.py
# Author       : Jose R Garcia (jg-fossh@protonmail.com)
# Project Name : Goldschmidt Integer Divider
# Class Name   : predictor
# Description  : Non Time Consuming model. Calculates the product of the division when tgd = 0
#                and calculates the remainder when tgd = 1.
#
# Additional Comments:
#
##################################################################################################
import binascii
from binascii import unhexlify, hexlify

import math

import cocotb
from cocotb.triggers import *
from uvm.base import *
from uvm.comps import *
from uvm.tlm1 import *
from uvm.macros import *
from wb4s_seq import *

class predictor(UVMSubscriber):
    """
       Class: Predictor

       Definition: Contains functions, tasks and methods of this predictor.
    """

    def __init__(self, name, parent=None):
        super().__init__(name, parent)
        """
           Function: new

           Definition: Adder.

           Args:
             name: This component's name.
             parent: NONE
        """
        self.ap = None
        self.num_items = 0
        self.tag = name
        #
        self.data_length = 0


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
             t: wb4s_seq (Sequence Item)
        """

        dividend, divisor = self.int_to_hex(t.data_in, int(self.data_length/2))

        if (t.cycle_tag == 0):
            # generate the result, convert it to hex, remove the '0x' appended by hex() and remove the overflow bit.
            if (divisor != 0):
                result_int = dividend / divisor
            else:
                result_int = -1


        if (t.cycle_tag == 2):
            # generate the result, convert it to hex, remove the '0x' appended by hex() and remove the overflow bit.
            if (divisor > 0):
                result_int = dividend % divisor
            else:
                result_int = -1

        if (t.cycle_tag == 1):
            if (divisor != 0):
                result_int = dividend / divisor
            else:
                result_int = -1

        if (t.cycle_tag == 3):
            # generate the result, convert it to hex, remove the '0x' appended by hex() and remove the overflow bit.
            if (divisor > 0):
                result_int = dividend % divisor
            else:
                result_int = -1

        uvm_info(self.get_type_name(), sv.sformatf("write() \
            \n  Dividen: %d <=> 0x%h \
            \n  Divisor: %d <=> 0x%h \
            \n  Result : %d <=> 0x%h",\
            dividend, dividend, divisor, divisor, round(result_int), round(result_int)), UVM_NONE)

        self.create_response(t, round(result_int))


    def create_response(self, t, result):
        """
           Function: create_response

           Definition: Creates a response transaction and updates the pc counter.

           Args:
             t: wb4s_seq (Sequence Item)
        """
        tr = wb4s_seq("tr")
        tr = t
        tr.data_out    = result
        tr.acknowledge = 1
        #tr = []
        #tr = t
        
        self.ap.write(tr)


    def int_to_hex(self, decimal_value, factors_length):
        """
           Function: hex_to_int

           Definition: This function returns the decimal value for a hexadecimal
             with a defined length.

           Args:
             factors_length: in bytes
             hex_value: a hex string without '0x' preappended
             hex_length: Number of bits used to represent the hex value
        """
        lower_mask = pow(2, factors_length)-1
        upper_mask = lower_mask << factors_length

        dividend = decimal_value & lower_mask
        divisor  = decimal_value & upper_mask
        divisor  = divisor >> factors_length

        # uvm_info(self.get_type_name(), sv.sformatf("int_to_hex() \
        #     \n Input vector: %d <=> 0x%h \
        #     \n  Data Length: %d \
        #     \n   Upper mask: 0x%h \
        #     \n   Lower mask: 0x%h \
        #     \n      Dividen: %d <=> 0x%h \
        #     \n      Divisor: %d <=> 0x%h",\
        #     int_value, int_value,factors_length, upper_mask, lower_mask, dividend, dividend, divisor, divisor), UVM_NONE)

        return dividend, divisor


uvm_component_utils(predictor)
