function y = Mv_mult_2(A, x)
    [x_rows, _] = size(x);
    [A_rows, A_cols] = size(A);
    assert(x_rows == A_cols);
    y = zeros(A_rows, 1);

    for i = 1:A_cols
        y += x(i) * A(:,i);
    endfor
endfunction
