// MyStrategy.cpp
#include "v1.h"

// 实现一个派生类
class TopDownStrategy : public MyStrategy {
public:
  void schedule() override {
    // 调度逻辑...
  }
};

static TopDownStrategy s;

void runScheduler(MyStrategy *S) {
  S->schedule();  // 通过基类指针调用虚函数
}
