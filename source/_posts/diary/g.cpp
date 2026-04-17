
class A {
public:
  virtual void foo();
};

class B : public A {
  int a;

public:
  void foo() {};
};

B *foo(A *a) { return dynamic_cast<B *>(a); }
