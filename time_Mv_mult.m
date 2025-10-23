n = 10
loops = 100
A = magic(n);
x = rand(n, 1);

disp('Timing Mv_mult_1');
id = tic();
for i = 1:loops
  Mv_mult_1(A,x);
endfor
time = toc(id)


disp('Timing Mv_mult_2');
id = tic();
for i = 1:loops
  Mv_mult_2(A,x);
endfor
time = toc(id)

