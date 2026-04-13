#include <iostream>

struct alignas(8) A {
    char a;
    int b;
    long long c;
};

int main(){

    std::cout<< sizeof(A)<<"\n";
    return 0;
}

