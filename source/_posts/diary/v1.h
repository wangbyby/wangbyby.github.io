// MyStrategy.h
#pragma once

class MyStrategy {
public:
  // 这是一个抽象基类，只有纯虚函数，没有非内联虚函数
  virtual void schedule() = 0;
  virtual ~MyStrategy() = default;
};

// 声明一个使用这个接口的全局函数
void runScheduler(MyStrategy *S);
