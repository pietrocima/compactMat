# compactMat

Data structure that represents a virtual matrix, where elements are stored as an array of arrays arrays [element, row, column].
It has a fixed size, contained in the property Size as [s1, s2, ..., sM] defined at its initialization and editable through the method compactSetSize.
Elements are contained in the property Data as [v1, d11, ..., dM1], ..., [vN, d1N, ..., dMN]
Methods include tools to access and modify the data, as well as basic matrix operations such as element-wise sum and product, reshape and matrix multiplication.
A matrix that is virtually represented by a compactMat object can have size of each dimension up to 10^308, and single-digit-level precision is always mantained as long as chararToSym is used to insert data, without any approximation. This means a matrix of size s1 x s2 where s1 and s2 can be any natural numbers lower than 10^308, can be easily represented. This is thank to the fact that this structure is oriented to the elements of the matrix, rather than the real space it occupies. Consequently, it works the best with highly sparse large matrices, requiring less than one second for a matrix product between matrices 10^308 x 10^308. The most complex method is compactMatProd which has complexity that is quadratic of the matches (coordinates at which both matrices have an element), the rest have complexity linear or constant of the number of elements.

To run it, simply download the files and run the test.m file, putting everything in the same folder and adding it to the path.

%Developed by Pietro Cimarosto - github.com/pietrocima
