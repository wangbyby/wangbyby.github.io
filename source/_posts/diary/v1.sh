# set -x

clang++ -c v1.cpp -o v1.o -S -emit-llvm
clang++ -c v2.cpp -o v2.o -S -emit-llvm
clang++ v1.o v2.o -o a.out  