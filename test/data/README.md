# PMsGMD Model Data Format

PowerModelGMD supports the following model data formats ...


## RAW and JSON Data Format

Data format similar to those used in PowerModelsONM ...

RAW is the simple model.
JSON is addition of PMsGMD data.


## MATPOWER Data Format

PMsGMD uses several extensions to the PMs data format to provide input for its problem specifications.
For generality, it uses a separate dc network defined by the `gmd_bus` and `gmd_branch` tables.
To correctly calculate the increased reactive power consumption of each transformer, the `branch_gmd` table adds all winding configuration related data. Furthermore, `branch_thermal` table adds thermal data necessary to determine the temperature changes in transformers.
The `bus_gmd` table includes the latitude and longitude of buses in the ac network for use in distributionally robust optimization or for convenience in plotting the network.

The description of B4GIC, an included four-bus test case is presented below to demonstrate the use of the PMsGMD data format and introduce each input fields.


### GMD Bus Data Table

This table includes
* `parent_index` - index of corresponding ac network bus
* `status` - binary value that defines the status of bus (1: enabled, 0: disabled)
* `g_gnd` - admittance to ground (in unit of Siemens)
* `name` - a descriptive name for the bus

```
%column_names% parent_index status g_gnd name
mpc.gmd_bus = {
	1	1	5	'dc_sub1'
	2	1	5	'dc_sub2'
	1	1	0	'dc_bus1'
	2	1	0	'dc_bus2'
	3	1	0	'dc_bus3'
	4	1	0	'dc_bus4'
};
```


### GMD Branch Data Table

This table includes
* `f_bus` - "from" bus in the gmd bus table
* `t_bus` - "to" bus in the gmd bus table
* `parent_index` - index of corresponding ac network branch
* `br_status` - binary value that defines the status of branch (1: enabled, 0: disabled)
* `br_r` - branch resistance (in unit of Ohms)
* `br_v` - induced quasi-dc voltage (in unit of Volts)
* `len_km` - length of branch (in unit of km) -- optional
* `name` - a descriptive name for the branch

```
%column_names% f_bus t_bus parent_index br_status br_r br_v len_km name
mpc.gmd_branch = {
	3	1	1	1	0.1	0	0	'dc_xf1_hi'
	3	4	2	1	1.001	170.788	170.788	'dc_br1'
	4	2	3	1	0.1	0	0	'dc_xf2_hi'
};
```


### Branch GMD Data Table

This table includes
* `hi_bus` - index of high-side ac network bus
* `lo_bus` - index of low-side ac network bus
* `gmd_br_hi` - index of gmd branch corresponding to high-side winding (for two-winding transformers)
* `gmd_br_lo` - index of gmd branch corresponding to low-side winding (for two-winding transformers)
* `gmd_k` - scaling factor to calculate reactive power consumption as a function of effective winding current (in per-unit)
* `gmd_br_series` - index of gmd branch corresponding to series winding (for auto-transformers)
* `gmd_br_common` - index of gmd branch corresponding to common winding (for auto-transformers)
* `baseMVA` - MVA base of transformer
* `type` - type of branch -- "xfmr" / "transformer", "line", or "series_cap"
* `config` - winding configuration of transformer -- currently "delta-delta", "delta-wye", "wye-delta", "wye-wye", "delta-gwye", "gwye-delta", "gwye-gwye", and "gwye-gwye-auto" are supported

```
%column_names% hi_bus lo_bus gmd_br_hi gmd_br_lo gmd_k gmd_br_series gmd_br_common baseMVA type config
mpc.branch_gmd = {
	1	3	1	-1	1.793	-1	-1	100	'xfmr'	'gwye-delta'
	1	2	-1	-1	-1	-1	-1	-1	'line'	'none'
	2	4	3	-1	1.793	-1	-1	100	'xfmr'	'gwye-delta'
};
```


### Branch Thermal Data Table 

This table includes
* `xfmr` - binary value that defines if branch is a transformer (1: transformer, 0: not a transformer)
* `temperature_ambient` - ambient temperature of transformer (in unit of Celsius)
* `hotspot_instant_limit` - 1-hour hot-spot temperature limit of transformer (in unit of Celsius)
* `hotspot_avg_limit` - 8-hour hot-spot temperature limit of transformer (in unit of Celsius)
* `hotspot_rated` - hot-spot temperature-rise of transformer at rated power (in unit of Celsius)
* `topoil_time_const` - top-oil temperature-rise time-constant of transformer (in unit of minutes)
* `topoil_rated` - top-oil temperature-rise of transformer at rated power (in unit of Celsius)
* `topoil_init` - initial top-oil temperature of transformer (in unit of Celsius)
* `topoil_initialized` - binary value that defines the initial top-oil temperature of transformer (1: temperature starts with `topoil_init` value, 0: temperature starts with steady-state value)
* `hotspot_coeff` - relationship of hot-spot temperature rise to Ieff (in unit of Celsius/Amp)

```
%column_names% xfmr temperature_ambient hotspot_instant_limit hotspot_avg_limit hotspot_rated
topoil_time_const topoil_rated topoil_init topoil_initialized hotspot_coeff
mpc.branch_thermal = {
	1	25	280	240	150	71	75	0	1	0.63
	0	-1	-1	-1	-1	-1	-1	-1	-1	-1
	1	25	280	240	150	71	75	0	1	0.63
};
```


### Bus GMD Data Table

This table includes 
* `lat` - latitude coordinate of ac network bus and corresponding dc network bus
* `lon` - longitude coordinate of ac network bus and corresponding dc network bus

```
%column_names% lat lon
mpc.bus_gmd = {
	40	-89
	40	-87
	40	-89
	40	-87
};
```


