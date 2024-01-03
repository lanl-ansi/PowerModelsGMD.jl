% Case saved by PowerWorld Simulator, version 23, build date October 31, 2023
% Case Information Header = 2 lines
%  
%  
function mpc = b4gic
mpc.version = '2';
mpc.baseMVA =  100.00;

%% bus data 
mpc.bus = [
1	1	0.00	0.00	0.00	0.00	1	0.9987129	8.044083	765.00	1	1.100	0.900
2	1	0.00	0.00	0.00	0.00	1	0.9968737	2.290307	765.00	1	1.100	0.900
3	2	0.00	0.00	0.00	0.00	1	1.0012021	10.333371	20.00	1	1.100	0.900
4	3	0.00	0.00	0.00	0.00	1	1.0000000	0.000000	20.00	1	1.100	0.900
];

%% generator data 
mpc.gen = [
3	1000.00	57.24	57.24	57.24	1.0012	2000.00	1	1000.00	1000.00	0.00	0.00	0.00	0.00	0.00	0.00	0	0	0	0	0.0000
4	-992.87	122.89	9900.00	-9900.00	1.0000	2000.00	1	1000.00	0.00	0.00	0.00	0.00	0.00	0.00	0.00	0	0	0	0	10.0000
];

%% generator cost data
mpc.gencost = [
2	0	0	4	0.0000	0.001	11.831	616.86
2	0	0	1	0	0	0	0
];

%% branch data
mpc.branch = [
1	2	0.000513	0.010000	0.00000	2000.00	0.00	0.00	0.00000	0.000	1	0.00	0.00	999.00	17.28	-993.87	82.81
1	3	0.000100	0.004000	0.00000	2000.00	0.00	0.00	1.00000	0.000	1	0.00	0.00	-998.97	-17.22	999.97	57.26
2	4	0.000100	0.004000	0.00000	2000.00	0.00	0.00	1.00000	0.000	1	0.00	0.00	993.87	-82.85	-992.87	122.89
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
%column_names% parent_index status g_gnd name
mpc.gmd_bus = {
1	1	5.00000		'dc Sub A'
2	1	5.00000		'dc Sub B'
1	1	0.00000		'dc Bus 1'
2	1	0.00000		'dc Bus 2'
3	1	0.00000		'dc Bus 3'
4	1	0.00000		'dc Bus 4'
};

%% gmd_branch data
%column_names% f_bus t_bus parent_index br_status br_r br_v len_km name
mpc.gmd_branch = {
3	4	1	1	1.00073		106.12311		170.78859		'dc 1'
3	1	2	1	0.10000		0.00000		0.00000		'dc 2_hi'
4	2	3	1	0.10000		0.00000		0.00000		'dc 3_hi'
};

%% branch_gmd data
%column_names% hi_bus lo_bus gmd_br_hi gmd_br_lo gmd_k gmd_br_series gmd_br_common baseMVA type config
mpc.branch_gmd = {
1	2	-1	-1	-1.00000		-1		-1		100	'line'	'none'
1	3	2	-1	1.80000		-1		-1		100	'xfmr'	'gwye-delta'
2	4	3	-1	1.80000		-1		-1		100	'xfmr'	'gwye-delta'
};

%% bus_gmd data
%column_names% lat lon
mpc.bus_gmd = {
40.00000		40.00000		
40.00000		40.00000		
40.00000		40.00000		
40.00000		40.00000		
};

%% branch_thermal data
%column_names% xfmr temperature_ambient hotspot_instant_limit hotspot_avg_limit hotspot_rated topoil_time_const topoil_rated topoil_init topoil_initialized hotspot_coeff
mpc.branch_thermal = {
0	-1	-1	-1	-1	-1	-1	-1	-1	-1
1	25	280	240	150	71	75	0	1	0.63
1	25	280	240	150	71	75	0	1	0.63
};
