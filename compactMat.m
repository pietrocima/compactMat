%% Class compactMat
% Data structure that represents a virtual matrix, where elements are
% stored as an array of arrays arrays [element, row, column].
% It has a fixed size, contained in the property Size as [s1, s2, ..., sM]
% defined at its initialization and editable through the method compactSetSize.
% Elements are contained in the property Data as [v1, d11, ..., dM1], ..., [vN, d1N, ..., dMN]
% Methods include tools to access and modify the data, as well as basic
% matrix operations such as element-wise sum and product, reshape and matrix
% multiplication.
% A matrix that is virtually represented by a compactMat object can have size of
% each dimension up to 10^308, and single-digit-level precision is always mantained as
% long as chararToSym is used to insert data, without any approximation.
% This means a matrix of size s1 x s2 where s1 and s2 can be any natural
% numbers lower than 10^308, can be easily represented. This is thank to
% the fact that this structure is oriented to the elements of the
% matrix, rather than the real space it occupies. Consequently, it works the best
% with highly sparse large matrices, requiring less than one second for a
% matrix product between matrices 10^308 x 10^308. The most complex method is 
% compactMatProd which has complexity that is quadratic of the matches
% (coordinates at which both matrices have an element), the rest have
% complexity linear or constant of the number of elements.




classdef compactMat
    properties (SetAccess = private)
        %size of virtual matrix/tensor 
        Size (1, :) = 0;

        %list of elements [v1, d11, ..., dM1], ..., [vN, d1N, ..., dMN]
        %representing a virtual matrix (M = 2) or tensor
        Data = []; 

    end

    methods

        %% compactMat 
        function M = compactMat(f, size, e)

        %Constructor:
        %Has three variants depending on the value of the flag f in the call:
        %'void' -> initializes empty matrix given size as [n_rows, n_cols]
        %'list' -> initializes matrix of given size with given list of
        %elements, takes two arguments: first [n_rows, n_cols] and second a list of elements [[e1, r1, c1]; [e2, r2, c2];...]
        %'mat' -> initializes matrix of given size with given 2D matrix (convert into list of elements and
        %insert)

            warning(['Values and coordinates with more than 9 digits will be approximated by default by Matlab. If numbers long more than 9 digits are used, ' ...
                'use function chararToSym'])
            switch f
                case 'void'  %Empty initialization

                    M.Size = sym(size);

                case 'list' %Initialization with elements

                    M.Size = sym(size);
                    M = compactInsert(f, M, e);

                case 'mat' %Initialization from bi-dimensional matrix
                    
                    M.Size = sym(size);
                    M = compactInsert(f, M, e);

            end
        end


        %% compactInsert

        function M = compactInsert(f, M, e)

        %Has two variants depending on the value of the flag f in the call:
        %'list' -> insert stack of elements [elem, row, col]. Inserts data [[e1, r1, c1]; [e2, r2, c2];...] 
        %in the compactMat object. If an element is already present in the matrix at
        %the given coordinates, the value is updated. Otherwise, it is
        %inserted from scratch
        %'mat' -> insert entire 2D matrix (convert into stack of elements and
        %insert)
        %Throws error if elements with rows or cols higher than the
        %values in Size. 
        % Throws error if at least two elements with the
        %same coordinates are given in input, as all elements must be
        %unique in the call

            switch f
                case 'list'

                if any(e(:,2) > M.Size(1)) || any(e(:,3) > M.Size(2))
                    error('Size out of Mat, element was not inserted. Change index or enlarge matrix \n')
                end
    
                u = unique(e(:, 2:end), 'rows');
                hasDuplicates = size(u,1) < size(e,1);
                if hasDuplicates
                    error('The call contained multiple elements to be added at the same coordinates. Only one element for the same set of coordinates is allowed in one call. \n')
                end          

                if any(isa(e, 'sym'))
                    warning('This object contains sym data.')
                end
    
                cM = M.Data;
                if ~isempty(cM)
                    [~,index_M,index_e] = intersect(cM(:, 2:end), e(:,2:end),'rows');
                    if ~(isempty(index_M) && isempty(index_e))
                        M.Data(index_M, 1) = e(index_e, 1);
                        e(index_e, :) = [];
                    end
                end

                M.Data = [M.Data; e];
                M.Data = sortrows(M.Data, 2);


                case 'mat'
                    if length(size(e)) > 2
                        error('Matrix initialization only allows 2D matrices');
                    end

                    values = [];
                    
                    for i = 1:size(e, 1)
                        for j = 1:size(e, 2)
                            values = [values; [e(i, j), i, j]   ];
                        end
                    end

                    M = compactInsert('list', M, values);
            end

        end

        %% compactSetSize


        function M = compactSetSize(M, size)

        %Updates the size of the matrix. Throws error is element are
        %present with coordinates higher than the new boundaries, in that
        %case, the elements must be deleted manually (compactDelete method).

            if any(size(1) < M.Data(:, 2)) || any(size(2) < M.Data(:, 3)) 
                error('Resizing not allowed, due to element in matrix at index higher than the new matrix dimension. First move that element to be within the new boundaries.')
            end
            M.Size = sym(size);
        end


        %% compactFind


        function R = compactFind(mode, M, what, where)

        %Given a value to search as "what", finds the element(s) that match
        %such value in the column "where" of the data. If mode == 'elem' the
        %search is executed on DataInd (indexing my element), if mode ==
        %'coord' it is executed on Data (indexing by row/cols)
        %The method allows multi-index search: the length of what and where
        %must coincide. Tf that is so, each "what" is searched at the
        %corresponding "where"       
        %Example: compactMat represents a 2D matrix and Data is N x 3
        %with elements [value1, row1, col1], ..., [valueN, rowN, colN].         
        %A call compactFind('coord', M, 1, 1) will return all elements [valuei, rowi, coli]
        %with valuei == 1. 
        % A call compactFind('coord', M, 1, 2) returns all elements at the 1st row of the matrix.
        %A call compactFind('coord', M, [1, 1], [1, 2]) will return all elements [valuei, rowi, coli]
        %with valuei == 1 && rowi == 1. 
        % A call compactFind('elem', M, 1, 2) returns the first element of the
        % matrix by element indexing (as if it was an reshaped to a one-row array)


            if length(what) ~= length(where)
                error('Length of what and length of where must coincide.')
            end

            D = compactGetInfo(M);
            switch mode
                case 'elem'
                [R] = D.DataInd(find(D.DataInd(:, where)' == what'), :);
                case 'coord'
                [R] = D.Data(find(all(D.Data(:, where)' == what')), :);
            end
        end

        %% compactGetInfo

        function D = compactGetInfo(M)

        %Gives an overview of the compactMat object as a structure with:
        %Size - size of matrix
        %Data - list of matrix elements
        %DataDouble - approximated data (for readability in case of sym data)
        %SizeDouble - approximated size (for readability in case of sym data)
        %DataInd - list of matrix element indexed by element (as if the
        %matrix was reshaped to a 1D array)

            D.Data = M.Data;
            D.DataDouble = double(M.Data); 
            D.Size = M.Size;
            D.SizeDouble = double(M.Size); 


            D.DataInd = [];

            tempSize = [1 M.Size];

            for indel = 1:size(M.Data, 1)
                  el = M.Data(indel, :);
                  elN = 1;

                  for indSize = 1:length(tempSize)-1
                      elN = elN + (prod(tempSize(1:end-indSize)) * (el(end-indSize+1)-sym(1)));
                  end
                  D.DataInd = [D.DataInd; el(1) elN];
            end
        end

        %% compactReshape
        

        function Mr = compactReshape(M, varargin)

        %Reshapes matrix given the compactMat object to reshape and
        %arguments the length of each dimension (example: compactReshape(M,
        %rows, cols) or compactReshape(M, d1, d2, d3, d4, ...))
        %One length can be [], but the product of all lengths, i.e., the
        %number of elements in the matrix, must be the same.
        %!!Bug: if operating on n-dimensional mats / tensors, newN ~= oldN.
        %Stick to 2D until fixed

              pastSize = [1, M.Size];

              if any(cellfun(@(c) ~isempty(c), varargin))
                    freeL = prod(pastSize)/prod([varargin{:}]);
                    for indcell = 1:length(varargin)
                        if isempty(varargin{indcell})
                            varargin{indcell} = freeL;
                            freeL = [];
                        end
                    end
              end

              newSize = sym([varargin{:}]);
              Mr = compactMat('void', newSize);

              newSize = [sym(1), newSize];


              if prod(pastSize) ~= prod(newSize)
                error("Number of elements in reshape must coincide: Newrows x Newcols != Oldrows x Oldcols")
              end


              for indel = 1:size(M.Data, 1)

                  oldN = 1;
                  newN = 1;
                  el = M.Data(indel, :);
                  newel = [el(1), ones(1, length(newSize)-1)];

                  %Element indexing in old size
                  for indSize = 1:length(pastSize)-1
                      oldN = oldN + (prod(pastSize(1:end-indSize)) * (el(end-indSize+1)-sym(1)));
                  end

                  %Building element coordinates in new size
                  temp = oldN;
                  for indSize = 1:length(newSize)-1
                      newel(end- indSize +1) = max(sym(1),floor(rdivide(temp,prod(newSize(1:end-indSize))))+sym(1));
                      temp = rem(temp, prod(newSize(1:end-indSize)) * (newel(end- indSize +1)-sym(1)))-sym(1);
                  end

                  %Element indexing in new size (should coincide with old)
                  for indSize = 1:length(newSize)-1
                      newN = newN + (prod(newSize(1:end-indSize)) * (newel(end-indSize+1)-sym(1)));
                  end

                  Mr = compactInsert('list', Mr, newel);
              end
          end



        %% compactDelete

        function M = compactDelete(M, coord)
        %Deletes an element at the given coordinates, if existing


            M.Data(compactFind(1, M, coord, [2:length(coord)+1]), :) = [];
        end

        
        %% compactTranspose

        function M = compactTranspose(M, order)
        %Gives the transpose of the matrix represented by a compactMat object

            M.Data = M.Data(:, [1, order+1]); 
            M.Size = M.Size(order);
        end


        %% compactElementWise
       

        function S = compactElementwise(op, M, Ms)

        %Gives the result of an element-wise operation between two matrices
        %represented as compactMat objects. The matrices must have the same
        %Size (throws error otherwise). The operation is defined in input,
        %choices are sum,, subtraction (sub), multiplication (mul), division (div)


            if any(compactGetInfo(M).Size ~= compactGetInfo(Ms).Size)
                error('compactElementwise must be performed between compactMat objects with the same size.')
            end
            S = compactMat('void', compactGetInfo(M).Size);

            cM = compactGetInfo(M).Data;
            cMs = compactGetInfo(Ms).Data;

            [~,index_M,index_Ms] = intersect(cM(:, 2:end), cMs(:,2:end),'rows');
            switch op
                case 'sum' 
                    S = compactInsert('list', S, cat(2, cM(index_M, 1) + cMs(index_Ms, 1), cM(index_M, 2:end)));
                    cM(index_M, :) = [];
                    cMs(index_Ms, :) = [];
                    S = compactInsert(0, S, cat(1, cM, cMs));

                case 'sub' 
                    S = compactInsert(0, S, cat(2, cM(index_M, 1) - cMs(index_Ms, 1), cM(index_M, 2:end)));
                    cM(index_M, :) = [];
                    cMs(index_Ms, :) = [];
                    S = compactInsert(0, S, cat(1, cM, cMs));

                case 'mul' 
                    S = compactInsert(0, S, cat(2, cM(index_M, 1) .* cMs(index_Ms, 1), cM(index_M, 2:end)));

                case 'div' 
                    S = compactInsert(0, S, cat(2, cM(index_M, 1) ./ cMs(index_Ms, 1), cM(index_M, 2:end)));

            end
        end

        %% compactMatProd
        

        function P = compactMatProd(M, Ms)

        %Gives the result of an matrix multiplication between two matrices
        %represented as compactMat objects. The first matrix must have the same
        %number of rows of the cols of thesecond matrix, and the same number of
        %cols of the rows of the second matrix (throws error otherwise).
        %Also, the matrices must be bi-dimensional.

            if length(M.Size) > 2 || length(Ms.Size) > 2
                error('compactMatProd must be performed between bidimensional compactMat objects (length Size <= 2).')
            end
            if (M.Size(2) ~= Ms.Size(1))
                error('compactMatProd must be performed between compactMat objects with equal cols of the first mat and rows of the second mat.')
            end
                
            P = compactMat('void',[M.Size(1), Ms.Size(2)]);

            cM = M.Data;
            cMs = Ms.Data;
            uniqueRows = unique(cM(:, 2));
            uniqueCols = unique(cMs(:, 3));


            for r = 1:length(uniqueRows)
                cMt = cM((cM(:,2) == uniqueRows(r)),:);
                for c = 1:length(uniqueCols)
                    cMst = cMs((cMs(:,3) == uniqueCols(c)),:);

                    [~,index_M,index_Ms] = intersect(cMt(:, 3), cMst(:,2),'rows');
                    nonZero = cat(2, cMt(index_M, 1) .* cMst(index_Ms, 1), cMt(index_M, 2), cMst(index_Ms, 3));
                    P = compactInsert('list', P, [sum(nonZero(:, 1)), uniqueRows(r), uniqueCols(c)]);
                end
            end


            end
        end
end