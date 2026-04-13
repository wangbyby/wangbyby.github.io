#include <iostream>
#include <utility>

// void foo(int a);

void foo(int& a){
    std::cout <<"int&"<<"\n";
}

void foo(int && a){
    std::cout <<"int &&"<<"\n";

}

int&& b();

int main(){
    int && r = 10;
    int r2 = b();
    // foo(b());
    foo((int&&)r);
    foo(static_cast< int&&>(r));
    return 0;
}

