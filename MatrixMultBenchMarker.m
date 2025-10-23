function MatrixMultBenchMarker()
  % MatrixMultBenchMarker.m
  % Multi-size, multi-trial timing, CSV + plots + system info.
  % Requires Mv_mult_1.m and Mv_mult_2.m in the same folder.

  % try to load boxplot
  try
    pkg load statistics;
  catch
    printf('Warning: could not load ''statistics'' package. Install with:\n');
    printf('  pkg install -forge statistics\n\n');
  end_try_catch

  % -------- params --------
  sizes = [10 15 25 30 35 40 45 50 55 60 65 70 75 80 85 90 95 100 110 120 130 140 150 160 170 180 190 200];
  trials = 5;
  base_n = 100;
  base_loops = 5;

  % reproducibility
  try
    rng(0);
  catch
    rand('seed', 0);
  end_try_catch

  % helper inline for loops scaling
  loops_for_n = @(n) max(1, round(base_loops * (base_n / n)^2));

  % warm-up
  A0 = rand(20,20); x0 = rand(20,1);
  Mv_mult_1(A0,x0);
  Mv_mult_2(A0,x0);

  % storage
  n_all = [];
  func_id_all = [];   % 1 = Mv_mult_1, 2 = Mv_mult_2
  trial_all = [];
  loops_used_all = [];
  time_tot_all = [];
  time_call_all = [];

  % -------- run --------
  for s = 1:numel(sizes)
    n = sizes(s);
    A = rand(n,n);
    x = rand(n,1);
    L = loops_for_n(n);

    for t = 1:trials
      % Mv_mult_1
      id = tic();
      for k = 1:L
        Mv_mult_1(A,x);
      endfor
      dt1 = toc(id);

      % Mv_mult_2
      id = tic();
      for k = 1:L
        Mv_mult_2(A,x);
      endfor
      dt2 = toc(id);

      % record
      n_all          = [n_all;          n; n];
      func_id_all    = [func_id_all;    1; 2];
      trial_all      = [trial_all;      t; t];
      loops_used_all = [loops_used_all; L; L];
      time_tot_all   = [time_tot_all;   dt1; dt2];
      time_call_all  = [time_call_all;  dt1 / L; dt2 / L];
    endfor
  endfor

  % -------- CSV --------
  csv_file = 'mv_timings.csv';
  fid = fopen(csv_file, 'w');
  fprintf(fid, 'n,function,trial,loops,total_seconds,seconds_per_call\n');
  for i = 1:numel(n_all)
    if func_id_all(i) == 1
      fn = 'Mv_mult_1';
    else
      fn = 'Mv_mult_2';
    endif
    fprintf(fid, '%d,%s,%d,%d,%.9f,%.9f\n', ...
            n_all(i), fn, trial_all(i), loops_used_all(i), time_tot_all(i), time_call_all(i));
  endfor
  fclose(fid);
  printf('Wrote %s\n', csv_file);

% -------- box plot (simple & reliable) --------
figure(2); clf;

% convert to microseconds and filter bad values
t_us = time_call_all(:) * 1e6;
sz    = n_all(:);
fid    = func_id_all(:);   % 1=Mv_mult_1, 2=Mv_mult_2
valid  = isfinite(t_us) & isfinite(sz) & isfinite(fid);
t_us   = t_us(valid);  sz = sz(valid);  fid = fid(valid);

if isempty(t_us)
  warning('No timing data to plot. Skipping boxplot.');
