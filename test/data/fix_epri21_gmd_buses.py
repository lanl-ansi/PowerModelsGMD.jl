# -*- coding: utf-8 -*-
"""
Spyder Editor

This is a temporary script file.
"""
import json, os

with open('deprecated/epri21.json') as io:
    net = json.load(io)
    
gids = sorted([x['index'] for x in net['gmd_bus'].values()])

# %% gmd_bus data
# %column_names% parent_index parent_type status g_gnd name
# mpc.gmd_bus = {
# 	7	'sub'	1	4.621712806766188	'dc_sub7'
# 	8	'sub'	1	10.0	'dc_sub8'
# 	1	'bus'	1	0.0	'dc_bus1'
# 

header = '''
%% gmd_bus data
%column_names% parent_index status g_gnd name
%column_names% parent_index parent_type status g_gnd name
mpc.gmd_bus = {'''

print(header)

for i in gids:
    gb = net['gmd_bus'][f'{i}']
    g = gb['g_gnd']
    tp = gb['parent_type']
    ip = gb['parent_index'] 
    name = gb['name']
    print(f"\t{ip}\t'{tp}'\t1\t{g}\t'{name}'")
    
print('};')