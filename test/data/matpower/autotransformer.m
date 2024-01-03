% Case saved by PowerWorld Simulator, version 23, build date October 31, 2023
function mpc = autotransformer
mpc.version = '2';
mpc.baseMVA =  100.00;

%% bus data 
mpc.bus = [
1	3	0.00	0.00	0.00	0.00	1	1.0200000	0.000000	20.00	1	1.100	0.900
2	1	0.00	0.00	0.00	0.00	1	1.0145274	-1.108127	345.00	1	1.100	0.900
3	1	0.00	0.00	0.00	0.00	1	1.0012179	-3.913351	345.00	1	1.100	0.900
4	1	0.00	0.00	0.00	0.00	1	0.9846040	-11.218635	500.00	1	1.100	0.900
5	1	0.00	0.00	0.00	0.00	1	0.9802384	-14.188484	500.00	1	1.100	0.900
6	1	500.00	0.00	0.00	0.00	1	0.9796940	-14.665789	20.00	1	1.100	0.900
];

%% generator data 
mpc.gen = [
1	503.61	131.80	9900.00	-9900.00	1.0200	100.00	1	503.61	503.61	0.00	0.00	0.00	0.00	0.00	0.00	0	0	0	0	10.0000
];

%% generator cost data
mpc.gencost = [
2	0	0	4	0	0	1	0
];

%% branch data
mpc.branch = [
1	2	0.000100	0.004000	0.00000	2000.00	0.00	0.00	1.00000	0.000	1	0.00	0.00	503.61	131.80	-503.35	-121.38
2	3	0.000513	0.010000	0.00000	0.00	0.00	0.00	0.00000	0.000	1	0.00	0.00	503.35	121.38	-502.01	-95.33
3	4	0.000160	0.025000	0.00000	0.00	0.00	0.00	1.00000	0.000	1	0.00	0.00	502.01	95.33	-501.60	-30.21
4	5	0.000513	0.010000	0.00000	0.00	0.00	0.00	0.00000	0.000	1	0.00	0.00	501.60	30.21	-500.26	-4.17
5	6	0.000100	0.001600	0.00000	0.00	0.00	0.00	1.00000	0.000	1	0.00	0.00	500.26	4.17	-500.00	0.00
];

%% bus names
mpc.bus_name = {
'1';
'2';
'3';
'4';
'5';
'6';
};

%% Generator Unit Types
mpc.gentype = {
'UN';
};

%% Generator Fuel Types
mpc.genfuel = {
'unknown';
};

%% gmd_bus data
%column_names% parent_index status g_gnd name
mpc.gmd_bus = {
1	1	3.90560		'dc Sub1'
2	1	5.66030		'dc Sub2'
3	1	5.66030		'dc Sub3'
1	1	0.00000		'dc 1'
2	1	0.00000		'dc 2'
3	1	0.00000		'dc 3'
4	1	0.00000		'dc 4'
5	1	0.00000		'dc 5'
6	1	0.00000		'dc 6'
};

%% gmd_branch data
%column_names% f_bus t_bus parent_index br_status br_r br_v len_km name
mpc.gmd_branch = {
5	6	2	1	0.20353		170.78859		170.78859		'dc 2'
7	8	4	1	0.42750		170.78859		170.78859		'dc 4'
8	3	5	1	0.04167		0.00000		0.00000		'dc 5_hi'
5	1	1	1	0.01984		0.00000		0.00000		'dc 1_hi'
7	6	3	1	0.06667		0.00000		0.00000		'dc 3_series'
6	2	3	1	0.33028		0.00000		0.00000		'dc 3_common'
};

%% branch_gmd data
%column_names% hi_bus lo_bus gmd_br_hi gmd_br_lo gmd_k gmd_br_series gmd_br_common baseMVA type config
mpc.branch_gmd = {
2	1	4	-1	1.50000		-1		-1		100	'xfmr'	'gwye-delta'
2	3	-1	-1	-1.00000		-1		-1		100	'line'	'none'
4	3	-1	-1	1.80000		5		6		100	'xfmr'	'gwye-gwye-auto'
4	5	-1	-1	-1.00000		-1		-1		100	'line'	'none'
5	6	3	-1	1.80000		-1		-1		100	'xfmr'	'gwye-delta'
};

%% bus_gmd data
%column_names% lat lon
mpc.bus_gmd = {
40.00000		40.00000		
40.00000		40.00000		
40.00000		40.00000		
40.00000		40.00000		
40.00000		40.00000		
40.00000		40.00000		
};

%% branch_thermal data
%column_names% xfmr temperature_ambient hotspot_instant_limit hotspot_avg_limit hotspot_rated topoil_time_const topoil_rated topoil_init topoil_initialized hotspot_coeff
mpc.branch_thermal = {
1	25	280	240	150	71	75	0	1	0.63
0	-1	-1	-1	-1	-1	-1	-1	-1	-1
1	25	280	240	150	71	75	0	1	0.63
0	-1	-1	-1	-1	-1	-1	-1	-1	-1
1	25	280	240	150	71	75	0	1	0.63
};
