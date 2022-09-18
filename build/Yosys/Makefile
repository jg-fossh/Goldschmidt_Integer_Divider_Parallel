PROJ = Goldschmidt_Integer_Divider_Parallel
PIN_DEF = up5k
DEVICE = up5k
PACKAGE = sg48
PLACE_AND_ROUTE = nextpnr-ice40
SEED_0 = 10
SEED_1 = 107
SEED_2 = 207
SEED_3 = 307
SEED_4 = 407
SEED_5 = 507
SEED_6 = 607
SEED_7 = 707
SEED_8 = 807
SEED_9 = 907
SEED_10 = 1007
SEED_11 = 1107

all: clean asc_0 rpt_0 assertions

assertions: 
	egrep -w 'Error-Type|Error-Msg' $(PROJ)_$(DEVICE)_syn.log

pnr: asc_0 asc_1 asc_2 asc_3 asc_4 asc_5 asc_6 asc_7 asc_8 asc_9 asc_10 asc_11

rpt: rpt_0 rpt_1 rpt_2 rpt_3 rpt_4 rpt_5 rpt_6 rpt_7 rpt_8 rpt_9 rpt_10 rpt_11

blif:
	yosys -ql $(PROJ)_$(DEVICE)_syn.log syn_ice40.ys $^

asc_0: blif 
	$(PLACE_AND_ROUTE) --$(DEVICE) --package $(PACKAGE) --json $(PROJ)_syn.json --pcf $(PIN_DEF).pcf --pcf-allow-unconstrained --timing-allow-fail --ignore-loops --pre-pack pre_pack.py --opt-timing --seed $(SEED_0) --asc $(PROJ)_$(SEED_0).asc --report critical_path_rpt$(SEED_0).json

asc_1: blif
	$(PLACE_AND_ROUTE) --$(DEVICE) --package $(PACKAGE) --json $(PROJ)_syn.json --pcf $(PIN_DEF).pcf --pcf-allow-unconstrained --timing-allow-fail --ignore-loops --pre-pack pre_pack.py --opt-timing --seed $(SEED_1) --asc $(PROJ)_$(SEED_1).asc --report critical_path_rpt$(SEED_1).json

asc_2: blif
	$(PLACE_AND_ROUTE) --$(DEVICE) --package $(PACKAGE) --json $(PROJ)_syn.json --pcf $(PIN_DEF).pcf --pcf-allow-unconstrained --timing-allow-fail --ignore-loops --pre-pack pre_pack.py --opt-timing --seed $(SEED_2) --asc $(PROJ)_$(SEED_2).asc --report critical_path_rpt$(SEED_2).json

asc_3: blif
	$(PLACE_AND_ROUTE) --$(DEVICE) --package $(PACKAGE) --json $(PROJ)_syn.json --pcf $(PIN_DEF).pcf --pcf-allow-unconstrained --timing-allow-fail --ignore-loops --pre-pack pre_pack.py --opt-timing --seed $(SEED_3) --asc $(PROJ)_$(SEED_3).asc --report critical_path_rpt$(SEED_3).json

asc_4: blif
	$(PLACE_AND_ROUTE) --$(DEVICE) --package $(PACKAGE) --json $(PROJ)_syn.json --pcf $(PIN_DEF).pcf --pcf-allow-unconstrained --timing-allow-fail --ignore-loops --pre-pack pre_pack.py --opt-timing --seed $(SEED_4) --asc $(PROJ)_$(SEED_4).asc --report critical_path_rpt$(SEED_4).json

asc_5: blif
	$(PLACE_AND_ROUTE) --$(DEVICE) --package $(PACKAGE) --json $(PROJ)_syn.json --pcf $(PIN_DEF).pcf --pcf-allow-unconstrained --timing-allow-fail --ignore-loops --pre-pack pre_pack.py --opt-timing --seed $(SEED_5) --asc $(PROJ)_$(SEED_5).asc --report critical_path_rpt$(SEED_5).json

asc_6: blif
	$(PLACE_AND_ROUTE) --$(DEVICE) --package $(PACKAGE) --json $(PROJ)_syn.json --pcf $(PIN_DEF).pcf --pcf-allow-unconstrained --timing-allow-fail --ignore-loops --pre-pack pre_pack.py --opt-timing --seed $(SEED_6) --asc $(PROJ)_$(SEED_6).asc --report critical_path_rpt$(SEED_6).json

asc_7: blif
	$(PLACE_AND_ROUTE) --$(DEVICE) --package $(PACKAGE) --json $(PROJ)_syn.json --pcf $(PIN_DEF).pcf --pcf-allow-unconstrained --timing-allow-fail --ignore-loops --pre-pack pre_pack.py --opt-timing --seed $(SEED_7) --asc $(PROJ)_$(SEED_7).asc --report critical_path_rpt$(SEED_7).json

asc_8: blif
	$(PLACE_AND_ROUTE) --$(DEVICE) --package $(PACKAGE) --json $(PROJ)_syn.json --pcf $(PIN_DEF).pcf --pcf-allow-unconstrained --timing-allow-fail --ignore-loops --pre-pack pre_pack.py --opt-timing --seed $(SEED_8) --asc $(PROJ)_$(SEED_8).asc --report critical_path_rpt$(SEED_8).json

