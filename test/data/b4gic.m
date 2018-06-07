%% MATPOWER Case Format : Version 2
mpc.version = '2';

%%-----  Power Flow Data  -----%%
%% system MVA base
mpc.baseMVA = 100;

%% bus data
%	bus_i	type	Pd	Qd	Gs	Bs	area	Vm	Va	baseKV	zone	Vmax	Vmin
mpc.bus = [
	1	1	0.0	0.0	0.0	0.0	1	1.1	0.0	765	1	1.3	0.7	
	2	1	0.0	0.0	0.0	0.0	1	1.1	0.0	765	1	1.3	0.7	
	3	1	1000.0	200.0	0.0	0.0	1	1.1	0.0	20	1	1.3	0.7	
	4	3	0.0	0.0	0.0	0.0	1	1.1	0.0	20	1	1	0.7	
];

%% generator data
%	bus	Pg	Qg	Qmax	Qmin	Vg	mBase	status	Pmax	Pmin	Pc1	Pc2	Qc1min	Qc1max	Qc2min	Qc2max	ramp_agc	ramp_10	ramp_30	ramp_q	apf
mpc.gen = [
	4	0.0	0.0	2000.0	-2000.0	1.1	100	1	2000.0	0.0	0	0	0	0	0	0	0	0	0	-1000	0
];

%% branch data
%	fbus	tbus	r	x	b	rateA	rateB	rateC	ratio	angle	status	angmin	angmax
mpc.branch = [
	1	3	0.0001	0.004	0	9000.0	0.0	0.0	1	0.0	1	-30.0	30.0
	1	2	0.000513	0.01	0	9000.0	0.0	0.0	1	0.0	1	-30.0	30.0
	2	4	0.0001	0.004	0	9000.0	0.0	0.0	1	0.0	1	-30.0	30.0
];

%%-----  OPF Data  -----%%
%% generator cost data
%	1	startup	shutdown	n	x1	y1	...	xn	yn
%	2	startup	shutdown	n	c(n-1)	...	c0
mpc.gencost = [
	2	0	0	3	0.11	5.0	0.0
];

