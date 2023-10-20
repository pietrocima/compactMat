clear all
close all
clc

dim1 = 10^308;
dim2 = 10^308;

M = compactMat('void', [dim1, dim2]); %Void initialization
M = compactInsert('list', M, [[15 10^30 3]; [15, 50 ,10^20]; [15 2 chararToSym('1234567890123456789000')]]); %Insert elements into void mat
D = compactGetInfo(M);

R = compactFind('coord', M, [15, 10^30], [1, 2]);



Ms = compactMat('list', [dim1, dim2], [[15 100000 23]; [15 10 10000000]; [45 1 10000]]); %Initialization with elements
Ms2 = compactInsert('list', compactMat('void', [dim1, dim2]), [[15 100000 23]; [15 10 10000000]; [45 1 10000]]);

a = round(rand(100, 100) * 10);
Mk = compactMat('mat', [dim1, dim2], a); %Initialization from matrix


ms = compactTranspose(Mk, [2, 1]);

R = compactReshape(M, 100, []);
S = compactElementwise('sum', M, Ms);
t = tic;
P = compactMatProd(Mk, ms);
fprintf('Time elapsed: %5f seconds\n',toc(t))


val = (1:4:2500);

M1 = compactInsert('list', M, [(val*3+1)', val', ones(length(val), 1)]);
M2 = compactInsert('mat', M, val);



% save 'M' M;
% %save 'M1' M1;
% 
% save 'val' val;
% %save 'val1' val1;