asc_9: blif
	$(PLACE_AND_ROUTE) --$(DEVICE) --package $(PACKAGE) --json $(PROJ)_syn.json --pcf $(PIN_DEF).pcf --pcf-allow-unconstrained --timing-allow-fail --ignore-loops --pre-pack pre_pack.py --opt-timing --seed $(SEED_9) --asc $(PROJ)_$(SEED_9).asc --report critical_path_rpt$(SEED_9).json

asc_10: blif
	$(PLACE_AND_ROUTE) --$(DEVICE) --package $(PACKAGE) --json $(PROJ)_syn.json --pcf $(PIN_DEF).pcf --pcf-allow-unconstrained --timing-allow-fail --ignore-loops --pre-pack pre_pack.py --opt-timing --seed $(SEED_10) --asc $(PROJ)_$(SEED_10).asc --report critical_path_rpt$(SEED_10).json

asc_11: blif
	$(PLACE_AND_ROUTE) --$(DEVICE) --package $(PACKAGE) --json $(PROJ)_syn.json --pcf $(PIN_DEF).pcf --pcf-allow-unconstrained --timing-allow-fail --ignore-loops --pre-pack pre_pack.py --opt-timing --seed $(SEED_11) --asc $(PROJ)_$(SEED_11).asc --report critical_path_rpt$(SEED_11).json



rpt_0: asc_0
	icetime -d $(DEVICE) -p $(PIN_DEF).pcf -P $(PACKAGE) -c 12 -mtr Timming_Report_$(SEED_0).rpt $(PROJ)_$(SEED_0).asc

rpt_1: asc_1
	icetime -d $(DEVICE) -p $(PIN_DEF).pcf -P $(PACKAGE) -c 12 -mtr Timming_Report_$(SEED_1).rpt $(PROJ)_$(SEED_1).asc

rpt_2: asc_2
	icetime -d $(DEVICE) -p $(PIN_DEF).pcf -P $(PACKAGE) -c 12 -mtr Timming_Report_$(SEED_2).rpt $(PROJ)_$(SEED_2).asc

rpt_3: asc_3
	icetime -d $(DEVICE) -p $(PIN_DEF).pcf -P $(PACKAGE) -c 12 -mtr Timming_Report_$(SEED_3).rpt $(PROJ)_$(SEED_3).asc

rpt_4: asc_4
	icetime -d $(DEVICE) -p $(PIN_DEF).pcf -P $(PACKAGE) -c 12 -mtr Timming_Report_$(SEED_4).rpt $(PROJ)_$(SEED_4).asc

rpt_5: asc_5
	icetime -d $(DEVICE) -p $(PIN_DEF).pcf -P $(PACKAGE) -c 12 -mtr Timming_Report_$(SEED_5).rpt $(PROJ)_$(SEED_5).asc

rpt_6: asc_6
	icetime -d $(DEVICE) -p $(PIN_DEF).pcf -P $(PACKAGE) -c 12 -mtr Timming_Report_$(SEED_6).rpt $(PROJ)_$(SEED_6).asc

rpt_7: asc_7
	icetime -d $(DEVICE) -p $(PIN_DEF).pcf -P $(PACKAGE) -c 12 -mtr Timming_Report_$(SEED_7).rpt $(PROJ)_$(SEED_7).asc

rpt_8: asc_8
	icetime -d $(DEVICE) -p $(PIN_DEF).pcf -P $(PACKAGE) -c 12 -mtr Timming_Report_$(SEED_8).rpt $(PROJ)_$(SEED_8).asc

rpt_9: asc_9
	icetime -d $(DEVICE) -p $(PIN_DEF).pcf -P $(PACKAGE) -c 12 -mtr Timming_Report_$(SEED_9).rpt $(PROJ)_$(SEED_9).asc

rpt_10: asc_10
	icetime -d $(DEVICE) -p $(PIN_DEF).pcf -P $(PACKAGE) -c 12 -mtr Timming_Report_$(SEED_10).rpt $(PROJ)_$(SEED_10).asc

rpt_11: asc_11
	icetime -d $(DEVICE) -p $(PIN_DEF).pcf -P $(PACKAGE) -c 12 -mtr Timming_Report_$(SEED_11).rpt $(PROJ)_$(SEED_11).asc



bin: asc_0
	icepack $(PROJ)_$(SEED_0).asc $(PROJ).bin

prog: $(PROJ).bin
	iceprog $<

sudo-prog: $(PROJ).bin
	@echo 'Executing prog as root!!!'
	sudo iceprog $<

clean:
	rm -f $(PROJ)_syn.blif $(PROJ)_syn.edif $(PROJ).asc $(PROJ).rpt $(PROJ).bin $(PROJ)_syn.json $(PROJ)_$(DEVICE)_syn.log $(PROJ)_*.asc Timming_Report_* critical_path_rpt*.json

.SECONDARY:
.PHONY: all pnr rpt prog sudo-prog clean
