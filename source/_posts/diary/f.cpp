#include <iostream>
#include <utility>

struct A {};

template <typename T> struct Base {};

struct C : Base<C> {};

struct D : Base<D> {
  int a;
};

int main() {
  std::cout << "sizeof A:" << sizeof(A) << "\n"; // 1
  std::cout << "sizeof C:" << sizeof(C) << "\n"; // 1
  std::cout << "sizeof D:" << sizeof(D) << "\n"; // 4
  return 0;
}