else
  sizes_u = unique(sz, 'stable');
  funcs_u = [1 2];

  vals2 = []; grp = []; labels = {};
  gid = 0;

  for si = 1:numel(sizes_u)
    for fj = 1:numel(funcs_u)
      gid = gid + 1;
      v = t_us(sz == sizes_u(si) & fid == funcs_u(fj));
      vals2 = [vals2; v];
      grp   = [grp; gid * ones(numel(v), 1)];
      if funcs_u(fj) == 1
        fn = 'Mv_mult_1';
      else
        fn = 'Mv_mult_2';
      endif
      labels{gid} = sprintf('%d, sizes_u(si));
    endfor
  endfor

  if isempty(vals2)
    warning('No grouped data. Check that time_call_all is populated.');
  else
    boxplot(vals2, grp, 'labels', labels);
    set(gca, 'XTick', 1:numel(labels), 'XTickLabel', labels);
    xlabel('size and function'); ylabel('microseconds per call');
    title('Time per call by size and function');
    grid on; drawnow;
    print('boxplot_times.png','-dpng','-r800');
    printf('Wrote boxplot_times.png\n');
  endif
endif




  % -------- median speedup summary --------
  printf('\nMedian speedup (Mv_mult_1 time / Mv_mult_2 time):\n');
  for s = 1:numel(sizes)
    n = sizes(s);
    m1 = median(time_call_all(n_all==n & func_id_all==1));
    m2 = median(time_call_all(n_all==n & func_id_all==2));
    printf('  n=%4d : %6.3fx\n', n, m1/m2);
  endfor

  % -------- system info --------
  info_txt = 'system_info.txt';
  fid = fopen(info_txt, 'w');
  fprintf(fid, 'Device & Software Info\n');
  fprintf(fid, '======================\n');

  % Octave version
  try
    v = ver('octave');
    fprintf(fid, 'Octave: %s %s\n', v.Name, v.Version);
  catch
    fprintf(fid, 'Octave version: unknown\n');
  end_try_catch

if ispc()
  fprintf(fid, "OS:\n");
  [~, osout] = system(['powershell -NoProfile -Command ', ...
    '"(Get-CimInstance Win32_OperatingSystem | Select-Object Caption,Version,OSArchitecture) ', ...
    '| Format-List | Out-String"']);
  fprintf(fid, "%s\n", osout);

  fprintf(fid, "CPU:\n");
  [~, cpuout] = system(['powershell -NoProfile -Command ', ...
    '"(Get-CimInstance Win32_Processor | Select-Object -First 1 Name,NumberOfCores,NumberOfLogicalProcessors,MaxClockSpeed) ', ...
    '| Format-List | Out-String"']);
  fprintf(fid, "%s\n", cpuout);

  fprintf(fid, "RAM:\n");
  % Pretty GiB line plus raw bytes
  [~, mem_gib] = system(['powershell -NoProfile -Command ', ...
    '"[math]::Round((Get-CimInstance Win32_ComputerSystem).TotalPhysicalMemory/1GB,2)"']);
  [~, mem_bytes] = system(['powershell -NoProfile -Command ', ...
    '"(Get-CimInstance Win32_ComputerSystem).TotalPhysicalMemory"']);
  fprintf(fid, "TotalPhysicalMemoryGiB: %s\n", strtrim(mem_gib));
  fprintf(fid, "TotalPhysicalMemoryBytes: %s\n\n", strtrim(mem_bytes));

  elseif ismac()
    fprintf(fid, 'OS:\n');
    [~, osout] = system('sw_vers');
    fprintf(fid, '%s\n', osout);

    fprintf(fid, 'CPU:\n');
    [~, cpuout] = system('sysctl -n machdep.cpu.brand_string');
    fprintf(fid, '%s\n', cpuout);

    fprintf(fid, 'RAM (bytes):\n');
    [~, memout] = system('sysctl -n hw.memsize');
    fprintf(fid, '%s\n', memout);

  else
    fprintf(fid, 'OS:\n');
    [~, osout] = system('uname -srv');
    fprintf(fid, '%s\n', osout);

    fprintf(fid, 'CPU:\n');
    [~, cpuout] = system('grep -m1 ''model name'' /proc/cpuinfo');
    fprintf(fid, '%s\n', cpuout);

    fprintf(fid, 'RAM:\n');
    [~, memout] = system('grep MemTotal /proc/meminfo');
    fprintf(fid, '%s\n', memout);
  end

  fclose(fid);
  printf('Wrote %s\n', info_txt);
  printf('\nDone.\n');
endfunction

