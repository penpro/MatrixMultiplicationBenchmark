# Matrix Multiplication Benchmark (Octave)

This repository benchmarks two matrix–vector multiplication kernels in GNU Octave: `Mv_mult_1` (row-by-column double loop) and `Mv_mult_2` (column-wise scaled vector add `y += x(i) * A(:,i)`). The driver `MatrixMultBenchMarker.m` iterates over multiple matrix sizes and trials, scales the number of repeats so that each size runs long enough to measure, records total time and time per call, writes a CSV of raw results, generates a scatter plot and a box plot, and writes basic system information.

Files included are `Mv_mult_1.m`, `Mv_mult_2.m`, and `MatrixMultBenchMarker.m`. When you run the driver it will create `mv_timings.csv` (raw data), `scatter_times.png` and `boxplot_times.png` (plots), and `system_info.txt` (Octave version, OS, CPU, RAM) in the working folder.

Requirements are GNU Octave (version 7 or 8 recommended). The Octave Forge `statistics` package provides `boxplot`. Install it once with `pkg install -forge statistics` (after running the command it can take upwards of 30 minutes to install depending on internet traffic etc so just run it and go get lunch or something) and load it in each Octave session with `pkg load statistics`. If the GUI does not show figures, set `graphics_toolkit('qt')` or use `graphics_toolkit('gnuplot')` as a fallback.

Quick start: open Octave, change to the repository folder, set a graphics toolkit if needed, load the statistics package, and run the driver. Example:
```
cd '<your path>/MatrixMultiplicationBenchmark'
graphics_toolkit('qt')    % or 'gnuplot' if qt is unavailable
pkg load statistics
MatrixMultBenchMarker
```
You should see progress in the Command Window. The CSV, plots, and system info file will be written to the current directory.

Configuration is in `MatrixMultBenchMarker.m`. Adjust the arrays and scalars at the top to fit your machine and assignment:
```
sizes      = [10 15 25 ... 200]   % sizes to test
trials     = 5                    % trials per size
base_n     = 100                  % scaling pivot
base_loops = 5                    % repeats at base_n
```
If runs are lengthy, reduce the list of sizes, lower the trial count, or decrease `base_loops`. You can also cap the repeats by setting `max_L` and using `L = min(max_L, loops_for_n(n));` inside the loop.

Notes on interpretation: Octave stores arrays in column-major order. `Mv_mult_2` processes `A` one column at a time with `y += x(i) * A(:,i)`, which streams contiguous memory and allows better cache use. `Mv_mult_1` fixes a row and walks across columns with a large stride in memory, which is less cache friendly. Both algorithms perform O(n^2) floating point operations but memory access costs dominate at larger n. For small matrices the difference is minor because loop overhead and interpreter costs dominate. For medium to large matrices `Mv_mult_2` generally shows lower median time per call. If you want a compiled baseline you can compare to the built-in `A*x` which uses BLAS when available.

Troubleshooting tips: if figures do not appear, run `graphics_toolkit('qt')` and `set(0,'DefaultFigureVisible','on')`. If `boxplot` fails, confirm that `statistics` is installed and loaded using `pkg load statistics; which boxplot`. If the box plot looks empty, verify that timing data exists and is finite with `whos time_call_all n_all func_id_all` and `sum(isfinite(time_call_all))`. On newer Windows versions the `wmic` tool is not present; this driver uses PowerShell `Get-CimInstance` calls for system info instead.

License: MIT for Octave
