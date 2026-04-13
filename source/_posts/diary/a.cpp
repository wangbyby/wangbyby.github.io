
#include <initializer_list>
#include <memory>
#include <iostream>

class A {
    int x;
    int y;
public:
    A(std::initializer_list<int*> a){}
    A(int a):x(a), y(0) {}
    A(int a, int b) : x(a), y(b) {}
};
struct B{
    int a;
    int *p = nullptr;
    int k;
};

void bar(int &);
void foo(const int &);

int main() {
    A aa{};
    A a0{2};
    A a1{1,2};

    B b{1,nullptr};

    const int &ip = 10;
    foo(10);

    auto sp = std::make_shared<int>(100);
    std::cout << sp.use_count() <<  "\n"; // 1

    std::weak_ptr<int> wp = sp;
    std::cout << wp.use_count() << ", "<< sp.use_count() <<  "\n"; // 1

    auto s2 = sp;
    std::cout << wp.use_count() << ", "<< sp.use_count() <<  "\n"; // 1


    if (auto locked = wp.lock()) {
        std::cout << *locked <<","<<locked.use_count() << "\n"; // 100
    }else{
        std::cout <<"none\n";
    }
}
