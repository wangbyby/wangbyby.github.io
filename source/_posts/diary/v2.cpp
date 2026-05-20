
// main.cpp
#include "v1.h"

class AnotherStrategy : public MyStrategy {
public:
  void schedule() override {
    // 另一种调度逻辑...
  }
};

int main() {
  AnotherStrategy S;
  runScheduler(&S);
  return 0;
}
