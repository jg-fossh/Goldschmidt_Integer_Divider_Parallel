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
# File name     : f_cov.py
# Author        : Jose R Garcia
# Created       : 2020/11/05 20:08:35
# Last modified : 2021/06/27 00:22:44
# Project Name  : Goldschmidt Integer Divider
# Module Name   : f_cov
# Description   : Funtional Coverage definitions and collections.
#
# Additional Comments:
#
##################################################################################################
import binascii
from binascii import unhexlify, hexlify

import math

import cocotb
import cocotb_coverage
from cocotb.triggers import *
from cocotb_coverage.crv import *
from cocotb_coverage import coverage
from cocotb_coverage.coverage import *

from uvm.base import *
from uvm.comps import *
from uvm.tlm1 import *
from uvm.macros import *
from wb4_master_seq import *
from wb4_slave_seq import *


class f_cov(UVMSubscriber):
    """
       Class: Predictor

       Definition: Contains functions, tasks and methods of this f_cov.
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
        self.num_items    = 0
        self.tag          = name
        self.data_length  = 0
        self.factors_bins = None
        #
        self.data_bins_range = [0, 50]


    def end_of_elaboration_phase(self, phase):
        """
           Function: end_of_elaboration_phase

           Definition: This function is executed before the run phase. We generate the coverage
             bins after the connect and build phase so that if the test intents to modify
             self.data_bins_range it should have already done so. Also this way we only generate
             self.factors_bins once as it is a loop that may have the pontential to slow the
             simulation.
        """

        if (self.data_length >= 8):
            # translate data length from width in bits to width in hex characters
            self.data_length = int(self.data_length / (8))

        self.factors_bins = self.hex_bins_gen(self.data_length)


    def write(self, t):
        """
           Function: write

           Definition: This function immediately receives the transaction sent to
             the UUT by the agent. Decodes the instruction and generates a response
             sent to the scoreboard.

           Args:
             t: wb4_slave_seq (Sequence Item)
        """

        # Define the cover point
        @coverage.CoverPoint("dut.operation", vname="div_rem_signess", bins = [0, 1, 2, 3], weight = 80)
        @coverage.CoverPoint("dut.dividend", vname="dividend", bins = self.factors_bins, weight = 10)
        @coverage.CoverPoint("dut.divisor", vname="divisor", bins = self.factors_bins, weight = 10)
        def sample(div_rem_signess, dividend, divisor):
            pass

        # get a string with the hex value of the dividend and the divisor
        dividend, divisor = self.int_to_hex(t.data_in, self.data_length)

        # Collect coverage
        sample(t.data_tag , dividend, divisor)


    def int_to_hex(self, int_value, factors_length):
        """
           Function: hex_to_int

           Definition: This function returns the decimal value for a hexadecimal
             with a defined length.

           Args:
             factors_length: in bytes
             hex_value: a hex string without '0x' preappended
             hex_length: Number of bits used to represent the hex value
        """
        data_in = hex(int_value).lstrip("0x").rstrip("L")

        if (len(data_in) < factors_length*2):
            for x in range(0, (factors_length*2)-len(data_in)):
                data_in = "0"+data_in

        dividend = data_in[factors_length:]
        divisor = data_in[:factors_length]

        return dividend, divisor


    # Define the bins for the hex values
    def hex_bins_gen(self, num_bytes):
        hex_bins_list = [""] * (self.data_bins_range[1]-self.data_bins_range[0])

        for ii in range(self.data_bins_range[0], self.data_bins_range[1]):
            count, discard_this = self.int_to_hex(ii, num_bytes)
            hex_bins_list[ii] = count

        return hex_bins_list

uvm_component_utils(f_cov)
