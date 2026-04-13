#include <iostream>

class A{
    int a;
public:
    A(): a(0) {
                std::cout<<__PRETTY_FUNCTION__ <<""<<"\n";

    }
    A(const A& a): a(a.a) {
        std::cout<<__PRETTY_FUNCTION__ <<", const A&a"<<"\n";
    }
    A(A&& other) noexcept : a(other.a) {
        std::cout << __PRETTY_FUNCTION__ << " move\n";
        other.a = 0; // 可选
    }
};

A&& rv(){
    return A();
}

A ret(){
    return A();
}

int main(){
    A a = rv();
    A b = ret();

    return 0;
}
