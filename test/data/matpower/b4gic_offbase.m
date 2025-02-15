% Case saved by PowerWorld Simulator, version 23, build date October 31, 2023
% Case Information Header = 2 lines
%  
%  
function mpc = b4gic_offbase
mpc.version = '2';
mpc.baseMVA =  100.00;

%% bus data 
mpc.bus = [
1	1	0.00	0.00	0.00	0.00	1	0.9998575	8.033893	765.00	1	1.100	0.900
2	1	0.00	0.00	0.00	0.00	1	0.9972043	2.289643	765.00	1	1.100	0.900
3	2	0.00	0.00	0.00	0.00	1	1.0019374	9.861487	20.00	1	1.100	0.900
4	3	0.00	0.00	0.00	0.00	1	1.0000000	0.000000	20.00	1	1.100	0.900
];

%% generator data 
mpc.gen = [
3	1000.00	57.24	57.24	57.24	1.0019	2000.00	1	1000.00	1000.00	0.00	0.00	0.00	0.00	0.00	0.00	0	0	0	0	0.0000
4	-993.12	114.62	9900.00	-9900.00	1.0000	2000.00	1	1000.00	0.00	0.00	0.00	0.00	0.00	0.00	0.00	0	0	0	0	10.0000
];

%% generator cost data
mpc.gencost = [
2	0	0	4	0.0000	0.001	11.831	616.86
2	0	0	1	0	0	0	0
];

%% branch data
mpc.branch = [
1	2	0.000513	0.010000	0.00000	2000.00	0.00	0.00	0.00000	0.000	1	0.00	0.00	999.24	25.33	-994.11	74.61
1	3	0.000076	0.003199	0.00000	2000.00	0.00	0.00	1.00000	0.000	1	0.00	0.00	-999.21	-25.28	999.97	57.26
2	4	0.000100	0.004000	0.00000	2000.00	0.00	0.00	1.00000	0.000	1	0.00	0.00	994.12	-74.65	-993.12	114.62
];

%% bus names
mpc.bus_name = {
'Bus 1';
'Bus 2';
'Bus 3';
'Bus 4';
};

%% Generator Unit Types
mpc.gentype = {
'UN';
'UN';
};

%% Generator Fuel Types
mpc.genfuel = {
'unknown';
'unknown';
};

%% gmd_bus data
%column_names% parent_index status g_gnd sub name
mpc.gmd_bus = {
-1	1	5.00000		-1	'dc sub Sub A'
-1	1	5.00000		-1	'dc sub Sub B'
1	1	0.00000		1	'dc bus Bus 1'
2	1	0.00000		2	'dc bus Bus 2'
3	1	0.00000		1	'dc bus Bus 3'
4	1	0.00000		2	'dc bus Bus 4'
};

%% gmd_branch data
%column_names% f_bus t_bus parent_type parent_index br_status br_r br_v len_km name
mpc.gmd_branch = {
3	4	'branch'	1	1	1.00073		106.12311	170.78859	'dc 1'		% line 1-2
3	1	'branch'	2	1	0.10000		0.00000		0.00000		'dc 2_hi'	% transformer 1-3
4	2	'branch'	3	1	0.10000		0.00000		0.00000		'dc 3_hi'	% transformer 2-4
3	1	'bus'	1	1	25000.00000		0.00000		0.00000		'dc bus_3'
4	2	'bus'	2	1	25000.00000		0.00000		0.00000		'dc bus_4'
5	1	'bus'	3	1	25000.00000		0.00000		0.00000		'dc bus_5'
6	2	'bus'	4	1	25000.00000		0.00000		0.00000		'dc bus_6'
};

%% branch_gmd data
%column_names% hi_bus lo_bus gmd_br_hi gmd_br_lo gmd_k gmd_br_series gmd_br_common baseMVA type config
mpc.branch_gmd = {
    1	2	-1	-1	-1.00000	-1		-1		100.0	'line'	'none'
    1	3	2	-1	1.80000     -1		-1		125.0	'xfmr'	'gwye-delta'
    2	4	3	-1	1.80000     -1		-1		100.0	'xfmr'	'gwye-delta'
};

%% bus_gmd data
%column_names% lat lon
mpc.bus_gmd = {
40.00000    -89.00000		
40.00000    -87.00000		
40.00000    -89.00000		
40.00000    -87.00000		
};

%% branch_thermal data
%column_names% xfmr temperature_ambient hotspot_instant_limit hotspot_avg_limit hotspot_rated topoil_time_const topoil_rated topoil_init topoil_initialized hotspot_coeff
mpc.branch_thermal = {
0	-1	-1	-1	-1	-1	-1	-1	-1	-1
1	25	280	240	150	71	75	0	1	0.63
1	25	280	240	150	71	75	0	1	0.63
};
