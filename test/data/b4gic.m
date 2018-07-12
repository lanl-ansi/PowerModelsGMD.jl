%% MATPOWER Case Format : Version 2
mpc.version = '2';

%%-----  Power Flow Data  -----%%
%% system MVA base
mpc.baseMVA = 100;

%% bus data
%    bus_i    type    Pd    Qd    Gs    Bs    area    Vm    Va    baseKV    zone    Vmax    Vmin
mpc.bus = [
	1	1	0	0	0	0	1	1.100000	0.000000	765	1	1.3	0.7
	2	1	0	0	0	0	1	1.100000	0.000000	765	1	1.3	0.7
	3	1	1000	200	0	0	1	1.100000	0.000000	20	1	1.3	0.7
	4	3	0	0	0	0	1	1.100000	0.000000	20	1	1	0.7
];

%% generator data
%    bus    Pg    Qg    Qmax    Qmin    Vg    mBase    status    Pmax    Pmin    Pc1    Pc2    Qc1min    Qc1max    Qc2min    Qc2max    ramp_agc    ramp_10    ramp_30    ramp_q    apf
mpc.gen = [
	4	0.0	0.0	2000.0	-2000.0	1.1	100	1	2000.0	0.0	0	0	0	0	0	0	0	0	0	-1000	0
];

%% branch data
%    fbus    tbus    r    x    b    rateA    rateB    rateC    ratio    angle    status    angmin    angmax
mpc.branch = [
	1	3	0.0001	0.004	0	9000.0	0.0	0.0	1	0.0	1	-30.0	30.0
	1	2	0.000513	0.01	0	9000.0	0.0	0.0	1	0.0	1	-30.0	30.0
	2	4	0.0001	0.004	0	9000.0	0.0	0.0	1	0.0	1	-30.0	30.0
];

%%-----  OPF Data  -----%%
%% generator cost data
%    1    startup    shutdown    n    x1    y1    ...    xn    yn
%    2    startup    shutdown    n    c(n-1)    ...    c0
mpc.gencost = [
	2	0	0	3	0.11	5.0	0
];

%column_names% parent_index g_gnd name
mpc.gmd_bus = {
	1	5	'dc_sub1'	
	2	5	'dc_sub2'	
	1	0	'dc_bus1'	
	2	0	'dc_bus2'	
	3	0	'dc_bus3'	
	4	0	'dc_bus4'	
};

%column_names%  f_bus t_bus parent_index br_status br_r br_v len_km name
mpc.gmd_branch = {
	3	1	1	1	0.1	0	0	'dc_xf1_hi'	
	3	4	2	1	1.00073475	170.78806587354	170.78806587354	'dc_br1'	
	4	2	3	1	0.1	0	0	'dc_xf2_hi'	
};

%column_names%  hi_bus lo_bus gmd_br_hi gmd_br_lo gmd_k gmd_br_series gmd_br_common baseMVA type config
mpc.branch_gmd = {
	1	3	1	-1	1.793	-1	-1	100	'xf'	'gwye-delta'	
	1	2	-1	-1	0	-1	-1	100	'line'	'none'	
	2	4	3	-1	1.793	-1	-1	100	'xf'	'gwye-delta'	
};

%column_names%  lat lon
mpc.bus_gmd = {
	40	-89	
	40	-87	
	40	-89	
	40	-87	
};

